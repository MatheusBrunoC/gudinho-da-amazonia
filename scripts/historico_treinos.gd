extends Node

signal treino_salvo(registro: Dictionary)
signal salvamento_falhou(mensagem: String)

const ENDERECO_API: String = "http://127.0.0.1:8000"


func gerar_identificador() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)

	# Identificador no formato UUID versão 4.
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80

	var texto: String = bytes.hex_encode()

	return "%s-%s-%s-%s-%s" % [
		texto.substr(0, 8),
		texto.substr(8, 4),
		texto.substr(12, 4),
		texto.substr(16, 4),
		texto.substr(20, 12)
	]


func salvar_treino(
	identificador: String,
	jogador_id: int,
	pontos_jogador: int,
	pontos_computador: int
) -> void:
	if jogador_id <= 0:
		_informar_falha("Treino não enviado: nenhum perfil selecionado.")
		return

	var requisicao: HTTPRequest = HTTPRequest.new()
	requisicao.timeout = 10.0
	add_child(requisicao)

	requisicao.request_completed.connect(
		_ao_concluir.bind(requisicao)
	)

	var dados: Dictionary = {
		"identificador": identificador,
		"jogador_id": jogador_id,
		"pontos_jogador": pontos_jogador,
		"pontos_computador": pontos_computador
	}

	var cabecalhos: PackedStringArray = PackedStringArray([
		"Content-Type: application/json"
	])

	var erro: Error = requisicao.request(
		ENDERECO_API + "/treinos",
		cabecalhos,
		HTTPClient.METHOD_POST,
		JSON.stringify(dados)
	)

	if erro != OK:
		requisicao.queue_free()
		_informar_falha(
			"Não foi possível iniciar o envio: %s"
			% error_string(erro)
		)


func _ao_concluir(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray,
	requisicao: HTTPRequest
) -> void:
	requisicao.queue_free()

	if resultado != HTTPRequest.RESULT_SUCCESS:
		_informar_falha(
			"Não foi possível confirmar o salvamento. Verifique a API."
		)
		return

	if codigo_http != 200 and codigo_http != 201:
		_informar_falha(
			"Falha ao salvar treino. HTTP %d: %s"
			% [codigo_http, corpo.get_string_from_utf8()]
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		_informar_falha("A API retornou uma resposta inválida.")
		return

	var registro: Dictionary = json.data

	if not registro.has("id"):
		_informar_falha("A resposta da API não contém o ID do treino.")
		return

	print("Treino salvo no banco! ID: ", registro["id"])
	treino_salvo.emit(registro)


func _informar_falha(mensagem: String) -> void:
	push_warning(mensagem)
	salvamento_falhou.emit(mensagem)
