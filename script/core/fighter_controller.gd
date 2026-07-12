class_name FighterController
extends FighterBase

const State = FighterEnums.State
const CHIP_DAMAGE_PERCENT: float = 0.10
const JUMP_GRAVITY_MULTIPLIER: float = 2.0
# ---------------------------------------------------------
# EXPORT
# ---------------------------------------------------------
@export var character_data: CharacterData
@export var opponent: Node3D
@export var screen_shake: ScreenShake

# ---------------------------------------------------------
# VARIABILI FISICHE (lette/scritte dagli stati)
# ---------------------------------------------------------
var jump_frame_counter: int = 0
var jump_trajectory: Vector3 = Vector3.ZERO
var jump_peak_reached: bool = false

# Velocità — valori di default, sovrascritti da CharacterData
var SPEED_FORWARD: float = 3.0
var SPEED_BACKWARD: float = 2.5
var JUMP_VELOCITY: float = 8.0
var JUMP_HORIZONTAL_SPEED: float = 3.0
var DASH_FORWARD_SPEED: float = 7.0
var BACKSTEP_SPEED: float = 6.0
var RUN_SPEED: float = 5.0

# ---------------------------------------------------------
# SALUTE LOCALIZZATA
# ---------------------------------------------------------
var can_run: bool = true
var is_limping: bool = false
var attack_power_mul: float = 1.0

# ---------------------------------------------------------
# DATI MOSSE
# ---------------------------------------------------------
var attack_data: Dictionary = {}

# ---------------------------------------------------------
# RIFERIMENTI NODI
# ---------------------------------------------------------
@onready var skeleton: Skeleton3D = $Armature/GeneralSkeleton
@onready var visual_mesh: Node3D = $Armature
@onready var hitbox_manager: HitboxManager = $HitboxManager

# ---------------------------------------------------------
# READY
# ---------------------------------------------------------
func _ready() -> void:
	state_machine.init(self, "StateIdle")
	
	_load_character_data()
	_connect_signals()
	hitbox_manager.init(hurtbox_manager)

func _load_character_data() -> void:
	if character_data == null:
		push_warning("FighterController: CharacterData non assegnato su " + name)
		return

	health_head  = character_data.health_head
	health_body  = character_data.health_body
	health_arms  = character_data.health_arms
	health_legs  = character_data.health_legs

	SPEED_FORWARD       = float(character_data.walk_forward_speed)
	SPEED_BACKWARD      = float(character_data.walk_back_speed)
	JUMP_VELOCITY       = float(character_data.jump_velocity)
	JUMP_HORIZONTAL_SPEED = float(character_data.jump_horizontal_speed)
	DASH_FORWARD_SPEED  = float(character_data.dash_speed)
	BACKSTEP_SPEED      = float(character_data.backstep_speed)
	RUN_SPEED           = float(character_data.run_speed)

	attack_data[State.ATTACK_1] = character_data.move_attack_1
	attack_data[State.ATTACK_2] = character_data.move_attack_2
	attack_data[State.ATTACK_3] = character_data.move_attack_3
	attack_data[State.ATTACK_4] = character_data.move_attack_4
	if character_data.move_attack_forward_1:
		attack_data[State.ATTACK_FORWARD_1] = character_data.move_attack_forward_1
	if character_data.move_attack_back_1:
		attack_data[State.ATTACK_BACK_1]    = character_data.move_attack_back_1
	if character_data.move_attack_low_1:
		attack_data[State.ATTACK_LOW_1]     = character_data.move_attack_low_1
	if character_data.move_attack_up_1:
		attack_data[State.ATTACK_UP_1]      = character_data.move_attack_up_1
	if character_data.move_attack_forward_2:
		attack_data[State.ATTACK_FORWARD_2] = character_data.move_attack_forward_2
	if character_data.move_attack_back_2:
		attack_data[State.ATTACK_BACK_2]    = character_data.move_attack_back_2
	if character_data.move_attack_low_2:
		attack_data[State.ATTACK_LOW_2]     = character_data.move_attack_low_2
	if character_data.move_attack_up_2:
		attack_data[State.ATTACK_UP_2]      = character_data.move_attack_up_2
	if character_data.move_attack_forward_3:
		attack_data[State.ATTACK_FORWARD_3] = character_data.move_attack_forward_3
	if character_data.move_attack_back_3:
		attack_data[State.ATTACK_BACK_3]    = character_data.move_attack_back_3
	if character_data.move_attack_low_3:
		attack_data[State.ATTACK_LOW_3]     = character_data.move_attack_low_3
	if character_data.move_attack_up_3:
		attack_data[State.ATTACK_UP_3]      = character_data.move_attack_up_3
	if character_data.move_attack_forward_4:
		attack_data[State.ATTACK_FORWARD_4] = character_data.move_attack_forward_4
	if character_data.move_attack_back_4:
		attack_data[State.ATTACK_BACK_4]    = character_data.move_attack_back_4
	if character_data.move_attack_low_4:
		attack_data[State.ATTACK_LOW_4]     = character_data.move_attack_low_4
	if character_data.move_attack_up_4:
		attack_data[State.ATTACK_UP_4]      = character_data.move_attack_up_4
	if character_data.move_attack_run_1:
		attack_data[State.ATTACK_RUN_1] = character_data.move_attack_run_1
	if character_data.move_attack_run_2:
		attack_data[State.ATTACK_RUN_2] = character_data.move_attack_run_2
	if character_data.move_attack_run_3:
		attack_data[State.ATTACK_RUN_3] = character_data.move_attack_run_3
	if character_data.move_attack_run_4:
		attack_data[State.ATTACK_RUN_4] = character_data.move_attack_run_4
func _connect_signals() -> void:
	# Controlliamo prima se il segnale è già stato collegato altrove
	if not hitbox_manager.hit_detected.is_connected(_on_hit_detected):
		hitbox_manager.hit_detected.connect(_on_hit_detected)

# ---------------------------------------------------------
# PHYSICS PROCESS — minimalista, delega tutto
# ---------------------------------------------------------
const MIN_DISTANCE: float = 0.7  # distanza minima tra i personaggi

func _physics_process(delta: float) -> void:
	# Pushback distanza minima
	if opponent != null:
		var diff := global_position - opponent.global_position
		diff.y = 0.0  # ignora asse verticale
		var dist := diff.length()
		if dist < MIN_DISTANCE and dist > 0.001:
			var push := diff.normalized() * (MIN_DISTANCE - dist) * 1.5
			velocity.x += push.x
			velocity.z += push.z
	# resto invariato
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return  # salta tutto il gameplay questo frame
	
	input_reader.update()
	if not is_on_floor():
		velocity.y -= gravity * JUMP_GRAVITY_MULTIPLIER * delta
	state_machine.process_physics(delta)
	move_and_slide()
	_update_rotation()

# ---------------------------------------------------------
# ROTAZIONE VERSO L'AVVERSARIO
# ---------------------------------------------------------
func _update_rotation() -> void:
	if opponent == null:
		return
	var sm := state_machine
	if sm.is_in_state("StateAttack") or sm.is_in_state("StateDashForward") \
		or sm.is_in_state("StateBackstep") or sm.is_in_state("StateRun") \
		or sm.is_in_state("StateJump") or sm.is_in_state("StateJumpForward") \
		or sm.is_in_state("StateJumpBackward"):
		return

	var dir := get_dir_to_opponent()
	if dir.length_squared() < 0.0001:
		return

	var look_target := Vector3(
		opponent.global_position.x,
		visual_mesh.global_position.y,
		opponent.global_position.z
	)
	visual_mesh.look_at(look_target, Vector3.UP)
	visual_mesh.rotate_y(deg_to_rad(180))

# ---------------------------------------------------------
# API PUBBLICA
# ---------------------------------------------------------
func get_dir_to_opponent() -> Vector3:
	if opponent == null:
		return Vector3.ZERO
	var d := opponent.global_position - global_position
	d.y = 0.0
	return d.normalized()

func is_aerial() -> bool:
	return state_machine.is_in_state("StateJump") \
		or state_machine.is_in_state("StateJumpForward") \
		or state_machine.is_in_state("StateJumpBackward")

# ---------------------------------------------------------
# RICEZIONE DANNO
# ---------------------------------------------------------
func _on_hit_detected(target_area: Area3D, move: MoveData) -> void:
	var defender := _find_fighter_from_area(target_area)
	if defender == null or defender == self:
		return
	var hit_zone: String = defender.hurtbox_manager.get_hit_zone_for_area(target_area)
	var hit_level: HurtboxManager.HitLevel = _move_hit_level_to_enum(move.hit_level)
	if not defender.hurtbox_manager.is_area_vulnerable_to(target_area, hit_level):
		return
	var damage: int = int(float(move.damage) * attack_power_mul)
	var knockback_dir: Vector3 = get_dir_to_opponent()
	var blocked: bool = defender.is_blocking(move.hit_level)
	
	defender.take_damage(
		damage, 
		hit_zone,                    # 2° Argomento: per la vita localizzata
		move.hit_stagger_frames, 
		move.reaction_anim, 
		move.knockback_force, 
		knockback_dir, 
		blocked, 
		move.knockback_force, 
		move.reaction_speed,
		move.block_stagger_frames, 
		move.block_reaction_speed,
		move.hit_level,              # 12° Argomento: per l'altezza del blocco
		move.block_knockback_force,
		move.causes_knockdown,
		move.causes_airborne,       
		move.airborne_velocity 
	)
	
	if not blocked:
		screen_shake.add_trauma(move.camera_trauma)
		# Hitstop sul gamestate
		hitstop_frames = move.camera_hitstop_frames
		defender.hitstop_frames = move.camera_hitstop_frames
		if move.camera_zoom_on_hit > 0.0:
			screen_shake.add_zoom(move.camera_zoom_on_hit, move.camera_zoom_duration)
		if move.camera_dramatic_angle > 0.0:
			screen_shake.add_dramatic_angle(move.camera_dramatic_angle, move.camera_dramatic_duration)
	else:
		screen_shake.add_trauma(move.camera_trauma * 0.3)
		# Hitstop visivo sulla camera (separato)
		screen_shake.add_hitstop(move.camera_hitstop_frames)
		
func _find_fighter_from_area(area: Area3D) -> FighterBase:
	var node: Node = area
	while node != null:
		if node is FighterBase:
			return node as FighterBase
		node = node.get_parent()
	return null

func _move_hit_level_to_enum(hit_level_str: String) -> HurtboxManager.HitLevel:
	match hit_level_str:
		"high":   return HurtboxManager.HitLevel.HIGH
		"mid":    return HurtboxManager.HitLevel.MID
		"low":    return HurtboxManager.HitLevel.LOW
		"aerial": return HurtboxManager.HitLevel.AERIAL
	return HurtboxManager.HitLevel.MID
	
func is_blocking(hit_level: String) -> bool:
	# Se il giocatore è in aria, non può parare nulla
	if is_aerial():
		return false
		
	# 1. Parata Attiva Bassa (Se il giocatore tiene giù ed è accovacciato)
	if hit_level == "low" and state_machine.is_in_state("StateDuck"):
		return true
		
	# 2. Parata Attiva Alta/Media (Se il giocatore preme attivamente "indietro")
	if input_reader.pressed("back") and (hit_level == "high" or hit_level == "mid"):
		return true
		
	# 3. Se non sta premendo indietro, usa la Parata Neutra automatica di FighterBase!
	return super.is_blocking(hit_level)

func take_damage(
	amount: int, 
	hit_zone: String, 
	hitstun_frames: int, 
	reaction: String = "hit_stomach_light", 
	knockback: float = 0.0, 
	knockback_dir: Vector3 = Vector3.ZERO, 
	blocked: bool = false, 
	raw_knockback: float = 0.0, 
	reaction_speed: float = 1.0,
	block_stagger_frames: int = 10,
	block_reaction_speed: float = 1.4,
	hit_level: String = "mid",
	block_knockback_force: float = 0.5,
	causes_knockdown: bool = false,
	causes_airborne: bool = false,
	airborne_velocity: float = 8.0
) -> void:
	var final_amount := amount
	var final_reaction := reaction
	var final_knockback := knockback
	var final_reaction_speed := reaction_speed
	
	if blocked:
		guard_health = max(0, guard_health - final_amount)
		final_amount = int(float(amount) * CHIP_DAMAGE_PERCENT)
		final_knockback = block_knockback_force
		final_reaction = _pick_block_anim(raw_knockback, hit_level)
		final_reaction_speed = block_reaction_speed
		_enter_hitstun(block_stagger_frames)
	else:
		match hit_zone:
			"head": health_head = max(0, health_head - final_amount)
			"body": health_body = max(0, health_body - final_amount)
			"arms": health_body = max(0, health_body - final_amount)
			"legs": health_legs = max(0, health_legs - final_amount)
		spawn_hit_effect(global_position)
		if causes_airborne:
			velocity.y = airborne_velocity
			state_machine.change_to("StateAirborne")
		elif causes_knockdown:
			_enter_knockdown()
		else:
			_enter_hitstun(hitstun_frames)
	
	if final_knockback > 0.0:
		velocity += knockback_dir * final_knockback
	
	play_anim(final_reaction, 0.05, final_reaction_speed)
	_log_health()

func _pick_block_anim(force: float, hit_level: String) -> String:
	var size := "big" if force > 3.0 else "light"
	match hit_level:
		"high": return "block_%s_high" % size
		"low": return "block_%s_low" % size
		_: return "block_%s_mid" % size

func _enter_hitstun(frames: int) -> void:
	var hit_stun_state: FighterState = state_machine.get_state("StateHitStun")
	if hit_stun_state and hit_stun_state.has_method("enter_with_stun"):
		hit_stun_state.enter_with_stun(frames)
	state_machine.change_to("StateHitStun")

func _update_leg_penalties() -> void:
	if character_data == null:
		return
	var pct: int = health_legs * 100 / character_data.health_legs
	if pct <= character_data.legs_no_run_threshold:
		can_run = false
		is_limping = true
	elif pct <= character_data.legs_limp_threshold:
		can_run = true
		is_limping = true
	elif pct <= character_data.legs_slow_threshold:
		can_run = true
		is_limping = false
	else:
		can_run = true
		is_limping = false

func _log_health() -> void:
	print("%s | head:%d body:%d arms:%d legs:%d" % [
		name, health_head, health_body, health_arms, health_legs
	])

func _enter_knockdown() -> void:
	state_machine.change_to("StateKnockedDown")

func _enter_airborne(_dir: Vector3, force: float) -> void:
	velocity.y = force
	state_machine.change_to("StateAirborne")
