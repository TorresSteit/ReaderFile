# File Analyzer

A C++ command-line utility that scans a directory and reports statistics for every file it finds — size, line count, word count, and character count. Built as a hands-on demo of a full DevOps pipeline: compilation with CMake, containerization with Docker (multi-stage build), orchestration with Docker Compose, and CI/CD with GitHub Actions.

## What it does

Point it at a directory (locally or via a mounted Docker volume) and it walks through every file, printing a per-file breakdown plus a summary. Useful as a lightweight building block for log auditing, codebase inventory, or simple reporting tools.
Scanning: /data
main.cpp | ext: .cpp | 2431 bytes | 78 lines | 312 words | 2100 chars
config.yaml | ext: .yaml | 512 bytes | 24 lines | 61 words | 480 chars

Total: 2 files, 2943 bytes


## Features

- Scans a directory non-recursively by default, or recursively with `--recursive`
- Target directory set via a command-line argument, an environment variable (`SCAN_DIR`), or defaults to the current working directory
- Runs identically on bare metal and inside a container — no code changes needed between environments
- Multi-stage Docker build keeps the runtime image free of the compiler and source code

## Tech stack

- **Language:** C++20
- **Build system:** CMake, GCC 13
- **Containerization:** Docker (multi-stage build), Docker Compose
- **CI/CD:** GitHub Actions
- **Tooling:** Makefile for a consistent local/CI workflow

## Getting started

### With Docker Compose (recommended)

```bash
git clone https://github.com/TorresSteit/ReaderFile.git
cd ReaderFile
cp .env.example .env    # adjust SCAN_DIR if needed
make up
```

### Locally, without Docker

```bash
make build
make run
```

## Environment variables

| Variable   | Description                          | Default |
|------------|---------------------------------------|---------|
| `SCAN_DIR` | Path to the directory to scan          | `/data` |

## Makefile commands

| Command              | What it does                                          |
|-----------------------|--------------------------------------------------------|
| `make build`           | Build the project locally with CMake                    |
| `make run`             | Build and run the binary locally                        |
| `make docker-build`    | Build the Docker image                                   |
| `make up`               | Build and start the stack via docker-compose             |
| `make down`             | Stop and remove the containers                            |
| `make clean-all`        | Remove containers, volumes, and unused images             |
| `make logs`             | Tail the logs                                             |
| `make all`              | Full pipeline in one shot: build → docker → run           |

## Project structure

.
├── src/
│ └── main.cpp # application source
├── CMakeLists.txt # build configuration
├── Dockerfile # multi-stage build (gcc:13 → ubuntu:24.04)
├── docker-compose.yaml # orchestration, volume + env_file
├── Makefile # build/run shortcuts
├── .gitlab-ci.yml # demo GitLab pipeline (Gitleaks, SonarQube, Trivy)
└── .github/workflows/
└── ci.yml # GitHub Actions: build + smoke test + docker build


## CI/CD

On every push to `master`, the GitHub Actions pipeline:
1. Configures and builds the project with CMake
2. Verifies the binary was produced
3. Runs a smoke test
4. Builds the Docker image

A separate `.gitlab-ci.yml` demonstrates a more security-focused pipeline: Gitleaks (secret scanning), SonarQube (static code analysis), and Trivy (container vulnerability scanning).

## Why this project

This is a small, self-contained project built to demonstrate a complete build-to-container-to-CI pipeline, end to end and hands-on — not a large production system, but every piece (compiler, linker, container, pipeline, security scanning) is understood and wired up deliberately rather than copy-pasted.

## License

MIT
