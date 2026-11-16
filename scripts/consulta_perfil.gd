class_name ConsultaPerfil
extends HTTPRequest

signal perfil_carregado(perfil: Dictionary)
signal consulta_falhou(mensagem: String)

@export var endereco_api: String = SessaoJogador.ENDERECO_API


func _ready() -> void:
	timeout = 8.0
	request_completed.connect(_ao_concluir)


func consultar(jogador_id: int) -> void:
	if jogador_id < 1:
		consulta_falhou.emit("Identificador de jogador inválido.")
		return

	var url: String = "%s/jogadores/%d" % [
		endereco_api.trim_suffix("/"),
		jogador_id
	]

	var erro: Error = request(url)

	if erro != OK:
		consulta_falhou.emit("Não foi possível iniciar a consulta.")


func _ao_concluir(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray
) -> void:
	if resultado != HTTPRequest.RESULT_SUCCESS:
		consulta_falhou.emit("Perfil indisponível: sem conexão com a API.")
		return

	if codigo_http == 404:
		consulta_falhou.emit("Jogador não encontrado.")
		return

	if codigo_http != 200 and codigo_http != 201:
		consulta_falhou.emit(
			"Perfil indisponível. Código HTTP: %d." % codigo_http
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK:
		consulta_falhou.emit("A API retornou uma resposta inválida.")
		return

	if not json.data is Dictionary:
		consulta_falhou.emit("Formato de perfil inválido.")
		return

	var perfil: Dictionary = json.data

	if not perfil.has("id") or not perfil.has("apelido"):
		consulta_falhou.emit("A resposta não contém os dados do perfil.")
		return

	if not perfil["apelido"] is String:
		consulta_falhou.emit("O apelido recebido é inválido.")
		return

	perfil_carregado.emit(perfil)
	
func cadastrar(apelido: String) -> void:
	var nome: String = apelido.strip_edges()

	if nome.is_empty() or nome.length() > 30:
		consulta_falhou.emit("Use um apelido de 1 a 30 caracteres.")
		return

	var cabecalhos: PackedStringArray = [
		"Content-Type: application/json"
	]

	var corpo: String = JSON.stringify({
		"apelido": nome
	})

	var erro: Error = request(
		endereco_api.trim_suffix("/") + "/jogadores",
		cabecalhos,
		HTTPClient.METHOD_POST,
		corpo
	)

	if erro != OK:
		consulta_falhou.emit("Não foi possível iniciar o cadastro.")
