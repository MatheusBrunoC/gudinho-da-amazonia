# Gudinho da Amazônia — confronto online de duas rodadas

Esta versão inclui duas rodadas, placar acumulado, resultado final e revanche, mantendo as tacadas online já implementadas.

## Como testar em um computador

1. Abra project.godot no Godot 4.6.3, habilite duas instâncias e execute com F5.
2. Escolha “Jogar online — 2 jogadores” nas duas.
3. Na primeira, crie a sala na porta 8910. Na segunda, entre com 127.0.0.1 e a mesma porta.
4. Confirme “Estou pronto” nas duas. O Jogador 1 começa a primeira rodada.
5. Na sua vez, escolha a posição inicial fora da região proibida; aponte, segure o botão esquerdo para carregar a força e solte.
6. Espere as bolinhas pararem. Quem pontua continua até o limite de duas tacadas seguidas; uma tacada sem pontos passa a vez.
7. Ao acabar a primeira rodada, cada participante clica em “Próxima rodada”. Uma confirmação sozinha não avança.
8. A segunda rodada recria os 13 alvos, reinicia a câmera e permite novas posições iniciais. O Jogador 2 começa. Os pontos da primeira rodada permanecem no acumulado.
9. Ao acabar a segunda rodada, ambas as telas mostram o vencedor pelo total ou o empate. Há 38 pontos disponíveis no confronto inteiro.
10. Para uma revanche, os dois clicam em “Jogar novamente”. A conexão permanece aberta, o total volta a zero e o Jogador 1 começa uma nova primeira rodada.

O total exibido inclui os pontos já confirmados da rodada em andamento. Ao terminar a rodada, esses pontos são incorporados ao acumulado uma única vez.

O botão “Voltar à sala (desconectar)” encerra sua conexão e avisa o outro participante. Para jogar novamente depois disso, criem outra sala. A confirmação de continuação não pausa uma tacada: ela aparece somente quando a rodada terminou.

## Regras mantidas

- Cada participante tem sua própria bolinha e só controla seu turno.
- A posição inicial é escolhida na primeira vez de cada rodada; nas tacadas seguintes, a bolinha permanece onde parou.
- Alvos comuns valem 1, especiais valem 2 e o central vale 3: 19 pontos por rodada.
- A pontuação é confirmada após todas as bolinhas pararem.
- Até duas tacadas consecutivas quando há pontuação.
- Câmera amplia até o limite; as bolinhas dos jogadores retornam pelo lado oposto da arena.

## Organização do código

RedeSala administra conexão, participantes, confirmação inicial e abertura da cena online.

partida_online.gd coordena ações, física autoritativa, sincronização e ciclo do confronto. O anfitrião valida os pedidos e usa RodadaPartida.finalizar_jogada() para aplicar as regras existentes de pontuação e turno. O visitante mantém seus corpos congelados e recebe as posições.

A cada nova rodada, o controlador recria partida.tscn e chama configurar_rodada(numero). Isso reaproveita as cenas e reinicia os alvos, as bolinhas dos jogadores e a câmera. Os totais do confronto permanecem no controlador.

Cada arena recebe um identificador crescente, inclusive nas revanches. Estados e confirmações de uma arena anterior são ignorados. As confirmações são registradas por participante, evitando que cliques repetidos substituam a confirmação do adversário.

A nova rodada só aceita ações após os dois participantes confirmarem automaticamente que terminaram de carregá-la. O botão de continuar também aguarda os dois jogadores. A mira e a barra de força continuam locais ao participante da vez.

Estados completos são enviados aproximadamente 20 vezes por segundo; mudanças importantes também têm envio confiável. Cada estado inclui sequência, identificador da arena, posições, alvos restantes, vez, pontuação, totais e zoom.

As cenas locais e o controlador confronto.gd continuam responsáveis pelo modo de dois jogadores no mesmo computador.

## Dois computadores

Na mesma rede, use o IPv4 local do anfitrião, obtido com ipconfig no Windows, em vez de 127.0.0.1.

Entre redes diferentes, o anfitrião precisa estar acessível pela internet. Esta versão usa conexão direta ENet/UDP, porta 8910 por padrão. Pode ser necessário encaminhar a porta UDP no roteador; CGNAT pode impedir esse método. Ainda não há servidor hospedado, descoberta automática ou código de sala.

Documentação: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html#hosting-considerations

## Verificação desta entrega

Testes em duas instâncias do Godot 4.6.3, em modo headless:

- Três confrontos consecutivos: empate, vitória do Jogador 1 e vitória do Jogador 2.
- Duas revanches mantendo a conexão, com totais zerados.
- Jogador 1 inicia a primeira rodada; Jogador 2 inicia a segunda.
- Recriação dos 13 alvos, reinício da câmera e necessidade de novas posições iniciais.
- Uma confirmação não avança; confirmações duplicadas não contam como dois participantes.
- Totais acumulados sem duplicação e resultado igual nas duas instâncias.
- Estados e confirmações antigos ignorados.
- Desconexão durante a confirmação bloqueia o início de outra revanche.
- Disparos reais dos dois participantes, movimento e alternância de turno após as mudanças.

Os testes dos resultados usam estados controlados de fim de tacada para verificar rapidamente as combinações de placar. Os testes de disparo usam a física real. Não houve teste visual interativo nem teste entre redes reais.
