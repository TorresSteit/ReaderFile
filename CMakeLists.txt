cmake_minimum_required(VERSION 3.16)
project(untitled)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(-Wall -Wextra)

find_package(fmt REQUIRED)

add_executable(file_analyzer src/main.cpp)
target_link_libraries(file_analyzer PRIVATE fmt::fmt)