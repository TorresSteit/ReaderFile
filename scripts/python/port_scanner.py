#!/usr/bin/env python3
"""
Port Scanner — проверяет, какие порты открыты на указанном хосте.
Простая, без внешних зависимостей — только стандартная библиотека socket.
"""

import socket
import sys
import argparse

# Часто используемые порты — узнаваемые сервисы для быстрой проверки
COMMON_PORTS = {
    22: "SSH",
    80: "HTTP",
    443: "HTTPS",
    5432: "PostgreSQL",
    3306: "MySQL",
    6379: "Redis",
    27017: "MongoDB",
    8080: "HTTP-alt / app server",
    9090: "Prometheus",
    3000: "Grafana",
}


def check_port(host: str, port: int, timeout: float = 1.0) -> bool:
    """Пытается открыть TCP-соединение с портом. True, если порт открыт."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        result = sock.connect_ex((host, port))
        return result == 0
    finally:
        sock.close()


def scan(host: str, ports: dict[int, str]) -> None:
    print(f"Scanning {host}...\n")

    open_count = 0
    for port, service in ports.items():
        is_open = check_port(host, port)
        status = "✅ OPEN" if is_open else "❌ closed"
        print(f"  {port:<6} ({service:<20}) — {status}")
        if is_open:
            open_count += 1

    print(f"\n{open_count}/{len(ports)} ports open on {host}")


def main():
    parser = argparse.ArgumentParser(description="Check which common ports are open on a host")
    parser.add_argument("host", nargs="?", default="localhost", help="Host to scan (default: localhost)")
    parser.add_argument("--port", type=int, help="Check a single specific port instead of the common list")
    args = parser.parse_args()

    ports = {args.port: "custom"} if args.port else COMMON_PORTS
    scan(args.host, ports)


if __name__ == "__main__":
    main()