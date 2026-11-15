extends Node
## Responsável pela conexão e pelo estado da sala de dois jogadores.
signal atualizada
signal partida_atualizada

var partida_em_abertura: bool = false
var cenas_carregadas: Dictionary = {}

var mensagem: String = "Crie uma sala ou entre pelo endereço do anfitrião."
var participantes: Dictionary = {}
var _peer: ENetMultiplayerPeer
var _prazo: float = 0.0

func _ready() -> void:
	multiplayer.peer_connected.connect(_ao_conectar_par)
	multiplayer.peer_disconnected.connect(_ao_sair_par)
	multiplayer.connected_to_server.connect(_conectado)
	multiplayer.connection_failed.connect(_falhou)
	multiplayer.server_disconnected.connect(_servidor_saiu)

func criar(porta: int) -> Error:
	fechar()
	_peer = ENetMultiplayerPeer.new()
	var erro: Error = _peer.create_server(porta, 1)
	if erro != OK:
		fechar("Não foi possível abrir a porta: " + error_string(erro))
		return erro
	multiplayer.multiplayer_peer = _peer
	participantes = {1: false}
	mensagem = "Sala criada. Aguardando o segundo jogador."
	atualizada.emit()
	return OK

func entrar(endereco: String, porta: int) -> Error:
	fechar()
	if endereco.strip_edges().is_empty():
		fechar("Informe o endereço do anfitrião.")
		return ERR_INVALID_PARAMETER
	_peer = ENetMultiplayerPeer.new()
	var erro: Error = _peer.create_client(endereco.strip_edges(), porta)
	if erro != OK:
		fechar("Não foi possível conectar: " + error_string(erro))
		return erro
	multiplayer.multiplayer_peer = _peer
	_prazo = 10.0
	mensagem = "Conectando…"
	atualizada.emit()
	return OK

func fechar(texto: String = "Crie uma sala ou entre pelo endereço do anfitrião.") -> void:
	_prazo = 0.0
	partida_em_abertura = false
	cenas_carregadas.clear()
	if _peer != null:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	participantes.clear()
	mensagem = texto
	atualizada.emit()
	partida_atualizada.emit()

func em_sala() -> bool:
	return _peer != null

func meu_id() -> int:
	return multiplayer.get_unique_id()

func marcar_pronto() -> void:
	if partida_em_abertura or not participantes.has(meu_id()):
		return
	if multiplayer.is_server():
		participantes[1] = true
		_publicar()
	else:
		_pedir_pronto.rpc_id(1)

func _process(delta: float) -> void:
	if _prazo <= 0.0:
		return
	_prazo -= delta
	if _prazo <= 0.0:
		fechar("Tempo esgotado. Confira endereço, porta e disponibilidade da sala.")

func _ao_conectar_par(id: int) -> void:
	if multiplayer.is_server():
		participantes[id] = false
		_publicar()

func _ao_sair_par(id: int) -> void:
	if _peer != null and multiplayer.is_server():
		if partida_em_abertura:
			fechar("O visitante saiu. A preparação da partida foi encerrada.")
			return
		participantes.erase(id)
		participantes[1] = false
		_publicar()

func _conectado() -> void:
	_prazo = 0.0

func _falhou() -> void:
	fechar("Conexão falhou. Confira o endereço e tente novamente.")

func _servidor_saiu() -> void:
	fechar("O anfitrião encerrou a sala.")

@rpc("any_peer", "call_remote", "reliable")
func _pedir_pronto() -> void:
	if not multiplayer.is_server() or partida_em_abertura:
		return
	var remetente: int = multiplayer.get_remote_sender_id()
	if participantes.has(remetente):
		participantes[remetente] = true
		_publicar()

func _publicar() -> void:
	if participantes.size() < 2:
		mensagem = "Aguardando o segundo jogador."
	elif participantes.values().has(false):
		mensagem = "Dois jogadores conectados. Confirmem que estão prontos."
	else:
		mensagem = "Ambos prontos! Teste de conexão concluído."
	_receber_estado.rpc(participantes, mensagem)
	if participantes.size() == 2 and not participantes.values().has(false):
		if not partida_em_abertura:
			_peer.refuse_new_connections = true
			_abrir_partida.rpc()

@rpc("authority", "call_local", "reliable")
func _receber_estado(estado: Dictionary, texto: String) -> void:
	participantes = estado.duplicate()
	mensagem = texto
	atualizada.emit()


@rpc("authority", "call_local", "reliable")
func _abrir_partida() -> void:
	if partida_em_abertura or participantes.size() != 2:
		return
	partida_em_abertura = true
	cenas_carregadas.clear()
	mensagem = "Abrindo a partida nos dois computadores…"
	_trocar_para_partida.call_deferred()

func _trocar_para_partida() -> void:
	if not partida_em_abertura:
		return
	var erro: Error = get_tree().change_scene_to_file("res://cenas/partida_online.tscn")
	if erro != OK:
		fechar("Falha ao abrir a partida: " + error_string(erro))

func confirmar_cena_carregada() -> void:
	if not partida_em_abertura:
		return
	if multiplayer.is_server():
		_registrar_cena(1)
	else:
		_cena_carregada.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _cena_carregada() -> void:
	if multiplayer.is_server() and partida_em_abertura:
		_registrar_cena(multiplayer.get_remote_sender_id())

func _registrar_cena(id: int) -> void:
	if not participantes.has(id):
		return
	cenas_carregadas[id] = true
	_confirmar_carregamento.rpc(cenas_carregadas)

@rpc("authority", "call_local", "reliable")
func _confirmar_carregamento(carregadas: Dictionary) -> void:
	if not partida_em_abertura:
		return
	cenas_carregadas = carregadas.duplicate()
	partida_atualizada.emit()
