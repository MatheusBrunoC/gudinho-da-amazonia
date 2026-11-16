import logging

import psycopg
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError

from repositorio_jogadores import RepositorioJogadores
from tokens import obter_id_do_token


_bearer = HTTPBearer(auto_error=False)
_repositorio = RepositorioJogadores()
_logger = logging.getLogger("uvicorn.error")


def exigir_jogador(
    credenciais: HTTPAuthorizationCredentials | None = Depends(_bearer),
):
    erro_autenticacao = HTTPException(
        status_code=401,
        detail="Sessão inválida ou expirada. Entre novamente.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credenciais is None:
        raise erro_autenticacao

    try:
        jogador_id = obter_id_do_token(credenciais.credentials)

    except InvalidTokenError:
        raise erro_autenticacao from None

    try:
        jogador = _repositorio.buscar_conta_por_id(jogador_id)

    except psycopg.Error:
        _logger.exception("Falha ao consultar jogador autenticado.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível verificar a sessão.",
        ) from None

    if jogador is None:
        raise erro_autenticacao

    return jogador