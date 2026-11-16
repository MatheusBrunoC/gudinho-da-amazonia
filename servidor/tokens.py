import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from dotenv import load_dotenv


load_dotenv(Path(__file__).resolve().parent / ".env")

CHAVE_SECRETA = os.environ.get("JWT_SECRET", "")

if len(CHAVE_SECRETA) < 64:
    raise RuntimeError(
        "Configure JWT_SECRET no .env com a chave gerada."
    )

ALGORITMO = "HS256"
DURACAO_TOKEN_SEGUNDOS = 3600


def criar_token_acesso(jogador_id: int) -> str:
    agora = datetime.now(timezone.utc)

    dados = {
        "sub": str(jogador_id),
        "iat": agora,
        "exp": agora + timedelta(seconds=DURACAO_TOKEN_SEGUNDOS),
    }

    return jwt.encode(
        dados,
        CHAVE_SECRETA,
        algorithm=ALGORITMO,
    )

def obter_id_do_token(token: str) -> int:
    dados = jwt.decode(
        token,
        CHAVE_SECRETA,
        algorithms=[ALGORITMO],
        options={"require": ["sub", "iat", "exp"]},
    )

    identificador = dados["sub"]

    if (
        not isinstance(identificador, str)
        or not identificador.isascii()
        or not identificador.isdecimal()
        or len(identificador) > 10
    ):
        raise jwt.InvalidTokenError("Identificador inválido.")

    jogador_id = int(identificador)

    if not 1 <= jogador_id <= 4294967295:
        raise jwt.InvalidTokenError("Identificador inválido.")

    return jogador_id