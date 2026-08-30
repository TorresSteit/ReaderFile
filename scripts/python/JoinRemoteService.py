import os
import sys
import subprocess


def load_env(path=".env"):
    """Read the .env file and store environment variables in a dictionary."""
    env = {}

    if not os.path.exists(path):
        print(f"File {path} not found.")
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


def analyze_remote_dir(user, host, key_path, remote_dir):
    """Connect to the server via SSH and inspect the contents of a directory."""
    print(f"Connecting to {user}@{host}...\n")

    # Command that will be executed ON the remote server:
    # ls -la — lists files, du -sh — shows the total directory size
    remote_command = f'ls -la "{remote_dir}" && echo "---" && du -sh "{remote_dir}"'

    ssh_command = [
        "ssh",
        "-i", key_path,
        f"{user}@{host}",
        remote_command
    ]

    try:
        result = subprocess.run(
            ssh_command,
            capture_output=True,
            text=True,
            timeout=15
        )

        if result.returncode == 0:
            print(result.stdout)
        else:
            print("Error while executing the command on the server:")
            print(result.stderr)

    except subprocess.TimeoutExpired:
        print("The server did not respond in time.")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    env = load_env()

    ssh_user = env.get("SSH_USER")
    ssh_host = env.get("SSH_HOST")
    ssh_key_path = env.get("SSH_KEY_PATH")
    remote_dir = env.get("REMOTE_DIR")

    if not all([ssh_user, ssh_host, ssh_key_path, remote_dir]):
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


