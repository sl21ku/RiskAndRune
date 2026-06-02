extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const BoltScript := preload("res://scripts/bolt.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const ShrineScript := preload("res://scripts/gamble_shrine.gd")
const PortalScript := preload("res://scripts/stage_portal.gd")
const WeaponShopScript := preload("res://scripts/weapon_shop.gd")

enum GameMode { COMBAT, SLOT, SHOP, GAME_OVER }
enum GambleGame { SLOT, BLACKJACK, POKER, ANGEL_RACE }
enum Stage { FIELD, CAVE, HEAVEN }

var player
var coins := 0
var wave := 1
var shrine
var camera: Camera2D
var weapon_shop
var arena_floor: ColorRect
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
var slot_machine_label: Label
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
var game_over_layer: CanvasLayer
var game_over_stats_label: Label
var restart_button: Button
var shop_layer: CanvasLayer
var shop_money_label: Label
var shop_status_label: Label
var shop_buttons: Array[Button] = []
var shop_exit_button: Button
var enemies: Array[Node2D] = []
var portals: Array[Node2D] = []
var mode := GameMode.COMBAT
var gamble_game := GambleGame.SLOT
var current_stage := Stage.FIELD
var bet_amount := 5
var _slot_symbols := ["@", "#", "$", "*", "!", "?"]
var _player_cards := []
var _dealer_cards := []
var _blackjack_active := false
var _poker_ranks := ["A", "K", "Q", "J", "10", "9", "8"]
var _race_runners := ["Seraph", "Halo", "Feather"]
var _owned_weapons := {
	"targeter": true,
	"blaster": false,
	"splitter": false,
	"nova": false,
	"repeater": false,
}
var _weapon_catalog := [
	{"id": "blaster", "name": "BLASTER", "cost": 10, "description": "Fires forward where @ faces."},
	{"id": "splitter", "name": "SPLITTER", "cost": 15, "description": "Adds two angled shots to Targeter."},
	{"id": "nova", "name": "NOVA", "cost": 20, "description": "Bursts in eight directions."},
	{"id": "repeater", "name": "REPEATER", "cost": 25, "description": "Doubles the Targeter shot."},
]
var _nova_timer := 0.0

func _ready() -> void:
	randomize()
	_setup_camera()
	_create_arena()
	_create_player()
	_create_shrine()
	_create_weapon_shop()
	_apply_stage(Stage.FIELD)
	_create_hud()
	_create_slot_ui()
	_create_shop_ui()
	_create_game_over_ui()
	_spawn_wave()
	_update_hud("DRAG to move. Shots fire automatically.")

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_update_camera(delta)
	if mode != GameMode.COMBAT:
		return
	var nearest := _nearest_enemy()
	player.set_nearest_enemy(nearest)
	_update_owned_weapon_attacks(delta)
	if player.health <= 0:
		_show_game_over()

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(0, 0)
	camera.zoom = Vector2(0.85, 0.85)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()

func _update_camera(_delta: float) -> void:
	camera.global_position = player.global_position

func _create_arena() -> void:
	arena_floor = ColorRect.new()
	arena_floor.color = Color(0.08, 0.1, 0.11)
	arena_floor.position = Vector2(-540, -960)
	arena_floor.size = Vector2(1080, 1920)
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

	var label := Label.new()
	label.text = "@"
	label.position = Vector2(-18, -34)
	label.add_theme_font_size_override("font_size", 52)
	player.add_child(label)

	player.shot_requested.connect(_spawn_bolt)
	player.forward_shot_requested.connect(_spawn_forward_bolt)

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
	if current_stage == Stage.FIELD:
		arena_floor.color = Color(0.07, 0.1, 0.085)
		stage_title_label.text = "# field.md"
		shrine_label.text = "$\nSLOT"
		shrine.global_position = Vector2(0, -300)
		weapon_shop.visible = true
		weapon_shop.monitoring = true
		weapon_shop.global_position = Vector2(-360, 160)
		_create_stage_portal("CAVE >", Vector2(-330, -650), Stage.CAVE)
		_create_stage_portal("VINE ^", Vector2(330, -650), Stage.HEAVEN)
	elif current_stage == Stage.CAVE:
		arena_floor.color = Color(0.035, 0.038, 0.045)
		stage_title_label.text = "# cave.md"
		shrine_label.text = "$\nPOKER"
		shrine.global_position = Vector2(0, -330)
		weapon_shop.visible = false
		weapon_shop.monitoring = false
		_create_stage_portal("< FIELD", Vector2(-330, -650), Stage.FIELD)
		_create_stage_portal("VINE ^", Vector2(330, -650), Stage.HEAVEN)
	else:
		arena_floor.color = Color(0.13, 0.15, 0.17)
		stage_title_label.text = "# heaven.md"
		shrine_label.text = "$\nRACE"
		shrine.global_position = Vector2(0, -330)
		weapon_shop.visible = false
		weapon_shop.monitoring = false
		_create_stage_portal("DESCEND", Vector2(0, -650), Stage.FIELD)

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

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-78, -24)
	label.size = Vector2(156, 56)
	label.add_theme_font_size_override("font_size", 28)
	portal.add_child(label)

	portal.body_entered.connect(portal._on_body_entered)
	portal.entered.connect(_change_stage)

func _clear_portals() -> void:
	for portal in portals:
		if is_instance_valid(portal):
			portal.queue_free()
	portals.clear()

func _change_stage(destination: int) -> void:
	if mode != GameMode.COMBAT or destination == current_stage:
		return
	_clear_run_nodes()
	_apply_stage(destination)
	player.global_position = Vector2(0, 320)
	_spawn_wave()
	_update_hud("Entered " + _stage_name(current_stage) + ".")

func _stage_name(stage: int) -> String:
	if stage == Stage.CAVE:
		return "CAVE"
	if stage == Stage.HEAVEN:
		return "HEAVEN"
	return "FIELD"

func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud_label = Label.new()
	hud_label.position = Vector2(24, 24)
	hud_label.add_theme_font_size_override("font_size", 28)
	canvas.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(24, 78)
	message_label.size = Vector2(680, 120)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(message_label)

func _create_slot_ui() -> void:
	slot_layer = CanvasLayer.new()
	slot_layer.visible = false
	add_child(slot_layer)

	var background := ColorRect.new()
	background.color = Color(0.02, 0.02, 0.025, 0.94)
	background.size = Vector2(900, 720)
	background.position = Vector2(0, 0)
	slot_layer.add_child(background)

	var title := Label.new()
	title.text = "## GAMBLE ROOM"
	title.position = Vector2(36, 28)
	title.add_theme_font_size_override("font_size", 32)
	slot_layer.add_child(title)

	gamble_money_label = Label.new()
	gamble_money_label.position = Vector2(38, 82)
	gamble_money_label.size = Vector2(340, 42)
	gamble_money_label.add_theme_font_size_override("font_size", 25)
	slot_layer.add_child(gamble_money_label)

	decrease_bet_button = Button.new()
	decrease_bet_button.text = "-"
	decrease_bet_button.position = Vector2(390, 78)
	decrease_bet_button.size = Vector2(62, 54)
	decrease_bet_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(decrease_bet_button)
	decrease_bet_button.pressed.connect(func(): _change_bet(-5))

	gamble_bet_label = Label.new()
	gamble_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gamble_bet_label.position = Vector2(466, 88)
	gamble_bet_label.size = Vector2(170, 38)
	gamble_bet_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(gamble_bet_label)

	increase_bet_button = Button.new()
	increase_bet_button.text = "+"
	increase_bet_button.position = Vector2(650, 78)
	increase_bet_button.size = Vector2(62, 54)
	increase_bet_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(increase_bet_button)
	increase_bet_button.pressed.connect(func(): _change_bet(5))

	slot_tab_button = Button.new()
	slot_tab_button.text = "SLOT"
	slot_tab_button.position = Vector2(70, 152)
	slot_tab_button.size = Vector2(300, 58)
	slot_tab_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(slot_tab_button)
	slot_tab_button.pressed.connect(func(): _set_gamble_game(GambleGame.SLOT))

	blackjack_tab_button = Button.new()
	blackjack_tab_button.text = "BLACKJACK"
	blackjack_tab_button.position = Vector2(420, 152)
	blackjack_tab_button.size = Vector2(300, 58)
	blackjack_tab_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(blackjack_tab_button)
	blackjack_tab_button.pressed.connect(func(): _set_gamble_game(GambleGame.BLACKJACK))

	slot_machine_label = Label.new()
	slot_machine_label.text = "[ ? ][ ? ][ ? ]"
	slot_machine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_machine_label.position = Vector2(36, 238)
	slot_machine_label.size = Vector2(720, 88)
	slot_machine_label.add_theme_font_size_override("font_size", 46)
	slot_layer.add_child(slot_machine_label)

	slot_result_label = Label.new()
	slot_result_label.text = "Bet 5 run coins. Match symbols to win."
	slot_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot_result_label.position = Vector2(70, 345)
	slot_result_label.size = Vector2(660, 86)
	slot_result_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(slot_result_label)

	spin_button = Button.new()
	spin_button.text = "SPIN"
	spin_button.position = Vector2(175, 458)
	spin_button.size = Vector2(450, 76)
	spin_button.add_theme_font_size_override("font_size", 30)
	slot_layer.add_child(spin_button)
	spin_button.pressed.connect(_spin_slot)

	dealer_hand_label = Label.new()
	dealer_hand_label.position = Vector2(70, 238)
	dealer_hand_label.size = Vector2(660, 58)
	dealer_hand_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(dealer_hand_label)

	blackjack_hand_label = Label.new()
	blackjack_hand_label.position = Vector2(70, 310)
	blackjack_hand_label.size = Vector2(660, 58)
	blackjack_hand_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(blackjack_hand_label)

	blackjack_result_label = Label.new()
	blackjack_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blackjack_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blackjack_result_label.position = Vector2(70, 390)
	blackjack_result_label.size = Vector2(660, 78)
	blackjack_result_label.add_theme_font_size_override("font_size", 23)
	slot_layer.add_child(blackjack_result_label)

	deal_button = Button.new()
	deal_button.text = "DEAL"
	deal_button.position = Vector2(70, 500)
	deal_button.size = Vector2(190, 64)
	deal_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(deal_button)
	deal_button.pressed.connect(_start_blackjack_hand)

	hit_button = Button.new()
	hit_button.text = "HIT"
	hit_button.position = Vector2(290, 500)
	hit_button.size = Vector2(190, 64)
	hit_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(hit_button)
	hit_button.pressed.connect(_blackjack_hit)

	stand_button = Button.new()
	stand_button.text = "STAND"
	stand_button.position = Vector2(510, 500)
	stand_button.size = Vector2(190, 64)
	stand_button.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(stand_button)
	stand_button.pressed.connect(_blackjack_stand)

	poker_hand_label = Label.new()
	poker_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poker_hand_label.position = Vector2(70, 250)
	poker_hand_label.size = Vector2(660, 70)
	poker_hand_label.add_theme_font_size_override("font_size", 30)
	slot_layer.add_child(poker_hand_label)

	poker_result_label = Label.new()
	poker_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poker_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	poker_result_label.position = Vector2(70, 360)
	poker_result_label.size = Vector2(660, 86)
	poker_result_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(poker_result_label)

	poker_deal_button = Button.new()
	poker_deal_button.text = "DRAW"
	poker_deal_button.position = Vector2(175, 500)
	poker_deal_button.size = Vector2(450, 70)
	poker_deal_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(poker_deal_button)
	poker_deal_button.pressed.connect(_deal_poker)

	race_track_label = Label.new()
	race_track_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race_track_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	race_track_label.position = Vector2(70, 238)
	race_track_label.size = Vector2(660, 120)
	race_track_label.add_theme_font_size_override("font_size", 25)
	slot_layer.add_child(race_track_label)

	race_result_label = Label.new()
	race_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	race_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	race_result_label.position = Vector2(70, 380)
	race_result_label.size = Vector2(660, 70)
	race_result_label.add_theme_font_size_override("font_size", 24)
	slot_layer.add_child(race_result_label)

	angel_a_button = Button.new()
	angel_a_button.text = "SERAPH"
	angel_a_button.position = Vector2(70, 500)
	angel_a_button.size = Vector2(190, 64)
	angel_a_button.add_theme_font_size_override("font_size", 22)
	slot_layer.add_child(angel_a_button)
	angel_a_button.pressed.connect(func(): _bet_angel_race(0))

	angel_b_button = Button.new()
	angel_b_button.text = "HALO"
	angel_b_button.position = Vector2(290, 500)
	angel_b_button.size = Vector2(190, 64)
	angel_b_button.add_theme_font_size_override("font_size", 22)
	slot_layer.add_child(angel_b_button)
	angel_b_button.pressed.connect(func(): _bet_angel_race(1))

	angel_c_button = Button.new()
	angel_c_button.text = "FEATHER"
	angel_c_button.position = Vector2(510, 500)
	angel_c_button.size = Vector2(190, 64)
	angel_c_button.add_theme_font_size_override("font_size", 22)
	slot_layer.add_child(angel_c_button)
	angel_c_button.pressed.connect(func(): _bet_angel_race(2))

	exit_button = Button.new()
	exit_button.text = "RETURN"
	exit_button.position = Vector2(175, 600)
	exit_button.size = Vector2(450, 72)
	exit_button.add_theme_font_size_override("font_size", 28)
	slot_layer.add_child(exit_button)
	exit_button.pressed.connect(_exit_slot_area)
	_set_gamble_game(GambleGame.SLOT)

func _create_shop_ui() -> void:
	shop_layer = CanvasLayer.new()
	shop_layer.visible = false
	add_child(shop_layer)

	var background := ColorRect.new()
	background.color = Color(0.018, 0.021, 0.018, 0.95)
	background.position = Vector2(0, 0)
	background.size = Vector2(900, 720)
	shop_layer.add_child(background)

	var title := Label.new()
	title.text = "## WEAPON SHOP"
	title.position = Vector2(36, 28)
	title.add_theme_font_size_override("font_size", 34)
	shop_layer.add_child(title)

	shop_money_label = Label.new()
	shop_money_label.position = Vector2(38, 82)
	shop_money_label.size = Vector2(650, 42)
	shop_money_label.add_theme_font_size_override("font_size", 25)
	shop_layer.add_child(shop_money_label)

	shop_status_label = Label.new()
	shop_status_label.position = Vector2(38, 130)
	shop_status_label.size = Vector2(720, 62)
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status_label.add_theme_font_size_override("font_size", 22)
	shop_layer.add_child(shop_status_label)

	for index in range(_weapon_catalog.size()):
		var weapon = _weapon_catalog[index]
		var button := Button.new()
		button.position = Vector2(70, 215 + index * 82)
		button.size = Vector2(660, 66)
		button.add_theme_font_size_override("font_size", 22)
		shop_layer.add_child(button)
		shop_buttons.append(button)
		button.pressed.connect(func(weapon_id = weapon["id"]): _buy_weapon(weapon_id))

	shop_exit_button = Button.new()
	shop_exit_button.text = "RETURN"
	shop_exit_button.position = Vector2(175, 575)
	shop_exit_button.size = Vector2(450, 72)
	shop_exit_button.add_theme_font_size_override("font_size", 28)
	shop_layer.add_child(shop_exit_button)
	shop_exit_button.pressed.connect(_exit_weapon_shop)
	_refresh_shop_ui()

func _create_game_over_ui() -> void:
	game_over_layer = CanvasLayer.new()
	game_over_layer.visible = false
	add_child(game_over_layer)

	var background := ColorRect.new()
	background.color = Color(0.015, 0.015, 0.018, 0.94)
	background.position = Vector2(0, 0)
	background.size = Vector2(900, 720)
	game_over_layer.add_child(background)

	var title := Label.new()
	title.text = "## RUN ENDED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(70, 150)
	title.size = Vector2(660, 72)
	title.add_theme_font_size_override("font_size", 44)
	game_over_layer.add_child(title)

	game_over_stats_label = Label.new()
	game_over_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_stats_label.position = Vector2(90, 270)
	game_over_stats_label.size = Vector2(620, 110)
	game_over_stats_label.add_theme_font_size_override("font_size", 28)
	game_over_layer.add_child(game_over_stats_label)

	restart_button = Button.new()
	restart_button.text = "RETRY RUN"
	restart_button.position = Vector2(175, 455)
	restart_button.size = Vector2(450, 86)
	restart_button.add_theme_font_size_override("font_size", 32)
	game_over_layer.add_child(restart_button)
	restart_button.pressed.connect(_restart_run)

func _spawn_wave() -> void:
	if mode != GameMode.COMBAT:
		return
	for index in range(3 + wave):
		_spawn_enemy(Vector2(randf_range(-420, 420), randf_range(-760, -140)))

func _spawn_enemy(spawn_position: Vector2) -> void:
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy"
	enemy.set_script(EnemyScript)
	enemy.global_position = spawn_position
	enemy.target = player
	add_child(enemy)
	enemies.append(enemy)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24
	shape.shape = circle
	enemy.add_child(shape)

	var label := Label.new()
	label.text = "x"
	label.position = Vector2(-14, -28)
	label.add_theme_font_size_override("font_size", 44)
	enemy.add_child(label)

	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit_player.connect(func(): _update_hud("Ouch. Keep moving."))

func _spawn_bolt(origin: Vector2, direction: Vector2) -> void:
	if mode != GameMode.COMBAT or not _owned_weapons["targeter"]:
		return
	_create_projectile(origin, direction, "-", 820.0, 1.2, 10.0, 1)
	if _owned_weapons["repeater"]:
		_create_projectile(origin + Vector2(18, 0), direction, "-", 820.0, 1.2, 10.0, 1)
	if _owned_weapons["splitter"]:
		_create_projectile(origin, direction.rotated(0.32), "\\", 780.0, 1.0, 10.0, 1)
		_create_projectile(origin, direction.rotated(-0.32), "/", 780.0, 1.0, 10.0, 1)

func _spawn_forward_bolt(origin: Vector2, direction: Vector2) -> void:
	if mode != GameMode.COMBAT or not _owned_weapons["blaster"]:
		return
	_create_projectile(origin + direction.normalized() * 34.0, direction, ">", 980.0, 0.75, 12.0, 1)

func _update_owned_weapon_attacks(delta: float) -> void:
	if _owned_weapons["nova"]:
		_nova_timer -= delta
		if _nova_timer <= 0.0:
			_nova_timer = 2.1
			_spawn_nova()

func _spawn_nova() -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		_create_projectile(player.global_position, Vector2.RIGHT.rotated(angle), "*", 700.0, 0.85, 11.0, 1)

func _create_projectile(origin: Vector2, direction: Vector2, symbol: String, speed: float, lifetime: float, radius: float, damage: int) -> void:
	if direction.length() <= 0.0:
		return
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

	var label := Label.new()
	label.text = symbol
	label.position = Vector2(-9, -20)
	label.add_theme_font_size_override("font_size", 35)
	bolt.add_child(label)

	bolt.body_entered.connect(func(body: Node) -> void:
		if body.has_method("damage") and body != player:
			body.damage(damage)
			bolt.queue_free()
	)

func _on_enemy_defeated(enemy: Node2D) -> void:
	enemies.erase(enemy)
	coins += randi_range(2, 5)
	if enemies.is_empty():
		wave += 1
		_update_hud("Wave cleared. Visit $ shrine or keep fighting.")
		_spawn_wave()
	else:
		_update_hud("Coin gained.")

func _spin_slot() -> void:
	if coins < bet_amount:
		slot_result_label.text = "Need $" + str(bet_amount) + " run coins to spin."
		return
	coins -= bet_amount
	var reels := [
		_slot_symbols.pick_random(),
		_slot_symbols.pick_random(),
		_slot_symbols.pick_random(),
	]
	slot_machine_label.text = "[ " + reels[0] + " ][ " + reels[1] + " ][ " + reels[2] + " ]"
	var payout := 0
	if reels[0] == reels[1] and reels[1] == reels[2]:
		payout = bet_amount * 6
	elif reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		payout = bet_amount * 2
	if payout > 0:
		coins += payout
		slot_result_label.text = "WIN +" + str(payout) + " run coins."
	else:
		slot_result_label.text = "No match. The dungeon takes its cut."
	_refresh_gamble_ui()
	_update_hud("Slot room. Coins change here only.")

func _set_gamble_game(next_game: int) -> void:
	if _blackjack_active and next_game != GambleGame.BLACKJACK:
		blackjack_result_label.text = "Finish this hand before switching games."
		return
	gamble_game = next_game
	var showing_slot := gamble_game == GambleGame.SLOT
	var showing_blackjack := gamble_game == GambleGame.BLACKJACK
	var showing_poker := gamble_game == GambleGame.POKER
	var showing_race := gamble_game == GambleGame.ANGEL_RACE
	slot_tab_button.visible = current_stage == Stage.FIELD
	blackjack_tab_button.visible = current_stage == Stage.FIELD
	slot_tab_button.text = "SLOT *" if showing_slot else "SLOT"
	blackjack_tab_button.text = "BLACKJACK *" if showing_blackjack else "BLACKJACK"
	slot_machine_label.visible = showing_slot
	slot_result_label.visible = showing_slot
	spin_button.visible = showing_slot
	dealer_hand_label.visible = showing_blackjack
	blackjack_hand_label.visible = showing_blackjack
	blackjack_result_label.visible = showing_blackjack
	deal_button.visible = showing_blackjack
	hit_button.visible = showing_blackjack
	stand_button.visible = showing_blackjack
	poker_hand_label.visible = showing_poker
	poker_result_label.visible = showing_poker
	poker_deal_button.visible = showing_poker
	race_track_label.visible = showing_race
	race_result_label.visible = showing_race
	angel_a_button.visible = showing_race
	angel_b_button.visible = showing_race
	angel_c_button.visible = showing_race
	if showing_slot:
		slot_result_label.text = "Match 2 for 2x, match 3 for 6x."
	elif showing_blackjack:
		_refresh_blackjack_view(false)
	elif showing_poker:
		poker_hand_label.text = "[ ? ][ ? ][ ? ][ ? ][ ? ]"
		poker_result_label.text = "Cave poker. Pair returns, better hands pay."
	else:
		race_track_label.text = "SERAPH / HALO / FEATHER"
		race_result_label.text = "Pick an angel. Winner pays 3x."
	_refresh_gamble_ui()

func _change_bet(delta: int) -> void:
	if _blackjack_active:
		blackjack_result_label.text = "Finish this hand before changing bet."
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
	else:
		race_result_label.text = "Bet changed. Pick an angel."

func _refresh_gamble_ui() -> void:
	gamble_money_label.text = "RUN $ " + str(coins)
	gamble_bet_label.text = "BET $" + str(bet_amount)
	spin_button.text = "SPIN  $" + str(bet_amount)
	deal_button.text = "DEAL  $" + str(bet_amount)
	poker_deal_button.text = "DRAW  $" + str(bet_amount)
	angel_a_button.text = "SERAPH $" + str(bet_amount)
	angel_b_button.text = "HALO $" + str(bet_amount)
	angel_c_button.text = "FEATHER $" + str(bet_amount)
	decrease_bet_button.disabled = bet_amount <= 5 or _blackjack_active
	increase_bet_button.disabled = bet_amount >= coins or _blackjack_active
	spin_button.disabled = gamble_game != GambleGame.SLOT or coins < bet_amount
	deal_button.disabled = gamble_game != GambleGame.BLACKJACK or _blackjack_active or coins < bet_amount
	hit_button.disabled = gamble_game != GambleGame.BLACKJACK or not _blackjack_active
	stand_button.disabled = gamble_game != GambleGame.BLACKJACK or not _blackjack_active
	poker_deal_button.disabled = gamble_game != GambleGame.POKER or coins < bet_amount
	angel_a_button.disabled = gamble_game != GambleGame.ANGEL_RACE or coins < bet_amount
	angel_b_button.disabled = gamble_game != GambleGame.ANGEL_RACE or coins < bet_amount
	angel_c_button.disabled = gamble_game != GambleGame.ANGEL_RACE or coins < bet_amount

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

func _refresh_blackjack_view(reveal_dealer: bool) -> void:
	if _dealer_cards.is_empty():
		dealer_hand_label.text = "DEALER: --"
	else:
		var dealer_text := _format_hand(_dealer_cards)
		if _blackjack_active and not reveal_dealer:
			dealer_text = _card_text(_dealer_cards[0]) + " [?]"
		dealer_hand_label.text = "DEALER: " + dealer_text
	if _player_cards.is_empty():
		blackjack_hand_label.text = "YOU: --"
	else:
		blackjack_hand_label.text = "YOU: " + _format_hand(_player_cards) + " = " + str(_hand_value(_player_cards))
	if not _blackjack_active and _player_cards.is_empty():
		blackjack_result_label.text = "Deal blackjack with run coins."

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
	if coins < bet_amount:
		poker_result_label.text = "Need $" + str(bet_amount) + " run coins to draw."
		return
	coins -= bet_amount
	var hand := []
	for index in range(5):
		hand.append(_poker_ranks.pick_random())
	var counts := {}
	for rank in hand:
		counts[rank] = counts.get(rank, 0) + 1
	var groups := []
	for rank in counts.keys():
		groups.append(counts[rank])
	groups.sort()
	groups.reverse()
	var payout := 0
	var result := "HIGH CARD"
	if groups[0] == 5:
		result = "FIVE OF A KIND"
		payout = bet_amount * 10
	elif groups[0] == 4:
		result = "FOUR OF A KIND"
		payout = bet_amount * 8
	elif groups[0] == 3 and groups.size() > 1 and groups[1] == 2:
		result = "FULL HOUSE"
		payout = bet_amount * 5
	elif groups[0] == 3:
		result = "THREE OF A KIND"
		payout = bet_amount * 3
	elif groups[0] == 2 and groups.size() > 1 and groups[1] == 2:
		result = "TWO PAIR"
		payout = bet_amount * 2
	elif groups[0] == 2:
		result = "PAIR"
		payout = bet_amount
	coins += payout
	poker_hand_label.text = "[ " + " ][ ".join(PackedStringArray(hand)) + " ]"
	if payout > 0:
		poker_result_label.text = result + ". +" + str(payout) + " run coins."
	else:
		poker_result_label.text = result + ". No payout."
	_refresh_gamble_ui()
	_update_hud("Cave poker resolved.")

func _bet_angel_race(choice: int) -> void:
	if coins < bet_amount:
		race_result_label.text = "Need $" + str(bet_amount) + " run coins to race."
		return
	coins -= bet_amount
	var winner := randi_range(0, _race_runners.size() - 1)
	var track := []
	for index in range(_race_runners.size()):
		var marker := ">>> "
		if index == winner:
			marker = "!!! "
		track.append(marker + _race_runners[index])
	race_track_label.text = "\n".join(PackedStringArray(track))
	if choice == winner:
		var payout := bet_amount * 3
		coins += payout
		race_result_label.text = _race_runners[winner] + " wins. +" + str(payout) + " run coins."
	else:
		race_result_label.text = _race_runners[winner] + " wins. Your angel falls behind."
	_refresh_gamble_ui()
	_update_hud("Angel race resolved.")

func _enter_slot_area() -> void:
	if mode != GameMode.COMBAT:
		return
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
	slot_machine_label.text = "[ ? ][ ? ][ ? ]"
	slot_result_label.text = "Match 2 for 2x, match 3 for 6x."
	if current_stage == Stage.CAVE:
		gamble_game = GambleGame.POKER
	elif current_stage == Stage.HEAVEN:
		gamble_game = GambleGame.ANGEL_RACE
	elif gamble_game == GambleGame.POKER or gamble_game == GambleGame.ANGEL_RACE:
		gamble_game = GambleGame.SLOT
	_set_gamble_game(gamble_game)
	slot_layer.visible = true
	_update_hud("Gamble room. Spin, deal, or return.")

func _exit_slot_area() -> void:
	mode = GameMode.COMBAT
	_blackjack_active = false
	slot_layer.visible = false
	player.global_position = Vector2(0, 120)
	player.visible = true
	player.set_control_enabled(true)
	shrine.visible = true
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			enemy.visible = true
	_update_hud("Returned to the dungeon.")

func _enter_weapon_shop() -> void:
	if mode != GameMode.COMBAT or current_stage != Stage.FIELD:
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
	player.global_position = Vector2(-180, 230)
	player.set_control_enabled(true)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
	_update_hud("Returned from weapon shop.")

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
		shop_status_label.text = "Targeter is the initial weapon. Buy more attack patterns here."
	for index in range(shop_buttons.size()):
		var weapon = _weapon_catalog[index]
		var weapon_id: String = weapon["id"]
		var weapon_name: String = weapon["name"]
		var description: String = weapon["description"]
		var owned: bool = _owned_weapons.get(weapon_id, false)
		var cost: int = weapon["cost"]
		var label: String = weapon_name + "  $" + str(cost) + "  -  " + description
		if owned:
			label = weapon_name + "  OWNED  -  " + description
		shop_buttons[index].text = label
		shop_buttons[index].disabled = owned or coins < cost

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
	coins = 0
	wave = 1
	bet_amount = 5
	mode = GameMode.COMBAT
	current_stage = Stage.FIELD
	_blackjack_active = false
	_player_cards.clear()
	_dealer_cards.clear()
	game_over_layer.visible = false
	slot_layer.visible = false
	player.health = 5
	player.global_position = Vector2(0, 360)
	player.visible = true
	player.set_control_enabled(true)
	shrine.visible = true
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
		hud_label.text = _stage_name(current_stage) + "  HP " + str(player.health) + "  $ " + str(coins) + "  WAVE " + str(wave)
	message_label.text = message
