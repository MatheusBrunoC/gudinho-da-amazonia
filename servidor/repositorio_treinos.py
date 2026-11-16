import mysql.connector

from banco import abrir_conexao


class ConflitoTreinoError(Exception):
    pass


class RepositorioTreinos:
    def salvar(
        self,
        identificador: str,
        jogador_id: int,
        pontos_jogador: int,
        pontos_computador: int,
    ):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)
            criado = True

            try:
                cursor.execute(
                    """
                    INSERT INTO historico_treinos (
                        identificador,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador
                    )
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        identificador,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador,
                    ),
                )

            except mysql.connector.IntegrityError as erro:
                conexao.rollback()

                # Outro erro deve ser tratado pela API.
                if erro.errno != 1062:
                    raise

                # O identificador já foi registrado.
                criado = False

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
                WHERE identificador = %s
                """,
                (identificador,),
            )

            treino = cursor.fetchone()

            if treino is None:
                raise RuntimeError("Não foi possível recuperar o treino.")

            # Repetir um envio só é permitido com os mesmos dados.
            if (
                treino["jogador_id"] != jogador_id
                or treino["pontos_jogador"] != pontos_jogador
                or treino["pontos_computador"] != pontos_computador
            ):
                raise ConflitoTreinoError(
                    "Este identificador já pertence a outro resultado."
                )

            conexao.commit()
            return treino, criado

        except Exception:
            conexao.rollback()
            raise

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()

    def listar_por_jogador(self, jogador_id: int, limite: int = 10):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                SELECT
                    id,
                    jogador_id,
                    pontos_jogador,
                    pontos_computador,
                    criado_em,
                    CASE
                        WHEN pontos_jogador > pontos_computador
                            THEN 'vitoria'
                        WHEN pontos_jogador < pontos_computador
                            THEN 'derrota'
                        ELSE 'empate'
                    END AS resultado
                FROM historico_treinos
                WHERE jogador_id = %s
                ORDER BY criado_em DESC, id DESC
                LIMIT %s
                """,
                (jogador_id, limite),
            )

            return cursor.fetchall()

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()