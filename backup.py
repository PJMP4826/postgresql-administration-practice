import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BACKUP_DIR = Path.home() / "postgres-backup" / "backups"
DATE = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


def create_backup_directory():
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)


def get_db_config() -> dict:
    return {
        "db":       os.getenv("POSTGRES_DB", "despacho_policial"),
        "user":     os.getenv("POSTGRES_USER", "admin"),
        "password": os.getenv("POSTGRES_PASSWORD", ""),
        "host":     os.getenv("POSTGRES_HOST", "localhost"),
        "port":     os.getenv("POSTGRES_PORT", "5434"),  # host-mapped port
    }


def get_env(config: dict) -> dict:
    """Pass PGPASSWORD via environment, not CLI args."""
    env = os.environ.copy()
    env["PGPASSWORD"] = config["password"]
    return env


def run_backup(config: dict) -> Path:
    backup_name = f"{config['db']}_{DATE}.dump"
    backup_file = BACKUP_DIR / backup_name

    subprocess.run([
        "pg_dump",
        "-h", config["host"],
        "-p", config["port"],
        "-U", config["user"],
        "-Fc",
        config["db"],
        "-f", str(backup_file)
    ], check=True, env=get_env(config))

    if not backup_file.exists() or backup_file.stat().st_size == 0:
        print("ERROR: Backup file missing or empty.")
        sys.exit(1)

    return backup_file


def test_restore(backup_file: Path, config: dict) -> bool:
    test_db = f"restore_test_{DATE}"
    env = get_env(config)

    try:
        subprocess.run([
            "createdb",
            "-h", config["host"],
            "-p", config["port"],
            "-U", config["user"],
            test_db
        ], check=True, env=env)

        subprocess.run([
            "pg_restore",
            "-h", config["host"],
            "-p", config["port"],
            "-U", config["user"],
            "-d", test_db,
            "--no-owner",
            str(backup_file)
        ], check=True, env=env)

        print(f"Restore test PASSED for {backup_file.name}")
        return True

    except subprocess.CalledProcessError as e:
        print(f"Restore test FAILED: {e}")
        return False

    finally:
        subprocess.run([
            "dropdb",
            "-h", config["host"],
            "-p", config["port"],
            "-U", config["user"],
            "--if-exists",
            test_db
        ], env=env)


def cleanup_old_backups(days: int = 7):
    cutoff = datetime.now().timestamp() - days * 86400
    removed = 0
    for dump_file in BACKUP_DIR.glob("*.dump"):
        if dump_file.stat().st_mtime < cutoff:
            dump_file.unlink()
            removed += 1
    if removed:
        print(f"Cleaned up {removed} old backup(s).")


def main():
    create_backup_directory()
    config = get_db_config()

    try:
        backup_file = run_backup(config)
    except subprocess.CalledProcessError as e:
        print(f"Backup failed: {e}")
        sys.exit(1)

    restore_ok = test_restore(backup_file, config)

    if not restore_ok:
        print("WARNING: Restore test failed. Investigate before trusting this backup.")

    cleanup_old_backups()
    size_kb = backup_file.stat().st_size // 1024
    print(f"Backup completed: {backup_file.name} ({size_kb} KB)")


if __name__ == "__main__":
    main()