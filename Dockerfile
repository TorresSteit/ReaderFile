# ---------- Stage 1: build ----------
FROM gcc:13 AS build

WORKDIR /app

COPY CMakeLists.txt .
COPY conanfile.txt .
COPY src/ ./src/

RUN apt-get update && apt-get install -y --no-install-recommends cmake python3-pip && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages conan
RUN conan profile detect

RUN conan install . --output-folder=build --build=missing -s build_type=Release

RUN cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build

# ---------- Stage 2: runtime ----------
FROM ubuntu:24.04
WORKDIR /app
COPY --from=build /app/build/file_analyzer ./file_analyzer
ENV SCAN_DIR=/data
EXPOSE 8080
CMD ["./file_analyzer"]