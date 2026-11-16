import os
from datetime import timezone
from pathlib import Path
from uuid import UUID

import mysql.connector
import psycopg
from psycopg import sql
from dotenv import load_dotenv


load_dotenv(Path(__file__).resolve().parent / ".env")


def ler_mysql():
    conexao = mysql.connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connection_timeout=10,
        time_zone="+00:00",
    )

    try:
        conexao.start_transaction(
            consistent_snapshot=True,
            isolation_level="REPEATABLE READ",
            readonly=True,
        )

        with conexao.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, apelido, nome_usuario, senha_hash, criado_em
                FROM jogadores
                ORDER BY id
                """
            )
            jogadores = [
                (
                    linha[0],
                    linha[1],
                    linha[2],
                    linha[3],
                    linha[4].replace(tzinfo=timezone.utc),
                )
                for linha in cursor.fetchall()
            ]

            cursor.execute(
                """
                SELECT
                    id,
                    identificador,
                    jogador_id,
                    pontos_jogador,
                    pontos_computador,
                    criado_em
                FROM historico_treinos
                ORDER BY id
                """
            )
            treinos = [
                (
                    linha[0],
                    UUID(linha[1]),
                    linha[2],
                    linha[3],
                    linha[4],
                    linha[5].replace(tzinfo=timezone.utc),
                )
                for linha in cursor.fetchall()
            ]

        return jogadores, treinos

    finally:
        conexao.close()


def ajustar_proximo_id(cursor, tabela, registros):
    proximo_id = max(
        (registro[0] for registro in registros),
        default=0,
    ) + 1

    cursor.execute(
        sql.SQL(
            "ALTER TABLE {} ALTER COLUMN id RESTART WITH {}"
        ).format(
            sql.Identifier("public", tabela),
            sql.Literal(proximo_id),
        )
    )


def migrar():
    jogadores, treinos = ler_mysql()

    print(f"MySQL: {len(jogadores)} jogadores.")
    print(f"MySQL: {len(treinos)} treinos.")

    if not jogadores:
        raise RuntimeError(
            "Nenhum jogador encontrado. Confira o banco MySQL de origem."
        )

    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=30,
    ) as destino:
        with destino.cursor() as cursor:
            cursor.execute("SET LOCAL TIME ZONE 'UTC'")
            cursor.execute("SET LOCAL lock_timeout = '10s'")

            cursor.execute(
                """
                LOCK TABLE public.jogadores,
                           public.historico_treinos
                IN ACCESS EXCLUSIVE MODE
                """
            )

            cursor.execute(
                """
                SELECT
                    (SELECT COUNT(*) FROM public.jogadores),
                    (SELECT COUNT(*) FROM public.historico_treinos)
                """
            )
            quantidade_jogadores, quantidade_treinos = cursor.fetchone()

            if quantidade_jogadores or quantidade_treinos:
                raise RuntimeError(
                    "Migração interrompida: o Neon já contém registros. "
                    "Nenhum dado existente foi substituído."
                )

            cursor.executemany(
                """
                INSERT INTO public.jogadores (
                    id, apelido, nome_usuario, senha_hash, criado_em
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                jogadores,
            )

            if treinos:
                cursor.executemany(
                    """
                    INSERT INTO public.historico_treinos (
                        id,
                        identificador,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador,
                        criado_em
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    treinos,
                )

            cursor.execute(
                """
                SELECT id, apelido, nome_usuario, senha_hash, criado_em
                FROM public.jogadores
                ORDER BY id
                """
            )

            if cursor.fetchall() != jogadores:
                raise RuntimeError(
                    "A conferência dos jogadores encontrou diferenças."
                )

            cursor.execute(
                """
                SELECT
                    id,
                    identificador,
                    jogador_id,
                    pontos_jogador,
                    pontos_computador,
                    criado_em
                FROM public.historico_treinos
                ORDER BY id
                """
            )

            if cursor.fetchall() != treinos:
                raise RuntimeError(
                    "A conferência dos treinos encontrou diferenças."
                )

            ajustar_proximo_id(cursor, "jogadores", jogadores)
            ajustar_proximo_id(cursor, "historico_treinos", treinos)

    print("Migração concluída e conferida!")
    print(f"Jogadores copiados: {len(jogadores)}")
    print(f"Treinos copiados: {len(treinos)}")
    print("O banco MySQL original não foi alterado.")


if __name__ == "__main__":
    try:
        migrar()

    except RuntimeError as erro:
        print(erro)
        raise SystemExit(1)

    except KeyError:
        print("Falta uma variável necessária no arquivo .env.")
        raise SystemExit(1)

    except (mysql.connector.Error, psycopg.Error) as erro:
        print("A migração não foi confirmada.")
        print("Tipo do erro:", type(erro).__name__)
        print(
            "Código:",
            getattr(erro, "sqlstate", None)
            or getattr(erro, "errno", None)
            or "não disponível",
        )
        print("Não apague dados nem repita sem conferir o estado do Neon.")
        raise SystemExit(1)

    except ValueError:
        print("Um valor da origem está em formato inesperado.")
        print("A migração não foi concluída.")
        raise SystemExit(1)