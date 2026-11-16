import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


load_dotenv(Path(__file__).resolve().parent / ".env")


def main():
    endereco = os.environ.get("DATABASE_URL")

    if not endereco:
        print("DATABASE_URL não foi encontrada no .env.")
        return

    try:
        with psycopg.connect(
            endereco,
            connect_timeout=30,
        ) as conexao:
            with conexao.cursor() as cursor:
                cursor.execute("SELECT current_database();")
                banco = cursor.fetchone()[0]

                cursor.execute(
                    """
                    SELECT 'jogadores' AS tabela, COUNT(*) AS quantidade
                    FROM public.jogadores

                    UNION ALL

                    SELECT 'historico_treinos', COUNT(*)
                    FROM public.historico_treinos;
                    """
                )

                resultados = cursor.fetchall()

        print("Conexão com o PostgreSQL realizada com sucesso!")
        print("Banco:", banco)

        for tabela, quantidade in resultados:
            print(f"{tabela}: {quantidade} registros")

    except psycopg.Error as erro:
        print("Falha no teste de conexão com o PostgreSQL.")
        print("Tipo:", type(erro).__name__)
        print("Código SQL:", erro.sqlstate or "não disponível")


if __name__ == "__main__":
    main()