extends Area2D

# O nome aqui deve ser igual ao que aparece na sua árvore de cena (canto superior esquerdo)
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var velocidade_giro: float = 200.0

func _ready() -> void:
	# Inicia a animação de frames que você criou
	if anim:
		anim.play("serra")
	
	# Conecta o sinal de colisão
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	# Além da animação de frames, o código faz o objeto todo girar
	# Isso dá um efeito de movimento mais fluido para serras
	rotation_degrees += velocidade_giro * delta

func _on_body_entered(body: Node) -> void:
	# Verifica se quem entrou na área é o jogador
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage"):
			# Verifique se no script do seu Player o 't' de 'take_damage' é minúsculo
			body.take_damage(999, global_position.direction_to(body.global_position))
