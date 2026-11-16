from uuid import UUID

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
    ) -> tuple[dict, bool]:
        identificador_uuid = UUID(str(identificador))

        with abrir_conexao() as conexao:
            with conexao.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO public.historico_treinos (
                        identificador,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador
                    )
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (identificador) DO NOTHING
                    RETURNING
                        id,
                        identificador,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador,
                        criado_em
                    """,
                    (
                        identificador_uuid,
                        jogador_id,
                        pontos_jogador,
                        pontos_computador,
                    ),
                )

                treino = cursor.fetchone()
                criado = treino is not None

                if treino is None:
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
                        WHERE identificador = %s
                        """,
                        (identificador_uuid,),
                    )

                    treino = cursor.fetchone()

                if treino is None:
                    raise RuntimeError(
                        "Não foi possível recuperar o treino."
                    )

                if (
                    treino["jogador_id"] != jogador_id
                    or treino["pontos_jogador"] != pontos_jogador
                    or treino["pontos_computador"] != pontos_computador
                ):
                    raise ConflitoTreinoError(
                        "Identificador utilizado por outro resultado."
                    )

                treino["identificador"] = str(
                    treino["identificador"]
                )

                return treino, criado

    def listar_por_jogador(
        self,
        jogador_id: int,
        limite: int = 10,
    ) -> list[dict]:
        with abrir_conexao() as conexao:
            with conexao.cursor() as cursor:
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
                    FROM public.historico_treinos
                    WHERE jogador_id = %s
                    ORDER BY criado_em DESC, id DESC
                    LIMIT %s
                    """,
                    (jogador_id, limite),
                )

                return cursor.fetchall()