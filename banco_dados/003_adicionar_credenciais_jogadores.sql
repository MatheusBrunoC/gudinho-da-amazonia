USE gudinho_amazonia;

ALTER TABLE jogadores
    ADD COLUMN nome_usuario VARCHAR(30)
        CHARACTER SET ascii
        COLLATE ascii_general_ci
        NULL,

    ADD COLUMN senha_hash VARCHAR(255)
        NULL,

    ADD CONSTRAINT uq_jogadores_nome_usuario
        UNIQUE (nome_usuario),

    ADD CONSTRAINT chk_jogadores_credenciais
        CHECK (
            (nome_usuario IS NULL AND senha_hash IS NULL)
            OR
            (nome_usuario IS NOT NULL AND senha_hash IS NOT NULL)
        );