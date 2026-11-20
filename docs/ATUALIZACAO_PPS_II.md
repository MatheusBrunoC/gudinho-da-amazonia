# Revisão do Gudinho da Amazônia — PPS II

## Integração do trabalho do grupo

Base funcional: projeto `gudinho-repositorio.zip`. Arte integrada: `gudinho-do-colega-alterado.zip`.

Foram aproveitadas as folhas de animação das bolinhas e o trecho ilustrado do título da tela de instruções. As instruções agora usam textos editáveis em três cartões, acessíveis pelo botão “Como jogar” do menu inicial. As regras antigas gravadas na imagem não são exibidas. A imagem original foi preservada como recurso, sem edição do arquivo.

A versão do colega também continha alterações no cenário, tema e configurações, além das bolinhas e instruções mencionadas. A integração foi seletiva: preservou o cenário e as configurações funcionais da base e trouxe a arte solicitada. A partida não recebeu o TileMap adicional do outro arquivo.

Os SpriteFrames foram separados em cinco recursos reutilizáveis, em `recursos/bolinhas`. O raio físico das bolinhas continua sendo 12 pixels. A imagem é ajustada à dimensão física. As bolinhas dos jogadores têm um número e um contorno para identificação.

O script mantém a cor usada pela prévia de posicionamento, oculta e reapresenta o corpo inteiro (inclusive no convidado online) e preserva a camada/máscara de colisão em penalidades sucessivas. O movimento recebido da rede também pode acionar a animação, mesmo sem simulação física no convidado.

## Regras e HUD

`RegrasPartida` centraliza a distância da linha de lançamento. `SeletorPosicao` valida a posição atrás da linha, os limites da arena e a ausência de sobreposição. `CampoBase` define o contrato para detectar o centro dentro do círculo; `CampoCircular` o implementa. `RodadaPartida` aplica a penalidade depois que todas as bolinhas param.

O retorno obrigatório à linha ocorre apenas na entrada de cada rodada e no turno posterior à penalidade. A penalidade vale para a bolinha de quem efetuou a tacada. Os pontos obtidos são mantidos nessa situação, conforme a hipótese comunicada durante a implementação.

`InterfacePartida` recebe a base de pontos das rodadas já concluídas e soma os pontos atuais. `Confronto` não envia a soma final como se fosse novamente a base da rodada que acabou. Isso evita dobrar os pontos no encerramento. O histórico continua recebendo os mesmos totais acumulados pelo confronto.

A interface separa placar geral, indicação da rodada, estado da vez, aviso de penalidade, força e status do salvamento. O modo treino identifica “Você” e “Computador”. No online, há um único placar acumulado e a identificação do participante.

## API e versão web

O teste OPTIONS em `/auth/login`, com origem do site Netlify e cabeçalhos de JSON/autorização, recebeu 405 na API publicada antes da atualização. O código-fonte não tinha middleware CORS.

Foi adicionado `CORSMiddleware` com origem explícita, métodos GET/POST e cabeçalhos Authorization/Content-Type. As origens podem ser configuradas por `CORS_ORIGINS`, separadas por vírgula. O padrão é `https://lively-sunburst-2446bf.netlify.app`. Não há liberação por curinga nem uso de cookies entre origens.

O cliente mantém `https://gudinho-api.onrender.com` como endereço da API. Não houve alteração de senhas, tokens, consultas SQL, dados do Neon ou estrutura de tabelas. A configuração precisa ser publicada no Render.

A predefinição Web usa uma única thread. Código do servidor, banco, testes e documentação são excluídos da exportação. O botão de sair é ocultado na web porque o jogo não deve tentar fechar uma aba aberta pelo usuário. O modo ENet é identificado como exclusivo da versão Windows no menu web; cadastro, login e histórico continuam sendo recursos HTTP independentes do multijogador.

## Validação realizada

Ambiente: Godot **4.6.3 stable**, Linux, código GDScript; renderização Compatibility. Não foi produzido ou executado um `.exe` Windows nem uma nova exportação Web nesta revisão.

| Verificação | Resultado |
| --- | --- |
| Importação e abertura do projeto no Godot 4.6.3 | Sem erros de compilação |
| 26 verificações de regras, reentrada, IA e placar | Aprovadas |
| Tacada simulada pela física real | Iniciou, deslocou a bolinha e encerrou após ela parar |
| Duas instâncias ENet no mesmo computador | Penalidade sincronizada; corpo ocultado e reapresentado; total 20 × 18 no convidado |
| Abertura de menus e instruções | Sem referências a nós ausentes |
| Interface renderizada em 1280 × 720 | Inspecionada; prévias incluídas no pacote |
| CORS: preflight das cinco rotas usadas pelo jogo | HTTP 200 e origem autorizada |
| Perfil sem token, com origem autorizada | HTTP 401, preservando autenticação |
| Preflight de origem não autorizada | HTTP 400, sem autorização para essa origem |

Os testes da API usaram o cliente de testes do FastAPI, sem banco e sem credenciais de produção. Não foram criadas contas ou partidas reais. O teste em rede foi local, não entre redes distintas. A autenticação e persistência completas no navegador devem ser verificadas depois do deploy.

### Reproduzir testes do jogo

Com o executável do Godot disponível como `godot` no terminal e estando na pasta do projeto:

```bash
godot --headless --path . res://testes/regras.tscn
godot --headless --fixed-fps 60 --path . res://testes/fisica.tscn
```

O teste de física desativa o áudio para executar de forma determinística sem dispositivo sonoro. Não é uma validação de áudio.

Para o teste ENet, use dois terminais; inicie o segundo imediatamente após o primeiro. Ele usa a porta local 17891 e não acessa a API:

```bash
# Terminal 1
godot --headless --path . res://testes/rede.tscn -- host
# Terminal 2
godot --headless --path . res://testes/rede.tscn -- client
```

Para testar CORS, ative o ambiente Python do servidor, instale `httpx` se ainda não estiver presente, entre em `servidor` e execute:

```bash
python -m unittest testar_cors.py
```

### Testes de aceitação após publicar

1. Abra Como jogar a partir do menu principal.
2. Coloque a bolinha atrás da linha e confira a prévia inválida acima dela.
3. Faça ponto parando fora: deve haver somente uma tacada extra.
4. Pare dentro: o turno termina e sua próxima entrada exige a linha.
5. Passe da primeira para a segunda rodada: os pontos permanecem no placar geral.
6. Faça login na versão web, conclua um treino e confira o histórico após reabrir o jogo.
7. Confirme a resposta OPTIONS no Render e verifique que o navegador não apresenta bloqueio de CORS.
8. Exporte novamente a versão Windows e faça um teste no notebook e no laboratório.

## Referências técnicas

- FastAPI, CORS: https://fastapi.tiangolo.com/tutorial/cors/
- Godot, exportação Web e limitações de rede: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html


## Arena com linha vertical (revisão posterior)

O círculo e os 13 alvos foram deslocados para a esquerda, centro (300, 360), com raio de 140 pixels preservado. A linha fica em x=1000; são 700 pixels do centro e 560 pixels da borda. O posicionamento inicial e após penalidade exige que a bolinha inteira esteja à direita da linha. A área à esquerda continua acessível durante a tacada e para continuar de onde a bolinha parou.

O impulso máximo foi ajustado de 750 para 1100 para permitir alcançar os alvos da nova distância, mantendo o impulso mínimo de 150. O validador compartilhado continua atendendo jogador local, computador e anfitrião online. Textos de instruções e testes foram atualizados. Esta revisão não modifica a API nem o banco.
