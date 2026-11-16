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

    def listar(self, limite: int = 50):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                SELECT id, apelido
                FROM jogadores
                ORDER BY apelido ASC, id ASC
                LIMIT %s
                """,
                (limite,),
            )

            return cursor.fetchall()

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()

    def criar_conta(
        self,
        apelido: str,
        nome_usuario: str,
        senha_hash: str,
    ):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                INSERT INTO jogadores (
                    apelido,
                    nome_usuario,
                    senha_hash
                )
                VALUES (%s, %s, %s)
                """,
                (apelido, nome_usuario, senha_hash),
            )

            jogador_id = cursor.lastrowid

            cursor.execute(
                """
                SELECT id, apelido, nome_usuario, criado_em
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

    def buscar_por_usuario(self, nome_usuario: str):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                SELECT
                    id,
                    apelido,
                    nome_usuario,
                    senha_hash,
                    criado_em
                FROM jogadores
                WHERE nome_usuario = %s
                """,
                (nome_usuario,),
            )

            return cursor.fetchone()

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()

    def buscar_conta_por_id(self, jogador_id: int):
        conexao = abrir_conexao()
        cursor = None

        try:
            cursor = conexao.cursor(dictionary=True)

            cursor.execute(
                """
                SELECT id, apelido, nome_usuario, criado_em
                FROM jogadores
                WHERE id = %s
                  AND nome_usuario IS NOT NULL
                  AND senha_hash IS NOT NULL
                """,
                (jogador_id,),
            )

            return cursor.fetchone()

        finally:
            if cursor is not None:
                cursor.close()

            conexao.close()