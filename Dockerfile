

FROM gcc:13 AS build

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages conan

COPY conanfile.txt .

RUN conan profile detect --force && \
    conan install . --output-folder=build --build=missing -s build_type=Release

COPY CMakeLists.txt .
COPY src ./src

RUN cmake -B build -S . \
    -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j$(nproc)


FROM debian:bookworm-slim AS runtime

WORKDIR /app

COPY --from=build /app/build/file_analyzer /app/app

# Порт, который слушает приложение (замените на реальный)
EXPOSE 8080

# Переменные окружения по умолчанию (не для секретов!)
ENV LOG_LEVEL=info

ENTRYPOINT ["/app/app"]
CMD []