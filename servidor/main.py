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

app = FastAPI(
    title="API Gudinho da Amazônia",
    version="0.1.0",
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


@app.get("/jogadores/{jogador_id}", response_model=JogadorResposta)
def consultar_jogador(jogador_id: int = Path(ge=1)):
    try:
        jogador = repositorio_jogadores.buscar_por_id(jogador_id)

    except mysql.connector.Error:
        logger.exception("Falha ao consultar jogador no MySQL.")

        raise HTTPException(
            status_code=503,
            detail="Banco de dados indisponível no momento.",
        ) from None

    if jogador is None:
        raise HTTPException(
            status_code=404,
            detail="Jogador não encontrado.",
        )

    return jogador

@app.post(
    "/jogadores",
    response_model=JogadorResposta,
    status_code=201,
)
def cadastrar_jogador(dados: JogadorCadastro):
    try:
        return repositorio_jogadores.criar(dados.apelido)

    except mysql.connector.Error:
        logger.exception("Falha ao cadastrar jogador no MySQL.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível cadastrar o jogador no momento.",
        ) from None

repositorio_treinos = RepositorioTreinos()


class TreinoCadastro(BaseModel):
    identificador: UUID
    jogador_id: int = Field(ge=1, strict=True)
    pontos_jogador: int = Field(ge=0, le=38, strict=True)
    pontos_computador: int = Field(ge=0, le=38, strict=True)


@app.post("/treinos", status_code=201)
def registrar_treino(dados: TreinoCadastro, response: Response):
    try:
        treino, criado = repositorio_treinos.salvar(
            identificador=str(dados.identificador),
            jogador_id=dados.jogador_id,
            pontos_jogador=dados.pontos_jogador,
            pontos_computador=dados.pontos_computador,
        )

    except ConflitoTreinoError as erro:
        raise HTTPException(
            status_code=409,
            detail=str(erro),
        ) from None

    except mysql.connector.Error as erro:
        if erro.errno == 1452:
            raise HTTPException(
                status_code=404,
                detail="Jogador não encontrado.",
            ) from None

        logger.exception("Falha ao salvar treino no MySQL.")

        raise HTTPException(
            status_code=503,
            detail="Não foi possível salvar o treino no momento.",
        ) from None

    # Um resultado repetido retorna o registro existente.
    if not criado:
        response.status_code = 200

    return treino