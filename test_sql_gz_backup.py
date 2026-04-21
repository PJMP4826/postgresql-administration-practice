import gzip
import shutil
import subprocess

import os
from dotenv import load_dotenv
from pathlib import Path


def get_env(config: dict) -> dict:
    env = os.environ.copy()
    env["PGPASSWORD"] = config["password"]
    return env


def get_config_from_env() -> dict:
    return {
        "db": os.getenv("POSTGRES_DB", "despacho_policial"),
        "user": os.getenv("POSTGRES_USER", "admin"),
        "password": os.getenv("POSTGRES_PASSWORD", ""),
        "host": os.getenv("POSTGRES_HOST", "localhost"),
        "port": os.getenv("POSTGRES_PORT", "5432"),
    }


from datetime import datetime


def test_sql_gz_backup(backup_file: Path, config: dict) -> bool:
    DATE = datetime.now().strftime("%Y%m%d_%H%M%S")
    test_db = f"restore_test_{DATE}"
    env = get_env(config)
    sql_file = backup_file.with_suffix("")  # elimina .gz

    try:
        # Descomprimir
        with gzip.open(backup_file, "rb") as f_in, open(sql_file, "wb") as f_out:
            shutil.copyfileobj(f_in, f_out)

        # Crear base temporal
        subprocess.run(
            [
                "createdb",
                "-h",
                config["host"],
                "-p",
                config["port"],
                "-U",
                config["user"],
                test_db,
            ],
            check=True,
            env=env,
        )

        # Restaurar usando psql
        subprocess.run(
            [
                "psql",
                "-h",
                config["host"],
                "-p",
                config["port"],
                "-U",
                config["user"],
                "-d",
                test_db,
                "-f",
                str(sql_file),
            ],
            check=True,
            env=env,
        )

        print(f"Restore test PASSED for {backup_file.name}")
        return True

    except subprocess.CalledProcessError as e:
        print(f"Restore test FAILED: {e}")
        return False

    finally:
        subprocess.run(
            [
                "dropdb",
                "-h",
                config["host"],
                "-p",
                config["port"],
                "-U",
                config["user"],
                "--if-exists",
                test_db,
            ],
            env=env,
        )
        if sql_file.exists():
            sql_file.unlink()  # Borra el archivo descomprimido


def find_gz_files(root: Path):
    return list(root.rglob("*.sql.gz"))


def main():
    load_dotenv()
    config = get_config_from_env()
    backup_root = Path("/app/backups")
    gz_files = find_gz_files(backup_root)
    print(f"Found {len(gz_files)} .gz backup(s) in {backup_root}")
    for gz in gz_files:
        print(f"Testing {gz}")
        test_sql_gz_backup(gz, config)


if __name__ == "__main__":
    main()
