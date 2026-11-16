from pwdlib import PasswordHash


_protetor_senhas = PasswordHash.recommended()


def gerar_hash_senha(senha: str) -> str:
    return _protetor_senhas.hash(senha)


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return _protetor_senhas.verify(senha, senha_hash)