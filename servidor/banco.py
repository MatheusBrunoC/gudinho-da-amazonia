from pathlib import Path
import os

import mysql.connector
from dotenv import load_dotenv


load_dotenv(Path(__file__).resolve().parent / ".env")


def abrir_conexao():
    return mysql.connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connection_timeout=5,
    )