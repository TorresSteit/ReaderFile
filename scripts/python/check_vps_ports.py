import os
import subprocess
import sys

def load_env(path=".env"):
    """Простой загрузчик .env — читает файл и кладёт переменные в словарь."""
    env = {}
    if not os.path.exists(path):
        print(f"Файл {path} не найден. Скопируй .env.example и заполни значения.")
        sys.exit(1)

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                env[key.strip()] = value.strip()

    return env



def check_vps_ports(host, user, port=22):
    """Подключается по SSH к серверу и запускает там команду просмотра открытых портов."""
    print(f"Подключаюсь к {user}@{host}:{port}...\n")

    ssh_command = [
        "ssh",
        "-p", str(port),
        "-o", "ConnectTimeout=5",
        f"{user}@{host}",
        "ss -tulnp"  # команда, которая выполнится НА сервере, не локально
    ]

    try:
        result = subprocess.run(
            ssh_command,
            capture_output=True,
            text=True,
            timeout=15
        )

        if result.returncode == 0:
            print("── Открытые порты на сервере ──")
            print(result.stdout)
        else:
            print("Не удалось выполнить команду на сервере")
            print(result.stderr)

    except subprocess.TimeoutExpired:
        print("Превышено время ожидания подключения")
    except Exception as e:
        print(f"Ошибка: {e}")


if __name__ == "__main__":
    env = load_env()

    ssh_host = env.get("SSH_HOST")
    ssh_user = env.get("SSH_USER")
    ssh_port = env.get("SSH_PORT", "22")

    if not ssh_host or not ssh_user:
        print("В .env должны быть заданы SSH_HOST и SSH_USER")
        sys.exit(1)

    check_vps_ports(ssh_host, ssh_user, ssh_port)



