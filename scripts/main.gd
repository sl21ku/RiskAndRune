extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const BoltScript := preload("res://scripts/bolt.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const ShrineScript := preload("res://scripts/gamble_shrine.gd")
const PortalScript := preload("res://scripts/stage_portal.gd")
const WeaponShopScript := preload("res://scripts/weapon_shop.gd")

enum GameMode { COMBAT, SLOT, SHOP, GAME_OVER, LENDER, GAME_CLEAR }
enum GambleGame { SLOT, BLACKJACK, POKER, ANGEL_RACE, DICE, WHEEL, HILO, PEARL, CRASH }
enum Stage { FIELD, CAVE, HEAVEN, HELL, FOREST, DESERT, OCEAN, SPACE }

var player
var total_coins_earned := 0
var coins := 0:
	set(val):
		if val > coins:
			total_coins_earned += (val - coins)
		coins = val
var wave := 1
var shrine
var camera: Camera2D
var weapon_shop
var arena_floor: TextureRect
var stage_title_label: Label
var shrine_label: Label
var weapon_shop_label: Label
var hud_label: Label
var message_label: Label
var slot_layer: CanvasLayer
var gamble_money_label: Label
var gamble_bet_label: Label
var decrease_bet_button: Button
var increase_bet_button: Button
var slot_tab_button: Button
var blackjack_tab_button: Button
var slot_machine_parent: Control
var blackjack_board_parent: Control
var poker_board_parent: Control
var race_board_parent: Control
var dice_board_parent: Control
var wheel_board_parent: Control
var hilo_board_parent: Control
var pearl_board_parent: Control
var crash_board_parent: Control

var _dealer_card_container: Control
var _player_card_container: Control
var _poker_card_container: Control
var _hilo_card_container: Control
var _dice1_rect: ColorRect
var _dice2_rect: ColorRect
var _race_track_container: Control
var _race_active: bool = false
var _race_positions: Array[float] = [10.0, 10.0, 10.0]
var _race_bet_choice: int = -1
var _race_winner: int = -1
var _poker_suits := ["♠", "♥", "♣", "♦"]
var _poker_current_hand: Array = []
var _poker_held_cards: Array[bool] = [false, false, false, false, false]
var _poker_deck: Array = []
var _poker_state: String = "DEAL"

var _wheel_anim_active: bool = false
var _wheel_steps_remaining: int = 0
var _wheel_current_idx: int = 0
var _wheel_target_idx: int = 0
var _wheel_step_delay: float = 0.05
var _wheel_step_timer: float = 0.0
var _wheel_payout: int = 0
var _wheel_multiplier: float = 0.0

var _pearl_oyster_container: Control
var _pearl_picked_idx: int = -1
var _pearl_layout: Array[String] = []
var _pearl_revealed: bool = false

var _crash_visual_container: Control
var _rocket_icon: Label
var _reel_containers: Array[Control] = []
var _stop_buttons: Array[Button] = []
var _lever_shaft: ColorRect
var _slot_textures: Array[Texture2D] = []
enum ReelState { IDLE, SPINNING, STOPPING }
var _reel_states := [ReelState.IDLE, ReelState.IDLE, ReelState.IDLE]
var _reel_speeds := [0.0, 0.0, 0.0]
var _reel_targets := [0, 0, 0]
var _reel_target_symbols := ["@", "@", "@"]
var _auto_stop_timers := [0.0, 0.0, 0.0]
var _slot_is_spinning := false
var _sfx_player: AudioStreamPlayer
var _sfx_cache: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _bgm_cache: Dictionary = {}
var _current_bgm_type: String = ""
var _bgm_tween: Tween
var _shake_intensity: float = 0.0
var _player_bullet_texture: Texture2D
var _enemy_bullet_texture: Texture2D
var _shake_duration: float = 0.0
var _casino_led_lights: Array = []
var _casino_led_timer: float = 0.0
var _casino_coins: Array = []
var slot_result_label: Label
var spin_button: Button
var blackjack_hand_label: Label
var dealer_hand_label: Label
var blackjack_result_label: Label
var deal_button: Button
var hit_button: Button
var stand_button: Button
var poker_hand_label: Label
var poker_result_label: Label
var poker_deal_button: Button
var race_track_label: Label
var race_result_label: Label
var angel_a_button: Button
var angel_b_button: Button
var angel_c_button: Button
var exit_button: Button

# Devil's Dice UI
var dice_label: Label
var dice_result_label: Label
var dice_roll_button: Button

# Forest Wheel UI
var wheel_label: Label
var wheel_result_label: Label
var wheel_spin_button: Button

# Desert Hi-Lo UI
var hilo_card_label: Label
var hilo_result_label: Label
var hilo_higher_button: Button
var hilo_lower_button: Button

# Pearl Oyster UI
var oyster_label: Label
var oyster_result_label: Label
var oyster_buttons: Array[Button] = []

# Cosmic Crash UI
var crash_multiplier_label: Label
var crash_result_label: Label
var crash_launch_button: Button
var crash_cashout_button: Button

# Cosmic Crash state
var _crash_active := false
var _crash_multiplier := 1.0
var _crash_point := 1.0

# Desert Hi-Lo state
var _hilo_current_card := 7
var game_over_layer: CanvasLayer
var game_over_stats_label: Label
var restart_button: Button
var shop_layer: CanvasLayer
var shop_money_label: Label
var shop_status_label: Label
var shop_buttons: Array[Button] = []
var shop_heal_button: Button
var shop_exit_button: Button
var enemies: Array[Node2D] = []
var portals: Array[Node2D] = []
var mode := GameMode.COMBAT
var gamble_game := GambleGame.SLOT
var current_stage := Stage.FIELD
var bet_amount := 5
var _stage_enemy_distributions := {
	Stage.FIELD: {
		"A": 0.70,
		"B": 0.20,
		"C": 0.10
	},
	Stage.CAVE: {
		"C": 0.40,
		"D": 0.30,
		"A": 0.20,
		"B": 0.10
	},
	Stage.HEAVEN: {
		"F": 0.40,
		"I": 0.30,
		"A": 0.20,
		"B": 0.10
	},
	Stage.HELL: {
		"H": 0.45,
		"G": 0.25,
		"E": 0.20,
		"J": 0.10
	},
	Stage.FOREST: {
		"A": 0.50,
		"B": 0.25,
		"D": 0.25
	},
	Stage.DESERT: {
		"E": 0.40,
		"I": 0.30,
		"C": 0.20,
		"B": 0.10
	},
	Stage.OCEAN: {
		"F": 0.40,
		"E": 0.30,
		"D": 0.20,
		"G": 0.10
	},
	Stage.SPACE: {
		"J": 0.40,
		"G": 0.30,
		"H": 0.20,
		"I": 0.10
	}
}
var _weapon_levels := {
	"targeter": 1,
	"blaster": 1,
	"splitter": 1,
	"repeater": 1,
	"nova": 1,
	"spore": 1,
	"mirage": 1,
	"wave": 1,
	"hellfire": 1,
	"halo": 1,
	"meteor": 1,
	"katana": 1,
	"boomerang": 1,
	"shockwave": 1,
	"bombardment": 1,
	"hyper_beam": 1,
}
var forge
var forge_label: Label
var forge_layer: CanvasLayer
var forge_money_label: Label
var forge_status_label: Label
var forge_buttons: Dictionary = {}
var forge_exit_button: Button

# HP Bar UI
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect
var hp_text_label: Label

var lender
var lender_label: Label
var lender_layer: CanvasLayer
var lender_money_label: Label
var lender_status_label: Label
var repay_button: Button
var lender_exit_button: Button

var _defeated_bosses := {
	Stage.FIELD: false,
	Stage.CAVE: false,
	Stage.FOREST: false,
	Stage.DESERT: false,
	Stage.HEAVEN: false,
	Stage.OCEAN: false,
	Stage.HELL: false,
	Stage.SPACE: false,
}

var _stage_textures := {
	Stage.FIELD: "res://assets/map_field.png",
	Stage.CAVE: "res://assets/map_cave.png",
	Stage.HEAVEN: "res://assets/map_heaven.png",
	Stage.HELL: "res://assets/map_hell.png",
	Stage.FOREST: "res://assets/map_forest.png",
	Stage.DESERT: "res://assets/map_desert.png",
	Stage.OCEAN: "res://assets/map_ocean.png",
	Stage.SPACE: "res://assets/map_space.png",
}

# Boss states
var boss_active := false
var boss_node: CharacterBody2D
var boss_health := 0
var boss_max_health := 100
var boss_title := ""

# Boss HP Bar UI
var boss_hp_bar_bg: ColorRect
var boss_hp_bar_fill: ColorRect
var boss_hp_label: Label

# Game Clear screen UI
var game_clear_layer: CanvasLayer
var game_clear_stats_label: Label
var game_clear_restart_button: Button

var _slot_symbols := ["@", "#", "$", "*", "!", "?"]
var _symbol_payout_multipliers := {
	"$": 15, # Coin / Gold
	"@": 10, # Player
	"?": 6,  # Tank Enemy
	"!": 4,  # Fast Enemy
	"#": 3,  # Common Slime
	"*": 2   # Portal
}
var _player_cards := []
var _dealer_cards := []
var _blackjack_active := false
var _poker_ranks := ["A", "K", "Q", "J", "10", "9", "8", "7", "6", "5", "4", "3", "2"]
var _poker_rank_values := {
	"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
	"J": 11, "Q": 12, "K": 13, "A": 14
}
var _race_runners := ["Seraph", "Halo", "Feather"]
var _owned_weapons := {
	"targeter": true,
	"blaster": false,
	"splitter": false,
	"nova": false,
	"repeater": false,
	"halo": false,
	"hellfire": false,
	"spore": false,
	"mirage": false,
	"wave": false,
	"meteor": false,
	"scythe": false,
	"drill": false,
	"lightning": false,
	"doom": false,
	"vine_whip": false,
	"sandstorm": false,
	"trident": false,
	"blackhole": false,
	"katana": false,
	"boomerang": false,
	"shockwave": false,
	"bombardment": false,
	"hyper_beam": false,
}
var _transition_cooldown := 0.0
var _weapon_catalog := [
	{"id": "blaster", "name": "BLASTER", "cost": 10, "description": "Fires forward where @ faces.", "stage": Stage.FIELD},
	{"id": "splitter", "name": "SPLITTER", "cost": 15, "description": "Adds two angled shots to Targeter.", "stage": Stage.FIELD},
	{"id": "repeater", "name": "REPEATER", "cost": 20, "description": "Doubles the Targeter shot.", "stage": Stage.FIELD},
	{"id": "nova", "name": "NOVA", "cost": 20, "description": "Bursts in eight directions.", "stage": Stage.CAVE},
	{"id": "katana", "name": "KATANA", "cost": 30, "description": "Slices in front, piercing enemies and slicing bullets.", "stage": Stage.CAVE},
	{"id": "spore", "name": "SPORE", "cost": 15, "description": "Fires diagonal spores on cooldown.", "stage": Stage.FOREST},
	{"id": "mirage", "name": "MIRAGE", "cost": 15, "description": "Fires side shots where @ faces.", "stage": Stage.DESERT},
	{"id": "boomerang", "name": "BOOMERANG", "cost": 35, "description": "Thrown forward, pierces and returns to you.", "stage": Stage.DESERT},
	{"id": "wave", "name": "WAVE", "cost": 20, "description": "Fires 3-way parallel waves forward.", "stage": Stage.OCEAN},
	{"id": "shockwave", "name": "SHOCKWAVE", "cost": 40, "description": "Releases an expanding ring that knocks enemies back.", "stage": Stage.OCEAN},
	{"id": "hellfire", "name": "HELLFIRE", "cost": 25, "description": "Fires powerful backward shots.", "stage": Stage.HELL},
	{"id": "bombardment", "name": "BOMBARDMENT", "cost": 45, "description": "Calls down target-locked heavy orbital strikes.", "stage": Stage.HELL},
	{"id": "halo", "name": "HALO", "cost": 25, "description": "Fires expanding holy rings.", "stage": Stage.HEAVEN},
	{"id": "meteor", "name": "METEOR", "cost": 30, "description": "Fires slow giant meteors.", "stage": Stage.SPACE},
	{"id": "hyper_beam", "name": "HYPER BEAM", "cost": 50, "description": "Channels a massive high-damage vertical beam.", "stage": Stage.SPACE},
]
var _nova_timer := 0.0
var _katana_timer := 0.0
var _spore_timer := 0.0
var _boomerang_timer := 0.0
var _meteor_timer := 0.0
var _halo_timer := 0.0
var _scythe_timer := 0.0
var _vine_whip_timer := 0.0
var _sandstorm_timer := 0.0
var _shockwave_timer := 0.0
var _lightning_timer := 0.0
var _doom_timer := 0.0
var _bombardment_timer := 0.0
var _blackhole_timer := 0.0
var _hyper_beam_timer := 0.0

func _ready() -> void:
	randomize()
	var raw_p_bullet = _load_texture("res://assets/sprite_bullet_player.png")
	_player_bullet_texture = _make_background_transparent(raw_p_bullet)
	var raw_e_bullet = _load_texture("res://assets/sprite_bullet_enemy.png")
	_enemy_bullet_texture = _make_background_transparent(raw_e_bullet)
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_preload_sfx()
	_bgm_player = AudioStreamPlayer.new()
	add_child(_bgm_player)
	_preload_bgm()
	_play_bgm("normal")
	_setup_camera()
	_create_arena()
	_create_player()
	_create_shrine()
	_create_weapon_shop()
	_create_forge()
	_create_lender()
	_apply_stage(Stage.FIELD)
	_create_hud()
	_create_slot_ui()
	_create_shop_ui()
	_create_forge_ui()
	_create_lender_ui()
	_create_game_over_ui()
	_create_game_clear_ui()
	_spawn_wave()
	_update_hud("DRAG to move. Shots fire automatically.")

func _process(delta: float) -> void:
	if _transition_cooldown > 0.0:
		_transition_cooldown -= delta
	if not is_instance_valid(player):
		return
	_update_camera(delta)
	if mode == GameMode.SLOT:
		_process_crash_game(delta)
		_process_slot_machine(delta)
		_process_angel_race(delta)
		_process_forest_wheel(delta)
		_update_casino_leds(delta)
		_process_casino_coins(delta)
		return
	if mode != GameMode.COMBAT:
		return
	var nearest := _nearest_enemy()
	player.set_nearest_enemy(nearest)
	_update_owned_weapon_attacks(delta)
	if player.health <= 0:
		_show_game_over()
	
	if is_instance_valid(message_label):
		_update_hud(message_label.text)

func _process_slot_machine(delta: float) -> void:
	if not _slot_is_spinning:
		return
	
	var all_idle := true
	for i in range(3):
		if _reel_states[i] == ReelState.SPINNING:
			all_idle = false
			_auto_stop_timers[i] -= delta
			if _auto_stop_timers[i] <= 0.0:
				_stop_reel(i)
			else:
				_reel_containers[i].position.y += _reel_speeds[i] * delta
				if _reel_containers[i].position.y > 50.0:
					_reel_containers[i].position.y -= 600.0
		elif _reel_states[i] == ReelState.STOPPING:
			all_idle = false
			var target_y: float = 150.0 - (float(_reel_targets[i] + 1) * 100.0)
			var current_y: float = _reel_containers[i].position.y
			
			while current_y - target_y > 300.0:
				current_y -= 600.0
			while current_y - target_y < -300.0:
				current_y += 600.0
			_reel_containers[i].position.y = current_y
			
			_reel_containers[i].position.y = move_toward(current_y, target_y, _reel_speeds[i] * delta)
			_reel_speeds[i] = move_toward(_reel_speeds[i], 180.0, 1000.0 * delta)
			
			if abs(_reel_containers[i].position.y - target_y) < 2.0:
				_reel_containers[i].position.y = target_y
				_reel_states[i] = ReelState.IDLE
		else:
			pass

	if all_idle and _slot_is_spinning:
		_slot_is_spinning = false
		_calculate_slot_result()

func _calculate_slot_result() -> void:
	var sprite_indices := [5, 0, 1, 2, 3, 4, 5, 0, 1, 2]
	var grid: Array[Array] = [
		["", "", ""],
		["", "", ""],
		["", "", ""]
	]
	
	for i in range(3):
		var target: int = _reel_targets[i]
		var idx_top: int = sprite_indices[target]
		var idx_mid: int = sprite_indices[target + 1]
		var idx_bot: int = sprite_indices[target + 2]
		
		grid[0][i] = _slot_symbols[idx_top]
		grid[1][i] = _slot_symbols[idx_mid]
		grid[2][i] = _slot_symbols[idx_bot]
		
	var lines := [
		# Horizontal
		{"name": "Top Row", "symbols": [grid[0][0], grid[0][1], grid[0][2]]},
		{"name": "Middle Row", "symbols": [grid[1][0], grid[1][1], grid[1][2]]},
		{"name": "Bottom Row", "symbols": [grid[2][0], grid[2][1], grid[2][2]]},
		# Vertical
		{"name": "Left Reel", "symbols": [grid[0][0], grid[1][0], grid[2][0]]},
		{"name": "Center Reel", "symbols": [grid[0][1], grid[1][1], grid[2][1]]},
		{"name": "Right Reel", "symbols": [grid[0][2], grid[1][2], grid[2][2]]},
		# Diagonal
		{"name": "Diagonal Down", "symbols": [grid[0][0], grid[1][1], grid[2][2]]},
		{"name": "Diagonal Up", "symbols": [grid[0][2], grid[1][1], grid[2][0]]}
	]
	
	var total_payout := 0
	var winning_details: Array[String] = []
	
	for line in lines:
		var syms: Array = line["symbols"]
		if syms[0] == syms[1] and syms[1] == syms[2]:
			var matched_symbol: String = syms[0]
			var multiplier: int = _symbol_payout_multipliers.get(matched_symbol, 2)
			var line_payout := bet_amount * multiplier
			total_payout += line_payout
			
			var sym_name := matched_symbol
			match matched_symbol:
				"$": sym_name = "💰Coin"
				"@": sym_name = "🛡️Player"
				"?": sym_name = "🐲Tank"
				"!": sym_name = "🦇Fast"
				"#": sym_name = "🟢Slime"
				"*": sym_name = "🌀Portal"
			
			winning_details.append(line["name"] + " (" + sym_name + " x" + str(multiplier) + ")")
			
	if total_payout > 0:
		coins += total_payout
		var detail_text := ""
		for k in range(winning_details.size()):
			if k > 0:
				detail_text += ", "
			detail_text += winning_details[k]
		slot_result_label.text = "WIN! " + str(winning_details.size()) + " lines matched: " + detail_text + ". Total +" + str(total_payout) + " run coins."
		_play_sfx("win")
		_trigger_coin_shower()
		_bounce_label(slot_result_label)
	else:
		slot_result_label.text = "No match. The dungeon takes its cut."
		_play_sfx("lose")
	
	_set_slot_buttons_disabled(false)
	_refresh_gamble_ui()
	_update_hud("Slot room. Coins change here only.")

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(0, 0)
	camera.zoom = Vector2(1.2, 1.2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = -1500
	camera.limit_right = 1500
	camera.limit_top = -1500
	camera.limit_bottom = 1500
	add_child(camera)
	camera.make_current()

func _update_camera(delta: float) -> void:
	camera.global_position = player.global_position
	
	if _shake_duration > 0.0:
		_shake_duration -= delta
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		camera.offset = offset
		if _shake_duration <= 0.0:
			camera.offset = Vector2.ZERO

func _create_arena() -> void:
	arena_floor = TextureRect.new()
	arena_floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arena_floor.stretch_mode = TextureRect.STRETCH_TILE
	arena_floor.position = Vector2(-1500, -1500)
	arena_floor.size = Vector2(3000, 3000)
	arena_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_floor)

	stage_title_label = Label.new()
	stage_title_label.text = "# markdown_rogue"
	stage_title_label.position = Vector2(-500, -900)
	stage_title_label.add_theme_font_size_override("font_size", 36)
	add_child(stage_title_label)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.set_script(PlayerScript)
	player.global_position = Vector2(0, 360)
	add_child(player)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28
	shape.shape = circle
	player.add_child(shape)

	var sprite := Sprite2D.new()
	var raw_tex = _load_texture("res://assets/sprite_player.png")
	var transparent_tex = _make_background_transparent(raw_tex)
	if is_instance_valid(transparent_tex):
		sprite.texture = transparent_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_size := 64.0
		sprite.scale = Vector2(target_size / transparent_tex.get_width(), target_size / transparent_tex.get_height())
		player.add_child(sprite)

	player.shot_requested.connect(_spawn_bolt)
	player.forward_shot_requested.connect(_spawn_forward_bolt)
	player.damaged.connect(_on_player_damaged)

func _on_player_damaged(_amount: int) -> void:
	_shake_intensity = 15.0
	_shake_duration = 0.22

func _create_shrine() -> void:
	shrine = Area2D.new()
	shrine.name = "GambleShrine"
	shrine.set_script(ShrineScript)
	shrine.global_position = Vector2(0, -300)
	add_child(shrine)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82
	shape.shape = circle
	shrine.add_child(shape)

	shrine_label = Label.new()
	shrine_label.text = "$\nBET"
	shrine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shrine_label.position = Vector2(-56, -58)
	shrine_label.size = Vector2(112, 100)
	shrine_label.add_theme_font_size_override("font_size", 34)
	shrine.add_child(shrine_label)

	shrine.body_entered.connect(shrine._on_body_entered)
	shrine.body_exited.connect(shrine._on_body_exited)
	shrine.entered.connect(_enter_slot_area)
	shrine.focus_changed.connect(_on_shrine_focus_changed)

func _create_weapon_shop() -> void:
	weapon_shop = Area2D.new()
	weapon_shop.name = "WeaponShop"
	weapon_shop.set_script(WeaponShopScript)
	weapon_shop.global_position = Vector2(-360, 160)
	add_child(weapon_shop)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82
	shape.shape = circle
	weapon_shop.add_child(shape)

	weapon_shop_label = Label.new()
	weapon_shop_label.text = "$\nSHOP"
	weapon_shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_shop_label.position = Vector2(-60, -58)
	weapon_shop_label.size = Vector2(120, 100)
	weapon_shop_label.add_theme_font_size_override("font_size", 32)
	weapon_shop.add_child(weapon_shop_label)

	weapon_shop.body_entered.connect(weapon_shop._on_body_entered)
	weapon_shop.body_exited.connect(weapon_shop._on_body_exited)
	weapon_shop.entered.connect(_enter_weapon_shop)
	weapon_shop.focus_changed.connect(_on_weapon_shop_focus_changed)

func _apply_stage(next_stage: int) -> void:
	current_stage = next_stage
	_clear_portals()
	
	if _stage_textures.has(next_stage):
		arena_floor.texture = load(_stage_textures[next_stage])
	
	# Force refresh physics monitoring state after teleportation to avoid sync lag
	weapon_shop.monitoring = false
	weapon_shop.call_deferred("set_monitoring", true)
	shrine.monitoring = false
	shrine.call_deferred("set_monitoring", true)
	if is_instance_valid(forge):
		forge.monitoring = false
		forge.visible = false
	if is_instance_valid(lender):
		lender.monitoring = false
		if _defeated_bosses.get(next_stage, false):
			lender.visible = false
		else:
			lender.call_deferred("set_monitoring", true)
			lender.visible = true
			lender.global_position = Vector2(0, 520)
	
	# Enable weapon shop by default for all stages
	weapon_shop.visible = true
	weapon_shop.global_position = Vector2(-360, 160)
	
	if current_stage == Stage.FIELD:
		stage_title_label.text = "# field.md"
		shrine_label.text = "$\nSLOT"
		shrine.global_position = Vector2(0, -300)
		_create_stage_portal("CAVE >", Vector2(-330, -650), Stage.CAVE)
		_create_stage_portal("VINE ^", Vector2(330, -650), Stage.HEAVEN)
		_create_stage_portal("FOREST >", Vector2(-330, 650), Stage.FOREST)
	elif current_stage == Stage.CAVE:
		stage_title_label.text = "# cave.md"
		shrine_label.text = "$\nPOKER"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("< FIELD", Vector2(-330, -650), Stage.FIELD)
		_create_stage_portal("VINE ^", Vector2(330, -650), Stage.HEAVEN)
		_create_stage_portal("DESERT >", Vector2(-330, 650), Stage.DESERT)
		if is_instance_valid(forge):
			forge.visible = true
			forge.global_position = Vector2(360, 160)
			forge.call_deferred("set_monitoring", true)
	elif current_stage == Stage.HEAVEN:
		stage_title_label.text = "# heaven.md"
		shrine_label.text = "$\nRACE"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("DESCEND", Vector2(0, -650), Stage.FIELD)
	elif current_stage == Stage.HELL:
		stage_title_label.text = "# hell.md"
		shrine_label.text = "$\nDICE"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("ASCEND", Vector2(330, 650), Stage.CAVE)
		_create_stage_portal("VOID *", Vector2(330, -650), Stage.SPACE)
	elif current_stage == Stage.FOREST:
		stage_title_label.text = "# forest.md"
		shrine_label.text = "$\nWHEEL"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("< FIELD", Vector2(-330, -650), Stage.FIELD)
		_create_stage_portal("DUNES >", Vector2(330, 650), Stage.DESERT)
		if is_instance_valid(forge):
			forge.visible = true
			forge.global_position = Vector2(360, 160)
			forge.call_deferred("set_monitoring", true)
	elif current_stage == Stage.DESERT:
		stage_title_label.text = "# desert.md"
		shrine_label.text = "$\nHILO"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("< FOREST", Vector2(-330, -650), Stage.FOREST)
		_create_stage_portal("POND ~", Vector2(330, 650), Stage.OCEAN)
		if is_instance_valid(forge):
			forge.visible = true
			forge.global_position = Vector2(360, 160)
			forge.call_deferred("set_monitoring", true)
	elif current_stage == Stage.OCEAN:
		stage_title_label.text = "# ocean.md"
		shrine_label.text = "$\nPEARL"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("< DESERT", Vector2(-330, -650), Stage.DESERT)
	elif current_stage == Stage.SPACE:
		stage_title_label.text = "# space.md"
		shrine_label.text = "$\nCRASH"
		shrine.global_position = Vector2(0, -330)
		_create_stage_portal("< FIELD", Vector2(-330, -650), Stage.FIELD)
		_create_stage_portal("BLACK HOLE", Vector2(0, 650), Stage.HELL)

func _create_stage_portal(text: String, position: Vector2, destination: int) -> void:
	var portal := Area2D.new()
	portal.name = "StagePortal"
	portal.set_script(PortalScript)
	portal.setup(destination)
	portal.global_position = position
	add_child(portal)
	portals.append(portal)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 76
	shape.shape = circle
	portal.add_child(shape)

	var sprite := Sprite2D.new()
	var texture_path := "res://assets/sprite_portal_field.png"
	match destination:
		Stage.FIELD:
			texture_path = "res://assets/sprite_portal_field.png"
		Stage.CAVE:
			texture_path = "res://assets/sprite_portal_cave.png"
		Stage.HEAVEN:
			texture_path = "res://assets/sprite_portal_heaven.png"
		Stage.HELL:
			texture_path = "res://assets/sprite_portal_hell.png"
		Stage.FOREST:
			texture_path = "res://assets/sprite_portal_forest.png"
		Stage.DESERT:
			texture_path = "res://assets/sprite_portal_desert.png"
		Stage.OCEAN:
			texture_path = "res://assets/sprite_portal_ocean.png"
		Stage.SPACE:
			texture_path = "res://assets/sprite_portal_space.png"
	var raw_tex = _load_texture(texture_path)
	var transparent_tex = _make_background_transparent(raw_tex)
	if is_instance_valid(transparent_tex):
		sprite.texture = transparent_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_size := 120.0
		sprite.scale = Vector2(target_size / transparent_tex.get_width(), target_size / transparent_tex.get_height())
	portal.add_child(sprite)

	portal.body_entered.connect(portal._on_body_entered)
	portal.entered.connect(_change_stage)

func _spawn_trigger_portal(text: String, position: Vector2, destination: int) -> void:
	for p in portals:
		if is_instance_valid(p) and p.destination_stage == destination:
			return
	_create_stage_portal(text, position, destination)

func _clear_portals() -> void:
	for portal in portals:
		if is_instance_valid(portal):
			portal.queue_free()
	portals.clear()

func _change_stage(destination: int) -> void:
	if mode != GameMode.COMBAT or destination == current_stage or _transition_cooldown > 0.0:
		return
	_transition_cooldown = 0.4
	call_deferred("_deferred_change_stage", destination)

func _deferred_change_stage(destination: int) -> void:
	if destination == current_stage:
		return
	_clear_run_nodes()
	if is_instance_valid(player):
		player.global_position = Vector2(0, 320)
		player.velocity = Vector2.ZERO
		camera.global_position = player.global_position
		camera.reset_smoothing()
	_apply_stage(destination)
	_spawn_wave()
	_update_hud("Entered " + _stage_name(current_stage) + ".")

func _stage_name(stage: int) -> String:
	if stage == Stage.CAVE:
		return "CAVE"
	if stage == Stage.HEAVEN:
		return "HEAVEN"
	if stage == Stage.HELL:
		return "HELL"
	if stage == Stage.FOREST:
		return "FOREST"
	if stage == Stage.DESERT:
		return "DESERT"
	if stage == Stage.OCEAN:
		return "OCEAN"
	if stage == Stage.SPACE:
		return "SPACE"
	return "FIELD"

func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud_label = Label.new()
	hud_label.position = Vector2(24, 24)
	hud_label.add_theme_font_size_override("font_size", 28)
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud_label)

	# HP Bar Background (Dark Red)
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.color = Color(0.3, 0.05, 0.05)
	hp_bar_bg.position = Vector2(24, 76)
	hp_bar_bg.size = Vector2(240, 24)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hp_bar_bg)

	# HP Bar Fill (Vibrant Green)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color(0.15, 0.75, 0.25)
	hp_bar_fill.position = Vector2(24, 76)
	hp_bar_fill.size = Vector2(240, 24)
	hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hp_bar_fill)

	# HP Text Label
	hp_text_label = Label.new()
	hp_text_label.position = Vector2(280, 72)
	hp_text_label.add_theme_font_size_override("font_size", 24)
	hp_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hp_text_label)

	# --- Boss HP Bar (Hidden by default) ---
	boss_hp_bar_bg = ColorRect.new()
	boss_hp_bar_bg.color = Color(0.2, 0.0, 0.0, 0.8)
	boss_hp_bar_bg.position = Vector2(140, 180)
	boss_hp_bar_bg.size = Vector2(440, 28)
	boss_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar_bg.visible = false
	canvas.add_child(boss_hp_bar_bg)

	boss_hp_bar_fill = ColorRect.new()
	boss_hp_bar_fill.color = Color(0.85, 0.1, 0.1) # Bold Red for Boss
	boss_hp_bar_fill.position = Vector2(140, 180)
	boss_hp_bar_fill.size = Vector2(440, 28)
	boss_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar_fill.visible = false
	canvas.add_child(boss_hp_bar_fill)

	boss_hp_label = Label.new()
	boss_hp_label.position = Vector2(140, 145)
	boss_hp_label.size = Vector2(440, 30)
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.add_theme_font_size_override("font_size", 20)
	boss_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_label.visible = false
	canvas.add_child(boss_hp_label)

	message_label = Label.new()
	message_label.position = Vector2(24, 220)
	message_label.size = Vector2(680, 120)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(message_label)

func _create_slot_ui() -> void:
	slot_layer = CanvasLayer.new()
	slot_layer.visible = false
	add_child(slot_layer)

	var background := ColorRect.new()
	background.color = Color(0.04, 0.22, 0.12, 0.96)
	background.size = Vector2(720, 1280)
	background.position = Vector2(0, 0)
	slot_layer.add_child(background)
	
	var felt_glow := ColorRect.new()
	felt_glow.color = Color(0.0, 0.05, 0.02, 0.4)
	felt_glow.size = Vector2(720, 1280)
	slot_layer.add_child(felt_glow)
	
	var outer_frame := ReferenceRect.new()
	outer_frame.size = Vector2(680, 1240)
	outer_frame.position = Vector2(20, 20)
	slot_layer.add_child(outer_frame)
	_add_border(outer_frame, Vector2(680, 1240), Color(0.9, 0.75, 0.1), 8.0)
	
	var inner_frame := ReferenceRect.new()
	inner_frame.size = Vector2(664, 1224)
	inner_frame.position = Vector2(28, 28)
	slot_layer.add_child(inner_frame)
	_add_border(inner_frame, Vector2(664, 1224), Color(0.7, 0.55, 0.06), 2.0)
	
	_casino_led_lights.clear()
	var color_pool := [Color(1,0.2,0.2), Color(1,0.9,0.1), Color(0.2,0.9,0.4), Color(0.2,0.6,1)]
	
	for x in range(35, 685, 45):
		var led_t := Polygon2D.new()
		led_t.polygon = [Vector2(0,-4), Vector2(4,0), Vector2(0,4), Vector2(-4,0)]
		led_t.position = Vector2(x, 24)
		led_t.color = color_pool[x % color_pool.size()]
		slot_layer.add_child(led_t)
		_casino_led_lights.append(led_t)
		
		var led_b := Polygon2D.new()
		led_b.polygon = led_t.polygon
		led_b.position = Vector2(x, 1256)
		led_b.color = color_pool[(x + 1) % color_pool.size()]
		slot_layer.add_child(led_b)
		_casino_led_lights.append(led_b)
		
	for y in range(50, 1230, 45):
		var led_l := Polygon2D.new()
		led_l.polygon = [Vector2(0,-4), Vector2(4,0), Vector2(0,4), Vector2(-4,0)]
		led_l.position = Vector2(24, y)
		led_l.color = color_pool[y % color_pool.size()]
		slot_layer.add_child(led_l)
		_casino_led_lights.append(led_l)
		
		var led_r := Polygon2D.new()
		led_r.polygon = led_l.polygon
		led_r.position = Vector2(696, y)
		led_r.color = color_pool[(y + 1) % color_pool.size()]
		slot_layer.add_child(led_r)
		_casino_led_lights.append(led_r)

	var title := Label.new()
	title.text = "## GAMBLE ROOM"
	title.position = Vector2(50, 50)
	title.add_theme_font_size_override("font_size", 32)
	slot_layer.add_child(title)

	gamble_money_label = Label.new()
	gamble_money_label.position = Vector2(50, 110)
	gamble_money_label.size = Vector2(280, 42)
	gamble_money_label.add_theme_font_size_override("font_size", 25)
	slot_layer.add_child(gamble_money_label)

	decrease_bet_button = Button.new()
	decrease_bet_button.text = "-"
	decrease_bet_button.position = Vector2(350, 100)
	decrease_bet_button.size = Vector2(62, 54)
	decrease_bet_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(decrease_bet_button)
	decrease_bet_button.pressed.connect(func(): _change_bet(-5))

	gamble_bet_label = Label.new()
	gamble_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gamble_bet_label.position = Vector2(420, 108)
	gamble_bet_label.size = Vector2(170, 38)
	gamble_bet_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(gamble_bet_label)

	increase_bet_button = Button.new()
	increase_bet_button.text = "+"
	increase_bet_button.position = Vector2(600, 100)
	increase_bet_button.size = Vector2(62, 54)
	increase_bet_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(increase_bet_button)
	increase_bet_button.pressed.connect(func(): _change_bet(5))

	slot_tab_button = Button.new()
	slot_tab_button.text = "SLOT"
	slot_tab_button.position = Vector2(50, 180)
	slot_tab_button.size = Vector2(290, 58)
	slot_tab_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(slot_tab_button)
	slot_tab_button.pressed.connect(func(): _set_gamble_game(GambleGame.SLOT))

	blackjack_tab_button = Button.new()
	blackjack_tab_button.text = "BLACKJACK"
	blackjack_tab_button.position = Vector2(380, 180)
	blackjack_tab_button.size = Vector2(290, 58)
	blackjack_tab_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(blackjack_tab_button)
	blackjack_tab_button.pressed.connect(func(): _set_gamble_game(GambleGame.BLACKJACK))

	slot_machine_parent = Control.new()
	slot_machine_parent.position = Vector2(50, 250)
	slot_machine_parent.size = Vector2(620, 440)
	slot_machine_parent.visible = false
	slot_layer.add_child(slot_machine_parent)

	var frame: Control
	if FileAccess.file_exists("res://assets/sprite_slot_housing.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_slot_housing.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.18, 0.12, 0.08)
		frame = col_rect
	
	frame.size = Vector2(500, 440)
	frame.position = Vector2(0, 0)
	slot_machine_parent.add_child(frame)
	if not (frame is TextureRect):
		_add_border(frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	_reel_containers.clear()
	_stop_buttons.clear()

	if _slot_textures.is_empty():
		_slot_textures.append(_make_background_transparent(_load_texture("res://assets/sprite_player.png")))
		_slot_textures.append(_make_background_transparent(_load_texture("res://assets/sprite_enemy_common.png")))
		var coin_img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		coin_img.fill(Color(1, 1, 1, 1))
		for cy in range(64):
			for cx in range(64):
				var dx := cx - 32
				var dy := cy - 32
				if dx*dx + dy*dy <= 24*24:
					coin_img.set_pixel(cx, cy, Color(0.95, 0.75, 0.15, 1.0))
					if dx*dx + dy*dy >= 21*21:
						coin_img.set_pixel(cx, cy, Color(0.8, 0.6, 0.1, 1.0))
		_slot_textures.append(_make_background_transparent(ImageTexture.create_from_image(coin_img)))
		_slot_textures.append(_make_background_transparent(_load_texture("res://assets/sprite_portal_field.png")))
		_slot_textures.append(_make_background_transparent(_load_texture("res://assets/sprite_enemy_fast.png")))
		_slot_textures.append(_make_background_transparent(_load_texture("res://assets/sprite_enemy_tank.png")))

	for i in range(3):
		var view := Control.new()
		view.size = Vector2(110, 300)
		view.position = Vector2(35 + i * 150, 30)
		view.clip_contents = true
		slot_machine_parent.add_child(view)

		var r_bg := ColorRect.new()
		r_bg.color = Color(0.08, 0.08, 0.08)
		r_bg.size = Vector2(110, 300)
		r_bg.position = Vector2(0, 0)
		view.add_child(r_bg)
		_add_border(r_bg, Vector2(110, 300), Color(0.4, 0.4, 0.4), 2.0)

		var container := Control.new()
		container.size = Vector2(110, 1000)
		container.position = Vector2(0, 150.0 - (5.0 + 1.0) * 100.0)
		view.add_child(container)
		_reel_containers.append(container)

		var sprite_indices := [5, 0, 1, 2, 3, 4, 5, 0, 1, 2]
		for j in range(10):
			var sym_idx = sprite_indices[j]
			var sprite := Sprite2D.new()
			sprite.texture = _slot_textures[sym_idx]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(70.0 / sprite.texture.get_width(), 70.0 / sprite.texture.get_height())
			sprite.position = Vector2(55, j * 100)
			container.add_child(sprite)

		var stop_btn := Button.new()
		stop_btn.text = "STOP"
		stop_btn.position = Vector2(35 + i * 150, 350)
		stop_btn.size = Vector2(110, 50)
		stop_btn.disabled = true
		stop_btn.add_theme_font_size_override("font_size", 18)
		if FileAccess.file_exists("res://assets/sprite_slot_stop_btn.png"):
			var normal_tex = load("res://assets/sprite_slot_stop_btn.png")
			var style_normal = StyleBoxTexture.new()
			style_normal.texture = normal_tex
			stop_btn.add_theme_stylebox_override("normal", style_normal)
			stop_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		slot_machine_parent.add_child(stop_btn)
		_stop_buttons.append(stop_btn)
		stop_btn.pressed.connect(func(): _stop_reel(i))

	var lever_base := ColorRect.new()
	lever_base.color = Color(0.3, 0.3, 0.3)
	lever_base.size = Vector2(24, 60)
	lever_base.position = Vector2(500, 185)
	slot_machine_parent.add_child(lever_base)

	if FileAccess.file_exists("res://assets/sprite_slot_lever_shaft.png"):
		_lever_shaft = ColorRect.new()
		_lever_shaft.color = Color(0, 0, 0, 0)
		_lever_shaft.size = Vector2(6, 70)
		_lever_shaft.position = Vector2(509, 135)
		_lever_shaft.pivot_offset = Vector2(3, 70)
		slot_machine_parent.add_child(_lever_shaft)
		
		var spr := Sprite2D.new()
		spr.texture = load("res://assets/sprite_slot_lever_shaft.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		spr.scale = Vector2(6.0 / spr.texture.get_width(), 70.0 / spr.texture.get_height())
		_lever_shaft.add_child(spr)
	else:
		_lever_shaft = ColorRect.new()
		_lever_shaft.color = Color(0.6, 0.6, 0.6)
		_lever_shaft.size = Vector2(6, 70)
		_lever_shaft.position = Vector2(509, 135)
		_lever_shaft.pivot_offset = Vector2(3, 70)
		slot_machine_parent.add_child(_lever_shaft)

	if FileAccess.file_exists("res://assets/sprite_slot_lever_knob.png"):
		var spr := Sprite2D.new()
		spr.texture = load("res://assets/sprite_slot_lever_knob.png")
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		spr.scale = Vector2(22.0 / spr.texture.get_width(), 22.0 / spr.texture.get_height())
		spr.position = Vector2(-8, -15)
		_lever_shaft.add_child(spr)
	else:
		var lever_knob := ColorRect.new()
		lever_knob.color = Color(0.85, 0.15, 0.15)
		lever_knob.size = Vector2(22, 22)
		lever_knob.position = Vector2(-8, -15)
		_lever_shaft.add_child(lever_knob)

	var lever_btn := TextureButton.new()
	lever_btn.size = Vector2(60, 140)
	lever_btn.position = Vector2(490, 115)
	slot_machine_parent.add_child(lever_btn)
	lever_btn.pressed.connect(_spin_slot)

	slot_result_label = Label.new()
	slot_result_label.text = "Bet 5 run coins. Match symbols to win."
	slot_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot_result_label.position = Vector2(50, 710)
	slot_result_label.size = Vector2(620, 60)
	slot_result_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(slot_result_label)

	spin_button = Button.new()
	spin_button.text = "SPIN"
	spin_button.position = Vector2(130, 790)
	spin_button.size = Vector2(460, 70)
	spin_button.add_theme_font_size_override("font_size", 30)
	slot_layer.add_child(spin_button)
	spin_button.pressed.connect(_spin_slot)

	blackjack_board_parent = Control.new()
	blackjack_board_parent.position = Vector2(50, 250)
	blackjack_board_parent.size = Vector2(620, 440)
	blackjack_board_parent.visible = false
	slot_layer.add_child(blackjack_board_parent)

	var bj_frame: Control
	if FileAccess.file_exists("res://assets/sprite_blackjack_table.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_blackjack_table.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bj_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.05, 0.22, 0.12, 0.94) # Deep Casino Felt Green
		bj_frame = col_rect
	
	bj_frame.size = Vector2(500, 440)
	bj_frame.position = Vector2(0, 0)
	blackjack_board_parent.add_child(bj_frame)
	if not (bj_frame is TextureRect):
		_add_border(bj_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	dealer_hand_label = Label.new()
	dealer_hand_label.position = Vector2(30, 20)
	dealer_hand_label.size = Vector2(440, 30)
	dealer_hand_label.add_theme_font_size_override("font_size", 20)
	blackjack_board_parent.add_child(dealer_hand_label)

	_dealer_card_container = Control.new()
	_dealer_card_container.position = Vector2(30, 55)
	_dealer_card_container.size = Vector2(440, 90)
	blackjack_board_parent.add_child(_dealer_card_container)

	blackjack_hand_label = Label.new()
	blackjack_hand_label.position = Vector2(30, 155)
	blackjack_hand_label.size = Vector2(440, 30)
	blackjack_hand_label.add_theme_font_size_override("font_size", 20)
	blackjack_board_parent.add_child(blackjack_hand_label)

	_player_card_container = Control.new()
	_player_card_container.position = Vector2(30, 190)
	_player_card_container.size = Vector2(440, 90)
	blackjack_board_parent.add_child(_player_card_container)

	blackjack_result_label = Label.new()
	blackjack_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blackjack_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blackjack_result_label.position = Vector2(30, 290)
	blackjack_result_label.size = Vector2(440, 50)
	blackjack_result_label.add_theme_font_size_override("font_size", 18)
	blackjack_board_parent.add_child(blackjack_result_label)

	deal_button = Button.new()
	deal_button.text = "DEAL"
	deal_button.position = Vector2(100, 355)
	deal_button.size = Vector2(300, 55)
	deal_button.add_theme_font_size_override("font_size", 22)
	blackjack_board_parent.add_child(deal_button)
	deal_button.pressed.connect(_start_blackjack_hand)

	hit_button = Button.new()
	hit_button.text = "HIT"
	hit_button.position = Vector2(30, 355)
	hit_button.size = Vector2(210, 55)
	hit_button.add_theme_font_size_override("font_size", 22)
	blackjack_board_parent.add_child(hit_button)
	hit_button.pressed.connect(_blackjack_hit)

	stand_button = Button.new()
	stand_button.text = "STAND"
	stand_button.position = Vector2(260, 355)
	stand_button.size = Vector2(210, 55)
	stand_button.add_theme_font_size_override("font_size", 22)
	blackjack_board_parent.add_child(stand_button)
	stand_button.pressed.connect(_blackjack_stand)

	# 3. Cave Poker UI
	poker_board_parent = Control.new()
	poker_board_parent.position = Vector2(50, 250)
	poker_board_parent.size = Vector2(620, 440)
	poker_board_parent.visible = false
	slot_layer.add_child(poker_board_parent)

	var poker_frame: Control
	if FileAccess.file_exists("res://assets/sprite_poker_table.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_poker_table.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		poker_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.22, 0.08, 0.28, 0.94) # Purple felt
		poker_frame = col_rect
	poker_frame.size = Vector2(500, 440)
	poker_frame.position = Vector2(0, 0)
	poker_board_parent.add_child(poker_frame)
	if not (poker_frame is TextureRect):
		_add_border(poker_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	poker_hand_label = Label.new()
	poker_hand_label.position = Vector2(30, 20)
	poker_hand_label.size = Vector2(440, 30)
	poker_hand_label.add_theme_font_size_override("font_size", 20)
	poker_board_parent.add_child(poker_hand_label)

	_poker_card_container = Control.new()
	_poker_card_container.position = Vector2(30, 60)
	_poker_card_container.size = Vector2(440, 90)
	poker_board_parent.add_child(_poker_card_container)

	poker_result_label = Label.new()
	poker_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poker_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	poker_result_label.position = Vector2(30, 290)
	poker_result_label.size = Vector2(440, 50)
	poker_result_label.add_theme_font_size_override("font_size", 18)
	poker_board_parent.add_child(poker_result_label)

	poker_deal_button = Button.new()
	poker_deal_button.text = "DRAW"
	poker_deal_button.position = Vector2(100, 355)
	poker_deal_button.size = Vector2(300, 55)
	poker_deal_button.add_theme_font_size_override("font_size", 22)
	poker_board_parent.add_child(poker_deal_button)
	poker_deal_button.pressed.connect(_deal_poker)

	# 4. Angel Race UI
	race_board_parent = Control.new()
	race_board_parent.position = Vector2(50, 250)
	race_board_parent.size = Vector2(620, 440)
	race_board_parent.visible = false
	slot_layer.add_child(race_board_parent)

	var race_frame: Control
	if FileAccess.file_exists("res://assets/sprite_race_track.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_race_track.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		race_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.12, 0.20, 0.35, 0.94) # Light sky blue
		race_frame = col_rect
	race_frame.size = Vector2(500, 440)
	race_frame.position = Vector2(0, 0)
	race_board_parent.add_child(race_frame)
	if not (race_frame is TextureRect):
		_add_border(race_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	race_track_label = Label.new()
	race_track_label.position = Vector2(30, 15)
	race_track_label.size = Vector2(440, 60)
	race_track_label.add_theme_font_size_override("font_size", 18)
	race_track_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	race_board_parent.add_child(race_track_label)

	_race_track_container = Control.new()
	_race_track_container.position = Vector2(30, 85)
	_race_track_container.size = Vector2(440, 180)
	race_board_parent.add_child(_race_track_container)
	_draw_race_visuals()

	race_result_label = Label.new()
	race_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	race_result_label.position = Vector2(30, 290)
	race_result_label.size = Vector2(440, 50)
	race_result_label.add_theme_font_size_override("font_size", 18)
	race_board_parent.add_child(race_result_label)

	angel_a_button = Button.new()
	angel_a_button.text = "SERAPH"
	angel_a_button.position = Vector2(20, 355)
	angel_a_button.size = Vector2(140, 55)
	angel_a_button.add_theme_font_size_override("font_size", 18)
	race_board_parent.add_child(angel_a_button)
	angel_a_button.pressed.connect(func(): _bet_angel_race(0))

	angel_b_button = Button.new()
	angel_b_button.text = "HALO"
	angel_b_button.position = Vector2(180, 355)
	angel_b_button.size = Vector2(140, 55)
	angel_b_button.add_theme_font_size_override("font_size", 18)
	race_board_parent.add_child(angel_b_button)
	angel_b_button.pressed.connect(func(): _bet_angel_race(1))

	angel_c_button = Button.new()
	angel_c_button.text = "FEATHER"
	angel_c_button.position = Vector2(340, 355)
	angel_c_button.size = Vector2(140, 55)
	angel_c_button.add_theme_font_size_override("font_size", 18)
	race_board_parent.add_child(angel_c_button)
	angel_c_button.pressed.connect(func(): _bet_angel_race(2))

	# 5. Devil's Dice UI
	dice_board_parent = Control.new()
	dice_board_parent.position = Vector2(50, 250)
	dice_board_parent.size = Vector2(620, 440)
	dice_board_parent.visible = false
	slot_layer.add_child(dice_board_parent)

	var dice_frame: Control
	if FileAccess.file_exists("res://assets/sprite_dice_table.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_dice_table.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dice_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.18, 0.04, 0.04, 0.94) # Dark red / black felt
		dice_frame = col_rect
	dice_frame.size = Vector2(500, 440)
	dice_frame.position = Vector2(0, 0)
	dice_board_parent.add_child(dice_frame)
	if not (dice_frame is TextureRect):
		_add_border(dice_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	dice_label = Label.new()
	dice_label.text = "Devil's Dice"
	dice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_label.position = Vector2(30, 20)
	dice_label.size = Vector2(440, 30)
	dice_label.add_theme_font_size_override("font_size", 20)
	dice_board_parent.add_child(dice_label)

	# Dice visuals containers
	_dice1_rect = ColorRect.new()
	_dice1_rect.size = Vector2(70, 70)
	_dice1_rect.position = Vector2(150, 80)
	_dice1_rect.color = Color(0.7, 0.1, 0.1) # Red dice
	dice_board_parent.add_child(_dice1_rect)
	_add_border(_dice1_rect, Vector2(70, 70), Color(1, 1, 1), 2.0)

	_dice2_rect = ColorRect.new()
	_dice2_rect.size = Vector2(70, 70)
	_dice2_rect.position = Vector2(280, 80)
	_dice2_rect.color = Color(0.7, 0.1, 0.1)
	dice_board_parent.add_child(_dice2_rect)
	_add_border(_dice2_rect, Vector2(70, 70), Color(1, 1, 1), 2.0)

	dice_result_label = Label.new()
	dice_result_label.text = "Devil's Dice. Roll 7 or 12 to win 3x, 9 or 11 to win 2x. 4,6,8,10 push."
	dice_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice_result_label.position = Vector2(30, 240)
	dice_result_label.size = Vector2(440, 100)
	dice_result_label.add_theme_font_size_override("font_size", 18)
	dice_board_parent.add_child(dice_result_label)

	dice_roll_button = Button.new()
	dice_roll_button.text = "ROLL DICE"
	dice_roll_button.position = Vector2(100, 355)
	dice_roll_button.size = Vector2(300, 55)
	dice_roll_button.add_theme_font_size_override("font_size", 22)
	dice_board_parent.add_child(dice_roll_button)
	dice_roll_button.pressed.connect(_roll_dice)

	# 6. Forest Wheel UI
	wheel_board_parent = Control.new()
	wheel_board_parent.position = Vector2(50, 250)
	wheel_board_parent.size = Vector2(620, 440)
	wheel_board_parent.visible = false
	slot_layer.add_child(wheel_board_parent)

	var wheel_frame: Control
	if FileAccess.file_exists("res://assets/sprite_wheel_board.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_wheel_board.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wheel_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.04, 0.18, 0.08, 0.94) # Dark forest green
		wheel_frame = col_rect
	wheel_frame.size = Vector2(500, 440)
	wheel_frame.position = Vector2(0, 0)
	wheel_board_parent.add_child(wheel_frame)
	if not (wheel_frame is TextureRect):
		_add_border(wheel_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	wheel_label = Label.new()
	wheel_label.text = "[ 0x | 0.5x | 1x | 1.5x | 2x | 3x | 5x | 0x ]"
	wheel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wheel_label.position = Vector2(30, 80)
	wheel_label.size = Vector2(440, 60)
	wheel_label.add_theme_font_size_override("font_size", 24)
	wheel_board_parent.add_child(wheel_label)

	wheel_result_label = Label.new()
	wheel_result_label.text = "Forest Wheel. Spin to win multipliers from 0x to 5x."
	wheel_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wheel_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wheel_result_label.position = Vector2(30, 220)
	wheel_result_label.size = Vector2(440, 80)
	wheel_result_label.add_theme_font_size_override("font_size", 18)
	wheel_board_parent.add_child(wheel_result_label)

	wheel_spin_button = Button.new()
	wheel_spin_button.text = "SPIN WHEEL"
	wheel_spin_button.position = Vector2(100, 355)
	wheel_spin_button.size = Vector2(300, 55)
	wheel_spin_button.add_theme_font_size_override("font_size", 22)
	wheel_board_parent.add_child(wheel_spin_button)
	wheel_spin_button.pressed.connect(_spin_wheel)

	# 7. Desert Hi-Lo UI
	hilo_board_parent = Control.new()
	hilo_board_parent.position = Vector2(50, 250)
	hilo_board_parent.size = Vector2(620, 440)
	hilo_board_parent.visible = false
	slot_layer.add_child(hilo_board_parent)

	var hilo_frame: Control
	if FileAccess.file_exists("res://assets/sprite_hilo_board.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_hilo_board.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hilo_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.24, 0.20, 0.10, 0.94) # Warm sand ochre
		hilo_frame = col_rect
	hilo_frame.size = Vector2(500, 440)
	hilo_frame.position = Vector2(0, 0)
	hilo_board_parent.add_child(hilo_frame)
	if not (hilo_frame is TextureRect):
		_add_border(hilo_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	hilo_card_label = Label.new()
	hilo_card_label.position = Vector2(30, 20)
	hilo_card_label.size = Vector2(440, 30)
	hilo_card_label.add_theme_font_size_override("font_size", 20)
	hilo_board_parent.add_child(hilo_card_label)

	_hilo_card_container = Control.new()
	_hilo_card_container.position = Vector2(30, 60)
	_hilo_card_container.size = Vector2(440, 90)
	hilo_board_parent.add_child(_hilo_card_container)

	hilo_result_label = Label.new()
	hilo_result_label.text = "Guess if next card is HIGHER or LOWER. Win pays 2x."
	hilo_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hilo_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hilo_result_label.position = Vector2(30, 260)
	hilo_result_label.size = Vector2(440, 80)
	hilo_result_label.add_theme_font_size_override("font_size", 18)
	hilo_board_parent.add_child(hilo_result_label)

	hilo_higher_button = Button.new()
	hilo_higher_button.text = "HIGHER"
	hilo_higher_button.position = Vector2(30, 355)
	hilo_higher_button.size = Vector2(210, 55)
	hilo_higher_button.add_theme_font_size_override("font_size", 22)
	hilo_board_parent.add_child(hilo_higher_button)
	hilo_higher_button.pressed.connect(func(): _play_hilo(true))

	hilo_lower_button = Button.new()
	hilo_lower_button.text = "LOWER"
	hilo_lower_button.position = Vector2(260, 355)
	hilo_lower_button.size = Vector2(210, 55)
	hilo_lower_button.add_theme_font_size_override("font_size", 22)
	hilo_board_parent.add_child(hilo_lower_button)
	hilo_lower_button.pressed.connect(func(): _play_hilo(false))

	# 8. Pearl Oyster UI
	pearl_board_parent = Control.new()
	pearl_board_parent.position = Vector2(50, 250)
	pearl_board_parent.size = Vector2(620, 440)
	pearl_board_parent.visible = false
	slot_layer.add_child(pearl_board_parent)

	var pearl_frame: Control
	if FileAccess.file_exists("res://assets/sprite_pearl_board.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_pearl_board.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pearl_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.02, 0.12, 0.22, 0.94) # Deep ocean blue
		pearl_frame = col_rect
	pearl_frame.size = Vector2(500, 440)
	pearl_frame.position = Vector2(0, 0)
	pearl_board_parent.add_child(pearl_frame)
	if not (pearl_frame is TextureRect):
		_add_border(pearl_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	oyster_label = Label.new()
	oyster_label.text = "🦪 Pick an Oyster!"
	oyster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oyster_label.position = Vector2(30, 15)
	oyster_label.size = Vector2(440, 45)
	oyster_label.add_theme_font_size_override("font_size", 20)
	pearl_board_parent.add_child(oyster_label)

	_pearl_oyster_container = Control.new()
	_pearl_oyster_container.position = Vector2(30, 70)
	_pearl_oyster_container.size = Vector2(440, 210)
	pearl_board_parent.add_child(_pearl_oyster_container)
	_draw_oyster_visuals()

	oyster_result_label = Label.new()
	oyster_result_label.text = "Pearl Oyster. Pick one! Empty = 0x, Silver = 2x, Golden = 5x."
	oyster_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oyster_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	oyster_result_label.position = Vector2(30, 290)
	oyster_result_label.size = Vector2(440, 50)
	oyster_result_label.add_theme_font_size_override("font_size", 18)
	pearl_board_parent.add_child(oyster_result_label)

	for i in range(5):
		var btn := Button.new()
		btn.text = "🦪 " + str(i+1)
		btn.position = Vector2(20 + i * 92, 355)
		btn.size = Vector2(80, 55)
		btn.add_theme_font_size_override("font_size", 18)
		pearl_board_parent.add_child(btn)
		oyster_buttons.append(btn)
		btn.pressed.connect(func(choice = i): _pick_oyster(choice))

	# 9. Cosmic Crash UI
	crash_board_parent = Control.new()
	crash_board_parent.position = Vector2(50, 250)
	crash_board_parent.size = Vector2(620, 440)
	crash_board_parent.visible = false
	slot_layer.add_child(crash_board_parent)

	var crash_frame: Control
	if FileAccess.file_exists("res://assets/sprite_crash_board.png"):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load("res://assets/sprite_crash_board.png")
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		crash_frame = tex_rect
	else:
		var col_rect := ColorRect.new()
		col_rect.color = Color(0.02, 0.02, 0.08, 0.94) # Cosmic star navy
		crash_frame = col_rect
	crash_frame.size = Vector2(500, 440)
	crash_frame.position = Vector2(0, 0)
	crash_board_parent.add_child(crash_frame)
	if not (crash_frame is TextureRect):
		_add_border(crash_frame, Vector2(500, 440), Color(0.9, 0.75, 0.1), 4.0)

	crash_multiplier_label = Label.new()
	crash_multiplier_label.text = "CRASH MULTIPLIER:  1.00x"
	crash_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crash_multiplier_label.position = Vector2(30, 15)
	crash_multiplier_label.size = Vector2(440, 45)
	crash_multiplier_label.add_theme_font_size_override("font_size", 22)
	crash_board_parent.add_child(crash_multiplier_label)

	_crash_visual_container = Control.new()
	_crash_visual_container.position = Vector2(30, 70)
	_crash_visual_container.size = Vector2(440, 210)
	crash_board_parent.add_child(_crash_visual_container)
	_draw_crash_visuals()

	crash_result_label = Label.new()
	crash_result_label.text = "Cosmic Crash. Cashout before the rocket crashes! Max payout 10x."
	crash_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crash_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crash_result_label.position = Vector2(30, 290)
	crash_result_label.size = Vector2(440, 50)
	crash_result_label.add_theme_font_size_override("font_size", 18)
	crash_board_parent.add_child(crash_result_label)

	crash_launch_button = Button.new()
	crash_launch_button.text = "LAUNCH"
	crash_launch_button.position = Vector2(30, 355)
	crash_launch_button.size = Vector2(210, 55)
	crash_launch_button.add_theme_font_size_override("font_size", 22)
	crash_board_parent.add_child(crash_launch_button)
	crash_launch_button.pressed.connect(_launch_crash)

	crash_cashout_button = Button.new()
	crash_cashout_button.text = "CASH OUT"
	crash_cashout_button.position = Vector2(260, 355)
	crash_cashout_button.size = Vector2(210, 55)
	crash_cashout_button.add_theme_font_size_override("font_size", 22)
	crash_board_parent.add_child(crash_cashout_button)
	crash_cashout_button.pressed.connect(_cash_out_crash)

	exit_button = Button.new()
	exit_button.text = "RETURN"
	exit_button.position = Vector2(130, 720)
	exit_button.size = Vector2(460, 72)
	exit_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(exit_button)
	exit_button.pressed.connect(_exit_slot_area)
	
	_style_casino_button(decrease_bet_button, Color(0.25, 0.25, 0.25))
	_style_casino_button(increase_bet_button, Color(0.25, 0.25, 0.25))
	_style_casino_button(slot_tab_button, Color(0.12, 0.28, 0.45))
	_style_casino_button(blackjack_tab_button, Color(0.12, 0.28, 0.45))
	_style_casino_button(spin_button, Color(0.7, 0.15, 0.15))
	_style_casino_button(exit_button, Color(0.25, 0.25, 0.25))
	
	_style_casino_button(deal_button, Color(0.7, 0.15, 0.15))
	_style_casino_button(hit_button, Color(0.12, 0.45, 0.28))
	_style_casino_button(stand_button, Color(0.65, 0.45, 0.05))
	
	_style_casino_button(poker_deal_button, Color(0.7, 0.15, 0.15))
	
	_style_casino_button(angel_a_button, Color(0.65, 0.45, 0.05))
	_style_casino_button(angel_b_button, Color(0.65, 0.45, 0.05))
	_style_casino_button(angel_c_button, Color(0.65, 0.45, 0.05))
	
	_style_casino_button(dice_roll_button, Color(0.7, 0.15, 0.15))
	
	_style_casino_button(wheel_spin_button, Color(0.7, 0.15, 0.15))
	
	_style_casino_button(hilo_higher_button, Color(0.12, 0.45, 0.28))
	_style_casino_button(hilo_lower_button, Color(0.7, 0.15, 0.15))
	
	for btn in oyster_buttons:
		_style_casino_button(btn, Color(0.12, 0.28, 0.45))
		
	_style_casino_button(crash_launch_button, Color(0.7, 0.15, 0.15))
	_style_casino_button(crash_cashout_button, Color(0.65, 0.45, 0.05))
	
	for btn in _stop_buttons:
		_style_casino_button(btn, Color(0.5, 0.1, 0.1))
		
	_set_gamble_game(GambleGame.SLOT)

func _add_border(parent: Control, size: Vector2, color: Color, width: float) -> void:
	var t := ColorRect.new()
	t.color = color
	t.size = Vector2(size.x, width)
	t.position = Vector2(0, 0)
	parent.add_child(t)
	var b := ColorRect.new()
	b.color = color
	b.size = Vector2(size.x, width)
	b.position = Vector2(0, size.y - width)
	parent.add_child(b)
	var l := ColorRect.new()
	l.color = color
	l.size = Vector2(width, size.y)
	l.position = Vector2(0, 0)
	parent.add_child(l)
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(width, size.y)
	r.position = Vector2(size.x - width, 0)
	parent.add_child(r)

func _reset_reels() -> void:
	for i in range(3):
		_reel_states[i] = ReelState.IDLE
		_reel_speeds[i] = 0.0
		_reel_targets[i] = 5
		_reel_containers[i].position.y = 150.0 - (5.0 + 1.0) * 100.0
	_set_slot_buttons_disabled(false)

func _stop_reel(i: int) -> void:
	if _reel_states[i] == ReelState.SPINNING:
		_reel_states[i] = ReelState.STOPPING
		_stop_buttons[i].disabled = true
		_play_sfx("stop")

func _set_slot_buttons_disabled(is_disabled: bool) -> void:
	decrease_bet_button.disabled = is_disabled
	increase_bet_button.disabled = is_disabled
	slot_tab_button.disabled = is_disabled
	blackjack_tab_button.disabled = is_disabled
	exit_button.disabled = is_disabled
	spin_button.disabled = is_disabled
	for btn in _stop_buttons:
		btn.disabled = not is_disabled

func _preload_sfx() -> void:
	var sfx_names: Array[String] = ["lever", "stop", "win", "lose", "deal", "hit", "push"]
	for sfx in sfx_names:
		var path: String = "res://assets/sfx_" + sfx + ".wav"
		if FileAccess.file_exists(path):
			_sfx_cache[sfx] = load(path)

func _play_sfx(sfx_name: String) -> void:
	if not is_instance_valid(_sfx_player):
		return
	if _sfx_cache.has(sfx_name):
		_sfx_player.stream = _sfx_cache[sfx_name]
		if sfx_name == "stop":
			_sfx_player.volume_db = 6.0
		else:
			_sfx_player.volume_db = 0.0
		_sfx_player.play()
	else:
		# Fallback if not preloaded (e.g. dynamically added files)
		var path: String = "res://assets/sfx_" + sfx_name + ".wav"
		if FileAccess.file_exists(path):
			var stream = load(path)
			_sfx_cache[sfx_name] = stream
			_sfx_player.stream = stream
			if sfx_name == "stop":
				_sfx_player.volume_db = 6.0
			else:
				_sfx_player.volume_db = 0.0
			_sfx_player.play()

func _preload_bgm() -> void:
	var bgm_files := {
		"normal": "res://assets/Call_of_the_Radiant_Blade.mp3",
		"casino": "res://assets/High_Roller_s_Gambit.mp3",
		"boss": "res://assets/Before_The_Kingdom_Falls.mp3"
	}
	for key in bgm_files.keys():
		var path: String = bgm_files[key]
		if FileAccess.file_exists(path):
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.size() > 0:
				var stream := AudioStreamMP3.new()
				stream.data = bytes
				stream.loop = true
				_bgm_cache[key] = stream

func _play_bgm(bgm_type: String) -> void:
	if not is_instance_valid(_bgm_player):
		return
	if _current_bgm_type == bgm_type:
		return
	_current_bgm_type = bgm_type
	
	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	
	if _bgm_player.playing:
		_bgm_tween.tween_property(_bgm_player, "volume_db", -60.0, 0.35)
		_bgm_tween.tween_callback(func():
			if _bgm_cache.has(bgm_type):
				_bgm_player.stream = _bgm_cache[bgm_type]
				_bgm_player.play()
			else:
				_bgm_player.stop()
		)
		_bgm_tween.tween_property(_bgm_player, "volume_db", 0.0, 0.35)
	else:
		_bgm_player.volume_db = -60.0
		if _bgm_cache.has(bgm_type):
			_bgm_player.stream = _bgm_cache[bgm_type]
			_bgm_player.play()
			_bgm_tween.tween_property(_bgm_player, "volume_db", 0.0, 0.35)
		else:
			_bgm_player.stop()

func _stop_bgm() -> void:
	_current_bgm_type = ""
	if _bgm_tween:
		_bgm_tween.kill()
	if is_instance_valid(_bgm_player):
		_bgm_player.stop()

func _create_shop_ui() -> void:
	shop_layer = CanvasLayer.new()
	shop_layer.visible = false
	add_child(shop_layer)

	var background := ColorRect.new()
	background.color = Color(0.018, 0.021, 0.018, 0.95)
	background.position = Vector2(0, 0)
	background.size = Vector2(720, 1280)
	shop_layer.add_child(background)

	var title := Label.new()
	title.text = "## WEAPON SHOP"
	title.position = Vector2(50, 50)
	title.add_theme_font_size_override("font_size", 34)
	shop_layer.add_child(title)

	shop_money_label = Label.new()
	shop_money_label.position = Vector2(50, 110)
	shop_money_label.size = Vector2(620, 42)
	shop_money_label.add_theme_font_size_override("font_size", 25)
	shop_layer.add_child(shop_money_label)

	shop_status_label = Label.new()
	shop_status_label.position = Vector2(50, 160)
	shop_status_label.size = Vector2(620, 62)
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status_label.add_theme_font_size_override("font_size", 22)
	shop_layer.add_child(shop_status_label)

	for index in range(_weapon_catalog.size()):
		var weapon = _weapon_catalog[index]
		var button := Button.new()
		button.position = Vector2(50, 240 + index * 90)
		button.size = Vector2(620, 74)
		button.add_theme_font_size_override("font_size", 22)
		shop_layer.add_child(button)
		shop_buttons.append(button)
		button.pressed.connect(func(weapon_id = weapon["id"]): _buy_weapon(weapon_id))
		_style_casino_button(button, Color(0.12, 0.26, 0.16))

	shop_heal_button = Button.new()
	shop_heal_button.size = Vector2(620, 74)
	shop_heal_button.add_theme_font_size_override("font_size", 22)
	shop_layer.add_child(shop_heal_button)
	shop_heal_button.pressed.connect(_buy_heal)
	_style_casino_button(shop_heal_button, Color(0.18, 0.35, 0.22))

	shop_exit_button = Button.new()
	shop_exit_button.text = "RETURN"
	shop_exit_button.position = Vector2(130, 720)
	shop_exit_button.size = Vector2(460, 72)
	shop_exit_button.add_theme_font_size_override("font_size", 28)
	shop_layer.add_child(shop_exit_button)
	shop_exit_button.pressed.connect(_exit_weapon_shop)
	_style_casino_button(shop_exit_button, Color(0.24, 0.26, 0.24))
	_refresh_shop_ui()

func _create_game_over_ui() -> void:
	game_over_layer = CanvasLayer.new()
	game_over_layer.visible = false
	add_child(game_over_layer)

	var background := ColorRect.new()
	background.color = Color(0.015, 0.015, 0.018, 0.94)
	background.position = Vector2(0, 0)
	background.size = Vector2(720, 1280)
	game_over_layer.add_child(background)

	var title := Label.new()
	title.text = "## RUN ENDED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 200)
	title.size = Vector2(620, 72)
	title.add_theme_font_size_override("font_size", 44)
	game_over_layer.add_child(title)

	game_over_stats_label = Label.new()
	game_over_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_stats_label.position = Vector2(50, 320)
	game_over_stats_label.size = Vector2(620, 110)
	game_over_stats_label.add_theme_font_size_override("font_size", 28)
	game_over_layer.add_child(game_over_stats_label)

	restart_button = Button.new()
	restart_button.text = "RETRY RUN"
	restart_button.position = Vector2(130, 520)
	restart_button.size = Vector2(460, 86)
	restart_button.add_theme_font_size_override("font_size", 32)
	game_over_layer.add_child(restart_button)
	restart_button.pressed.connect(_restart_run)

func _spawn_wave() -> void:
	if mode != GameMode.COMBAT:
		return
	for index in range(3 + wave):
		var type = _pick_random_enemy_type(current_stage)
		_spawn_enemy(Vector2(randf_range(-1400, 1400), randf_range(-1400, 0)), type)

func _spawn_enemy(spawn_position: Vector2, type: String = "A") -> void:
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy_" + type
	enemy.set_script(EnemyScript)
	enemy.setup(type)
	enemy.global_position = spawn_position
	enemy.target = player
	add_child(enemy)
	enemies.append(enemy)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36 if type == "G" else 24
	shape.shape = circle
	enemy.add_child(shape)

	var sprite := Sprite2D.new()
	var texture_path := "res://assets/sprite_enemy_common.png"
	match type:
		"A", "D":
			texture_path = "res://assets/sprite_enemy_common.png"
		"B", "F", "I":
			texture_path = "res://assets/sprite_enemy_fast.png"
		"C", "G":
			texture_path = "res://assets/sprite_enemy_tank.png"
		"E", "H", "J":
			texture_path = "res://assets/sprite_enemy_range.png"
	var raw_tex = _load_texture(texture_path)
	var transparent_tex = _make_background_transparent(raw_tex)
	if is_instance_valid(transparent_tex):
		sprite.texture = transparent_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_size := 72.0 if type == "G" else 48.0
		sprite.scale = Vector2(target_size / transparent_tex.get_width(), target_size / transparent_tex.get_height())
	enemy.add_child(sprite)

	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit_player.connect(func(): _update_hud("Ouch. Keep moving."))
	if enemy.has_signal("shot_requested"):
		enemy.shot_requested.connect(_spawn_enemy_bolt)

func _pick_random_enemy_type(stage: int) -> String:
	var dist = _stage_enemy_distributions.get(stage, {"A": 1.0})
	var roll = randf()
	var cumulative_probability = 0.0
	for type in dist:
		cumulative_probability += dist[type]
		if roll <= cumulative_probability:
			return type
	return dist.keys().back()

func _color_for_enemy_type(type: String) -> Color:
	match type:
		"A": return Color(0.4, 0.8, 0.4) # Light Green
		"B": return Color(0.9, 0.9, 0.3) # Yellow
		"C": return Color(0.3, 0.6, 0.9) # Blue
		"D": return Color(0.9, 0.6, 0.2) # Orange
		"E": return Color(0.7, 0.3, 0.8) # Purple
		"F": return Color(0.3, 0.8, 0.8) # Cyan
		"G": return Color(0.6, 0.6, 0.6) # Gray
		"H": return Color(0.9, 0.2, 0.2) # Red
		"I": return Color(0.8, 0.8, 0.9, 0.75) # Translucent White
		"J": return Color(0.9, 0.1, 0.6) # Magenta
	return Color.WHITE

func _spawn_enemy_bolt(origin: Vector2, direction: Vector2, damage: int, color := Color(1.0, 0.3, 0.3), size := 12.0, speed := 350.0, lifetime := 2.0, symbol := "o") -> void:
	if mode != GameMode.COMBAT:
		return
	var bolt := Area2D.new()
	bolt.name = "EnemyBolt"
	bolt.add_to_group("enemy_bolts")
	bolt.set_script(BoltScript)
	bolt.setup(origin, direction)
	bolt.speed = speed
	bolt.lifetime = lifetime
	add_child(bolt)
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	shape.shape = circle
	bolt.add_child(shape)
	
	if direction.length() > 0.0:
		if is_instance_valid(_enemy_bullet_texture):
			var sprite := Sprite2D.new()
			sprite.texture = _enemy_bullet_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.modulate = color
			var tw := size * 2.6
			sprite.scale = Vector2(tw / _enemy_bullet_texture.get_width(), tw / _enemy_bullet_texture.get_height())
			bolt.add_child(sprite)
		else:
			var line := Line2D.new()
			line.width = size * 0.5
			line.default_color = color
			line.points = [Vector2.ZERO, -direction.normalized() * (size * 2.5)]
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(line)
	else:
		match symbol:
			"*":
				for i in range(4):
					var angle := PI * float(i) / 4.0
					var sp_line := Line2D.new()
					sp_line.width = 3.0
					sp_line.default_color = color
					var dir_vec := Vector2.RIGHT.rotated(angle)
					sp_line.points = [-dir_vec * size, dir_vec * size]
					bolt.add_child(sp_line)
			"x", "X":
				var cross1 := Line2D.new()
				cross1.width = 4.0
				cross1.default_color = color
				cross1.points = [Vector2(-size, -size), Vector2(size, size)]
				bolt.add_child(cross1)
				
				var cross2 := Line2D.new()
				cross2.width = 4.0
				cross2.default_color = color
				cross2.points = [Vector2(size, -size), Vector2(-size, size)]
				bolt.add_child(cross2)
			"o", "O":
				if is_instance_valid(_enemy_bullet_texture):
					var sprite := Sprite2D.new()
					sprite.texture = _enemy_bullet_texture
					sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					sprite.modulate = color
					var tw := size * 2.6
					sprite.scale = Vector2(tw / _enemy_bullet_texture.get_width(), tw / _enemy_bullet_texture.get_height())
					bolt.add_child(sprite)
				else:
					var poly := Polygon2D.new()
					poly.color = color
					var points := PackedVector2Array()
					var steps := 12
					for i in range(steps):
						var angle := TAU * float(i) / float(steps)
						points.append(Vector2(cos(angle), sin(angle)) * size)
					poly.polygon = points
					bolt.add_child(poly)
					
					var core := Polygon2D.new()
					core.color = Color(1.0, 1.0, 1.0, 0.7)
					var core_points := PackedVector2Array()
					for i in range(steps):
						var angle := TAU * float(i) / float(steps)
						core_points.append(Vector2(cos(angle), sin(angle)) * (size * 0.45))
					core.polygon = core_points
					bolt.add_child(core)
			"v", "V":
				var arrow := Line2D.new()
				arrow.width = 4.0
				arrow.default_color = color
				arrow.points = [Vector2(-size, -size * 0.6), Vector2(0, size * 0.6), Vector2(size, -size * 0.6)]
				bolt.add_child(arrow)
			"-":
				var laser := Line2D.new()
				laser.width = 5.0
				laser.default_color = color
				laser.points = [Vector2(-size * 2.0, 0), Vector2(size * 2.0, 0)]
				bolt.add_child(laser)
			_:
				var poly := Polygon2D.new()
				poly.color = color
				poly.polygon = [
					Vector2(0, -size),
					Vector2(size, 0),
					Vector2(0, size),
					Vector2(-size, 0)
				]
				bolt.add_child(poly)
	
	bolt.body_entered.connect(func(body: Node) -> void:
		if body == player:
			if player.has_method("damage"):
				player.damage(damage, bolt.global_position)
				_update_hud("Ouch! Hit by enemy projectile.")
			bolt.queue_free()
	)

func _spawn_bolt(origin: Vector2, direction: Vector2) -> void:
	if mode != GameMode.COMBAT or not _owned_weapons["targeter"]:
		return
	var lvl_tgt = _weapon_levels.get("targeter", 1)
	_create_projectile(origin, direction, "-", 820.0, 1.2, 10.0, lvl_tgt)
	
	if _owned_weapons["repeater"]:
		var lvl_rep = _weapon_levels.get("repeater", 1)
		var dmg_rep = 1 + int(lvl_rep / 2) # Lv 1-2: 1, Lv 3-4: 2, Lv 5: 3
		_create_projectile(origin + Vector2(18, 0), direction, "-", 820.0, 1.2, 10.0, dmg_rep)
		if lvl_rep >= 3:
			_create_projectile(origin - Vector2(18, 0), direction, "-", 820.0, 1.2, 10.0, dmg_rep)
		if lvl_rep >= 5:
			_create_projectile(origin + Vector2(36, 0), direction, "-", 820.0, 1.2, 10.0, dmg_rep)
			
	if _owned_weapons["splitter"]:
		var lvl_spl = _weapon_levels.get("splitter", 1)
		_create_projectile(origin, direction.rotated(0.32), "\\", 780.0, 1.0, 10.0, lvl_spl)
		_create_projectile(origin, direction.rotated(-0.32), "/", 780.0, 1.0, 10.0, lvl_spl)
		if lvl_spl >= 3:
			_create_projectile(origin, direction.rotated(0.64), "\\", 780.0, 1.0, 10.0, lvl_spl)
			_create_projectile(origin, direction.rotated(-0.64), "/", 780.0, 1.0, 10.0, lvl_spl)

func _spawn_forward_bolt(origin: Vector2, direction: Vector2) -> void:
	if mode != GameMode.COMBAT:
		return
	if _owned_weapons["blaster"]:
		var lvl = _weapon_levels.get("blaster", 1)
		_create_projectile(origin + direction.normalized() * 34.0, direction, ">", 980.0 + lvl * 50.0, 0.75, 12.0, lvl)
	if _owned_weapons["wave"]:
		var lvl = _weapon_levels.get("wave", 1)
		var perpendicular := direction.rotated(PI/2).normalized()
		var offset = 30.0 + lvl * 5.0
		_create_projectile(origin + perpendicular * offset, direction, "~", 850.0, 0.8, 10.0, lvl)
		_create_projectile(origin, direction, "~", 850.0, 0.8, 10.0, lvl)
		_create_projectile(origin - perpendicular * offset, direction, "~", 850.0, 0.8, 10.0, lvl)
	if _owned_weapons["hellfire"]:
		var lvl = _weapon_levels.get("hellfire", 1)
		_create_projectile(origin - direction.normalized() * 34.0, -direction, "f", 900.0, 0.8, 14.0 + lvl * 2.0, 1 + lvl)
	if _owned_weapons["mirage"]:
		var lvl = _weapon_levels.get("mirage", 1)
		_create_projectile(origin, direction.rotated(PI/2), "|", 850.0, 0.8, 10.0, lvl)
		_create_projectile(origin, direction.rotated(-PI/2), "|", 850.0, 0.8, 10.0, lvl)
	if _owned_weapons["drill"]:
		var lvl = _weapon_levels.get("drill", 1)
		var bolt = _create_projectile(origin, direction, ">>>", 1100.0, 0.6, 16.0 + lvl * 2.0, 1 + lvl)
		if is_instance_valid(bolt):
			bolt.piercing = true
	if _owned_weapons["trident"]:
		var lvl = _weapon_levels.get("trident", 1)
		var angle_offset = 0.2
		var bolt_center = _create_projectile(origin, direction, "Ψ", 900.0, 1.0, 22.0 + lvl * 2.0, 3 + lvl * 2)
		if is_instance_valid(bolt_center):
			bolt_center.piercing = true
		var bolt_left = _create_projectile(origin, direction.rotated(-angle_offset), "ψ", 900.0, 1.0, 18.0 + lvl * 2.0, 2 + lvl * 2)
		if is_instance_valid(bolt_left):
			bolt_left.piercing = true
		var bolt_right = _create_projectile(origin, direction.rotated(angle_offset), "ψ", 900.0, 1.0, 18.0 + lvl * 2.0, 2 + lvl * 2)
		if is_instance_valid(bolt_right):
			bolt_right.piercing = true

func _update_owned_weapon_attacks(delta: float) -> void:
	if _owned_weapons["nova"]:
		_nova_timer -= delta
		if _nova_timer <= 0.0:
			var lvl = _weapon_levels.get("nova", 1)
			_nova_timer = max(0.8, 2.1 - lvl * 0.2)
			_spawn_nova()
	if _owned_weapons["spore"]:
		_spore_timer -= delta
		if _spore_timer <= 0.0:
			var lvl = _weapon_levels.get("spore", 1)
			_spore_timer = max(0.6, 1.6 - lvl * 0.15)
			_spawn_spore()
	if _owned_weapons["halo"]:
		_halo_timer -= delta
		if _halo_timer <= 0.0:
			var lvl = _weapon_levels.get("halo", 1)
			_halo_timer = max(1.0, 2.5 - lvl * 0.2)
			_spawn_halo()
	if _owned_weapons["meteor"]:
		_meteor_timer -= delta
		if _meteor_timer <= 0.0:
			var lvl = _weapon_levels.get("meteor", 1)
			_meteor_timer = max(0.5, 1.4 - lvl * 0.15)
			var nearest := _nearest_enemy()
			if is_instance_valid(nearest):
				var direction: Vector2 = player.global_position.direction_to(nearest.global_position)
				_create_projectile(player.global_position, direction, "O", 500.0, 1.8, 20.0 + lvl * 5.0, 2 + lvl)
	if _owned_weapons["scythe"]:
		_scythe_timer -= delta
		if _scythe_timer <= 0.0:
			var lvl = _weapon_levels.get("scythe", 1)
			_scythe_timer = 2.0
			var count = 1 + lvl
			for i in range(count):
				var angle = TAU * float(i) / float(count)
				var bolt = _create_projectile(player.global_position, Vector2.RIGHT, ")", 0.0, 3.5, 18.0, 2 + lvl)
				if is_instance_valid(bolt):
					bolt.custom_behavior = "orbit"
					bolt.orbit_target = player
					bolt.orbit_angle = angle
					bolt.orbit_radius = 120.0
					bolt.orbit_speed = 3.5 + lvl * 0.5
					bolt.piercing = true
	if _owned_weapons["vine_whip"]:
		_vine_whip_timer -= delta
		if _vine_whip_timer <= 0.0:
			var lvl = _weapon_levels.get("vine_whip", 1)
			_vine_whip_timer = max(0.6, 1.8 - lvl * 0.2)
			var left_dir = Vector2.LEFT
			var right_dir = Vector2.RIGHT
			for i in range(1 + lvl):
				var dist = 50.0 + i * 40.0
				var bolt_l = _create_projectile(player.global_position + left_dir * dist, left_dir, "\\/", 100.0, 0.4, 18.0, 2 + lvl)
				if is_instance_valid(bolt_l):
					bolt_l.piercing = true
				var bolt_r = _create_projectile(player.global_position + right_dir * dist, right_dir, "\\/", 100.0, 0.4, 18.0, 2 + lvl)
				if is_instance_valid(bolt_r):
					bolt_r.piercing = true
	if _owned_weapons["sandstorm"]:
		_sandstorm_timer -= delta
		if _sandstorm_timer <= 0.0:
			var lvl = _weapon_levels.get("sandstorm", 1)
			_sandstorm_timer = 0.5
			for i in range(2):
				var angle = randf() * TAU
				var bolt = _create_projectile(player.global_position, Vector2.RIGHT, ".", 0.0, 1.5, 25.0, 1 + lvl)
				if is_instance_valid(bolt):
					bolt.custom_behavior = "orbit"
					bolt.orbit_target = player
					bolt.orbit_angle = angle
					bolt.orbit_radius = randf_range(60.0, 110.0)
					bolt.orbit_speed = randf_range(5.0, 8.0)
					bolt.piercing = true
	if _owned_weapons["lightning"]:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			var lvl = _weapon_levels.get("lightning", 1)
			_lightning_timer = max(0.5, 1.5 - lvl * 0.2)
			var nearest = _nearest_enemy()
			if is_instance_valid(nearest):
				var strike_pos = nearest.global_position
				for j in range(3):
					var offset_pos = strike_pos + Vector2(0, -j * 40.0)
					var bolt = _create_projectile(offset_pos, Vector2.DOWN, "V", 300.0, 0.25, 20.0 + lvl * 3.0, 3 + lvl * 2)
					if is_instance_valid(bolt):
						bolt.piercing = true
	if _owned_weapons["doom"]:
		_doom_timer -= delta
		if _doom_timer <= 0.0:
			var lvl = _weapon_levels.get("doom", 1)
			_doom_timer = max(1.5, 4.0 - lvl * 0.5)
			for enemy in enemies:
				if is_instance_valid(enemy):
					enemy.damage(1 + lvl)
			for i in range(8):
				var angle = TAU * float(i) / 8.0
				_create_projectile(player.global_position, Vector2.RIGHT.rotated(angle), "f", 500.0, 1.0, 16.0, 2 + lvl)
	if _owned_weapons["blackhole"]:
		_blackhole_timer -= delta
		if _blackhole_timer <= 0.0:
			var lvl = _weapon_levels.get("blackhole", 1)
			_blackhole_timer = max(2.0, 5.0 - lvl * 0.5)
			var spawn_pos = player.global_position + Vector2.UP * 100.0
			var nearest = _nearest_enemy()
			if is_instance_valid(nearest):
				spawn_pos = nearest.global_position
			var bolt = _create_projectile(spawn_pos, Vector2.UP, "@", 0.0, 3.5, 80.0, 0)
			if is_instance_valid(bolt):
				bolt.add_to_group("blackholes")
				for child in bolt.get_children():
					if child is Label:
						child.add_theme_font_size_override("font_size", 65)

	# Handle the pulling and ticking for blackholes
	for bh in get_tree().get_nodes_in_group("blackholes"):
		if is_instance_valid(bh):
			var bh_pos = bh.global_position
			var lvl = _weapon_levels.get("blackhole", 1)
			if not bh.has_meta("tick_timer"):
				bh.set_meta("tick_timer", 0.0)
			var t = bh.get_meta("tick_timer") - delta
			var do_damage = false
			if t <= 0.0:
				do_damage = true
				bh.set_meta("tick_timer", 0.4)
				
			for enemy in enemies:
				if is_instance_valid(enemy):
					var dist = enemy.global_position.distance_to(bh_pos)
					if dist < 250.0:
						var pull_dir = enemy.global_position.direction_to(bh_pos)
						enemy.global_position += pull_dir * 180.0 * delta
						if do_damage and dist < 100.0:
							enemy.damage(1 + lvl)

	if _owned_weapons["katana"]:
		_katana_timer -= delta
		if _katana_timer <= 0.0:
			var lvl = _weapon_levels.get("katana", 1)
			_katana_timer = max(0.4, 1.2 - lvl * 0.15)
			var dir = player.aim_direction
			if dir.length() <= 0.0:
				dir = Vector2.RIGHT
			var slash_pos = player.global_position + dir.normalized() * 40.0
			var bolt = _create_projectile(slash_pos, dir, "katana", 0.0, 0.25, 45.0 + lvl * 8.0, 3 + lvl * 2)
			if is_instance_valid(bolt):
				bolt.custom_behavior = "katana_slash"
				bolt.orbit_target = player
				bolt.orbit_angle = dir.angle()
				bolt.orbit_radius = 40.0
				bolt.orbit_speed = 6.0
				bolt.piercing = true
				bolt.set_meta("total_lifetime", 0.25)
				bolt.area_entered.connect(func(area: Area2D) -> void:
					if area.is_in_group("enemy_bolts"):
						area.queue_free()
				)

	if _owned_weapons["boomerang"]:
		_boomerang_timer -= delta
		if _boomerang_timer <= 0.0:
			var lvl = _weapon_levels.get("boomerang", 1)
			_boomerang_timer = max(0.5, 1.5 - lvl * 0.15)
			var dir = player.aim_direction
			if dir.length() <= 0.0:
				dir = Vector2.RIGHT
			var bolt = _create_projectile(player.global_position, dir, "boomerang", 650.0, 1.6, 24.0 + lvl * 2.0, 2 + lvl)
			if is_instance_valid(bolt):
				bolt.custom_behavior = "boomerang"
				bolt.orbit_target = player
				bolt.set_meta("total_lifetime", 1.6)
				bolt.set_meta("returning", false)
				bolt.piercing = true

	if _owned_weapons["shockwave"]:
		_shockwave_timer -= delta
		if _shockwave_timer <= 0.0:
			var lvl = _weapon_levels.get("shockwave", 1)
			_shockwave_timer = max(1.0, 3.0 - lvl * 0.3)
			var bolt = _create_projectile(player.global_position, Vector2.RIGHT, "shockwave", 0.0, 0.45, 10.0, 1 + lvl)
			if is_instance_valid(bolt):
				bolt.custom_behavior = "shockwave"
				bolt.orbit_target = player
				bolt.piercing = true
				bolt.set_meta("max_radius", 140.0 + lvl * 30.0)

	if _owned_weapons["bombardment"]:
		_bombardment_timer -= delta
		if _bombardment_timer <= 0.0:
			var lvl = _weapon_levels.get("bombardment", 1)
			_bombardment_timer = max(1.2, 3.2 - lvl * 0.4)
			var target_count = 2 + lvl
			var valid_targets := []
			for enemy in enemies:
				if is_instance_valid(enemy):
					valid_targets.append(enemy.global_position)
			while valid_targets.size() < target_count:
				valid_targets.append(player.global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300)))
			valid_targets.shuffle()
			for i in range(min(target_count, valid_targets.size())):
				var strike_pos = valid_targets[i]
				var bolt = _create_projectile(strike_pos, Vector2.RIGHT, "bombardment_strike", 0.0, 0.6, 50.0 + lvl * 10.0, 3 + lvl * 3)
				if is_instance_valid(bolt):
					bolt.custom_behavior = "bombardment_strike"
					bolt.piercing = true

	if _owned_weapons["hyper_beam"]:
		_hyper_beam_timer -= delta
		if _hyper_beam_timer <= 0.0:
			var lvl = _weapon_levels.get("hyper_beam", 1)
			_hyper_beam_timer = max(2.0, 5.0 - lvl * 0.5)
			var dir = player.aim_direction
			if dir.length() <= 0.0:
				dir = Vector2.RIGHT
			var bolt = _create_projectile(player.global_position, dir, "hyper_beam", 0.0, 0.8, 40.0 + lvl * 5.0, 1 + lvl)
			if is_instance_valid(bolt):
				bolt.custom_behavior = "hyper_beam"
				bolt.orbit_target = player
				bolt.direction = dir.normalized()
				bolt.piercing = true
				bolt.set_meta("tick_timer", 0.15)
				bolt.set_meta("damage_val", 1 + lvl)

	# Handle the continuous laser tick and body collision updates for hyper_beam
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt) and bolt.custom_behavior == "hyper_beam":
			if not bolt.has_meta("tick_timer"):
				bolt.set_meta("tick_timer", 0.0)
			var tick_t = bolt.get_meta("tick_timer") - delta
			if tick_t <= 0.0:
				tick_t = 0.15
				bolt.damaged_bodies.clear()
				if bolt.has_method("get_overlapping_bodies"):
					for body in bolt.get_overlapping_bodies():
						if body.has_method("damage") and body != player:
							if not body in bolt.damaged_bodies:
								bolt.damaged_bodies.append(body)
								body.damage(bolt.get_meta("damage_val") if bolt.has_meta("damage_val") else 2)
			bolt.set_meta("tick_timer", tick_t)

func _spawn_nova() -> void:
	var lvl = _weapon_levels.get("nova", 1)
	var count = 8 + (lvl - 1) * 2
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		_create_projectile(player.global_position, Vector2.RIGHT.rotated(angle), "*", 700.0, 0.85, 11.0, lvl)

func _spawn_spore() -> void:
	var lvl = _weapon_levels.get("spore", 1)
	var angles := [PI/4, 3*PI/4, 5*PI/4, 7*PI/4]
	if lvl >= 3:
		angles.append_array([0.0, PI/2, PI, 3*PI/2])
	for angle in angles:
		_create_projectile(player.global_position, Vector2.RIGHT.rotated(angle), ".", 350.0, 1.5, 8.0, lvl)

func _spawn_halo() -> void:
	var lvl = _weapon_levels.get("halo", 1)
	var count = 6 + (lvl - 1) * 2
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		_create_projectile(player.global_position, Vector2.RIGHT.rotated(angle), "o", 400.0, 1.4, 10.0, lvl)

func _create_projectile(origin: Vector2, direction: Vector2, symbol: String, speed: float, lifetime: float, radius: float, damage: int) -> Area2D:
	if direction.length() <= 0.0:
		return null
	var bolt = Area2D.new()
	bolt.name = "Bolt"
	bolt.add_to_group("bolts")
	bolt.set_script(BoltScript)
	bolt.setup(origin, direction.normalized())
	bolt.speed = speed
	bolt.lifetime = lifetime
	add_child(bolt)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	bolt.add_child(shape)
	match symbol:
		"-":
			if is_instance_valid(_player_bullet_texture):
				var sprite := Sprite2D.new()
				sprite.texture = _player_bullet_texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.modulate = Color(1.0, 0.9, 0.2)
				var tw := radius * 2.5
				sprite.scale = Vector2(tw / _player_bullet_texture.get_width(), tw / _player_bullet_texture.get_height())
				bolt.add_child(sprite)
			else:
				var line := Line2D.new()
				line.width = 4.0
				line.default_color = Color(0.95, 0.85, 0.15)
				line.points = [Vector2.ZERO, Vector2.LEFT * 20.0]
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				bolt.add_child(line)
		"\\", "/":
			if is_instance_valid(_player_bullet_texture):
				var sprite := Sprite2D.new()
				sprite.texture = _player_bullet_texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.modulate = Color(0.2, 0.7, 1.0)
				var tw := radius * 2.5
				sprite.scale = Vector2(tw / _player_bullet_texture.get_width(), tw / _player_bullet_texture.get_height())
				bolt.add_child(sprite)
			else:
				var line := Line2D.new()
				line.width = 4.0
				line.default_color = Color(0.2, 0.6, 0.95)
				line.points = [Vector2.ZERO, Vector2.LEFT * 20.0]
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				bolt.add_child(line)
		">":
			if is_instance_valid(_player_bullet_texture):
				var sprite := Sprite2D.new()
				sprite.texture = _player_bullet_texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.modulate = Color(1.0, 0.2, 0.2)
				var tw := radius * 2.5
				sprite.scale = Vector2(tw / _player_bullet_texture.get_width(), tw / _player_bullet_texture.get_height())
				bolt.add_child(sprite)
			else:
				var line := Line2D.new()
				line.width = 6.0
				line.default_color = Color(0.95, 0.2, 0.2)
				line.points = [Vector2.ZERO, Vector2.LEFT * 22.0]
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				bolt.add_child(line)
		"~":
			if is_instance_valid(_player_bullet_texture):
				var sprite := Sprite2D.new()
				sprite.texture = _player_bullet_texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.modulate = Color(0.2, 1.0, 0.4)
				var tw := radius * 2.5
				sprite.scale = Vector2(tw / _player_bullet_texture.get_width(), tw / _player_bullet_texture.get_height())
				bolt.add_child(sprite)
			else:
				var line := Line2D.new()
				line.width = 4.0
				line.default_color = Color(0.2, 0.9, 0.4)
				line.points = [Vector2.ZERO, Vector2.LEFT * 12.0, Vector2.LEFT * 24.0]
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				bolt.add_child(line)
		")":
			var blade := Line2D.new()
			blade.width = 6.0
			blade.default_color = Color(0.85, 0.2, 0.95)
			var points := PackedVector2Array()
			var steps := 8
			for i in range(steps):
				var angle := PI * float(i) / float(steps - 1) - PI/2
				points.append(Vector2(cos(angle), sin(angle)) * radius)
			blade.points = points
			blade.begin_cap_mode = Line2D.LINE_CAP_ROUND
			blade.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(blade)
		">>>":
			bolt.rotation_speed = 18.0
			var drill := Polygon2D.new()
			drill.color = Color(0.7, 0.7, 0.8)
			drill.polygon = [
				Vector2(radius * 1.5, 0),
				Vector2(0, -radius * 0.5),
				Vector2(-radius * 0.3, 0),
				Vector2(0, radius * 0.5)
			]
			bolt.add_child(drill)
			
			var spiral := Line2D.new()
			spiral.width = 3.0
			spiral.default_color = Color(0.95, 0.95, 1.0)
			spiral.points = [Vector2(-radius * 0.3, 0), Vector2(radius * 0.5, 0), Vector2(radius * 1.5, 0)]
			bolt.add_child(spiral)
		"\\\\/":
			var whip := Line2D.new()
			whip.width = 5.0
			whip.default_color = Color(0.15, 0.65, 0.25)
			whip.points = [Vector2.ZERO, Vector2.LEFT * radius * 0.5, Vector2.LEFT * radius]
			whip.begin_cap_mode = Line2D.LINE_CAP_ROUND
			whip.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(whip)
			
			for i in range(2):
				var thorn := Polygon2D.new()
				thorn.color = Color(0.8, 0.9, 0.2)
				thorn.position = Vector2.LEFT * (radius * 0.4 * (i + 1))
				thorn.polygon = [Vector2(0, -4), Vector2(6, -8), Vector2(4, 0)]
				bolt.add_child(thorn)
		"V":
			var l_line := Line2D.new()
			l_line.width = 7.0
			l_line.default_color = Color(1.0, 1.0, 0.3)
			l_line.points = [
				Vector2(0, -320),
				Vector2(randf_range(-15, 15), -240),
				Vector2(randf_range(-15, 15), -160),
				Vector2(randf_range(-15, 15), -80),
				Vector2.ZERO
			]
			l_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			l_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(l_line)
			
			var l_core := Line2D.new()
			l_core.width = 3.0
			l_core.default_color = Color(1.0, 1.0, 1.0)
			l_core.points = l_line.points
			bolt.add_child(l_core)
		"Ψ", "ψ":
			var fork := Line2D.new()
			fork.width = 4.0
			fork.default_color = Color(0.25, 0.8, 0.9)
			fork.points = [
				Vector2(-15, -12),
				Vector2(10, -12),
				Vector2(20, -12),
				Vector2(10, -12),
				Vector2(10, 0),
				Vector2(25, 0),
				Vector2(10, 0),
				Vector2(10, 12),
				Vector2(20, 12)
			]
			bolt.add_child(fork)
			
			var shaft := Line2D.new()
			shaft.width = 3.0
			shaft.default_color = Color(0.6, 0.5, 0.4)
			shaft.points = [Vector2(10, 0), Vector2(-15, 0)]
			bolt.add_child(shaft)
		"f":
			bolt.rotation_speed = 3.0
			var fire := Polygon2D.new()
			fire.color = Color(0.9, 0.25, 0.1)
			var points := PackedVector2Array()
			var steps := 8
			for i in range(steps):
				var angle := TAU * float(i) / float(steps)
				var r := radius * (0.8 + randf() * 0.4)
				points.append(Vector2(cos(angle), sin(angle)) * r)
			fire.polygon = points
			bolt.add_child(fire)
			
			var fire_inner := Polygon2D.new()
			fire_inner.color = Color(0.95, 0.75, 0.1)
			var inner_points := PackedVector2Array()
			for i in range(steps):
				var angle := TAU * float(i) / float(steps)
				var r := radius * 0.5 * (0.8 + randf() * 0.4)
				inner_points.append(Vector2(cos(angle), sin(angle)) * r)
			fire_inner.polygon = inner_points
			bolt.add_child(fire_inner)
		"@":
			bolt.rotation_speed = -4.5
			var aura := Polygon2D.new()
			aura.color = Color(0.4, 0.1, 0.85, 0.75)
			var a_points := PackedVector2Array()
			var steps := 16
			for i in range(steps):
				var angle := TAU * float(i) / float(steps)
				var r := radius * (0.9 + sin(angle * 4.0) * 0.1)
				a_points.append(Vector2(cos(angle), sin(angle)) * r)
			aura.polygon = a_points
			bolt.add_child(aura)
			
			var core := Polygon2D.new()
			core.color = Color(0.02, 0.02, 0.04, 1.0)
			var c_points := PackedVector2Array()
			for i in range(steps):
				var angle := TAU * float(i) / float(steps)
				c_points.append(Vector2(cos(angle), sin(angle)) * (radius * 0.5))
			core.polygon = c_points
			bolt.add_child(core)
		".":
			if is_instance_valid(_player_bullet_texture):
				var sprite := Sprite2D.new()
				sprite.texture = _player_bullet_texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.modulate = Color(0.9, 0.85, 0.7)
				var tw := radius * 2.2
				sprite.scale = Vector2(tw / _player_bullet_texture.get_width(), tw / _player_bullet_texture.get_height())
				bolt.add_child(sprite)
			else:
				bolt.rotation_speed = 6.0
				for i in range(8):
					var dot := ColorRect.new()
					dot.color = Color(0.85, 0.75, 0.55)
					dot.size = Vector2(4, 4)
					var angle := TAU * float(i) / 8.0
					dot.position = Vector2(cos(angle), sin(angle)) * radius - Vector2(2, 2)
					bolt.add_child(dot)
		"katana":
			var katana_blade := Line2D.new()
			katana_blade.width = 6.0
			katana_blade.default_color = Color(0.75, 0.9, 1.0)
			var katana_points := PackedVector2Array()
			var katana_steps := 10
			for i in range(katana_steps):
				var angle := -1.2 + 2.4 * float(i) / float(katana_steps - 1)
				katana_points.append(Vector2(cos(angle), sin(angle)) * radius)
			katana_blade.points = katana_points
			katana_blade.begin_cap_mode = Line2D.LINE_CAP_ROUND
			katana_blade.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(katana_blade)
			
			var katana_core := Line2D.new()
			katana_core.width = 2.0
			katana_core.default_color = Color(1.0, 1.0, 1.0)
			katana_core.points = katana_points
			katana_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
			katana_core.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(katana_core)
		"boomerang":
			bolt.rotation_speed = 15.0
			var boom_shape := Line2D.new()
			boom_shape.width = 5.0
			boom_shape.default_color = Color(1.0, 0.7, 0.2)
			boom_shape.points = [
				Vector2(-12, -8),
				Vector2(12, 0),
				Vector2(-12, 8)
			]
			boom_shape.begin_cap_mode = Line2D.LINE_CAP_ROUND
			boom_shape.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(boom_shape)
		"shockwave":
			var shock_ring := Line2D.new()
			shock_ring.width = 6.0
			shock_ring.default_color = Color(0.3, 0.6, 1.0, 0.7)
			var shock_points := PackedVector2Array()
			var shock_steps := 24
			for i in range(shock_steps + 1):
				var angle = TAU * float(i) / float(shock_steps)
				shock_points.append(Vector2(cos(angle), sin(angle)) * 1.0)
			shock_ring.points = shock_points
			shock_ring.name = "Ring"
			bolt.add_child(shock_ring)
		"bombardment_strike":
			var bomb_ivis := Node2D.new()
			bomb_ivis.name = "IndicatorVisuals"
			bolt.add_child(bomb_ivis)
			
			var bomb_ring := Line2D.new()
			bomb_ring.width = 3.0
			bomb_ring.default_color = Color(1.0, 0.2, 0.2, 0.6)
			var bomb_rpoints := PackedVector2Array()
			var bomb_steps := 18
			for i in range(bomb_steps + 1):
				var angle = TAU * float(i) / float(bomb_steps)
				bomb_rpoints.append(Vector2(cos(angle), sin(angle)) * radius)
			bomb_ring.points = bomb_rpoints
			bomb_ivis.add_child(bomb_ring)
			
			var bomb_hline := Line2D.new()
			bomb_hline.width = 2.0
			bomb_hline.default_color = Color(1.0, 0.2, 0.2, 0.6)
			bomb_hline.points = [Vector2(-radius * 1.2, 0), Vector2(radius * 1.2, 0)]
			bomb_ivis.add_child(bomb_hline)
			
			var bomb_vline := Line2D.new()
			bomb_vline.width = 2.0
			bomb_vline.default_color = Color(1.0, 0.2, 0.2, 0.6)
			bomb_vline.points = [Vector2(0, -radius * 1.2), Vector2(0, radius * 1.2)]
			bomb_ivis.add_child(bomb_vline)
			
			for child in bolt.get_children():
				if child is CollisionShape2D:
					child.disabled = true
					
			var bomb_evis := Node2D.new()
			bomb_evis.name = "ExplosionVisuals"
			bomb_evis.visible = false
			bolt.add_child(bomb_evis)
			
			var bomb_circle := Polygon2D.new()
			bomb_circle.color = Color(1.0, 0.4, 0.1, 0.8)
			var bomb_cpoints := PackedVector2Array()
			for i in range(bomb_steps):
				var angle = TAU * float(i) / float(bomb_steps)
				bomb_cpoints.append(Vector2(cos(angle), sin(angle)) * radius)
			bomb_circle.polygon = bomb_cpoints
			bomb_evis.add_child(bomb_circle)
			
			var bomb_ering := Line2D.new()
			bomb_ering.width = 4.0
			bomb_ering.default_color = Color(1.0, 0.9, 0.3)
			bomb_ering.points = bomb_rpoints
			bomb_evis.add_child(bomb_ering)
		"hyper_beam":
			var beam_line := Line2D.new()
			beam_line.width = radius * 2.0
			beam_line.default_color = Color(0.2, 0.9, 1.0, 0.85)
			beam_line.points = [Vector2.ZERO, Vector2.RIGHT * 850.0]
			beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(beam_line)
			
			var beam_core := Line2D.new()
			beam_core.width = radius * 0.8
			beam_core.default_color = Color(1.0, 1.0, 1.0, 1.0)
			beam_core.points = beam_line.points
			beam_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
			beam_core.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(beam_core)
			
			for child in bolt.get_children():
				if child is CollisionShape2D:
					var beam_rect := RectangleShape2D.new()
					beam_rect.size = Vector2(850.0, radius * 2.0)
					child.shape = beam_rect
					child.position = Vector2.RIGHT * 425.0
		_:
			var line := Line2D.new()
			line.width = 4.0
			line.default_color = Color(0.95, 0.95, 0.95)
			line.points = [Vector2.ZERO, Vector2.LEFT * 20.0]
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			bolt.add_child(line)

	bolt.body_entered.connect(func(body: Node) -> void:
		if body.has_method("damage") and body != player:
			if "piercing" in bolt and bolt.piercing:
				if body in bolt.damaged_bodies:
					return
				bolt.damaged_bodies.append(body)
				body.damage(damage)
				if bolt.custom_behavior == "shockwave":
					if body.has_method("apply_knockback"):
						var push_dir = player.global_position.direction_to(body.global_position).normalized()
						var force = 450.0 + _weapon_levels.get("shockwave", 1) * 50.0
						body.apply_knockback(push_dir * force)
			else:
				body.damage(damage)
				bolt.queue_free()
	)
	return bolt

func _on_enemy_defeated(enemy: Node2D) -> void:
	enemies.erase(enemy)
	
	if enemy == boss_node:
		_on_boss_defeated(current_stage)
		return
		
	coins += randi_range(2, 5)
	
	# Split behavior for type E
	if is_instance_valid(enemy) and enemy.has_method("get") and enemy.get("enemy_type") == "E":
		_update_hud("Splitted! E type divided into two A types.")
		for i in range(2):
			var spawn_pos = enemy.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			spawn_pos.x = clamp(spawn_pos.x, -1450, 1450)
			spawn_pos.y = clamp(spawn_pos.y, -1450, 1450)
			_spawn_enemy(spawn_pos, "A")
			
	if enemies.is_empty():
		wave += 1
		_update_hud("Wave cleared. Visit $ shrine or keep fighting.")
		_spawn_wave()
	else:
		_update_hud("Coin gained.")

func _spin_slot() -> void:
	if _slot_is_spinning:
		return
	if coins < bet_amount:
		slot_result_label.text = "Need $" + str(bet_amount) + " run coins to spin."
		return
	coins -= bet_amount
	_slot_is_spinning = true
	slot_result_label.text = "Spinning..."
	
	var reels := [
		_slot_symbols.pick_random(),
		_slot_symbols.pick_random(),
		_slot_symbols.pick_random(),
	]
	_reel_target_symbols = reels
	for i in range(3):
		_reel_targets[i] = _slot_symbols.find(reels[i])
		_reel_states[i] = ReelState.SPINNING
		_reel_speeds[i] = 1200.0
		_auto_stop_timers[i] = 3.0 + i * 1.5
	
	_play_sfx("lever")
	var tween := create_tween()
	tween.tween_property(_lever_shaft, "rotation_degrees", 45.0, 0.15)
	tween.tween_property(_lever_shaft, "rotation_degrees", 0.0, 0.15)
	
	_set_slot_buttons_disabled(true)
	_refresh_gamble_ui()
	_update_hud("Pull! Reels are spinning.")

func _set_gamble_game(next_game: int) -> void:
	if _blackjack_active and next_game != GambleGame.BLACKJACK:
		blackjack_result_label.text = "Finish this hand before switching games."
		return
	if _crash_active and next_game != GambleGame.CRASH:
		return
	gamble_game = next_game
	var showing_slot := gamble_game == GambleGame.SLOT
	var showing_blackjack := gamble_game == GambleGame.BLACKJACK
	var showing_poker := gamble_game == GambleGame.POKER
	var showing_race := gamble_game == GambleGame.ANGEL_RACE
	var showing_dice := gamble_game == GambleGame.DICE
	var showing_wheel := gamble_game == GambleGame.WHEEL
	var showing_hilo := gamble_game == GambleGame.HILO
	var showing_pearl := gamble_game == GambleGame.PEARL
	var showing_crash := gamble_game == GambleGame.CRASH
	slot_tab_button.visible = current_stage == Stage.FIELD
	blackjack_tab_button.visible = current_stage == Stage.FIELD
	slot_tab_button.text = "SLOT *" if showing_slot else "SLOT"
	blackjack_tab_button.text = "BLACKJACK *" if showing_blackjack else "BLACKJACK"
	slot_machine_parent.visible = showing_slot
	slot_result_label.visible = showing_slot
	spin_button.visible = showing_slot
	blackjack_board_parent.visible = showing_blackjack
	poker_board_parent.visible = showing_poker
	race_board_parent.visible = showing_race
	dice_board_parent.visible = showing_dice
	wheel_board_parent.visible = showing_wheel
	hilo_board_parent.visible = showing_hilo
	pearl_board_parent.visible = showing_pearl
	crash_board_parent.visible = showing_crash
	
	if showing_slot:
		slot_result_label.text = "Match 3 on 8 lines to win. Payouts vary by symbol."
	elif showing_blackjack:
		_refresh_blackjack_view(false)
	elif showing_poker:
		_poker_state = "DEAL"
		poker_hand_label.text = "Cave Poker"
		poker_result_label.text = "Pair of Jacks or Better returns bet. Better hands pay more."
		_draw_poker_visuals(_poker_card_container, ["?", "?", "?", "?", "?"], true)
	elif showing_race:
		_race_active = false
		_race_positions = [10.0, 10.0, 10.0]
		race_track_label.text = "SERAPH / HALO / FEATHER"
		race_result_label.text = "Pick an angel. Winner pays 3x."
		_draw_race_visuals()
	elif showing_dice:
		dice_label.text = "Devil's Dice"
		dice_result_label.text = "Devil's Dice. Roll 7 or 12 to win 3x, 9 or 11 to win 2x. 4,6,8,10 push."
		_draw_dice_visuals(1, 1, true)
	elif showing_wheel:
		wheel_label.text = "[ 0x | 0.5x | 1x | 1.5x | 2x | 3x | 5x | 0x ]"
		wheel_result_label.text = "Forest Wheel. Spin to win multipliers from 0x to 5x."
	elif showing_hilo:
		_hilo_current_card = randi_range(1, 13)
		hilo_card_label.text = "Hi-Lo Card"
		hilo_result_label.text = "Guess if next card is HIGHER or LOWER than current. Win pays 2x."
		_draw_hilo_visuals(_hilo_card_container, _hilo_current_card, 0, true)
	elif showing_pearl:
		_pearl_revealed = false
		_pearl_picked_idx = -1
		oyster_label.text = "🦪 Pick an Oyster!"
		oyster_result_label.text = "Pearl Oyster. Pick one! Empty = 0x, Silver = 2x, Golden = 5x."
		_draw_oyster_visuals()
	elif showing_crash:
		_crash_active = false
		_crash_multiplier = 1.0
		crash_multiplier_label.text = "CRASH MULTIPLIER:  1.00x"
		crash_result_label.text = "Cosmic Crash. Cashout before the rocket crashes! Max payout 10x."
		_draw_crash_visuals()
	
	if is_instance_valid(exit_button):
		if showing_slot:
			exit_button.position.y = 890.0
		else:
			exit_button.position.y = 720.0
			
	_refresh_gamble_ui()

func _change_bet(delta: int) -> void:
	if _blackjack_active:
		blackjack_result_label.text = "Finish this hand before changing bet."
		return
	if _crash_active:
		return
	var max_bet: int = maxi(5, coins)
	bet_amount = clampi(bet_amount + delta, 5, max_bet)
	_refresh_gamble_ui()
	if gamble_game == GambleGame.SLOT:
		slot_result_label.text = "Bet changed. Match 2 for 2x, match 3 for 6x."
	elif gamble_game == GambleGame.BLACKJACK:
		blackjack_result_label.text = "Bet changed. Deal when ready."
	elif gamble_game == GambleGame.POKER:
		poker_result_label.text = "Bet changed. Draw when ready."
	elif gamble_game == GambleGame.ANGEL_RACE:
		race_result_label.text = "Bet changed. Pick an angel."
	elif gamble_game == GambleGame.DICE:
		dice_result_label.text = "Bet changed. Roll dice when ready."
	elif gamble_game == GambleGame.WHEEL:
		wheel_result_label.text = "Bet changed. Spin wheel when ready."
	elif gamble_game == GambleGame.HILO:
		hilo_result_label.text = "Bet changed. Guess higher or lower."
	elif gamble_game == GambleGame.PEARL:
		oyster_result_label.text = "Bet changed. Pick an oyster."
	elif gamble_game == GambleGame.CRASH:
		crash_result_label.text = "Bet changed. Launch when ready."

func _refresh_gamble_ui() -> void:
	gamble_money_label.text = "RUN $ " + str(coins)
	gamble_bet_label.text = "BET $" + str(bet_amount)
	spin_button.text = "SPIN  $" + str(bet_amount)
	deal_button.text = "DEAL  $" + str(bet_amount)
	poker_deal_button.text = ("DRAW  $" if _poker_state == "DRAW" else "DEAL  $") + str(bet_amount)
	angel_a_button.text = "SERAPH $" + str(bet_amount)
	angel_b_button.text = "HALO $" + str(bet_amount)
	angel_c_button.text = "FEATHER $" + str(bet_amount)
	
	dice_roll_button.text = "ROLL DICE  $" + str(bet_amount)
	wheel_spin_button.text = "SPIN WHEEL  $" + str(bet_amount)
	hilo_higher_button.text = "HIGHER  $" + str(bet_amount)
	hilo_lower_button.text = "LOWER  $" + str(bet_amount)
	for i in range(5):
		oyster_buttons[i].text = "🦪 " + str(i+1) + " $" + str(bet_amount)
	crash_launch_button.text = "LAUNCH  $" + str(bet_amount)
	
	var is_gambling_locked := _blackjack_active or _crash_active or _slot_is_spinning or _race_active or _wheel_anim_active
	decrease_bet_button.disabled = bet_amount <= 5 or is_gambling_locked
	increase_bet_button.disabled = bet_amount >= coins or is_gambling_locked
	exit_button.disabled = is_gambling_locked
	
	spin_button.disabled = gamble_game != GambleGame.SLOT or coins < bet_amount or _slot_is_spinning
	deal_button.disabled = gamble_game != GambleGame.BLACKJACK or _blackjack_active or coins < bet_amount
	hit_button.disabled = gamble_game != GambleGame.BLACKJACK or not _blackjack_active
	stand_button.disabled = gamble_game != GambleGame.BLACKJACK or not _blackjack_active
	
	deal_button.visible = not _blackjack_active
	hit_button.visible = _blackjack_active
	stand_button.visible = _blackjack_active
	poker_deal_button.disabled = gamble_game != GambleGame.POKER or (coins < bet_amount and _poker_state == "DEAL")
	angel_a_button.disabled = gamble_game != GambleGame.ANGEL_RACE or _race_active or coins < bet_amount
	angel_b_button.disabled = gamble_game != GambleGame.ANGEL_RACE or _race_active or coins < bet_amount
	angel_c_button.disabled = gamble_game != GambleGame.ANGEL_RACE or _race_active or coins < bet_amount
	
	dice_roll_button.disabled = gamble_game != GambleGame.DICE or coins < bet_amount
	wheel_spin_button.disabled = gamble_game != GambleGame.WHEEL or _wheel_anim_active or coins < bet_amount
	hilo_higher_button.disabled = gamble_game != GambleGame.HILO or coins < bet_amount
	hilo_lower_button.disabled = gamble_game != GambleGame.HILO or coins < bet_amount
	for btn in oyster_buttons:
		btn.disabled = gamble_game != GambleGame.PEARL or _pearl_revealed or coins < bet_amount
	crash_launch_button.disabled = gamble_game != GambleGame.CRASH or _crash_active or coins < bet_amount
	crash_cashout_button.disabled = gamble_game != GambleGame.CRASH or not _crash_active

func _start_blackjack_hand() -> void:
	if _blackjack_active:
		return
	if coins < bet_amount:
		blackjack_result_label.text = "Need $" + str(bet_amount) + " run coins to deal."
		return
	coins -= bet_amount
	_blackjack_active = true
	_player_cards = [_draw_card(), _draw_card()]
	_dealer_cards = [_draw_card(), _draw_card()]
	blackjack_result_label.text = "Hit or stand."
	_play_sfx("deal")
	if _hand_value(_player_cards) == 21:
		_finish_blackjack("BLACKJACK +" + str(bet_amount * 3) + " run coins.", bet_amount * 3)
	else:
		_refresh_blackjack_view(false)
		_refresh_gamble_ui()
	_update_hud("Blackjack hand started.")

func _blackjack_hit() -> void:
	if not _blackjack_active:
		return
	_player_cards.append(_draw_card())
	_play_sfx("hit")
	if _hand_value(_player_cards) > 21:
		_finish_blackjack("BUST. Lost $" + str(bet_amount) + ".", 0)
	else:
		blackjack_result_label.text = "Hit or stand."
		_refresh_blackjack_view(false)

func _blackjack_stand() -> void:
	if not _blackjack_active:
		return
	while _hand_value(_dealer_cards) < 17:
		_dealer_cards.append(_draw_card())
	_play_sfx("deal")
	var player_value := _hand_value(_player_cards)
	var dealer_value := _hand_value(_dealer_cards)
	if dealer_value > 21 or player_value > dealer_value:
		_finish_blackjack("WIN +" + str(bet_amount * 2) + " run coins.", bet_amount * 2)
	elif player_value == dealer_value:
		_finish_blackjack("PUSH. Bet returned.", bet_amount)
	else:
		_finish_blackjack("LOSE. Dealer has " + str(dealer_value) + ".", 0)

func _finish_blackjack(message: String, payout: int) -> void:
	coins += payout
	_blackjack_active = false
	blackjack_result_label.text = message
	_refresh_blackjack_view(true)
	_refresh_gamble_ui()
	_update_hud("Blackjack resolved.")
	
	if payout > bet_amount:
		_play_sfx("win")
		_trigger_coin_shower()
		_bounce_label(blackjack_result_label)
	elif payout == bet_amount:
		_play_sfx("push")
	else:
		_play_sfx("lose")

func _refresh_blackjack_view(reveal_dealer: bool) -> void:
	if _dealer_cards.is_empty():
		dealer_hand_label.text = "DEALER: --"
		for child in _dealer_card_container.get_children():
			child.queue_free()
	else:
		var dealer_text := _format_hand(_dealer_cards)
		var is_hidden := _blackjack_active and not reveal_dealer
		if is_hidden:
			dealer_text = _card_text(_dealer_cards[0]) + " [?]"
		dealer_hand_label.text = "DEALER: " + dealer_text
		_draw_card_visuals(_dealer_card_container, _dealer_cards, is_hidden)
		
	if _player_cards.is_empty():
		blackjack_hand_label.text = "YOU: --"
		for child in _player_card_container.get_children():
			child.queue_free()
	else:
		blackjack_hand_label.text = "YOU: " + _format_hand(_player_cards) + " = " + str(_hand_value(_player_cards))
		_draw_card_visuals(_player_card_container, _player_cards, false)
		
	if not _blackjack_active and _player_cards.is_empty():
		blackjack_result_label.text = "Deal blackjack with run coins."

func _draw_card_visuals(container: Control, cards: Array, hide_second_card: bool) -> void:
	for child in container.get_children():
		child.queue_free()
		
	for i in range(cards.size()):
		var card_val: int = cards[i]
		var card_rect := ColorRect.new()
		card_rect.size = Vector2(55, 80)
		card_rect.position = Vector2(i * 65, 5)
		container.add_child(card_rect)
		
		_add_border(card_rect, Vector2(55, 80), Color(0.7, 0.7, 0.7), 1.0)
		
		if i == 1 and hide_second_card:
			card_rect.color = Color(0.6, 0.1, 0.1) # Dark red card back
			_add_border(card_rect, Vector2(55, 80), Color(0.9, 0.75, 0.1), 3.0)
			
			var pattern := Label.new()
			pattern.text = "◆"
			pattern.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pattern.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pattern.size = Vector2(55, 80)
			pattern.position = Vector2(0, 0)
			pattern.add_theme_font_size_override("font_size", 20)
			pattern.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
			card_rect.add_child(pattern)
		else:
			card_rect.color = Color(0.98, 0.98, 0.98) # White card front
			
			var val_label := Label.new()
			var txt := _card_text(card_val)
			val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			val_label.size = Vector2(55, 80)
			val_label.position = Vector2(0, 0)
			val_label.add_theme_font_size_override("font_size", 22)
			
			var suit := "♠"
			var s_mod := card_val % 4
			if s_mod == 0:
				suit = "♠"
			elif s_mod == 1:
				suit = "♥"
			elif s_mod == 2:
				suit = "♣"
			else:
				suit = "♦"
				
			var color := Color(0.1, 0.1, 0.1)
			if suit == "♥" or suit == "♦":
				color = Color(0.8, 0.1, 0.1)
				
			val_label.text = txt + "\n" + suit
			val_label.add_theme_color_override("font_color", color)
			card_rect.add_child(val_label)

func _draw_poker_visuals(container: Control, hand: Array, hide_all: bool) -> void:
	for child in container.get_children():
		child.queue_free()
		
	for i in range(hand.size()):
		var card_rect := ColorRect.new()
		card_rect.size = Vector2(55, 80)
		card_rect.position = Vector2(i * 65 + 10, 5)
		container.add_child(card_rect)
		_add_border(card_rect, Vector2(55, 80), Color(0.7, 0.7, 0.7), 1.0)
		
		if hide_all:
			card_rect.color = Color(0.6, 0.1, 0.1) # Red card back
			_add_border(card_rect, Vector2(55, 80), Color(0.9, 0.75, 0.1), 3.0)
			var pattern := Label.new()
			pattern.text = "◆"
			pattern.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pattern.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pattern.size = Vector2(55, 80)
			pattern.position = Vector2(0, 0)
			pattern.add_theme_font_size_override("font_size", 20)
			pattern.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
			card_rect.add_child(pattern)
		else:
			var card_data = hand[i]
			var rank_str := ""
			var suit_str := "♠"
			if card_data is Dictionary:
				rank_str = card_data.rank
				suit_str = card_data.suit
			else:
				rank_str = str(card_data)
				
			card_rect.color = Color(0.98, 0.98, 0.98) # White card front
			var val_label := Label.new()
			val_label.text = rank_str + "\n" + suit_str
			val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			val_label.size = Vector2(55, 80)
			val_label.position = Vector2(0, 0)
			val_label.add_theme_font_size_override("font_size", 22)
			
			var color := Color(0.1, 0.1, 0.1)
			if suit_str == "♥" or suit_str == "♦":
				color = Color(0.8, 0.1, 0.1)
				
			val_label.add_theme_color_override("font_color", color)
			card_rect.add_child(val_label)
			
			if _poker_held_cards[i]:
				var hold_rect := ColorRect.new()
				hold_rect.size = Vector2(55, 20)
				hold_rect.position = Vector2(0, 60)
				hold_rect.color = Color(0.1, 0.6, 0.1, 0.9) # Semi-translucent green
				card_rect.add_child(hold_rect)
				
				var hold_label := Label.new()
				hold_label.text = "HELD"
				hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				hold_label.size = Vector2(55, 20)
				hold_label.position = Vector2(0, 0)
				hold_label.add_theme_font_size_override("font_size", 12)
				hold_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
				hold_rect.add_child(hold_label)
				
			if _poker_state == "DRAW":
				var click_btn := Button.new()
				click_btn.size = Vector2(55, 80)
				click_btn.position = Vector2(0, 0)
				click_btn.flat = true
				click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				card_rect.add_child(click_btn)
				click_btn.pressed.connect(_toggle_poker_card_hold.bind(i))

func _toggle_poker_card_hold(index: int) -> void:
	if _poker_state != "DRAW":
		return
	_poker_held_cards[index] = not _poker_held_cards[index]
	_play_sfx("hit")
	_draw_poker_visuals(_poker_card_container, _poker_current_hand, false)

func _draw_dice_visuals(val1: int, val2: int, hide_dots: bool) -> void:
	_draw_die_dots(_dice1_rect, val1, hide_dots)
	_draw_die_dots(_dice2_rect, val2, hide_dots)

func _draw_die_dots(die_rect: ColorRect, val: int, hide: bool) -> void:
	for child in die_rect.get_children():
		child.queue_free()
		
	if hide:
		var question := Label.new()
		question.text = "?"
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.size = Vector2(70, 70)
		question.position = Vector2(0, 0)
		question.add_theme_font_size_override("font_size", 30)
		question.add_theme_color_override("font_color", Color(1, 1, 1))
		die_rect.add_child(question)
		return
		
	var dots_pos := {
		"center": Vector2(35, 35),
		"tl": Vector2(20, 20),
		"br": Vector2(50, 50),
		"tr": Vector2(50, 20),
		"bl": Vector2(20, 50),
		"ml": Vector2(20, 35),
		"mr": Vector2(50, 35)
	}
	
	var active_dots := []
	match val:
		1:
			active_dots = [dots_pos["center"]]
		2:
			active_dots = [dots_pos["tl"], dots_pos["br"]]
		3:
			active_dots = [dots_pos["tl"], dots_pos["center"], dots_pos["br"]]
		4:
			active_dots = [dots_pos["tl"], dots_pos["br"], dots_pos["tr"], dots_pos["bl"]]
		5:
			active_dots = [dots_pos["tl"], dots_pos["br"], dots_pos["tr"], dots_pos["bl"], dots_pos["center"]]
		6:
			active_dots = [dots_pos["tl"], dots_pos["br"], dots_pos["tr"], dots_pos["bl"], dots_pos["ml"], dots_pos["mr"]]
			
	for pos in active_dots:
		var dot := ColorRect.new()
		dot.size = Vector2(10, 10)
		dot.position = pos - Vector2(5, 5)
		dot.color = Color(1.0, 1.0, 1.0)
		die_rect.add_child(dot)

func _draw_hilo_visuals(container: Control, cur_val: int, next_val: int, hide_next: bool) -> void:
	for child in container.get_children():
		child.queue_free()
		
	var card1 := ColorRect.new()
	card1.size = Vector2(55, 80)
	card1.position = Vector2(130, 5)
	container.add_child(card1)
	_add_border(card1, Vector2(55, 80), Color(0.7, 0.7, 0.7), 1.0)
	card1.color = Color(0.98, 0.98, 0.98)
	
	var val1_label := Label.new()
	var txt1 := _card_text(cur_val)
	val1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val1_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val1_label.size = Vector2(55, 80)
	val1_label.position = Vector2(0, 0)
	val1_label.add_theme_font_size_override("font_size", 22)
	
	var suit1 := "♥" if cur_val % 2 == 0 else "♠"
	var color1 := Color(0.8, 0.1, 0.1) if suit1 == "♥" else Color(0.1, 0.1, 0.1)
	val1_label.text = txt1 + "\n" + suit1
	val1_label.add_theme_color_override("font_color", color1)
	card1.add_child(val1_label)
	
	var card2 := ColorRect.new()
	card2.size = Vector2(55, 80)
	card2.position = Vector2(250, 5)
	container.add_child(card2)
	_add_border(card2, Vector2(55, 80), Color(0.7, 0.7, 0.7), 1.0)
	
	if hide_next:
		card2.color = Color(0.6, 0.1, 0.1)
		_add_border(card2, Vector2(55, 80), Color(0.9, 0.75, 0.1), 3.0)
		var pattern := Label.new()
		pattern.text = "◆"
		pattern.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pattern.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pattern.size = Vector2(55, 80)
		pattern.position = Vector2(0, 0)
		pattern.add_theme_font_size_override("font_size", 20)
		pattern.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
		card2.add_child(pattern)
	else:
		card2.color = Color(0.98, 0.98, 0.98)
		var val2_label := Label.new()
		var txt2 := _card_text(next_val)
		val2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val2_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val2_label.size = Vector2(55, 80)
		val2_label.position = Vector2(0, 0)
		val2_label.add_theme_font_size_override("font_size", 22)
		
		var suit2 := "♦" if next_val % 2 == 0 else "♣"
		var color2 := Color(0.8, 0.1, 0.1) if suit2 == "♦" else Color(0.1, 0.1, 0.1)
		val2_label.text = txt2 + "\n" + suit2
		val2_label.add_theme_color_override("font_color", color2)
		card2.add_child(val2_label)

func _draw_race_visuals() -> void:
	if not is_instance_valid(_race_track_container):
		return
	for child in _race_track_container.get_children():
		child.queue_free()
		
	var lane_colors := [
		Color(0.2, 0.35, 0.55, 0.4),
		Color(0.2, 0.35, 0.55, 0.5),
		Color(0.2, 0.35, 0.55, 0.6)
	]
	var runner_names := ["Seraph", "Halo", "Feather"]
	var runner_colors := [
		Color(1.0, 0.85, 0.3),
		Color(0.9, 0.4, 0.4),
		Color(0.3, 0.8, 0.8)
	]
	
	for i in range(3):
		var lane_rect := ColorRect.new()
		lane_rect.size = Vector2(440, 45)
		lane_rect.position = Vector2(0, i * 55 + 5)
		lane_rect.color = lane_colors[i]
		_race_track_container.add_child(lane_rect)
		_add_border(lane_rect, Vector2(440, 45), Color(0.9, 0.9, 0.9, 0.2), 1.0)
		
		var finish_line := ColorRect.new()
		finish_line.size = Vector2(5, 45)
		finish_line.position = Vector2(380, 0)
		finish_line.color = Color(1.0, 1.0, 1.0, 0.8)
		lane_rect.add_child(finish_line)
		
		var runner_rect := ColorRect.new()
		runner_rect.size = Vector2(70, 35)
		runner_rect.position = Vector2(_race_positions[i], 5)
		runner_rect.color = runner_colors[i]
		lane_rect.add_child(runner_rect)
		_add_border(runner_rect, Vector2(70, 35), Color(1.0, 1.0, 1.0), 1.0)
		
		var runner_label := Label.new()
		runner_label.text = runner_names[i]
		runner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		runner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		runner_label.size = Vector2(70, 35)
		runner_label.position = Vector2(0, 0)
		runner_label.add_theme_font_size_override("font_size", 12)
		runner_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		runner_rect.add_child(runner_label)

func _draw_oyster_visuals() -> void:
	if not is_instance_valid(_pearl_oyster_container):
		return
	for child in _pearl_oyster_container.get_children():
		child.queue_free()
		
	for i in range(5):
		var shell_rect := ColorRect.new()
		shell_rect.size = Vector2(70, 70)
		shell_rect.position = Vector2(i * 85 + 10, 65)
		shell_rect.color = Color(0.15, 0.25, 0.4, 0.9)
		_pearl_oyster_container.add_child(shell_rect)
		
		var border_color = Color(0.7, 0.7, 0.7)
		var border_width = 1.0
		if _pearl_revealed and i == _pearl_picked_idx:
			border_color = Color(0.9, 0.75, 0.1)
			border_width = 3.0
		_add_border(shell_rect, Vector2(70, 70), border_color, border_width)
		
		var symbol_label := Label.new()
		symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol_label.size = Vector2(70, 70)
		symbol_label.position = Vector2(0, 0)
		symbol_label.add_theme_font_size_override("font_size", 28)
		
		if not _pearl_revealed:
			symbol_label.text = "🦪"
		else:
			var item = _pearl_layout[i]
			if item == "GOLDEN PEARL":
				symbol_label.text = "🟡"
				symbol_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1))
			elif item == "SILVER PEARL":
				symbol_label.text = "⚪"
				symbol_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			else:
				symbol_label.text = "❌"
				symbol_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				
		shell_rect.add_child(symbol_label)
		
		var click_btn := Button.new()
		click_btn.size = Vector2(70, 70)
		click_btn.position = Vector2(0, 0)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		shell_rect.add_child(click_btn)
		click_btn.pressed.connect(_pick_oyster.bind(i))

func _draw_crash_visuals() -> void:
	if not is_instance_valid(_crash_visual_container):
		return
	for child in _crash_visual_container.get_children():
		child.queue_free()
		
	var bg_grid := ColorRect.new()
	bg_grid.size = Vector2(440, 210)
	bg_grid.position = Vector2(0, 0)
	bg_grid.color = Color(0.01, 0.01, 0.05, 0.6)
	_crash_visual_container.add_child(bg_grid)
	_add_border(bg_grid, Vector2(440, 210), Color(0.2, 0.25, 0.4, 0.5), 1.0)
	
	for i in range(1, 4):
		var y_pos = i * 50
		var h_line := ColorRect.new()
		h_line.size = Vector2(440, 1)
		h_line.position = Vector2(0, y_pos)
		h_line.color = Color(0.2, 0.25, 0.4, 0.2)
		bg_grid.add_child(h_line)
	for i in range(1, 8):
		var x_pos = i * 55
		var v_line := ColorRect.new()
		v_line.size = Vector2(1, 210)
		v_line.position = Vector2(x_pos, 0)
		v_line.color = Color(0.2, 0.25, 0.4, 0.2)
		bg_grid.add_child(v_line)
		
	var progress: float = (_crash_multiplier - 1.0) / 9.0
	progress = clamp(progress, 0.0, 1.0)
	var rx: float = lerp(20.0, 380.0, progress)
	var ry: float = 180.0 - 150.0 * pow(progress, 1.5)
	
	var steps := int(progress * 15.0)
	for s in range(steps):
		var sp: float = float(s) / 15.0
		var sx: float = lerp(20.0, 380.0, sp)
		var sy: float = 180.0 - 150.0 * pow(sp, 1.5)
		
		var star := Label.new()
		star.text = "."
		star.size = Vector2(10, 10)
		star.position = Vector2(sx - 3, sy - 8)
		star.add_theme_font_size_override("font_size", 16)
		star.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.6))
		bg_grid.add_child(star)
		
	_rocket_icon = Label.new()
	_rocket_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rocket_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rocket_icon.size = Vector2(30, 30)
	_rocket_icon.position = Vector2(rx - 15, ry - 15)
	_rocket_icon.add_theme_font_size_override("font_size", 24)
	
	if not _crash_active:
		if _crash_multiplier >= _crash_point and _crash_point > 1.0:
			_rocket_icon.text = "💥"
		else:
			_rocket_icon.text = "🚀"
			if _crash_multiplier < _crash_point:
				_rocket_icon.position = Vector2(400, -20)
	else:
		_rocket_icon.text = "🚀"
		
	bg_grid.add_child(_rocket_icon)

func _evaluate_poker_hand(hand: Array) -> Dictionary:
	var sorted_hand = hand.duplicate()
	sorted_hand.sort_custom(func(a, b): return _poker_rank_values[a.rank] > _poker_rank_values[b.rank])
	
	var is_flush := true
	var target_suit: String = sorted_hand[0].suit
	for i in range(1, 5):
		if sorted_hand[i].suit != target_suit:
			is_flush = false
			break
			
	var is_straight := true
	for i in range(0, 4):
		var val_curr: int = _poker_rank_values[sorted_hand[i].rank]
		var val_next: int = _poker_rank_values[sorted_hand[i+1].rank]
		if val_curr - val_next != 1:
			is_straight = false
			break
			
	if not is_straight and _poker_rank_values[sorted_hand[0].rank] == 14 and _poker_rank_values[sorted_hand[1].rank] == 5 and _poker_rank_values[sorted_hand[2].rank] == 4 and _poker_rank_values[sorted_hand[3].rank] == 3 and _poker_rank_values[sorted_hand[4].rank] == 2:
		is_straight = true

	var counts := {}
	for card in sorted_hand:
		counts[card.rank] = counts.get(card.rank, 0) + 1
		
	var freq_list := []
	for rank in counts.keys():
		freq_list.append({"rank": rank, "count": counts[rank], "value": _poker_rank_values[rank]})
		
	freq_list.sort_custom(func(a, b):
		if a.count != b.count:
			return a.count > b.count
		return a.value > b.value
	)
	
	var payout_mult := 0
	var name := "HIGH CARD"
	
	if is_flush and is_straight:
		if _poker_rank_values[sorted_hand[0].rank] == 14 and _poker_rank_values[sorted_hand[4].rank] == 10:
			name = "ROYAL FLUSH"
			payout_mult = 50
		else:
			name = "STRAIGHT FLUSH"
			payout_mult = 25
	elif freq_list[0].count == 4:
		name = "FOUR OF A KIND"
		payout_mult = 15
	elif freq_list[0].count == 3 and freq_list.size() > 1 and freq_list[1].count == 2:
		name = "FULL HOUSE"
		payout_mult = 8
	elif is_flush:
		name = "FLUSH"
		payout_mult = 6
	elif is_straight:
		name = "STRAIGHT"
		payout_mult = 4
	elif freq_list[0].count == 3:
		name = "THREE OF A KIND"
		payout_mult = 3
	elif freq_list[0].count == 2 and freq_list.size() > 1 and freq_list[1].count == 2:
		name = "TWO PAIR"
		payout_mult = 2
	elif freq_list[0].count == 2:
		if freq_list[0].value >= 11:
			name = "JACKS OR BETTER"
			payout_mult = 1
		else:
			name = "PAIR (" + freq_list[0].rank + "s)"
			payout_mult = 0
			
	return {"name": name, "payout": payout_mult}

func _draw_card() -> int:
	return randi_range(1, 13)

func _format_hand(cards: Array) -> String:
	var pieces := PackedStringArray()
	for card in cards:
		pieces.append(_card_text(card))
	return " ".join(pieces)

func _card_text(card: int) -> String:
	if card == 1:
		return "A"
	if card == 11:
		return "J"
	if card == 12:
		return "Q"
	if card == 13:
		return "K"
	return str(card)

func _hand_value(cards: Array) -> int:
	var total := 0
	var aces := 0
	for card in cards:
		if card == 1:
			total += 11
			aces += 1
		elif card > 10:
			total += 10
		else:
			total += card
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _deal_poker() -> void:
	if coins < bet_amount and _poker_state == "DEAL":
		poker_result_label.text = "Need $" + str(bet_amount) + " run coins to deal."
		return
		
	if _poker_state == "DEAL":
		coins -= bet_amount
		_play_sfx("deal")
		
		_poker_deck.clear()
		for rank in _poker_ranks:
			for suit in _poker_suits:
				_poker_deck.append({"rank": rank, "suit": suit})
		_poker_deck.shuffle()
		
		_poker_current_hand.clear()
		for i in range(5):
			_poker_current_hand.append(_poker_deck.pop_back())
			
		for i in range(5):
			_poker_held_cards[i] = false
			
		_poker_state = "DRAW"
		poker_hand_label.text = "SELECT HELD CARDS"
		poker_result_label.text = "Select cards to HOLD, then press DRAW to replace others."
		_draw_poker_visuals(_poker_card_container, _poker_current_hand, false)
		_refresh_gamble_ui()
		_update_hud("Poker hand dealt.")
		
	elif _poker_state == "DRAW":
		_play_sfx("deal")
		
		for i in range(5):
			if not _poker_held_cards[i]:
				_poker_current_hand[i] = _poker_deck.pop_back()
				
		var evaluation = _evaluate_poker_hand(_poker_current_hand)
		var result_name: String = evaluation["name"]
		var payout_mult: int = evaluation["payout"]
		var payout := bet_amount * payout_mult
		
		coins += payout
		poker_hand_label.text = "FINAL HAND"
		_poker_state = "DEAL"
		
		_draw_poker_visuals(_poker_card_container, _poker_current_hand, false)
		
		if payout > 0:
			poker_result_label.text = result_name + "! +" + str(payout) + " run coins."
			_play_sfx("win")
			_trigger_coin_shower()
			_bounce_label(poker_result_label)
		else:
			poker_result_label.text = result_name + ". No payout."
			_play_sfx("lose")
			
		_refresh_gamble_ui()
		_update_hud("Poker hand resolved.")

func _bet_angel_race(choice: int) -> void:
	if _race_active:
		return
	if coins < bet_amount:
		race_result_label.text = "Need $" + str(bet_amount) + " run coins to race."
		return
	coins -= bet_amount
	_play_sfx("deal")
	
	_race_active = true
	_race_bet_choice = choice
	_race_positions = [10.0, 10.0, 10.0]
	_race_winner = -1
	
	race_track_label.text = "THE RACE IS ON! GO!"
	race_result_label.text = "Watch the track!"
	_draw_race_visuals()
	_refresh_gamble_ui()
	_update_hud("Angel race started.")

func _roll_dice() -> void:
	if coins < bet_amount:
		dice_result_label.text = "Need $" + str(bet_amount) + " run coins to roll."
		return
	coins -= bet_amount
	_play_sfx("stop")
	var die1 := randi_range(1, 6)
	var die2 := randi_range(1, 6)
	var sum := die1 + die2
	dice_label.text = "Devil's Dice  =  " + str(sum)
	_draw_dice_visuals(die1, die2, false)
	
	var payout := 0
	var outcome := ""
	if sum == 7 or sum == 12:
		payout = bet_amount * 3
		outcome = "DEVIL'S FAVOR! "
	elif sum == 9 or sum == 11:
		payout = bet_amount * 2
		outcome = "GREAT ROLL! "
	elif sum == 4 or sum == 6 or sum == 8 or sum == 10:
		payout = bet_amount
		outcome = "PUSH. "
	else:
		payout = 0
		outcome = "DEVIL CLAIMS IT. "
		
	coins += payout
	if payout > bet_amount:
		dice_result_label.text = outcome + "+" + str(payout) + " run coins."
		_play_sfx("win")
		_trigger_coin_shower()
		_bounce_label(dice_result_label)
	elif payout == bet_amount:
		dice_result_label.text = outcome + "Bet returned."
		_play_sfx("push")
	else:
		dice_result_label.text = outcome + "No payout."
		_play_sfx("lose")
		
	_refresh_gamble_ui()
	_update_hud("Devil's dice resolved.")
	
	if current_stage == Stage.HELL and sum == 12:
		_spawn_trigger_portal("HEAVEN GATE ^", Vector2(-330, -650), Stage.HEAVEN)
		_update_hud("Rolling double sixes opened a passage back to HEAVEN!")

func _spin_wheel() -> void:
	if _wheel_anim_active:
		return
	if coins < bet_amount:
		wheel_result_label.text = "Need $" + str(bet_amount) + " run coins to spin."
		return
	coins -= bet_amount
	_play_sfx("deal")
	
	var segments: Array[float] = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 0.0]
	_wheel_target_idx = randi_range(0, segments.size() - 1)
	_wheel_multiplier = segments[_wheel_target_idx]
	_wheel_payout = int(floor(bet_amount * _wheel_multiplier))
	
	var start_idx := _wheel_current_idx
	var steps_needed := 32 + (_wheel_target_idx - start_idx + 8) % 8
	
	_wheel_anim_active = true
	_wheel_steps_remaining = steps_needed
	_wheel_step_delay = 0.04
	_wheel_step_timer = 0.0
	
	wheel_result_label.text = "Spinning... Good luck!"
	_refresh_gamble_ui()
	_update_hud("Forest wheel spinning started.")

func _process_forest_wheel(delta: float) -> void:
	if not _wheel_anim_active:
		return
		
	_wheel_step_timer += delta
	if _wheel_step_timer >= _wheel_step_delay:
		_wheel_step_timer = 0.0
		_wheel_current_idx = (_wheel_current_idx + 1) % 8
		_wheel_steps_remaining -= 1
		
		_play_sfx("hit")
		
		var segments: Array[float] = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 0.0]
		var label_parts: Array[String] = []
		for i in range(segments.size()):
			if i == _wheel_current_idx:
				label_parts.append("▶" + str(segments[i]) + "x◀")
			else:
				label_parts.append(str(segments[i]) + "x")
		wheel_label.text = "[ " + " | ".join(PackedStringArray(label_parts)) + " ]"
		
		if _wheel_steps_remaining < 12:
			_wheel_step_delay += 0.04
		elif _wheel_steps_remaining < 24:
			_wheel_step_delay += 0.015
			
		if _wheel_steps_remaining <= 0:
			_wheel_anim_active = false
			coins += _wheel_payout
			
			if _wheel_payout > bet_amount:
				wheel_result_label.text = "WIN! Multiplier " + str(_wheel_multiplier) + "x -> +" + str(_wheel_payout) + " run coins."
				_play_sfx("win")
				_trigger_coin_shower()
				_bounce_label(wheel_result_label)
			elif _wheel_payout == bet_amount:
				wheel_result_label.text = "PUSH. Multiplier " + str(_wheel_multiplier) + "x -> Bet returned."
				_play_sfx("push")
			elif _wheel_payout > 0:
				wheel_result_label.text = "PARTIAL WIN. Multiplier " + str(_wheel_multiplier) + "x -> Returned " + str(_wheel_payout) + " run coins."
				_play_sfx("win")
				_trigger_coin_shower()
				_bounce_label(wheel_result_label)
			else:
				wheel_result_label.text = "LOSE! Multiplier 0x. Better luck next spin."
				_play_sfx("lose")
				
			_refresh_gamble_ui()
			_update_hud("Forest wheel resolved.")

func _play_hilo(guess_higher: bool) -> void:
	if coins < bet_amount:
		hilo_result_label.text = "Need $" + str(bet_amount) + " run coins to guess."
		return
	coins -= bet_amount
	
	var next_card := randi_range(1, 13)
	var win := false
	var push := false
	
	if next_card == _hilo_current_card:
		push = true
	elif guess_higher and next_card > _hilo_current_card:
		win = true
	elif not guess_higher and next_card < _hilo_current_card:
		win = true
		
	var payout := 0
	var old_card := _hilo_current_card
	if win:
		payout = bet_amount * 2
		coins += payout
		hilo_result_label.text = "Correct! " + _card_text(old_card) + " -> " + _card_text(next_card) + ". +" + str(payout) + " run coins."
		_play_sfx("win")
		_trigger_coin_shower()
		_bounce_label(hilo_result_label)
	elif push:
		payout = bet_amount
		coins += payout
		hilo_result_label.text = "PUSH! Cards are equal: " + _card_text(old_card) + " = " + _card_text(next_card) + ". Bet returned."
		_play_sfx("push")
	else:
		hilo_result_label.text = "Incorrect! " + _card_text(old_card) + " -> " + _card_text(next_card) + ". Lost $" + str(bet_amount) + "."
		_play_sfx("lose")
		
	_hilo_current_card = next_card
	hilo_card_label.text = "Hi-Lo Card"
	_draw_hilo_visuals(_hilo_card_container, old_card, next_card, false)
	_refresh_gamble_ui()
	_update_hud("Desert Hi-Lo resolved.")

func _pick_oyster(choice: int) -> void:
	if _pearl_revealed:
		return
	if coins < bet_amount:
		oyster_result_label.text = "Need $" + str(bet_amount) + " run coins to open."
		return
	coins -= bet_amount
	_play_sfx("deal")
	
	var golden_idx := randi_range(0, 4)
	var silver_idx := randi_range(0, 4)
	while silver_idx == golden_idx:
		silver_idx = randi_range(0, 4)
		
	_pearl_layout.clear()
	var payout := 0
	var found_golden := false
	
	for idx in range(5):
		if idx == golden_idx:
			_pearl_layout.append("GOLDEN PEARL")
			if idx == choice:
				payout = bet_amount * 5
				found_golden = true
		elif idx == silver_idx:
			_pearl_layout.append("SILVER PEARL")
			if idx == choice:
				payout = bet_amount * 2
		else:
			_pearl_layout.append("EMPTY")
			
	coins += payout
	_pearl_picked_idx = choice
	_pearl_revealed = true
	
	var reveal_strs: Array[String] = []
	for idx in range(5):
		var prefix := ""
		var suffix := ""
		if idx == choice:
			prefix = ">"
			suffix = "<"
		if _pearl_layout[idx] == "GOLDEN PEARL":
			reveal_strs.append(prefix + "💎 GOLDEN" + suffix)
		elif _pearl_layout[idx] == "SILVER PEARL":
			reveal_strs.append(prefix + "⚪ SILVER" + suffix)
		else:
			reveal_strs.append(prefix + "🦪 EMPTY" + suffix)
			
	oyster_label.text = " | ".join(PackedStringArray(reveal_strs))
	
	if payout > 0:
		oyster_result_label.text = "Found " + _pearl_layout[choice] + "! +" + str(payout) + " run coins."
		_play_sfx("win")
		_trigger_coin_shower()
		_bounce_label(oyster_result_label)
	else:
		oyster_result_label.text = "Oyster was empty. Try another one."
		_play_sfx("lose")
		
	_draw_oyster_visuals()
	_refresh_gamble_ui()
	_update_hud("Pearl oyster resolved.")
	
	if current_stage == Stage.OCEAN and found_golden:
		_spawn_trigger_portal("WARP *", Vector2(330, -650), Stage.SPACE)
		_update_hud("The Golden Pearl triggered a cosmic WARP portal to SPACE!")

func _launch_crash() -> void:
	if _crash_active:
		return
	if coins < bet_amount:
		crash_result_label.text = "Need $" + str(bet_amount) + " run coins to launch."
		return
	coins -= bet_amount
	_play_sfx("deal")
	_crash_active = true
	_crash_multiplier = 1.0
	if randf() < 0.15:
		_crash_point = 1.0
	else:
		_crash_point = randf_range(1.1, 10.0)
	crash_result_label.text = "Rocket launched! Cash out before it crashes."
	crash_multiplier_label.text = "LAUNCHED! Rocket speed: 1.00x"
	_draw_crash_visuals()
	_refresh_gamble_ui()
	_update_hud("Cosmic crash rocket launched.")

func _cash_out_crash() -> void:
	if not _crash_active:
		return
	_crash_active = false
	var payout := int(floor(bet_amount * _crash_multiplier))
	coins += payout
	crash_result_label.text = "CASH OUT SUCCESS! Paid " + ("%.2f" % _crash_multiplier) + "x -> +" + str(payout) + " run coins."
	crash_multiplier_label.text = "CASHED OUT AT " + ("%.2f" % _crash_multiplier) + "x"
	_play_sfx("win")
	_trigger_coin_shower()
	_bounce_label(crash_result_label)
	_draw_crash_visuals()
	_refresh_gamble_ui()
	_update_hud("Cosmic crash cashout success.")
	
	if current_stage == Stage.SPACE and _crash_multiplier >= 5.0:
		_spawn_trigger_portal("SUPER WARP *", Vector2(0, -650), Stage.HEAVEN)
		_update_hud("Cashing out above 5x opened a SUPER WARP portal to HEAVEN!")

func _process_crash_game(delta: float) -> void:
	if not _crash_active:
		return
	_crash_multiplier += delta * 0.8
	crash_multiplier_label.text = "LAUNCHED! Rocket speed: " + ("%.2f" % _crash_multiplier) + "x"
	_draw_crash_visuals()
	if _crash_multiplier >= _crash_point:
		_crash_active = false
		crash_result_label.text = "CRASHED at " + ("%.2f" % _crash_multiplier) + "x! Lost $" + str(bet_amount) + " run coins."
		crash_multiplier_label.text = "💥 CRASHED! 💥"
		_play_sfx("lose")
		_draw_crash_visuals()
		_refresh_gamble_ui()
		_update_hud("Cosmic crash rocket exploded.")

func _process_angel_race(delta: float) -> void:
	if not _race_active:
		return
		
	var finish_line_crossed := false
	for i in range(3):
		_race_positions[i] += delta * randf_range(80.0, 160.0)
		if _race_positions[i] >= 310.0:
			finish_line_crossed = true
			
	_draw_race_visuals()
	
	if finish_line_crossed:
		_race_active = false
		
		var winner_idx := 0
		var max_pos := -1.0
		for i in range(3):
			if _race_positions[i] > max_pos:
				max_pos = _race_positions[i]
				winner_idx = i
				
		_race_winner = winner_idx
		var winner_name: String = _race_runners[_race_winner]
		
		if _race_bet_choice == _race_winner:
			var payout := bet_amount * 3
			coins += payout
			race_result_label.text = winner_name + " WINS! +" + str(payout) + " run coins."
			_play_sfx("win")
			_trigger_coin_shower()
			_bounce_label(race_result_label)
		else:
			race_result_label.text = winner_name + " WINS. Your angel fell behind."
			_play_sfx("lose")
			if current_stage == Stage.HEAVEN:
				_spawn_trigger_portal("HELL GATE v", Vector2(330, -650), Stage.HELL)
				_update_hud("Losing the race opened a dark gate to HELL!")
				
		_refresh_gamble_ui()
		_update_hud("Angel race resolved.")

func _enter_slot_area() -> void:
	if mode != GameMode.COMBAT:
		return
	_play_bgm("casino")
	mode = GameMode.SLOT
	player.set_control_enabled(false)
	player.visible = false
	shrine.visible = false
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.visible = false
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	_blackjack_active = false
	_player_cards.clear()
	_dealer_cards.clear()
	_reset_reels()
	slot_result_label.text = "Match 2 for 2x, match 3 for 6x."
	
	if current_stage == Stage.FIELD:
		if gamble_game != GambleGame.SLOT and gamble_game != GambleGame.BLACKJACK:
			gamble_game = GambleGame.SLOT
	elif current_stage == Stage.CAVE:
		gamble_game = GambleGame.POKER
	elif current_stage == Stage.HEAVEN:
		gamble_game = GambleGame.ANGEL_RACE
	elif current_stage == Stage.HELL:
		gamble_game = GambleGame.DICE
	elif current_stage == Stage.FOREST:
		gamble_game = GambleGame.WHEEL
	elif current_stage == Stage.DESERT:
		gamble_game = GambleGame.HILO
	elif current_stage == Stage.OCEAN:
		gamble_game = GambleGame.PEARL
	elif current_stage == Stage.SPACE:
		gamble_game = GambleGame.CRASH
		
	_set_gamble_game(gamble_game)
	slot_layer.visible = true
	_update_hud("Gamble room. Spin, deal, or return.")

func _exit_slot_area() -> void:
	if _crash_active:
		return
	_play_bgm("boss" if boss_active else "normal")
	mode = GameMode.COMBAT
	_blackjack_active = false
	slot_layer.visible = false
	player.global_position = shrine.global_position + Vector2(0, 180)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	player.visible = true
	player.set_control_enabled(true)
	shrine.visible = true
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy.visible = true
	_update_hud("Returned to the dungeon.")

func _enter_weapon_shop() -> void:
	if mode != GameMode.COMBAT:
		return
	mode = GameMode.SHOP
	player.set_control_enabled(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	_refresh_shop_ui()
	shop_layer.visible = true
	_update_hud("Weapon shop. Buy with run coins.")

func _exit_weapon_shop() -> void:
	mode = GameMode.COMBAT
	shop_layer.visible = false
	player.global_position = weapon_shop.global_position + Vector2(180, 70)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	player.set_control_enabled(true)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
	_update_hud("Returned from weapon shop.")

func _buy_heal() -> void:
	var heal_cost = 8
	if coins < heal_cost:
		shop_status_label.text = "Need $" + str(heal_cost) + " run coins to heal."
		return
	if is_instance_valid(player):
		if player.health >= 5:
			shop_status_label.text = "Already at Max HP."
			return
		coins -= heal_cost
		player.health = 5
		shop_status_label.text = "Healed to Full HP!"
		_refresh_shop_ui()
		_update_hud("Healed to Full HP.")

func _buy_weapon(weapon_id: String) -> void:
	if _owned_weapons.get(weapon_id, false):
		shop_status_label.text = "Already owned."
		return
	var weapon = _weapon_by_id(weapon_id)
	if weapon.is_empty():
		shop_status_label.text = "Unknown weapon."
		return
	var cost: int = weapon["cost"]
	if coins < cost:
		shop_status_label.text = "Need $" + str(cost) + " run coins for " + weapon["name"] + "."
		return
	coins -= cost
	_owned_weapons[weapon_id] = true
	shop_status_label.text = "Bought " + weapon["name"] + ". " + weapon["description"]
	_refresh_shop_ui()
	_update_hud("Bought " + weapon["name"] + ".")

func _weapon_by_id(weapon_id: String) -> Dictionary:
	for weapon in _weapon_catalog:
		if weapon["id"] == weapon_id:
			return weapon
	return {}

func _refresh_shop_ui() -> void:
	if not is_instance_valid(shop_money_label):
		return
	shop_money_label.text = "RUN $ " + str(coins) + "  EQUIPPED: " + _owned_weapon_names()
	if shop_status_label.text.is_empty():
		shop_status_label.text = "Buy stage-specific unique attack patterns here."
		
	var visible_count := 0
	for index in range(_weapon_catalog.size()):
		var weapon = _weapon_catalog[index]
		var weapon_id: String = weapon["id"]
		var weapon_name: String = weapon["name"]
		var description: String = weapon["description"]
		var w_stage: int = weapon["stage"]
		var btn := shop_buttons[index]
		
		if w_stage == current_stage:
			btn.visible = true
			btn.position = Vector2(50, 240 + visible_count * 90)
			visible_count += 1
			
			var owned: bool = _owned_weapons.get(weapon_id, false)
			var cost: int = weapon["cost"]
			var label: String = weapon_name + "  $" + str(cost) + "  -  " + description
			if owned:
				label = weapon_name + "  OWNED  -  " + description
			btn.text = label
			btn.disabled = owned or coins < cost
		else:
			btn.visible = false

	if is_instance_valid(shop_heal_button):
		shop_heal_button.visible = true
		shop_heal_button.position = Vector2(50, 240 + visible_count * 90)
		var heal_cost = 8
		var current_hp = player.health if is_instance_valid(player) else 5
		if current_hp >= 5:
			shop_heal_button.text = "HEAL (FULL HP)  -  MAX HP ALREADY"
			shop_heal_button.disabled = true
		else:
			shop_heal_button.text = "HEAL (FULL HP)  $" + str(heal_cost) + "  -  Restores HP to 5"
			shop_heal_button.disabled = coins < heal_cost

func _owned_weapon_names() -> String:
	var names := PackedStringArray(["TARGETER"])
	for weapon in _weapon_catalog:
		if _owned_weapons.get(weapon["id"], false):
			names.append(weapon["name"])
	return ", ".join(names)

func _on_weapon_shop_focus_changed(is_active: bool) -> void:
	if mode != GameMode.COMBAT:
		return
	if is_active:
		_update_hud("$ shop: buy weapons with run coins.")
	else:
		_update_hud("Shots fire automatically. Clear waves for coins.")

func _show_game_over() -> void:
	if mode == GameMode.GAME_OVER:
		return
	_stop_bgm()
	mode = GameMode.GAME_OVER
	_blackjack_active = false
	slot_layer.visible = false
	if is_instance_valid(player):
		player.set_control_enabled(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	game_over_stats_label.text = "WAVE " + str(wave) + " / RUN $ " + str(coins)
	game_over_layer.visible = true
	_update_hud("Run ended. Retry when ready.")

func _restart_run() -> void:
	_clear_run_nodes()
	_play_bgm("normal")
	total_coins_earned = 0
	coins = 0
	wave = 1
	bet_amount = 5
	mode = GameMode.COMBAT
	current_stage = Stage.FIELD
	boss_active = false
	boss_node = null
	_blackjack_active = false
	_crash_active = false
	_player_cards.clear()
	_dealer_cards.clear()
	game_over_layer.visible = false
	if is_instance_valid(game_clear_layer):
		game_clear_layer.visible = false
	slot_layer.visible = false
	player.health = 5
	player.global_position = Vector2(0, 360)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	player.visible = true
	player.set_control_enabled(true)
	shrine.visible = true
	
	# Reset defeated bosses
	for key in _defeated_bosses.keys():
		_defeated_bosses[key] = false
		
	# Reset owned weapons
	for key in _owned_weapons.keys():
		_owned_weapons[key] = (key == "targeter")
		
	# Reset weapon levels
	for key in _weapon_levels.keys():
		_weapon_levels[key] = 1
		
	_apply_stage(Stage.FIELD)
	_set_gamble_game(GambleGame.SLOT)
	_spawn_wave()
	_update_hud("New run. DRAG to move.")

func _clear_run_nodes() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	for bolt in get_tree().get_nodes_in_group("enemy_bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if mode == GameMode.GAME_OVER and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_restart_run()

func _on_shrine_focus_changed(is_active: bool) -> void:
	if mode != GameMode.COMBAT:
		return
	if is_active:
		_update_hud("$ shrine: " + _gamble_name_for_stage() + ".")
	else:
		_update_hud("Shots fire automatically. Clear waves for coins.")

func _gamble_name_for_stage() -> String:
	if current_stage == Stage.CAVE:
		return "cave poker"
	if current_stage == Stage.HEAVEN:
		return "angel race"
	return "slot / blackjack"

func _nearest_enemy() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _update_hud(message: String) -> void:
	if is_instance_valid(player):
		hud_label.text = _stage_name(current_stage) + "   $ " + str(coins) + "   WAVE " + str(wave)
		var health = clamp(player.health, 0, 5)
		if is_instance_valid(hp_bar_fill):
			hp_bar_fill.size.x = 240.0 * (health / 5.0)
			if health <= 1:
				hp_bar_fill.color = Color(0.85, 0.15, 0.15) # Red
			elif health <= 2:
				hp_bar_fill.color = Color(0.9, 0.6, 0.1) # Orange
			else:
				hp_bar_fill.color = Color(0.15, 0.75, 0.25) # Green
		if is_instance_valid(hp_text_label):
			hp_text_label.text = "HP " + str(health) + "/5"
			
	# Update Boss HP Bar
	if is_instance_valid(boss_hp_bar_bg):
		if boss_active and is_instance_valid(boss_node):
			boss_hp_bar_bg.visible = true
			boss_hp_bar_fill.visible = true
			boss_hp_label.visible = true
			
			boss_health = boss_node.health
			var fill_pct = clamp(float(boss_health) / float(boss_max_health), 0.0, 1.0)
			boss_hp_bar_fill.size.x = 440.0 * fill_pct
			boss_hp_label.text = boss_title + "  HP " + str(boss_health) + "/" + str(boss_max_health)
		else:
			boss_hp_bar_bg.visible = false
			boss_hp_bar_fill.visible = false
			boss_hp_label.visible = false
			
	message_label.text = message

func _create_forge() -> void:
	forge = Area2D.new()
	forge.name = "WeaponForge"
	forge.set_script(WeaponShopScript)
	add_child(forge)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82
	shape.shape = circle
	forge.add_child(shape)

	forge_label = Label.new()
	forge_label.text = "⚒️\nFORGE"
	forge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	forge_label.position = Vector2(-60, -58)
	forge_label.size = Vector2(120, 100)
	forge_label.add_theme_font_size_override("font_size", 30)
	forge.add_child(forge_label)

	forge.body_entered.connect(forge._on_body_entered)
	forge.body_exited.connect(forge._on_body_exited)
	forge.entered.connect(_enter_forge)
	forge.focus_changed.connect(_on_forge_focus_changed)

func _create_forge_ui() -> void:
	forge_layer = CanvasLayer.new()
	forge_layer.visible = false
	add_child(forge_layer)

	var background := ColorRect.new()
	background.color = Color(0.02, 0.018, 0.022, 0.95)
	background.position = Vector2(0, 0)
	background.size = Vector2(720, 1280)
	forge_layer.add_child(background)

	var title := Label.new()
	title.text = "## WEAPON FORGE"
	title.position = Vector2(50, 50)
	title.add_theme_font_size_override("font_size", 34)
	forge_layer.add_child(title)

	forge_money_label = Label.new()
	forge_money_label.position = Vector2(50, 110)
	forge_money_label.size = Vector2(620, 42)
	forge_money_label.add_theme_font_size_override("font_size", 25)
	forge_layer.add_child(forge_money_label)

	forge_status_label = Label.new()
	forge_status_label.position = Vector2(50, 160)
	forge_status_label.size = Vector2(620, 62)
	forge_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forge_status_label.add_theme_font_size_override("font_size", 22)
	forge_layer.add_child(forge_status_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(50, 240)
	scroll.size = Vector2(620, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	forge_layer.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "ForgeList"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	for index in range(_weapon_catalog.size()):
		var weapon = _weapon_catalog[index]
		var weapon_id: String = weapon["id"]
		var button := Button.new()
		button.custom_minimum_size = Vector2(600, 74)
		button.add_theme_font_size_override("font_size", 22)
		vbox.add_child(button)
		forge_buttons[weapon_id] = button
		button.pressed.connect(func(w_id = weapon_id): _upgrade_weapon(w_id))
		_style_casino_button(button, Color(0.2, 0.16, 0.24))

	forge_exit_button = Button.new()
	forge_exit_button.text = "RETURN"
	forge_exit_button.position = Vector2(130, 840)
	forge_exit_button.size = Vector2(460, 72)
	forge_exit_button.add_theme_font_size_override("font_size", 28)
	forge_layer.add_child(forge_exit_button)
	forge_exit_button.pressed.connect(_exit_forge)
	_style_casino_button(forge_exit_button, Color(0.24, 0.24, 0.28))

func _enter_forge() -> void:
	if mode != GameMode.COMBAT:
		return
	mode = GameMode.SHOP
	player.set_control_enabled(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	for bolt in get_tree().get_nodes_in_group("enemy_bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	forge_status_label.text = "Select an owned weapon to upgrade its level (Max Lv. 5)."
	_refresh_forge_ui()
	forge_layer.visible = true
	_update_hud("Weapon Forge. Upgrade with coins.")

func _exit_forge() -> void:
	mode = GameMode.COMBAT
	forge_layer.visible = false
	player.global_position = forge.global_position + Vector2(-180, 70)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	player.set_control_enabled(true)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
	_update_hud("Returned from Weapon Forge.")

func _upgrade_cost(level: int) -> int:
	match level:
		1: return 12
		2: return 20
		3: return 30
		4: return 45
	return 9999

func _upgrade_weapon(weapon_id: String) -> void:
	var current_lvl = _weapon_levels.get(weapon_id, 1)
	if current_lvl >= 5:
		forge_status_label.text = "Weapon is already at Max Level (Lv. 5)."
		return
	var cost = _upgrade_cost(current_lvl)
	if coins < cost:
		forge_status_label.text = "Need $" + str(cost) + " coins to upgrade."
		return
	coins -= cost
	_weapon_levels[weapon_id] = current_lvl + 1
	var weapon = _weapon_by_id(weapon_id)
	var w_name = weapon.get("name", "Weapon")
	forge_status_label.text = "Upgraded " + w_name + " to Lv. " + str(current_lvl + 1) + "!"
	_refresh_forge_ui()

func _refresh_forge_ui() -> void:
	if not is_instance_valid(forge_money_label):
		return
	forge_money_label.text = "RUN $ " + str(coins) + "  UPGRADED WEAPONS"
	
	for weapon in _weapon_catalog:
		var weapon_id: String = weapon["id"]
		var weapon_name: String = weapon["name"]
		var btn = forge_buttons[weapon_id]
		var owned: bool = _owned_weapons.get(weapon_id, false)
		
		if owned:
			btn.visible = true
			var level = _weapon_levels.get(weapon_id, 1)
			if level >= 5:
				btn.text = weapon_name + "  [Lv. 5 MAX]"
				btn.disabled = true
			else:
				var cost = _upgrade_cost(level)
				btn.text = weapon_name + "  [Lv. " + str(level) + " -> " + str(level + 1) + "]  Cost: $" + str(cost)
				btn.disabled = coins < cost
		else:
			btn.visible = false

func _on_forge_focus_changed(is_active: bool) -> void:
	if mode != GameMode.COMBAT:
		return
	if is_active:
		_update_hud("⚒️ forge: upgrade weapons with coins.")
	else:
		_update_hud("Shots fire automatically. Clear waves for coins.")

func _create_lender() -> void:
	lender = Area2D.new()
	lender.name = "DebtLender"
	lender.set_script(WeaponShopScript)
	add_child(lender)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82
	shape.shape = circle
	lender.add_child(shape)

	lender_label = Label.new()
	lender_label.text = "L\nLENDER"
	lender_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lender_label.position = Vector2(-60, -58)
	lender_label.size = Vector2(120, 100)
	lender_label.add_theme_font_size_override("font_size", 30)
	lender.add_child(lender_label)

	lender.body_entered.connect(lender._on_body_entered)
	lender.body_exited.connect(lender._on_body_exited)
	lender.entered.connect(_enter_lender_area)
	lender.focus_changed.connect(_on_lender_focus_changed)

func _create_lender_ui() -> void:
	lender_layer = CanvasLayer.new()
	lender_layer.visible = false
	add_child(lender_layer)

	var background := ColorRect.new()
	background.color = Color(0.015, 0.02, 0.025, 0.95)
	background.position = Vector2(0, 0)
	background.size = Vector2(720, 1280)
	lender_layer.add_child(background)

	var title := Label.new()
	title.text = "## DEBT COLLECTOR"
	title.position = Vector2(50, 50)
	title.add_theme_font_size_override("font_size", 34)
	lender_layer.add_child(title)

	lender_money_label = Label.new()
	lender_money_label.position = Vector2(50, 110)
	lender_money_label.size = Vector2(620, 42)
	lender_money_label.add_theme_font_size_override("font_size", 25)
	lender_layer.add_child(lender_money_label)

	lender_status_label = Label.new()
	lender_status_label.position = Vector2(50, 180)
	lender_status_label.size = Vector2(620, 180)
	lender_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lender_status_label.add_theme_font_size_override("font_size", 24)
	lender_layer.add_child(lender_status_label)

	repay_button = Button.new()
	repay_button.position = Vector2(130, 420)
	repay_button.size = Vector2(460, 90)
	repay_button.add_theme_font_size_override("font_size", 28)
	lender_layer.add_child(repay_button)
	repay_button.pressed.connect(_repay_debt)

	lender_exit_button = Button.new()
	lender_exit_button.text = "RETURN"
	lender_exit_button.position = Vector2(130, 580)
	lender_exit_button.size = Vector2(460, 72)
	lender_exit_button.add_theme_font_size_override("font_size", 28)
	lender_layer.add_child(lender_exit_button)
	lender_exit_button.pressed.connect(_exit_lender_area)

func _on_lender_focus_changed(is_active: bool) -> void:
	if mode != GameMode.COMBAT:
		return
	if is_active:
		var debt = _stage_debt(current_stage)
		_update_hud("💰 lender: pay off stage debt of $" + str(debt) + " coins.")
	else:
		_update_hud("Shots fire automatically. Clear waves for coins.")

func _enter_lender_area() -> void:
	if mode != GameMode.COMBAT:
		return
	if boss_active:
		_update_hud("A boss is active! Defeat them first.")
		return
	if _defeated_bosses.get(current_stage, false):
		return
		
	mode = GameMode.LENDER
	player.set_control_enabled(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for bolt in get_tree().get_nodes_in_group("bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
	for bolt in get_tree().get_nodes_in_group("enemy_bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
			
	var debt = _stage_debt(current_stage)
	lender_money_label.text = "RUN $ " + str(coins)
	lender_status_label.text = "You owe the " + _boss_name(current_stage) + " $" + str(debt) + " G.\nPay it back to challenge them."
	
	if coins >= debt:
		repay_button.disabled = false
		repay_button.text = "REPAY $" + str(debt) + " G"
	else:
		repay_button.disabled = true
		repay_button.text = "NEED $" + str(debt) + " G"
		
	lender_layer.visible = true
	_update_hud("Lender Office. Repay your debt.")

func _exit_lender_area() -> void:
	mode = GameMode.COMBAT
	lender_layer.visible = false
	player.global_position = lender.global_position + Vector2(0, -180)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	player.set_control_enabled(true)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
	_update_hud("Returned from Lender.")

func _repay_debt() -> void:
	var debt = _stage_debt(current_stage)
	if coins < debt:
		return
	coins -= debt
	lender_layer.visible = false
	
	if is_instance_valid(lender):
		lender.visible = false
		lender.set_deferred("monitoring", false)
		
	player.set_deferred("global_position", Vector2.ZERO)
	player.set_control_enabled(true)
	mode = GameMode.COMBAT
	
	_spawn_boss(current_stage)

func _spawn_boss(stage_id: int) -> void:
	boss_active = true
	_play_bgm("boss")
	# Clear normal waves
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	
	# Clear bullets
	for bolt in get_tree().get_nodes_in_group("enemy_bolts"):
		if is_instance_valid(bolt):
			bolt.queue_free()
			
	boss_max_health = _boss_hp(stage_id)
	boss_health = boss_max_health
	boss_title = _boss_name(stage_id)
	
	var boss = CharacterBody2D.new()
	var boss_type = "BOSS_FIELD"
	match stage_id:
		Stage.FIELD: boss_type = "BOSS_FIELD"
		Stage.CAVE: boss_type = "BOSS_CAVE"
		Stage.FOREST: boss_type = "BOSS_FOREST"
		Stage.DESERT: boss_type = "BOSS_DESERT"
		Stage.HEAVEN: boss_type = "BOSS_HEAVEN"
		Stage.OCEAN: boss_type = "BOSS_OCEAN"
		Stage.HELL: boss_type = "BOSS_HELL"
		Stage.SPACE: boss_type = "BOSS_SPACE"
	
	boss.name = "Boss"
	boss.set_script(EnemyScript)
	boss.setup(boss_type)
	boss.global_position = Vector2(0, -300)
	boss.target = player
	add_child(boss)
	enemies.append(boss)
	boss_node = boss

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 54
	shape.shape = circle
	boss.add_child(shape)

	var sprite := Sprite2D.new()
	var texture_path := "res://assets/sprite_boss.png"
	match stage_id:
		Stage.FIELD: texture_path = "res://assets/sprite_boss_field.png"
		Stage.CAVE: texture_path = "res://assets/sprite_boss_cave.png"
		Stage.FOREST: texture_path = "res://assets/sprite_boss_forest.png"
		Stage.DESERT: texture_path = "res://assets/sprite_boss_desert.png"
		Stage.HEAVEN: texture_path = "res://assets/sprite_boss_heaven.png"
		Stage.OCEAN: texture_path = "res://assets/sprite_boss_ocean.png"
		Stage.HELL: texture_path = "res://assets/sprite_boss_hell.png"
		Stage.SPACE: texture_path = "res://assets/sprite_boss_space.png"
	
	if not FileAccess.file_exists(texture_path):
		texture_path = "res://assets/sprite_boss.png"
		
	var raw_tex = _load_texture(texture_path)
	var transparent_tex = _make_background_transparent(raw_tex)
	if is_instance_valid(transparent_tex):
		sprite.texture = transparent_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var target_size := 128.0
		sprite.scale = Vector2(target_size / transparent_tex.get_width(), target_size / transparent_tex.get_height())
	boss.add_child(sprite)

	boss.defeated.connect(_on_enemy_defeated)
	boss.hit_player.connect(func(): _update_hud("Ouch. Boss hit you!"))
	if boss.has_signal("shot_requested"):
		boss.shot_requested.connect(_spawn_enemy_bolt)
		
	_update_hud("CHALLENGE MET: " + boss_title + " has arrived!")

func _on_boss_defeated(stage_id: int) -> void:
	boss_active = false
	boss_node = null
	_play_bgm("normal")
	_defeated_bosses[stage_id] = true
	
	if is_instance_valid(player):
		player.health = 5
	
	var reward = 2 * _stage_debt(stage_id)
	coins += reward
	var weapon_id = _boss_weapon(stage_id)
	_owned_weapons[weapon_id] = true
	_update_hud("Defeated " + _boss_name(stage_id) + "! HP FULLY RESTORED! Won $" + str(reward) + " and " + weapon_id.to_upper() + "!")
	
	if stage_id == Stage.SPACE:
		_show_game_clear()
	else:
		_spawn_wave()

func _create_game_clear_ui() -> void:
	game_clear_layer = CanvasLayer.new()
	game_clear_layer.visible = false
	add_child(game_clear_layer)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.1, 0.05, 0.98)
	background.position = Vector2(0, 0)
	background.size = Vector2(720, 1280)
	game_clear_layer.add_child(background)

	var title := Label.new()
	title.text = "🏆 GAME CLEAR 🏆\nDEBT REPAID!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 120)
	title.size = Vector2(620, 150)
	title.add_theme_font_size_override("font_size", 38)
	game_clear_layer.add_child(title)

	game_clear_stats_label = Label.new()
	game_clear_stats_label.position = Vector2(50, 320)
	game_clear_stats_label.size = Vector2(620, 400)
	game_clear_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_clear_stats_label.add_theme_font_size_override("font_size", 25)
	game_clear_layer.add_child(game_clear_stats_label)

	game_clear_restart_button = Button.new()
	game_clear_restart_button.text = "PLAY AGAIN"
	game_clear_restart_button.position = Vector2(130, 800)
	game_clear_restart_button.size = Vector2(460, 90)
	game_clear_restart_button.add_theme_font_size_override("font_size", 32)
	game_clear_layer.add_child(game_clear_restart_button)
	game_clear_restart_button.pressed.connect(_restart_run)

func _show_game_clear() -> void:
	mode = GameMode.GAME_CLEAR
	player.set_control_enabled(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Determine unlocked weapons
	var unlocked_weapons: Array[String] = []
	for key in _owned_weapons:
		if _owned_weapons[key]:
			unlocked_weapons.append(key.to_upper())
	
	var weapons_text = ", ".join(unlocked_weapons)
	
	game_clear_stats_label.text = (
		"RUN STATISTICS:\n\n"
		+ "• STAGE REACHED: SPACE\n"
		+ "• WAVES COMPLETED: " + str(wave) + "\n"
		+ "• TOTAL COINS EARNED: $" + str(total_coins_earned) + "\n"
		+ "• REMAINING COINS: $" + str(coins) + "\n\n"
		+ "• WEAPONS ACQUIRED:\n  " + weapons_text + "\n\n"
		+ "Congratulations! You survived the markdown roguelike dungeon, paid off all your loans, and vanquished the Void Emperor!"
	)
	
	game_clear_layer.visible = true
	_update_hud("VICTORY! All debts paid.")

func _stage_debt(stage_id: int) -> int:
	match stage_id:
		Stage.FIELD: return 100
		Stage.CAVE: return 200
		Stage.FOREST: return 300
		Stage.DESERT: return 400
		Stage.HEAVEN: return 500
		Stage.OCEAN: return 600
		Stage.HELL: return 700
		Stage.SPACE: return 1000
	return 100

func _boss_name(stage_id: int) -> String:
	match stage_id:
		Stage.FIELD: return "THE LOAN SHARK"
		Stage.CAVE: return "DRILL SPECTER"
		Stage.FOREST: return "ROOT OVERLORD"
		Stage.DESERT: return "SAND SHADOW"
		Stage.HEAVEN: return "ARCHANGEL URAEL"
		Stage.OCEAN: return "ABYSSAL LEVIATHAN"
		Stage.HELL: return "SATANIC BARON"
		Stage.SPACE: return "VOID EMPEROR"
	return "BOSS"

func _boss_symbol(stage_id: int) -> String:
	match stage_id:
		Stage.FIELD: return "👹"
		Stage.CAVE: return "⚙️"
		Stage.FOREST: return "🌿"
		Stage.DESERT: return "💀"
		Stage.HEAVEN: return "👼"
		Stage.OCEAN: return "🐉"
		Stage.HELL: return "👿"
		Stage.SPACE: return "Ω"
	return "👹"

func _boss_hp(stage_id: int) -> int:
	match stage_id:
		Stage.FIELD: return 80
		Stage.CAVE: return 150
		Stage.FOREST: return 200
		Stage.DESERT: return 300
		Stage.HEAVEN: return 300
		Stage.OCEAN: return 450
		Stage.HELL: return 550
		Stage.SPACE: return 800
	return 100

func _boss_weapon(stage_id: int) -> String:
	match stage_id:
		Stage.FIELD: return "scythe"
		Stage.CAVE: return "drill"
		Stage.FOREST: return "vine_whip"
		Stage.DESERT: return "sandstorm"
		Stage.HEAVEN: return "lightning"
		Stage.OCEAN: return "trident"
		Stage.HELL: return "doom"
		Stage.SPACE: return "blackhole"
	return "scythe"

func _load_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var tex = load(path)
	if is_instance_valid(tex) and tex is Texture2D:
		return tex
	var img := Image.load_from_file(path)
	if img:
		return ImageTexture.create_from_image(img)
	return null

func _make_background_transparent(tex: Texture2D) -> ImageTexture:
	if not is_instance_valid(tex):
		return null
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.r > 0.92 and c.g > 0.92 and c.b > 0.92:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _style_casino_button(btn: Button, base_color: Color) -> void:
	if not is_instance_valid(btn):
		return
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = base_color
	normal_sb.border_width_left = 2
	normal_sb.border_width_top = 2
	normal_sb.border_width_right = 2
	normal_sb.border_width_bottom = 2
	normal_sb.border_color = Color(0.9, 0.75, 0.1)
	normal_sb.corner_radius_top_left = 8
	normal_sb.corner_radius_top_right = 8
	normal_sb.corner_radius_bottom_left = 8
	normal_sb.corner_radius_bottom_right = 8
	
	var hover_sb := normal_sb.duplicate()
	hover_sb.bg_color = base_color + Color(0.12, 0.12, 0.12)
	
	var pressed_sb := normal_sb.duplicate()
	pressed_sb.bg_color = base_color - Color(0.15, 0.15, 0.15)
	
	var disabled_sb := normal_sb.duplicate()
	disabled_sb.bg_color = Color(0.15, 0.15, 0.15, 0.5)
	disabled_sb.border_color = Color(0.4, 0.4, 0.4, 0.5)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	
	btn.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pivot_offset = btn.size / 2.0
	btn.button_down.connect(func():
		var tween = btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	)
	btn.button_up.connect(func():
		var tween = btn.create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.06)
	)

func _trigger_coin_shower() -> void:
	if not is_instance_valid(slot_layer) or not slot_layer.visible:
		return
	for i in range(40):
		var coin := Polygon2D.new()
		coin.color = Color(0.95, 0.75, 0.15)
		var steps := 8
		var points := PackedVector2Array()
		for j in range(steps):
			var angle := TAU * float(j) / float(steps)
			points.append(Vector2(cos(angle), sin(angle)) * 8.0)
		coin.polygon = points
		
		var core := Polygon2D.new()
		core.color = Color(1.0, 0.92, 0.4)
		var core_points := PackedVector2Array()
		for j in range(steps):
			var angle := TAU * float(j) / float(steps)
			core_points.append(Vector2(cos(angle), sin(angle)) * 4.0)
		core.polygon = core_points
		coin.add_child(core)
		
		coin.position = Vector2(randf_range(60, 660), randf_range(-120, -20))
		coin.set_meta("velocity", Vector2(randf_range(-80, 80), randf_range(350, 750)))
		coin.set_meta("spin_speed", randf_range(-8, 8))
		coin.set_meta("lifetime", 3.5)
		slot_layer.add_child(coin)
		_casino_coins.append(coin)

func _process_casino_coins(delta: float) -> void:
	var remaining_coins := []
	for coin in _casino_coins:
		if is_instance_valid(coin):
			var lifetime: float = coin.get_meta("lifetime") - delta
			if lifetime <= 0.0:
				coin.queue_free()
				continue
			coin.set_meta("lifetime", lifetime)
			var velocity: Vector2 = coin.get_meta("velocity")
			velocity.y += 1200.0 * delta
			coin.set_meta("velocity", velocity)
			coin.position += velocity * delta
			coin.rotation += float(coin.get_meta("spin_speed")) * delta
			
			if coin.position.x < 30.0:
				coin.position.x = 30.0
				coin.set_meta("velocity", Vector2(-velocity.x * 0.6, velocity.y))
			elif coin.position.x > 690.0:
				coin.position.x = 690.0
				coin.set_meta("velocity", Vector2(-velocity.x * 0.6, velocity.y))
			remaining_coins.append(coin)
	_casino_coins = remaining_coins

func _update_casino_leds(delta: float) -> void:
	if not slot_layer or not slot_layer.visible or _casino_led_lights.is_empty():
		return
	_casino_led_timer += delta
	if _casino_led_timer >= 0.12:
		_casino_led_timer = 0.0
		var colors := [
			Color(1.0, 0.2, 0.2),
			Color(1.0, 0.9, 0.1),
			Color(0.2, 0.9, 0.4),
			Color(0.2, 0.6, 1.0)
		]
		var base_offset = Time.get_ticks_msec() / 120
		for i in range(_casino_led_lights.size()):
			var light = _casino_led_lights[i]
			if is_instance_valid(light):
				var color_idx = (i + base_offset) % colors.size()
				light.color = colors[color_idx]

func _bounce_label(label: Label) -> void:
	if not is_instance_valid(label):
		return
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.35, 1.35)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(label, "theme_override_colors/font_color", Color(1.0, 0.85, 0.2), 0.1)
	flash_tween.tween_property(label, "theme_override_colors/font_color", Color(1.0, 1.0, 1.0), 0.1)
	flash_tween.set_loops(3)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
