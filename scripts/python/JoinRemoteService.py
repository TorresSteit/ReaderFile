import os
import sys
import subprocess
# ^ os — работа с файловой системой/переменными окружения
# ^ sys — для sys.exit() (завершение программы с кодом ошибки)
# ^ subprocess — запуск внешних команд (тут — ssh) из Python


def load_env(path=".env"):
    """Read the .env file and store environment variables in a dictionary."""
    # Читает .env файл вручную (без сторонних библиотек типа python-dotenv)
    env = {}
    if not os.path.exists(path):
        print(f"File {path} not found.")
        sys.exit(1)
        # ^ Если файла .env нет — выходим с кодом ошибки 1 (не 0 = "что-то пошло не так")

    with open(path) as f:
        for line in f:
            line = line.strip()                    # убираем пробелы/переносы строк по краям
            if not line or line.startswith("#"):
                continue                            # пропускаем пустые строки и комментарии (#...)
            if "=" in line:
                key, value = line.split("=", 1)
                # ^ split("=", 1) — делим строку только по ПЕРВОМУ "=",
                #   чтобы значение вида KEY=some=value не сломалось
                env[key.strip()] = value.strip()
    return env


def analyze_remote_dir(user, host, key_path, remote_dir):
    """Connect to the server via SSH and inspect the contents of a directory."""
    print(f"Connecting to {user}@{host}...\n")

    # Command that will be executed ON the remote server:
    # ls -la — lists files, du -sh — shows the total directory size
    remote_command = f'ls -la "{remote_dir}" && echo "---" && du -sh "{remote_dir}"'
    # ^ Собираем ОДНУ строку-команду, которая выполнится НЕ локально, а на удалённом сервере:
    #   ls -la  — подробный список файлов (включая скрытые)
    #   echo "---"  — просто разделитель в выводе, для читаемости
    #   du -sh  — суммарный размер директории (human-readable, например "1.2G")

    ssh_command = [
        "ssh",
        "-i", key_path,             # -i — путь к приватному SSH-ключу для авторизации
        f"{user}@{host}",           # куда подключаемся: пользователь@хост
        remote_command               # что выполнить на удалённой машине после подключения
    ]
    # ^ subprocess ожидает команду как список аргументов (а не одну строку) —
    #   это безопаснее, чем shell=True, меньше риск shell-инъекции

    try:
        result = subprocess.run(
            ssh_command,
            capture_output=True,     # перехватываем stdout/stderr вместо вывода прямо в консоль
            text=True,                # результат сразу как строка, а не байты
            timeout=15                # если сервер не ответит за 15 секунд — кидаем TimeoutExpired
        )
        if result.returncode == 0:
            # returncode == 0 значит команда на сервере отработала без ошибок
            print(result.stdout)
        else:
            # ненулевой код — что-то пошло не так на удалённой стороне
            print("Error while executing the command on the server:")
            print(result.stderr)
    except subprocess.TimeoutExpired:
        # сработает, если сервер не ответил за отведённые 15 секунд
        print("The server did not respond in time.")
    except Exception as e:
        # ловим всё остальное (например, ssh-бинарник не найден, ключ не существует и т.д.)
        print(f"Error: {e}")


if __name__ == "__main__":
    # Этот блок выполняется, только если файл запущен напрямую (python script.py),
    # а не импортирован как модуль в другой файл

    env = load_env()
    ssh_user = env.get("SSH_USER")
    ssh_host = env.get("SSH_HOST")
    ssh_key_path = env.get("SSH_KEY_PATH")
    remote_dir = env.get("REMOTE_DIR")
    # ^ .get() вместо env["SSH_USER"] — если ключа нет, вернёт None, а не упадёт с ошибкой

    if not all([ssh_user, ssh_host, ssh_key_path, remote_dir]):
        # all([...]) — True, только если ВСЕ четыре значения не пустые/не None
        print(
            "The .env file must contain "
            "SSH_USER, SSH_HOST, SSH_KEY_PATH, and REMOTE_DIR."
        )
        sys.exit(1)

    analyze_remote_dir(
        ssh_user,
        ssh_host,
        ssh_key_path,
        remote_dir
    )

