extends Node

signal treino_salvo(registro: Dictionary)
signal salvamento_falhou(mensagem: String)
signal estado_atualizado(identificador: String, mensagem: String)
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
	cabecalhos_sessao: PackedStringArray,
	pontos_jogador: int,
	pontos_computador: int
) -> void:
	if cabecalhos_sessao.is_empty():
		_informar_falha(
			"Treino não enviado: nenhuma sessão foi iniciada "
			+ "antes do confronto."
		)
		estado_atualizado.emit(
			identificador,
			"Treino sem conta — resultado não salvo."
		)
		return
	estado_atualizado.emit(identificador, "Salvando resultado...")
	var requisicao: HTTPRequest = HTTPRequest.new()
	requisicao.timeout = 10.0
	add_child(requisicao)

	requisicao.request_completed.connect(
		_ao_concluir.bind(requisicao, identificador)
	)
	requisicao.request_completed.connect(
		_publicar_estado.bind(identificador)
	)

	var dados: Dictionary = {
		"identificador": identificador,
		"pontos_jogador": pontos_jogador,
		"pontos_computador": pontos_computador
	}

	var erro: Error = requisicao.request(
		SessaoJogador.ENDERECO_API + "/treinos",
		cabecalhos_sessao,
		HTTPClient.METHOD_POST,
		JSON.stringify(dados)
	)

	if erro != OK:
		requisicao.queue_free()
		_informar_falha(
			"Não foi possível iniciar o envio: %s"
			% error_string(erro)
		)
		estado_atualizado.emit(
			identificador,
			"Não foi possível iniciar o salvamento."
		)

func _ao_concluir(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray,
	requisicao: HTTPRequest,
	identificador_esperado: String
) -> void:
	requisicao.queue_free()

	if resultado != HTTPRequest.RESULT_SUCCESS:
		_informar_falha(
			"Não foi possível confirmar o salvamento. "
			+ "Verifique a conexão com a API."
		)
		return

	if codigo_http == 401:
		_informar_falha(
			"A sessão usada neste treino expirou ou é inválida. "
			+ "O resultado não foi salvo. Entre novamente."
		)
		return

	if codigo_http == 409:
		_informar_falha(
			"O identificador deste treino já foi utilizado "
			+ "com outros dados."
		)
		return

	if codigo_http != 200 and codigo_http != 201:
		_informar_falha(
			"Não foi possível salvar o treino. HTTP %d."
			% codigo_http
		)
		return

	var json: JSON = JSON.new()
	var erro: Error = json.parse(corpo.get_string_from_utf8())

	if erro != OK or not json.data is Dictionary:
		_informar_falha(
			"A API retornou uma confirmação inválida."
		)
		return

	var registro: Dictionary = json.data

	if (
		int(registro.get("id", 0)) <= 0
		or str(registro.get("identificador", "")) != identificador_esperado
	):
		_informar_falha(
			"A resposta não corresponde ao treino enviado."
		)
		return

	print("Treino salvo na conta! ID: ", registro["id"])
	treino_salvo.emit(registro)


func _informar_falha(mensagem: String) -> void:
	push_warning(mensagem)
	salvamento_falhou.emit(mensagem)

func _publicar_estado(
	resultado: int,
	codigo_http: int,
	_cabecalhos: PackedStringArray,
	corpo: PackedByteArray,
	identificador: String
) -> void:
	var mensagem: String = "Salvamento não confirmado. Consulte o histórico."

	if resultado == HTTPRequest.RESULT_SUCCESS:
		if codigo_http == 401:
			mensagem = "Resultado não salvo: sessão inválida ou expirada."
		elif codigo_http == 409:
			mensagem = "Resultado não salvo: identificador em conflito."
		elif codigo_http == 200 or codigo_http == 201:
			var json: JSON = JSON.new()
			var erro: Error = json.parse(corpo.get_string_from_utf8())

			if erro == OK and json.data is Dictionary:
				var registro: Dictionary = json.data

				if (
					int(registro.get("id", 0)) > 0
					and str(registro.get("identificador", "")) == identificador
				):
					mensagem = "Resultado salvo no histórico."

	estado_atualizado.emit(identificador, mensagem)
