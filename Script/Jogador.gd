extends CharacterBody2D

@onready var anim      := $AnimatedSprite2D as AnimatedSprite2D
@onready var sfx_jump  := $SfxJump         as AudioStreamPlayer
@onready var sfx_dash  := $SfxDash         as AudioStreamPlayer
@onready var sfx_coin  := $SfxCoin         as AudioStreamPlayer

# ── Física (Super Meat Boy feel) ──────────────────────────────
const FALL_SPEED         = 1200.0  # velocidade máxima de queda
const GRAVITY            = 2800.0  # queda pesada e rápida
const SPEED              = 875.0   # velocidade horizontal
const ACCELERATION       = 4500.0  # arranca e para instantaneamente

const JUMP_POWER_INITIAL = -1000.0  # força inicial do pulo
const JUMP_HOLD_FORCE    =  900.0   # força ao segurar o pulo
const JUMP_HOLD_TARGET   = -500.0   # velocidade alvo ao segurar
const JUMP_HOLD_TIME     =  0.12    # janela máxima para segurar o pulo
const JUMP_CUT_MULTIPLIER=  0.45    # fator de corte ao soltar cedo (< 1 = mais suave)

# ── Coyote Time ───────────────────────────────────────────────
# Permite pular por um breve instante após sair de uma plataforma
const COYOTE_TIME        = 0.10    # segundos após deixar o chão
var   coyote_timer       = 0.0
var   coyote_usable      = false

# ── Jump Buffer (Pré-pulo) ────────────────────────────────────
# Registra o input de pulo antes de tocar o chão
const JUMP_BUFFER_TIME   = 0.12
var   jump_buffer_timer  = 0.0

var   jump_timer         = 0.0
var   is_jumping         = false   # true enquanto o pulo está ativo (hold)

# ── Wall Jump / Wall Slide ────────────────────────────────────
const WALL_JUMP_PUSH     = 1200.0  # força horizontal do wall jump
const WALL_SLIDE_SPEED   =  350.0  # velocidade máxima de queda na parede (mais lento = mais controle)
var   last_wall: Vector2 = Vector2.ZERO
var   wall_jump_lock     = 0.0     # trava o controle horizontal brevemente após wall jump
const WALL_JUMP_LOCK_TIME= 0.12

# ── Dash ──────────────────────────────────────────────────────
const DASH_SPEED         = 1100.0
const DASH_DURATION      = 0.18
const DASH_COOLDOWN      = 0.35
const DASH_FREEZE        = 0.04

var is_dashing:        bool    = false
var dash_timer:        float   = 0.0
var dash_cooldown_t:   float   = 0.0
var dash_direction:    Vector2 = Vector2.ZERO
var can_dash:          bool    = true
var dash_freeze_timer: float   = 0.0

var was_on_floor:      bool    = false
var was_on_wall:       bool    = false
var _is_dying:         bool    = false

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if _is_dying or get_tree().paused:
		return

	_update_timers(delta)
	_update_dash_cooldown(delta)
	_handle_dash_input()

	if is_dashing:
		_process_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_wall_slide()
		_handle_jump(delta)
		_handle_movement(delta)

	_update_dash_refresh()
	_update_animation()
	was_on_floor = is_on_floor()
	was_on_wall  = is_on_wall()
	move_and_slide()

# ── Timers auxiliares ─────────────────────────────────────────
func _update_timers(delta: float) -> void:
	# Coyote time: conta enquanto está no ar após ter saído do chão
	if is_on_floor():
		coyote_timer  = COYOTE_TIME
		coyote_usable = true
		last_wall     = Vector2.ZERO
	elif coyote_timer > 0.0:
		coyote_timer -= delta

	# Jump buffer: conta o tempo desde o último input de pulo
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# Wall jump lock
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta

# ── Gravidade ─────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# Mantém pequena gravidade para colar no chão
		if velocity.y > 0:
			velocity.y = 0
		return

	if _is_wall_sliding():
		# Na parede, a queda é muito mais lenta
		velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, GRAVITY * delta)
	else:
		velocity.y = move_toward(velocity.y, FALL_SPEED, GRAVITY * delta)

# ── Wall Slide ────────────────────────────────────────────────
func _is_wall_sliding() -> bool:
	return is_on_wall() \
		and not is_on_floor() \
		and velocity.y > 0 \
		and abs(get_wall_normal().x) > 0.9 \
		and (Input.get_action_strength("ui_right") > 0 or Input.get_action_strength("ui_left") > 0)

func _handle_wall_slide() -> void:
	if _is_wall_sliding():
		var wn = get_wall_normal()
		# Permite reutilizar o wall jump nessa parede se mudou de parede
		if wn != last_wall:
			can_dash  = true
			last_wall = wn

# ── Pulo ──────────────────────────────────────────────────────
func _handle_jump(delta: float) -> void:
	var want_jump = jump_buffer_timer > 0.0

	# ── Pulo do chão (com coyote time) ──
	if want_jump and (is_on_floor() or (coyote_usable and coyote_timer > 0.0)):
		_do_jump()
		return

	# ── Wall Jump ──
	if want_jump and is_on_wall() and not is_on_floor() and abs(get_wall_normal().x) > 0.9:
		_do_wall_jump()
		return

	# ── Sustentação do pulo (hold) ──
	if is_jumping:
		if Input.is_action_pressed("ui_accept") and jump_timer > 0.0:
			velocity.y  = move_toward(velocity.y, JUMP_HOLD_TARGET, JUMP_HOLD_FORCE * delta)
			jump_timer -= delta
		else:
			is_jumping = false
			jump_timer = 0.0
			# Jump cut: ao soltar cedo, reduz a velocidade vertical (arco menor)
			if Input.is_action_just_released("ui_accept") and velocity.y < 0:
				velocity.y *= JUMP_CUT_MULTIPLIER

func _do_jump() -> void:
	velocity.y        = JUMP_POWER_INITIAL
	jump_timer        = JUMP_HOLD_TIME
	is_jumping        = true
	coyote_usable     = false
	coyote_timer      = 0.0
	jump_buffer_timer = 0.0
	sfx_jump.play()

func _do_wall_jump() -> void:
	var wall_normal   = get_wall_normal()
	velocity.y        = JUMP_POWER_INITIAL
	velocity.x        = wall_normal.x * WALL_JUMP_PUSH
	jump_timer        = JUMP_HOLD_TIME
	is_jumping        = true
	last_wall         = wall_normal
	wall_jump_lock    = WALL_JUMP_LOCK_TIME
	jump_buffer_timer = 0.0
	can_dash          = true
	sfx_jump.play()

# ── Movimento horizontal ──────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	# Durante o wall jump, reduz o controle horizontal brevemente
	if wall_jump_lock > 0.0:
		var lock_factor = wall_jump_lock / WALL_JUMP_LOCK_TIME
		direction = lerp(direction, 0.0, lock_factor * 0.7)

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)

# ── Dash ──────────────────────────────────────────────────────
func _update_dash_cooldown(delta: float) -> void:
	if dash_cooldown_t > 0.0:
		dash_cooldown_t -= delta

func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_t <= 0.0:
		var dir := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		if dir == Vector2.ZERO:
			dir.x = 1.0 if velocity.x >= 0 else -1.0
		dash_direction    = dir.normalized()
		is_dashing        = true
		can_dash          = false
		dash_timer        = DASH_DURATION
		dash_freeze_timer = DASH_FREEZE
		velocity          = Vector2.ZERO
		is_jumping        = false
		sfx_dash.play()

func _process_dash(delta: float) -> void:
	if dash_freeze_timer > 0.0:
		dash_freeze_timer -= delta
		velocity = Vector2.ZERO
		return
	dash_timer -= delta
	if dash_timer <= 0.0:
		is_dashing      = false
		dash_cooldown_t = DASH_COOLDOWN
		velocity        = dash_direction * SPEED * 0.6
	else:
		velocity = dash_direction * DASH_SPEED

func _update_dash_refresh() -> void:
	if is_on_floor():
		can_dash = true
	elif is_on_wall() and not was_on_wall:
		can_dash = true

# ── Morte ─────────────────────────────────────────────────────
func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	set_physics_process(false)
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()

# ── Coletável ─────────────────────────────────────────────────
func play_coin_sfx() -> void:
	sfx_coin.play()

# ── Animação ──────────────────────────────────────────────────
func _update_animation() -> void:
	if is_dashing:
		anim.play("dash")
		_apply_dash_visuals()
		return

	anim.rotation = 0.0
	anim.flip_v   = false

	if _is_wall_sliding():
		anim.play("wallslide")
		anim.flip_h = get_wall_normal().x > 0
		return

	if not is_on_floor():
		anim.play("jump")
		_flip_to_velocity()
		return

	var direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if direction != 0:
		anim.play("run")
		anim.flip_h = direction < 0
	else:
		anim.play("idle")

func _apply_dash_visuals() -> void:
	if dash_direction.y == 0.0:
		anim.rotation = 0.0
		anim.flip_h   = dash_direction.x < 0
		anim.flip_v   = false
	elif dash_direction.x == 0.0:
		anim.rotation = deg_to_rad(-90.0)
		anim.flip_h   = false
		anim.flip_v   = dash_direction.y > 0
	else:
		anim.rotation = deg_to_rad(-45.0)
		anim.flip_h   = dash_direction.x < 0
		anim.flip_v   = dash_direction.y > 0

func _flip_to_velocity() -> void:
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
