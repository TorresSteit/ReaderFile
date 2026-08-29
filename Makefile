# ─────────────────────────────────────────────
# 🔧 ЛОКАЛЬНАЯ СБОРКА (CMake, без Docker)
# ─────────────────────────────────────────────

build:
	cmake -B build -S .
	cmake --build build

run: build
	docker run --rm \
      -e SCAN_DIR=/data \
      -v /mnt/c/Users/taras:/data:ro \
      file-analyzer

clean:
	rm -rf build

# ─────────────────────────────────────────────
# 🐳 DOCKER
# ─────────────────────────────────────────────

docker-build:
	docker build -t file-analyzer .

docker-run: docker-build
	docker run --rm --env-file .env -v /mnt/c/Users/taras:/data:ro file-analyzer

# ─────────────────────────────────────────────
# 🚀 ОСНОВНЫЕ КОМАНДЫ (docker-compose)
# ─────────────────────────────────────────────

up:
	docker compose up --build

up-d:
	docker compose up --build -d

down:
	docker compose down

restart:
	docker compose down
	docker compose up --build

# Полная очистка (контейнеры + volumes + неиспользуемые образы)
clean-all:
	docker compose down -v
	docker system prune -f

# Логи
logs:
	docker compose logs -f

logs-app:
	docker compose logs -f file-analyzer

# Статус контейнеров
ps:
	docker compose ps




# ─────────────────────────────────────────────
# 📦 ВСЁ СРАЗУ
# ─────────────────────────────────────────────

# Полный прогон: чистая сборка + docker + запуск
all: clean build docker-build up

.PHONY: build run clean docker-build docker-run up up-d down restart clean-all logs logs-app ps all

help:
	@echo "make build       — собрать локально через CMake"
	@echo "make run         — собрать и запустить бинарник"
	@echo "make docker-build — собрать Docker-образ"
	@echo "make up          — поднять через docker-compose"
	@echo "make down        — остановить контейнеры"
	@echo "make clean-all   — снести всё, включая volumes"
	@echo "make logs        — смотреть логи всех сервисов"
	@echo "make ps          — статус контейнеров"
	@echo "make all         — весь пайплайн одной командой"