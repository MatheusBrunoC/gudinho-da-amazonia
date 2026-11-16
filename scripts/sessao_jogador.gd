extends Node

signal login_realizado(perfil: Dictionary)
signal login_falhou(mensagem: String)
signal sessao_encerrada

const ENDERECO_API: String = "https://gudinho-api.onrender.com"
var _requisicao: HTTPRequest
var _token: String = ""
var _perfil: Dictionary = {}
var _ocupado: bool = false
var _validade_ms: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_requisicao = HTTPRequest.new()
	_requisicao.timeout = 90.0
	add_child(_requisicao)

	_requisicao.request_completed.connect(_ao_receber_login)


func entrar(nome_usuario: String, senha: String) -> void:
	if _ocupado:
		return

	var usuario: String = nome_usuario.strip_edges().to_lower()

	if usuario.is_empty() or senha.is_empty():
		login_falhou.emit("Preencha o usuário e a senha.")
		return

	_token = ""
	_perfil = {}
	_validade_ms = 0
	_ocupado = true

	var dados: Dictionary = {
		"nome_usuario": usuario,
		"senha": senha
	}

	var erro: Error = _requisicao.request(
		ENDERECO_API + "/auth/login",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(dados)
	)

	if erro != OK:
		_ocupado = false
		login_falhou.emit("Não foi possível iniciar o login.")


func _ao_receber_login(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray
) -> void:
	_ocupado = false

	if resultado != HTTPRequest.RESULT_SUCCESS:
		login_falhou.emit("Sem conexão com a API. Tente novamente.")
		return

	if codigo_http == 429:
		login_falhou.emit(
			"Muitas tentativas de login. "
			+ "Aguarde 60 segundos e tente novamente."
		)
		return


	if codigo_http == 401:
		login_falhou.emit("Usuário ou senha incorretos.")
		return

	if codigo_http == 422:
		login_falhou.emit("Confira o formato do usuário e da senha.")
		return

	if codigo_http != 200:
		login_falhou.emit("Não foi possível entrar no momento.")
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		login_falhou.emit("A API retornou uma resposta inválida.")
		return

	var dados: Dictionary = json.data

	if (
		not dados.get("access_token") is String
		or not dados.get("jogador") is Dictionary
	):
		login_falhou.emit("A resposta de login está incompleta.")
		return

	var token_recebido: String = dados["access_token"]
	var perfil_recebido: Dictionary = dados["jogador"]
	var duracao: int = int(dados.get("expires_in", 0))

	if (
		token_recebido.is_empty()
		or int(perfil_recebido.get("id", 0)) <= 0
		or duracao <= 0
	):
		login_falhou.emit("A resposta de login está inválida.")
		return

	_token = token_recebido
	_perfil = perfil_recebido.duplicate(true)

	# Pequena margem antes do vencimento informado pela API.
	_validade_ms = (
		Time.get_ticks_msec() + maxi(duracao - 5, 0) * 1000
	)

	login_realizado.emit(obter_perfil())


func possui_sessao() -> bool:
	return (
		not _token.is_empty()
		and Time.get_ticks_msec() < _validade_ms
	)


func obter_perfil() -> Dictionary:
	if not possui_sessao():
		return {}

	return _perfil.duplicate(true)


func obter_cabecalhos() -> PackedStringArray:
	if not possui_sessao():
		return PackedStringArray()

	return PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + _token
	])


func cancelar_login() -> void:
	_requisicao.cancel_request()
	_ocupado = false


func sair() -> void:
	cancelar_login()
	_token = ""
	_perfil = {}
	_validade_ms = 0
	sessao_encerrada.emit()
