from pathlib import Path
import os

import mysql.connector
from dotenv import load_dotenv


ARQUIVO_ENV = Path(__file__).resolve().parent / ".env"


def main():
    load_dotenv(ARQUIVO_ENV)

    conexao = None
    cursor = None

    try:
        conexao = mysql.connector.connect(
            host=os.environ["DB_HOST"],
            port=int(os.environ["DB_PORT"]),
            database=os.environ["DB_NAME"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            connection_timeout=5,
        )

        cursor = conexao.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT id, apelido, criado_em
            FROM jogadores
            ORDER BY id
            LIMIT 10
            """
        )

        jogadores = cursor.fetchall()

        print("Conexão com o MySQL realizada com sucesso!")

        if not jogadores:
            print("Nenhum jogador cadastrado.")

        for jogador in jogadores:
            print(
                f"ID: {jogador['id']} | "
                f"Apelido: {jogador['apelido']} | "
                f"Criado em: {jogador['criado_em']}"
            )

    except KeyError as erro:
        print(f"Falta a configuração {erro} no arquivo .env.")

    except ValueError:
        print("Confira DB_PORT: a porta precisa ser um número.")

    except mysql.connector.Error as erro:
        print(f"Falha na conexão ou consulta: {erro}")

    finally:
        if cursor is not None:
            cursor.close()

        if conexao is not None:
            conexao.close()


if __name__ == "__main__":
    main()