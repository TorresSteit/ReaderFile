# ─────────────────────────────────────────────
# 🔧 ЛОКАЛЬНАЯ СБОРКА (CMake, без Docker)
# ─────────────────────────────────────────────

build:
	cmake -B build -S .
	cmake --build build

run: build
	./build/file_analyzer

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
# 🐍 PYTHON СКРИПТЫ
# ─────────────────────────────────────────────

# Сводный Markdown-отчёт по нескольким директориям
report: build
	python3 scripts/python/report_generator.py

# Сканирование лог-файлов на ошибки/варнинги (make scan-logs DIR=./logs)
scan-logs:
	python3 scripts/python/log_scanner.py $(DIR)

# Проверка открытых портов на хосте (make port-scan HOST=192.168.1.10)
port-scan:
	python3 scripts/python/port_scanner.py $(HOST)

# Бэкап базы данных в Backblaze B2
backup-db:
	python3 scripts/python/db_backup_to_b2.py

# ─────────────────────────────────────────────
# 🐚 BASH СКРИПТЫ
# ─────────────────────────────────────────────

# Проверка состояния Docker на удалённом сервере (make check-remote-docker HOST=user@server)
check-remote-docker:
	./scripts/Bash/check_remote_docker.sh $(HOST)

# Общий health-check удалённого VPS (make check-remote-server HOST=user@server)
check-remote-server:
	./scripts/Bash/check_remote_server.sh $(HOST)

# Проверка локальных открытых портов
check-ports:
	./scripts/Bash/check_ports.sh

# ─────────────────────────────────────────────
# 📦 ВСЁ СРАЗУ
# ─────────────────────────────────────────────

# Полный прогон: чистая сборка + docker + запуск
all: clean build docker-build up

.PHONY: build run clean docker-build docker-run up up-d down restart clean-all \
        logs logs-app ps report scan-logs port-scan backup-db \
        check-remote-docker check-remote-server check-ports all help

help:
	@echo "── Build & Run ──────────────────────────────"
	@echo "make build                        — собрать локально через CMake"
	@echo "make run                          — собрать и запустить бинарник"
	@echo "make clean                        — удалить папку build/"
	@echo ""
	@echo "── Docker ────────────────────────────────────"
	@echo "make docker-build                 — собрать Docker-образ"
	@echo "make docker-run                   — собрать и запустить контейнер"
	@echo "make up                           — поднять через docker-compose"
	@echo "make down                         — остановить контейнеры"
	@echo "make restart                      — перезапустить всё"
	@echo "make clean-all                    — снести всё, включая volumes"
	@echo ""
	@echo "── Логи и статус ────────────────────────────"
	@echo "make logs                         — логи всех сервисов"
	@echo "make logs-app                     — логи только file-analyzer"
	@echo "make ps                           — статус контейнеров"
	@echo ""
	@echo "── Python скрипты ────────────────────────────"
	@echo "make report                       — сводный отчёт по директориям"
	@echo "make scan-logs DIR=./logs         — сканировать логи на ошибки"
	@echo "make port-scan HOST=1.2.3.4       — проверить открытые порты на хосте"
	@echo "make backup-db                    — бэкап БД в Backblaze B2"
	@echo ""
	@echo "── Bash скрипты ───────────────────────────────"
	@echo "make check-remote-docker HOST=u@h — Docker на удалённом сервере"
	@echo "make check-remote-server HOST=u@h — health-check удалённого VPS"
	@echo "make check-ports                  — открытые порты локально"
	@echo ""
	@echo "── Всё сразу ─────────────────────────────────"
	@echo "make all                          — весь пайплайн одной командой"