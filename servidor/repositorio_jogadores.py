from banco import abrir_conexao


class RepositorioJogadores:
    def criar_conta(
        self,
        apelido: str,
        nome_usuario: str,
        senha_hash: str,
    ) -> dict:
        with abrir_conexao() as conexao:
            with conexao.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO public.jogadores (
                        apelido,
                        nome_usuario,
                        senha_hash
                    )
                    VALUES (%s, %s, %s)
                    RETURNING
                        id,
                        apelido,
                        nome_usuario,
                        criado_em
                    """,
                    (apelido, nome_usuario, senha_hash),
                )

                return cursor.fetchone()

    def buscar_por_usuario(
        self,
        nome_usuario: str,
    ) -> dict | None:
        with abrir_conexao() as conexao:
            with conexao.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT
                        id,
                        apelido,
                        nome_usuario,
                        senha_hash,
                        criado_em
                    FROM public.jogadores
                    WHERE LOWER(nome_usuario) = LOWER(%s)
                    """,
                    (nome_usuario,),
                )

                return cursor.fetchone()

    def buscar_conta_por_id(
        self,
        jogador_id: int,
    ) -> dict | None:
        with abrir_conexao() as conexao:
            with conexao.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT
                        id,
                        apelido,
                        nome_usuario,
                        criado_em
                    FROM public.jogadores
                    WHERE id = %s
                      AND nome_usuario IS NOT NULL
                      AND senha_hash IS NOT NULL
                    """,
                    (jogador_id,),
                )

                return cursor.fetchone()