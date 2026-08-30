# Minimum CMake version required to build this project.
# RU: Минимальная версия CMake, необходимая для сборки проекта.
cmake_minimum_required(VERSION 3.16)

# Project name — used internally by CMake, also appears in IDE project settings.
# RU: Название проекта — используется CMake внутри, отображается в настройках IDE.
project(untitled)

# Require C++20 — enables modern language features (concepts, ranges, etc.).
# RU: Требуем стандарт C++20 — даёт доступ к современным возможностям языка
# (concepts, ranges и т.д.).
set(CMAKE_CXX_STANDARD 20)

# If the compiler doesn't support C++20, fail the build instead of silently
# falling back to an older standard.
# RU: Если компилятор не поддерживает C++20, сборка упадёт с ошибкой,
# а не тихо откатится на более старый стандарт.
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable extended compiler warnings — catches unused variables, sign
# comparison issues, and other common mistakes at compile time.
# RU: Включаем расширенные предупреждения компилятора — ловят
# неиспользуемые переменные, проблемы сравнения signed/unsigned
# и другие частые ошибки ещё на этапе компиляции.
add_compile_options(-Wall -Wextra)

# Look for the fmt library, installed via Conan (see conanfile.txt).
# fmt is a fast, modern string formatting library — a safer and more
# convenient alternative to printf/std::cout for building formatted output.
# REQUIRED means the build fails immediately if fmt isn't found.
# RU: Ищем библиотеку fmt, установленную через Conan (см. conanfile.txt).
# fmt — быстрая современная библиотека форматирования строк, более
# безопасная и удобная альтернатива printf/std::cout.
# REQUIRED означает, что сборка сразу упадёт, если fmt не найдена.
find_package(fmt REQUIRED)

# Define the executable target — compiles src/main.cpp into a binary
# named "file_analyzer".
# RU: Определяем исполняемый файл — компилирует src/main.cpp в бинарник
# с именем "file_analyzer".
add_executable(file_analyzer src/main.cpp)

# Link the fmt library to our executable.
# PRIVATE means fmt is only used internally by this target, not exposed
# to anything that might depend on file_analyzer (irrelevant here since
# this is an executable, not a library, but it's good practice).
# RU: Подключаем библиотеку fmt к нашему исполняемому файлу.
# PRIVATE означает, что fmt используется только внутри этого таргета,
# не "пробрасывается" наружу тем, кто мог бы зависеть от file_analyzer
# (здесь не критично, так как это исполняемый файл, а не библиотека,
# но это хорошая практика).
target_link_libraries(file_analyzer PRIVATE fmt::fmt)