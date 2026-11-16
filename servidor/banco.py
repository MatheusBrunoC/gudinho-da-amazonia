import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row


load_dotenv(Path(__file__).resolve().parent / ".env")


def abrir_conexao():
    return psycopg.connect(
        os.environ["DATABASE_URL"],
        row_factory=dict_row,
        connect_timeout=30,
        options="-c timezone=America/Manaus",
    )