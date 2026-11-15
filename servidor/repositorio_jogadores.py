from banco import abrir_conexao


class RepositorioJogadores:
    def buscar_por_id(self, jogador_id: int):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                SELECT id, apelido, criado_em
                FROM jogadores
                WHERE id = %s
                """,
                (jogador_id,),
            )

            return cursor.fetchone()

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()

    def criar(self, apelido: str):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                "INSERT INTO jogadores (apelido) VALUES (%s)",
                (apelido,),
            )

            jogador_id = cursor.lastrowid

            cursor.execute(
                """
                SELECT id, apelido, criado_em
                FROM jogadores
                WHERE id = %s
                """,
                (jogador_id,),
            )

            jogador = cursor.fetchone()
            conexao.commit()

            return jogador

        except Exception:
            conexao.rollback()
            raise

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()