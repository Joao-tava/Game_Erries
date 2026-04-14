extends CharacterBody2D

# ── Exportáveis ────────────────────────────────────────────
@export_group("Movimento")
@export var walk_speed: float         = 80.0
@export var gravity: float            = 900.0

@export_group("Vida")
@export var max_health: int           = 1
@export var stomp_impulse: float      = -350.0

@export_group("Knockback")
@export var knockback_force: float    = 200.0
@export var knockback_duration: float = 0.3

# ── Sinais ─────────────────────────────────────────────────
signal enemy_died(pos: Vector2)
signal player_stomped(impulse: float)

# ── Estado ─────────────────────────────────────────────────
enum State { PATROL, KNOCKBACK, SQUISHED, DEAD }

var _state: State            = State.PATROL
var _health: int             = 0
var _direction: float        = -1.0
var _knockback_timer: float  = 0.0
var _knockback_vel: Vector2  = Vector2.ZERO
var _squish_timer: float     = 0.0

const SQUISH_DURATION = 0.4

# ── Nós ────────────────────────────────────────────────────
@onready var anim:      AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray:  RayCast2D        = $WallDetector
@onready var floor_ray: RayCast2D        = $FloorDetect

# ── Inicialização ──────────────────────────────────────────
func _ready() -> void:
	_health = max_health
	add_to_group("enemy")
	anim.play("walk")

	# Configura direção inicial com segurança
	_set_direction(_direction)

# ── Loop principal ─────────────────────────────────────────
func _physics_process(delta: float) -> void:
	match _state:
		State.PATROL:    _process_patrol(delta)
		State.KNOCKBACK: _process_knockback(delta)
		State.SQUISHED:  _process_squished(delta)
		State.DEAD:      pass

# ── Patrulha ───────────────────────────────────────────────
func _process_patrol(delta: float) -> void:
	if is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, 50.0)
	else:
		velocity.y += gravity * delta

	# Verifica parede e borda — só usa raycasts se existirem
	var hit_wall:  bool = wall_ray  != null and wall_ray.is_colliding()
	var has_floor: bool = floor_ray == null or floor_ray.is_colliding()

	if is_on_floor() and (hit_wall or not has_floor):
		_flip_direction()

	velocity.x = _direction * walk_speed
	move_and_slide()

	# Verifica pisão do jogador
	for i in get_slide_collision_count():
		var col      = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player"):
			var player_vel: Vector2 = collider.velocity if "velocity" in collider else Vector2.ZERO
			if col.get_normal().y < -0.5 and player_vel.y > 0:
				take_stomp_damage(collider)
				return

	_play_anim("walk")

# ── Knockback ──────────────────────────────────────────────
func _process_knockback(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = _knockback_vel.x
	move_and_slide()

	_knockback_timer -= delta
	if _knockback_timer <= 0.0:
		if _health > 0:
			_state = State.PATROL
		else:
			_finish_death()

# ── Squished ───────────────────────────────────────────────
func _process_squished(delta: float) -> void:
	velocity.x = 0.0
	velocity.y += gravity * delta
	move_and_slide()

	_squish_timer -= delta
	if _squish_timer <= 0.0:
		_finish_death()

# ── Receber dano (pisão) ───────────────────────────────────
func take_stomp_damage(_stomper: Node) -> void:
	if _state in [State.SQUISHED, State.DEAD]:
		return

	_health -= 1
	player_stomped.emit(stomp_impulse)

	if _health <= 0:
		_squish()
	else:
		_start_knockback(Vector2.ZERO)

# ── Receber dano (geral) ───────────────────────────────────
func take_damage(amount: int, hit_direction: Vector2) -> void:
	if _state in [State.SQUISHED, State.DEAD]:
		return

	_health -= amount
	_start_knockback(hit_direction)

# ── Aplicar squish ─────────────────────────────────────────
func _squish() -> void:
	_state        = State.SQUISHED
	_squish_timer = SQUISH_DURATION
	velocity      = Vector2.ZERO
	if anim.sprite_frames.has_animation("squished"):
		_play_anim("squished")

# ── Iniciar knockback ──────────────────────────────────────
func _start_knockback(direction: Vector2) -> void:
	_state           = State.KNOCKBACK
	_knockback_timer = knockback_duration
	var kdir: float  = sign(direction.x) if direction.x != 0.0 else -_direction
	_knockback_vel   = Vector2(kdir * knockback_force, -150.0)
	velocity         = _knockback_vel

# ── Finalizar morte ────────────────────────────────────────
func _finish_death() -> void:
	enemy_died.emit(global_position)
	queue_free()

# ── Direção ────────────────────────────────────────────────
func _flip_direction() -> void:
	_set_direction(-_direction)

func _set_direction(dir: float) -> void:
	_direction  = dir
	anim.flip_h = (_direction < 0.0)

	if wall_ray != null:
		wall_ray.target_position.x = abs(wall_ray.target_position.x) * _direction

	if floor_ray != null:
		floor_ray.target_position.x = abs(floor_ray.target_position.x) * _direction

# ── Animação ───────────────────────────────────────────────
func _play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

# ── Dano ao jogador ────────────────────────────────────────
func deal_damage_to_player(player: Node) -> void:
	if _state in [State.SQUISHED, State.DEAD]:
		return
	if player.has_method("take_damage"):
		player.take_damage(1, global_position.direction_to(player.global_position))
