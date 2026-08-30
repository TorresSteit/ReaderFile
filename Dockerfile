# ---------- Stage 1: build ----------
# Build stage: uses the gcc:13 image, which includes the GCC 13 compiler
# and standard build tools. This stage compiles the project but is
# discarded after the build — it never ends up in the final image.
# RU: Стадия сборки: используем образ gcc:13, в котором уже есть
# компилятор GCC 13 и стандартные инструменты сборки. Эта стадия
# компилирует проект, но отбрасывается после сборки — она никогда
# не попадёт в финальный образ.
FROM gcc:13 AS build

# Set the working directory inside the container for all following commands.
# RU: Устанавливаем рабочую директорию внутри контейнера для всех
# последующих команд.
WORKDIR /app

# Copy only the files needed for the build first, before the full source.
# This improves Docker layer caching: if only main.cpp changes, these
# earlier layers (and the apt-get/conan install below) can stay cached.
# RU: Сначала копируем только файлы, нужные для сборки — это улучшает
# кэширование слоёв Docker: если поменяется только main.cpp, эти более
# ранние слои (включая apt-get/conan install ниже) останутся в кэше.
COPY CMakeLists.txt .
COPY conanfile.txt .
COPY src/ ./src/

# Install cmake (not included in the gcc image by default) and python3-pip
# (required to install Conan via pip). --no-install-recommends avoids
# pulling in unnecessary extra packages, keeping this layer smaller.
# rm -rf /var/lib/apt/lists/* clears the apt package cache afterward,
# so it doesn't bloat the image layer.
# RU: Устанавливаем cmake (его нет в образе gcc по умолчанию) и
# python3-pip (нужен для установки Conan через pip).
# --no-install-recommends не тянет лишние необязательные пакеты,
# уменьшая размер слоя. rm -rf /var/lib/apt/lists/* очищает кэш apt
# после установки, чтобы не раздувать образ.
RUN apt-get update && apt-get install -y --no-install-recommends cmake python3-pip && rm -rf /var/lib/apt/lists/*

# Install Conan (C++ package manager) via pip.
# --break-system-packages is required on newer Debian/Ubuntu images,
# which block direct pip installs into the system Python by default (PEP 668).
# RU: Устанавливаем Conan (менеджер пакетов для C++) через pip.
# --break-system-packages обязателен на новых образах Debian/Ubuntu,
# которые по умолчанию блокируют прямую установку через pip в системный
# Python (PEP 668).
RUN pip install --break-system-packages conan

# Auto-detect a Conan profile (compiler version, architecture, OS, C++
# standard settings) based on the current environment. Conan needs this
# profile to know how to build/select the right binary packages.
# RU: Автоматически определяем Conan-профиль (версия компилятора,
# архитектура, ОС, настройки стандарта C++) на основе текущего окружения.
# Этот профиль нужен Conan, чтобы понять, как собрать или подобрать
# нужные бинарные пакеты.
RUN conan profile detect

# Install project dependencies (fmt, per conanfile.txt) into the ./build
# folder. --build=missing tells Conan to compile from source any package
# for which no pre-built binary is available for this exact platform/compiler.
# -s build_type=Release ensures Conan builds/selects Release binaries,
# matching the CMake build type used below.
# RU: Устанавливаем зависимости проекта (fmt, согласно conanfile.txt)
# в папку ./build. --build=missing говорит Conan собрать из исходников
# любой пакет, для которого нет готового бинарника под эту платформу
# и компилятор. -s build_type=Release гарантирует, что Conan
# соберёт/подберёт именно Release-версии, совпадающие с типом сборки
# CMake ниже.
RUN conan install . --output-folder=build --build=missing -s build_type=Release

# Configure the project with CMake, using the toolchain file generated
# by Conan (sets compiler flags/settings to match the installed
# dependencies). CMAKE_BUILD_TYPE=Release must match the build_type
# used in the Conan install step above.
# RU: Конфигурируем проект через CMake, используя toolchain-файл,
# сгенерированный Conan (задаёт флаги компилятора/настройки,
# совпадающие с установленными зависимостями). CMAKE_BUILD_TYPE=Release
# должен совпадать с build_type, указанным в шаге conan install выше.
RUN cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release

# Actually compile the project — produces the file_analyzer binary
# inside ./build.
# RU: Непосредственно компилируем проект — итоговый бинарник
# file_analyzer появляется внутри ./build.
RUN cmake --build build

# ---------- Stage 2: runtime ----------
# Runtime stage: starts from a clean, minimal Ubuntu image with no
# compiler, no Conan, no source code — only what's needed to run the
# already-built binary. This keeps the final image small and reduces
# its attack surface.
# RU: Стадия запуска: чистый минимальный образ Ubuntu без компилятора,
# без Conan, без исходного кода — только то, что нужно для запуска
# уже собранного бинарника. Это делает финальный образ маленьким
# и уменьшает поверхность атаки.
FROM ubuntu:24.04

WORKDIR /app

# Copy ONLY the compiled binary from the build stage — nothing else
# from that stage (no compiler, no intermediate build files) makes it
# into the final image.
# RU: Копируем ТОЛЬКО скомпилированный бинарник из build-стадии —
# больше ничего из неё (ни компилятор, ни промежуточные файлы сборки)
# не попадает в финальный образ.
COPY --from=build /app/build/file_analyzer ./file_analyzer

# Default value for the directory the program scans. Can be overridden
# at runtime via `docker run -e SCAN_DIR=...` or docker-compose environment/env_file.
# RU: Значение по умолчанию для директории, которую сканирует программа.
# Можно переопределить при запуске через `docker run -e SCAN_DIR=...`
# или environment/env_file в docker-compose.
ENV SCAN_DIR=/data

# Documents which port the container would listen on if this were
# turned into a network service. Currently unused by this CLI tool —
# kept here as a placeholder/example for a future HTTP API.
# RU: Документирует, какой порт слушал бы контейнер, если бы это был
# сетевой сервис. Сейчас не используется этой CLI-утилитой — оставлен
# как заготовка/пример на случай будущего HTTP API.
EXPOSE 8080

# The command that runs when the container starts.
# RU: Команда, которая выполняется при запуске контейнера.
CMD ["./file_analyzer"]