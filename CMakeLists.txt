cmake_minimum_required(VERSION 3.16)
project(untitled)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)   # требовать именно C++20, не откатываться на более старый

add_compile_options(-Wall -Wextra)    # включить предупреждения компилятора — часто спрашивают про это

add_executable(file_analyzer src/main.cpp)