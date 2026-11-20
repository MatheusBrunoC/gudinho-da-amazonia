extends Node

func _ready() -> void:
	run.call_deferred()

func examinar(no: Node) -> void:
	if no is Control and no.visible and no.size.x > 0:
		var area: Rect2 = no.get_global_rect()
		if area.position.x < -1 or area.position.y < -1 or area.end.x > 1281 or area.end.y > 721:
			push_error("Controle fora da tela: %s %s" % [no.get_path(), area])
	if no is Label and no.visible and not no.text.is_empty():
		var altura: float = no.get_line_height() * no.get_line_count()
		if altura > no.size.y + 2:
			push_error("Texto excede caixa: %s altura=%s caixa=%s" % [no.name, altura, no.size])
		print("LAYOUT ", no.name, " ", no.size, " linhas=", no.get_line_count())
	for filho in no.get_children():
		examinar(filho)

func run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	for caminho in ["menu_inicial", "menu_opcoes", "menu_jogar", "instrucoes", "treino", "partida_online"]:
		var cena: Node = load("res://cenas/%s.tscn" % caminho).instantiate()
		get_tree().root.add_child(cena)
		await get_tree().process_frame
		await get_tree().process_frame
		examinar(cena)
		cena.queue_free()
		await get_tree().process_frame
	get_tree().quit()
