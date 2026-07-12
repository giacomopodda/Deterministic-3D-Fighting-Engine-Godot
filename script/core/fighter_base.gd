class_name FighterBase
extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox_manager: HurtboxManager = $HurtboxManager
@onready var state_machine: Node = $StateMachine
@onready var inputs: InputReader = $InputReader 
@onready var input_reader: InputReader = $InputReader
@export var hit_effect: GPUParticles3D

var health_head: int = 100
var health_body: int = 100
var health_arms: int = 100
var health_legs: int = 100
var guard_health: int = 100
var guard_health_max: int = 100
var hitstop_frames: int = 0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func take_damage(
	_amount: int, 
	_hit_zone: String, 
	_hitstun_frames: int, 
	_reaction: String = "hit_stomach_light", 
	_knockback: float = 0.0, 
	_knockback_dir: Vector3 = Vector3.ZERO, 
	_blocked: bool = false, 
	_raw_knockback: float = 0.0, 
	_reaction_speed: float = 1.0,
	_block_stagger_frames: int = 10,     # <-- AGGIUNTO (10° argomento)
	_block_reaction_speed: float = 1.4,   # <-- AGGIUNTO (11° argomento)
	_hit_level: String = "mid",
	_block_knockback_force: float = 0.5,
	_causes_knockdown: bool = false,
	_causes_airborne: bool = false,
	_airborne_velocity: float = 8.0
) -> void:
	pass

func is_blocking(hit_level: String) -> bool:
	# Sicurezza: se la macchina a stati non esiste o non ha uno stato attivo, subisci danno
	if not state_machine or not state_machine.get("current_state"):
		return false
		
	var current_state_name: String = state_machine.current_state.name

	# --- PARATA NEUTRA DA FERMO (Stile Tekken) ---
	if current_state_name == "StateIdle" or current_state_name == "StateWalkBack":
		if hit_level == "high" or hit_level == "mid":
			return true 

	# --- PARATA BASSA AUTOMATICA ---
	if current_state_name == "StateDuck":
		if hit_level == "low":
			return true 
			
	return false
	
func play_anim(anim_name: String, blend: float = 0.1, speed: float = 1.0) -> void:
	var candidates := [
		anim_name,
		"attacks/" + anim_name,
		"reactions/" + anim_name,
		"blocks/" + anim_name,
		"locomotion/" + anim_name,
	]
	var target := ""
	for candidate in candidates:
		if anim_player.has_animation(candidate):
			target = candidate
			break
	if target == "":
		push_warning("play_anim: '%s' non trovata in nessuna libreria" % anim_name)
		return
	if anim_player.current_animation != target:
		anim_player.play(target, blend)
	anim_player.speed_scale = speed

func spawn_hit_effect(position: Vector3) -> void:
	if hit_effect:
		hit_effect.global_position = position
		hit_effect.restart()
		hit_effect.emitting = true
