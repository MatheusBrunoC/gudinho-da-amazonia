from getpass import getpass

from seguranca import gerar_hash_senha, verificar_senha


def main():
    senha = getpass("Digite uma senha temporária para o teste: ")

    if not senha:
        print("Digite uma senha não vazia para testar.")
        return

    primeiro_hash = gerar_hash_senha(senha)
    segundo_hash = gerar_hash_senha(senha)

    print(
        "Senha correta aceita:",
        verificar_senha(senha, primeiro_hash),
    )

    print(
        "Senha incorreta rejeitada:",
        not verificar_senha(senha + "_diferente", primeiro_hash),
    )

    print(
        "Hashes diferentes para a mesma senha:",
        primeiro_hash != segundo_hash,
    )

    print(
        "Segundo hash também reconhece a senha:",
        verificar_senha(senha, segundo_hash),
    )

    print(
        "Formato Argon2id:",
        primeiro_hash.startswith("$argon2id$"),
    )


if __name__ == "__main__":
    main()