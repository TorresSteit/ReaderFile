# ---------- Stage 1: build ----------
# Образ с компилятором GCC 13 — здесь есть всё для сборки (компилятор, cmake, apt)
FROM gcc:13 AS build

WORKDIR /app

# Копируем файлы отдельно от исходников, чтобы Docker кэшировал слои эффективнее:
# если поменяется только main.cpp, CMakeLists.txt не нужно копировать заново
COPY CMakeLists.txt .
COPY src/ ./src/

# В образе gcc нет cmake по умолчанию — ставим отдельно
# rm -rf /var/lib/apt/lists/* чистит кэш apt, чтобы не раздувать слой образа
RUN apt-get update && apt-get install -y --no-install-recommends cmake=3.25.1-1 && rm -rf /var/lib/apt/lists/*

# Конфигурируем проект (создаём build/) и собираем бинарник
# Имя бинарника берётся из add_executable(<имя> ...) в CMakeLists.txt
RUN cmake -B build -S . && cmake --build build

# ---------- Stage 2: runtime ----------
# Ubuntu вместо gcc/debian — чистый образ БЕЗ компилятора и исходников,
# только то, что нужно для запуска готового бинарника (маленький размер)
FROM ubuntu:24.04

WORKDIR /app

# Копируем ТОЛЬКО готовый бинарник из стадии build
# ⚠️ ВАЖНО: имя файла (/app/build/<имя>) должно СОВПАДАТЬ с add_executable() в CMakeLists.txt
COPY --from=build /app/build/file_analyzer ./file_analyzer

# Переменная окружения по умолчанию — путь, который сканирует программа.
# Можно переопределить снаружи через docker run -e или .env / environment: в compose
ENV SCAN_DIR=/data

# EXPOSE документирует порт, который слушает приложение внутри контейнера.
# Для этой CLI-утилиты (читает файлы, не поднимает сервер) порт не нужен —
# но если позже добавишь HTTP API поверх, сеть будет слушать именно здесь
EXPOSE 8080

# Команда запуска контейнера — выполняет бинарник
CMD ["./file_analyzer"]