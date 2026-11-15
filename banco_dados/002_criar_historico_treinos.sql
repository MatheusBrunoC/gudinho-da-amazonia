USE gudinho_amazonia;

CREATE TABLE IF NOT EXISTS historico_treinos (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    identificador VARCHAR(36) NOT NULL,
    jogador_id INT UNSIGNED NOT NULL,
    pontos_jogador INT UNSIGNED NOT NULL,
    pontos_computador INT UNSIGNED NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT uq_historico_treinos_identificador
        UNIQUE (identificador),

    CONSTRAINT fk_historico_treinos_jogador
        FOREIGN KEY (jogador_id)
        REFERENCES jogadores (id)
) ENGINE = InnoDB;