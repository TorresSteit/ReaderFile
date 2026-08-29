#!/usr/bin/env python3
"""
DB Backup to B2 — делает дамп PostgreSQL/MySQL базы данных на удалённом
сервере и загружает его в Backblaze B2 (S3-совместимое хранилище).

Требует:
    pip install boto3
    (boto3 работает с B2 через S3-совместимый API)

Переменные окружения:
    DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
    B2_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_NAME, B2_ENDPOINT
"""

import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import boto3
from botocore.exceptions import ClientError


def get_env_or_exit(var_name: str) -> str:
    """Читает обязательную переменную окружения, завершает скрипт, если её нет."""
    value = os.environ.get(var_name)
    if not value:
        print(f"Error: environment variable {var_name} is not set", file=sys.stderr)
        sys.exit(1)
    return value


def create_dump(db_type: str, host: str, port: str, db_name: str,
                user: str, password: str, output_path: Path) -> None:
    """Создаёт дамп базы данных через pg_dump (PostgreSQL) или mysqldump (MySQL)."""

    print(f"Creating dump of {db_name} on {host}:{port}...")

    if db_type == "postgres":
        env = os.environ.copy()
        env["PGPASSWORD"] = password
        cmd = [
            "pg_dump",
            "-h", host, "-p", port,
            "-U", user, "-d", db_name,
            "-F", "c",  # custom format — сжатый, поддерживает pg_restore
            "-f", str(output_path)
        ]
        subprocess.run(cmd, env=env, check=True)

    elif db_type == "mysql":
        cmd = [
            "mysqldump",
            "-h", host, "-P", port,
            "-u", user, f"-p{password}",
            db_name
        ]
        with open(output_path, "wb") as f:
            subprocess.run(cmd, stdout=f, check=True)

    else:
        raise ValueError(f"Unsupported db_type: {db_type}")

    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"✅ Dump created: {output_path} ({size_mb:.2f} MB)")


def upload_to_b2(local_path: Path, bucket: str, key_id: str,
                 app_key: str, endpoint: str) -> None:
    """Загружает файл в Backblaze B2 через S3-совместимый API."""

    print(f"Uploading {local_path.name} to B2 bucket '{bucket}'...")

    s3 = boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=key_id,
        aws_secret_access_key=app_key,
    )

    remote_key = f"backups/{local_path.name}"

    try:
        s3.upload_file(str(local_path), bucket, remote_key)
        print(f"✅ Uploaded to b2://{bucket}/{remote_key}")
    except ClientError as e:
        print(f"❌ Upload failed: {e}", file=sys.stderr)
        sys.exit(1)


def cleanup_local_dump(path: Path) -> None:
    """Удаляет локальный файл дампа после успешной загрузки — не храним копии зря."""
    path.unlink()
    print(f"🧹 Removed local dump file: {path}")


def main():
    db_type = os.environ.get("DB_TYPE", "postgres")
    db_host = get_env_or_exit("DB_HOST")
    db_port = os.environ.get("DB_PORT", "5432" if db_type == "postgres" else "3306")
    db_name = get_env_or_exit("DB_NAME")
    db_user = get_env_or_exit("DB_USER")
    db_password = get_env_or_exit("DB_PASSWORD")

    b2_key_id = get_env_or_exit("B2_KEY_ID")
    b2_app_key = get_env_or_exit("B2_APPLICATION_KEY")
    b2_bucket = get_env_or_exit("B2_BUCKET_NAME")
    b2_endpoint = get_env_or_exit("B2_ENDPOINT")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dump_filename = f"{db_name}_{timestamp}.dump"
    dump_path = Path("/tmp") / dump_filename

    create_dump(db_type, db_host, db_port, db_name, db_user, db_password, dump_path)
    upload_to_b2(dump_path, b2_bucket, b2_key_id, b2_app_key, b2_endpoint)
    cleanup_local_dump(dump_path)

    print("✅ Backup completed successfully")


if __name__ == "__main__":
    main()