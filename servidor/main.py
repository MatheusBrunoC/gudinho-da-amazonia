import logging
from datetime import datetime

import mysql.connector
from fastapi import FastAPI, HTTPException, Path
from pydantic import BaseModel, field_validator

from repositorio_jogadores import RepositorioJogadores

from uuid import UUID
from fastapi import Response
from pydantic import Field

from repositorio_treinos import (
    RepositorioTreinos,
    ConflitoTreinoError,
)

from fastapi import Query


import re

from pydantic import SecretStr
from seguranca import gerar_hash_senha, verificar_senha
from tokens import criar_token_acesso, DURACAO_TOKEN_SEGUNDOS

from fastapi import Depends
from pydantic import ConfigDict

from autenticacao import exigir_jogador

from fastapi import Request
from fastapi.responses import JSONResponse

from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

app = FastAPI(
    title="API Gudinho da Amazônia",
    version="0.1.0",
)

limitador = Limiter(
    key_func=get_remote_address,
    storage_uri="memory://",
    strategy="fixed-window",
)

app.state.limiter = limitador


@app.exception_handler(RateLimitExceeded)
async def tratar_limite_excedido(
    request: Request,
    exc: RateLimitExceeded,
):
    return JSONResponse(
        status_code=429,
        content={
            "detail": (
                "Muitas tentativas. Aguarde 60 segundos "
                "e tente novamente."
            )
        },
        headers={
            "Retry-After": "60",
            "Cache-Control": "no-store",
        },
    )

logger = logging.getLogger("uvicorn.error")
repositorio_jogadores = RepositorioJogadores()


class JogadorResposta(BaseModel):
    id: int
    apelido: str
    criado_em: datetime

class JogadorCadastro(BaseModel):
    apelido: str

    @field_validator("apelido")
    @classmethod
    def validar_apelido(cls, valor: str) -> str:
        apelido = valor.strip()

        if not 1 <= len(apelido) <= 30:
            raise ValueError(
                "O apelido deve ter entre 1 e 30 caracteres."
            )

        return apelido

@app.get("/")
def inicio():
    return {
        "mensagem": "API Gudinho da Amazônia funcionando!"
    }






repositorio_treinos = RepositorioTreinos()


class TreinoCadastro(BaseModel):
    model_config = ConfigDict(extra="forbid")

    identificador: UUID
    pontos_jogador: int = Field(ge=0, le=38, strict=True)
    pontos_computador: int = Field(ge=0, le=38, strict=True)


@app.post("/treinos", status_code=201)
def registrar_treino(
    dados: TreinoCadastro,
    response: Response,
    jogador: dict = Depends(exigir_jogador),
):
    try:
        treino, criado = repositorio_treinos.salvar(
            identificador=str(dados.identificador),
            jogador_id=jogador["id"],
            pontos_jogador=dados.pontos_jogador,
            pontos_computador=dados.pontos_computador,
        )

    except ConflitoTreinoError:
        raise HTTPException(
            status_code=409,
            detail="Este identificador já foi utilizado.",
        ) from None

    except mysql.connector.Error:
        logger.exception("Falha ao salvar treino no MySQL.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível salvar o treino no momento.",
        ) from None

    if not criado:
        response.status_code = 200

    return treino





class ContaCadastro(BaseModel):
    apelido: str
    nome_usuario: str
    senha: SecretStr = Field(min_length=15, max_length=128)

    @field_validator("apelido")
    @classmethod
    def validar_apelido(cls, valor: str) -> str:
        apelido = valor.strip()

        if not 1 <= len(apelido) <= 30:
            raise ValueError(
                "O apelido deve ter entre 1 e 30 caracteres."
            )

        return apelido

    @field_validator("nome_usuario")
    @classmethod
    def validar_nome_usuario(cls, valor: str) -> str:
        nome = valor.strip().lower()

        if re.fullmatch(r"[a-z0-9_]{3,30}", nome) is None:
            raise ValueError(
                "Use de 3 a 30 caracteres: letras sem acentos, "
                "números ou sublinhado."
            )

        return nome


class ContaResposta(BaseModel):
    id: int
    apelido: str
    nome_usuario: str
    criado_em: datetime

@app.post(
    "/contas",
    response_model=ContaResposta,
    status_code=201,
)
@limitador.limit("5/minute")
def cadastrar_conta(request: Request, dados: ContaCadastro):
    senha_hash = gerar_hash_senha(
        dados.senha.get_secret_value()
    )

    try:
        return repositorio_jogadores.criar_conta(
            apelido=dados.apelido,
            nome_usuario=dados.nome_usuario,
            senha_hash=senha_hash,
        )

    except mysql.connector.Error as erro:
        if erro.errno == 1062:
            raise HTTPException(
                status_code=409,
                detail="Este nome de usuário já está em uso.",
            ) from None

        logger.exception("Falha ao cadastrar conta no MySQL.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível criar a conta no momento.",
        ) from None

# Usado para realizar uma verificação mesmo quando a conta não existe.
_HASH_FICTICIO = gerar_hash_senha(
    "Verificacao interna de usuario inexistente."
)


class LoginEntrada(BaseModel):
    nome_usuario: str = Field(min_length=3, max_length=30)
    senha: SecretStr = Field(min_length=1, max_length=128)

    @field_validator("nome_usuario")
    @classmethod
    def normalizar_usuario(cls, valor: str) -> str:
        return valor.strip().lower()


class LoginResposta(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    jogador: ContaResposta


@app.post("/auth/login", response_model=LoginResposta)
@limitador.limit("10/minute")
def entrar(request: Request, dados: LoginEntrada):
    try:
        jogador = repositorio_jogadores.buscar_por_usuario(
            dados.nome_usuario
        )

    except mysql.connector.Error:
        logger.exception("Falha ao consultar conta para login.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível entrar no momento.",
        ) from None

    senha_hash = (
        jogador.get("senha_hash")
        if jogador is not None
        else None
    )

    senha_correta = verificar_senha(
        dados.senha.get_secret_value(),
        senha_hash or _HASH_FICTICIO,
    )

    if jogador is None or not senha_hash or not senha_correta:
        raise HTTPException(
            status_code=401,
            detail="Usuário ou senha incorretos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = criar_token_acesso(jogador["id"])

    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": DURACAO_TOKEN_SEGUNDOS,
        "jogador": {
            "id": jogador["id"],
            "apelido": jogador["apelido"],
            "nome_usuario": jogador["nome_usuario"],
            "criado_em": jogador["criado_em"],
        },
    }

@app.get("/me", response_model=ContaResposta)
def consultar_meu_perfil(
    jogador: dict = Depends(exigir_jogador),
):
    return jogador


@app.get("/me/treinos")
def consultar_meus_treinos(
    limite: int = Query(default=10, ge=1, le=50),
    jogador: dict = Depends(exigir_jogador),
):
    try:
        treinos = repositorio_treinos.listar_por_jogador(
            jogador["id"],
            limite,
        )

    except mysql.connector.Error:
        logger.exception("Falha ao consultar histórico de treinos.")

        raise HTTPException(
            status_code=503,
            detail="Histórico indisponível no momento.",
        ) from None

    return {
        "jogador_id": jogador["id"],
        "apelido": jogador["apelido"],
        "treinos": treinos,
    }