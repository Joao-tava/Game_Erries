extends CharacterBody2D

# ── Referências ──────────────────────────────────────────────
@onready var anim      := $AnimatedSprite2D    as AnimatedSprite2D
@onready var sfx_jump  := $SfxJump             as AudioStreamPlayer
@onready var sfx_dash  := $SfxDash             as AudioStreamPlayer
@onready var sfx_coin  := $SfxCoin             as AudioStreamPlayer

# ── Movimento (Super Meat Boy feel) ──────────────────────────
const SPEED             = 700.0    # Velocidade máxima horizontal
const ACCELERATION      = 6000.0   # Aceleração no chão — rápida e responsiva
const AIR_ACCEL         = 4500.0   # Aceleração no ar — ainda responsivo
const FRICTION          = 8000.0   # Frenagem no chão — para instantâneo
const AIR_FRICTION      = 800.0    # Frenagem no ar — menor controle

# ── Pulo ─────────────────────────────────────────────────────
const JUMP_VELOCITY     = -880.0   # Pulo alto
const JUMP_CUT          = 0.25     # Pulo curto bem curto
const COYOTE_TIME       = 0.1
const JUMP_BUFFER_TIME  = 0.15     # Buffer generoso
const GRAVITY_UP        = 2200.0   # Gravidade subindo — sente pesado
const GRAVITY_DOWN      = 3800.0   # Gravidade descendo — cai rápido
const MAX_FALL_SPEED    = 1000.0

# ── Wall Slide / Wall Jump ────────────────────────────────────
const WALL_SLIDE_SPEED      = 80.0    # Desce devagar na parede
const WALL_JUMP_VY          = -880.0  # Força vertical do wall jump
const WALL_JUMP_VX          = 580.0   # Força horizontal — empurra forte
const WALL_JUMP_LOCK_TIME   = 0.18    # Trava o input horizontal brevemente

# ── Dash ─────────────────────────────────────────────────────
const DASH_SPEED     = 1100.0
const DASH_DURATION  = 0.18
const DASH_COOLDOWN  = 0.35
const DASH_FREEZE    = 0.04

# ── Estado interno ────────────────────────────────────────────
var coyote_timer:       float = 0.0
var jump_buffer:        float = 0.0
var was_on_floor:       bool  = false
var was_on_wall:        bool  = false

var is_dashing:         bool    = false
var dash_timer:         float   = 0.0
var dash_cooldown_t:    float   = 0.0
var dash_direction:     Vector2 = Vector2.ZERO
var can_dash:           bool    = true
var dash_freeze_timer:  float   = 0.0

var is_wall_sliding:    bool  = false
var wall_dir:           int   = 0

var wall_jump_lock:     float = 0.0  # Timer que trava input após wall jump

# ── Inicialização ────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")

# ── Loop principal ────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_update_dash_cooldown(delta)
	_handle_dash_input()

	if is_dashing:
		_process_dash(delta)
	else:
		_apply_gravity(delta)
		_update_wall_slide()
		_handle_jump(delta)
		_handle_movement(delta)

	_update_dash_refresh()
	_update_animation()
	was_on_floor = is_on_floor()
	was_on_wall  = is_on_wall()
	move_and_slide()

	# Reduz timer de wall jump lock
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta

# ── Wall Slide ────────────────────────────────────────────────
func _update_wall_slide() -> void:
	is_wall_sliding = false
	wall_dir = 0

	if is_on_floor() or not is_on_wall():
		return

	var normal    := get_wall_normal()
	var input_dir := Input.get_axis("ui_left", "ui_right")

	if normal.x > 0 and input_dir < 0:
		wall_dir = -1
		is_wall_sliding = true
	elif normal.x < 0 and input_dir > 0:
		wall_dir = 1
		is_wall_sliding = true

	if is_wall_sliding and velocity.y > 0:
		velocity.y = move_toward(velocity.y, WALL_SLIDE_SPEED, 3000.0 * get_physics_process_delta_time())

# ── Gravidade ─────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	# Gravidade extra ao soltar o pulo (feel de peso)
	var grav := GRAVITY_UP if velocity.y < 0 else GRAVITY_DOWN
	velocity.y = min(velocity.y + grav * delta, MAX_FALL_SPEED)

# ── Pulo + Wall Jump ──────────────────────────────────────────
func _handle_jump(delta: float) -> void:
	# Coyote time
	if was_on_floor or is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer -= delta

	# Wall jump — prioridade máxima
	if jump_buffer > 0.0 and is_wall_sliding:
		velocity.y      = WALL_JUMP_VY
		velocity.x      = -wall_dir * WALL_JUMP_VX
		coyote_timer    = 0.0
		jump_buffer     = 0.0
		is_wall_sliding = false
		wall_jump_lock  = WALL_JUMP_LOCK_TIME
		sfx_jump.play()
		return

	# Pulo normal
	if jump_buffer > 0.0 and coyote_timer > 0.0:
		velocity.y   = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer  = 0.0
		sfx_jump.play()

	# Pulo curto (soltar cedo = cai rápido)
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= JUMP_CUT

# ── Movimento horizontal ──────────────────────────────────────
func _handle_movement(delta: float) -> void:
	# Durante o wall jump lock, o input horizontal é ignorado brevemente
	# para dar sensação de ser "arremessado" da parede
	if wall_jump_lock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, AIR_FRICTION * 0.3 * delta)
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	var accel    := ACCELERATION if is_on_floor() else AIR_ACCEL
	var friction := FRICTION     if is_on_floor() else AIR_FRICTION

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

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
	# No chão: recarrega continuamente (dash repetido como Hollow Knight)
	# Na parede: recarrega só ao encostar
	if is_on_floor():
		can_dash = true
	elif is_on_wall() and not was_on_wall:
		can_dash = true

# ── Morte ─────────────────────────────────────────────────────
func die() -> void:
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	set_physics_process(false)
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()

# ── Coletável ─────────────────────────────────────────────────
func play_coin_sfx() -> void:
	sfx_coin.play()

# ── Animações ─────────────────────────────────────────────────
func _update_animation() -> void:
	if is_dashing:
		anim.play("dash")
		_apply_dash_visuals()
		return

	anim.rotation = 0.0
	anim.flip_v   = false

	if is_wall_sliding:
		anim.play("wallslide")
		anim.flip_h = wall_dir > 0
		return

	if not is_on_floor():
		anim.play("jump")
		_flip_to_velocity()
		return

	var direction := Input.get_axis("ui_left", "ui_right")
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
