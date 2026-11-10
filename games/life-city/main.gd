extends Node3D
## Life in the City: a small everyday-life sim. Walk around town, work shifts
## for money, buy food, eat, sleep and pay the rent. The scene is built in code.

const HOUR_SECONDS := 25.0         # real seconds per game hour while walking
const WALK_SPEED := 7.0
const RENT := 450
const RENT_DAYS := 3
const SHIFT_HOURS := 4.0
const FRIDGE_MAX := 12
const ITEM_SCALE := 1.5
const STORE := Vector3(0, 0, -200)   # the supermarket interior lives far from the street
const PRODUCTS: Array[Dictionary] = [
	{"name": "לחם", "price": 9, "food": 22.0},
	{"name": "גבינה", "price": 14, "food": 18.0},
	{"name": "חלב", "price": 7, "food": 12.0},
	{"name": "תפוח", "price": 3, "food": 8.0},
	{"name": "פסטה", "price": 8, "food": 30.0},
	{"name": "ביצים", "price": 13, "food": 28.0},
	{"name": "עוף", "price": 32, "food": 55.0},
	{"name": "שוקולד", "price": 7, "food": 10.0},
]
const SAVE_PATH := "user://life-city.cfg"

enum State { MENU, PLAY, OVER }


class Person:
	var root: Node3D
	var limbs: Array[Node3D] = []   # leg, leg, arm, arm
	var phase := 0.0
	var dir := 1.0
	var speed := 2.0


class Place:
	var key: String
	var title: String
	var prompt: String
	var door: Vector3
	var open_from := 0.0
	var open_to := 24.0


## Drag-anywhere joystick drawn while a finger is down.
class TouchPad:
	extends Control
	var on := false
	var origin := Vector2.ZERO
	var knob := Vector2.ZERO

	func _draw() -> void:
		if on:
			draw_circle(origin, 110.0, Color(1, 1, 1, 0.14))
			draw_arc(origin, 110.0, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 4.0, true)
			draw_circle(origin + knob * 110.0, 48.0, Color(1, 1, 1, 0.6))


var state := State.MENU
var busy := false                  # a time-skip fade is running

# Life stats
var day := 1
var clock := 7.0                   # hours, 0..24
var money := 200
var hunger := 70.0                 # 100 = full
var energy := 85.0
var health := 100.0
var fridge: Array[int] = []        # product ids waiting at home
var basket: Array[Node3D] = []     # items picked off the shelves, not yet paid for
var store_items: Array[Node3D] = []
var inside := false                # walking around inside the supermarket
var focus: Node3D                  # shelf item close enough to grab
var reach := 0.0
var basket_mesh: MeshInstance3D
var press_pos := Vector2.INF
var shifts := 0
var wage := 40                     # per hour
var over_reason := ""

var places: Array[Place] = []
var near: Place
var open_place: Place
var actions: Array[Callable] = []

var player: CharacterBody3D
var me := Person.new()
var npcs: Array[Person] = []
var cam: Camera3D
var cam_focus := Vector3.ZERO
var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var lamp_mat: StandardMaterial3D
var window_mat: StandardMaterial3D

# HUD
var bidi := true
var font: Font
var hud: Control
var stats_box: Control
var info_label: Label
var bars := {}
var prompt: Button
var panel: PanelContainer
var panel_title: Label
var panel_text: Label
var panel_buttons: GridContainer
var panel_note: Label
var toast: Label
var toast_tween: Tween
var fade: ColorRect
var fade_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_text: Label
var overlay_buttons: VBoxContainer
var pad: TouchPad
var stick_id := -1
var stick_vec := Vector2.ZERO

var sfx := {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	bidi = TextServerManager.get_primary_interface().has_feature(TextServer.FEATURE_BIDI_LAYOUT)
	font = load("res://font.ttf")
	_build_world()
	_build_player()
	_build_hud()
	_build_sounds()
	get_window().size_changed.connect(_layout)
	_layout()
	_apply_daylight()
	_show_menu()


# ---------------------------------------------------------------- world ----

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _solid(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = pos
	add_child(body)


func _sign(text: String, pos: Vector3, size: int = 96) -> void:
	var l := Label3D.new()
	l.text = _h(text)
	l.font = font
	l.font_size = size
	l.pixel_size = 0.012
	l.outline_size = 24
	l.modulate = Color.WHITE
	l.outline_modulate = Color(0.1, 0.1, 0.2)
	l.position = pos
	add_child(l)


func _building(key: String, title: String, x: float, w: float, h: float, wall: Color, roof: Color,
		open_from: float, open_to: float) -> void:
	var depth := 8.0
	var z := -10.0
	_box(Vector3(w, h, depth), Vector3(x, h * 0.5, z), _mat(wall))
	_box(Vector3(w + 0.6, 0.4, depth + 0.6), Vector3(x, h + 0.2, z), _mat(roof))
	_solid(Vector3(w, h, depth), Vector3(x, h * 0.5, z))
	var front := z + depth * 0.5
	_box(Vector3(1.5, 2.5, 0.12), Vector3(x, 1.25, front + 0.05), _mat(Color(0.3, 0.2, 0.12)))
	var floors := int(h / 3.2)
	for f in maxi(floors, 1):
		for side: float in [-1.0, 1.0]:
			_box(Vector3(1.6, 1.3, 0.1), Vector3(x + side * w * 0.3, 2.1 + f * 3.2, front + 0.05), window_mat)
	_sign(title, Vector3(x, h + 1.4, front + 0.3))
	# Door mat marks where to stand.
	_box(Vector3(2.4, 0.04, 1.6), Vector3(x, 0.03, front + 1.3), _mat(roof.lightened(0.2)))
	var p := Place.new()
	p.key = key
	p.title = title
	p.prompt = "להיכנס: " + title
	p.door = Vector3(x, 0, front + 1.3)
	p.open_from = open_from
	p.open_to = open_to
	places.append(p)


func _tree(pos: Vector3) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.3
	trunk.height = 2.0
	var t := MeshInstance3D.new()
	t.mesh = trunk
	t.material_override = _mat(Color(0.42, 0.28, 0.16))
	t.position = pos + Vector3(0, 1.0, 0)
	add_child(t)
	var crown := SphereMesh.new()
	var r := rng.randf_range(1.3, 1.9)
	crown.radius = r
	crown.height = r * 2.0
	crown.radial_segments = 10
	crown.rings = 6
	var c := MeshInstance3D.new()
	c.mesh = crown
	c.material_override = _mat(Color.from_hsv(rng.randf_range(0.27, 0.36), 0.6, rng.randf_range(0.45, 0.65)))
	c.position = pos + Vector3(0, 2.0 + r * 0.7, 0)
	add_child(c)


func _build_world() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	cam = Camera3D.new()
	cam.far = 300.0
	add_child(cam)
	cam.make_current()

	window_mat = _mat(Color(0.55, 0.75, 0.9))
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.85, 0.5)
	lamp_mat = _mat(Color(1.0, 0.95, 0.75))
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.6)

	# Ground, road, pavements.
	_box(Vector3(160, 1, 110), Vector3(0, -0.5, 0), _mat(Color(0.34, 0.56, 0.3)))
	_solid(Vector3(160, 1, 110), Vector3(0, -0.5, 0))
	_box(Vector3(160, 0.04, 6), Vector3(0, 0.02, 1.5), _mat(Color(0.25, 0.26, 0.29)))
	var dash := _mat(Color(0.9, 0.9, 0.85))
	for k in range(-19, 20):
		_box(Vector3(1.8, 0.02, 0.2), Vector3(k * 4.0, 0.05, 1.5), dash)
	var paving := _mat(Color(0.58, 0.56, 0.53))
	_box(Vector3(160, 0.04, 4.5), Vector3(0, 0.015, -3.75), paving)
	_box(Vector3(160, 0.04, 2.0), Vector3(0, 0.015, 5.5), paving)

	_building("home", "הבית שלי", -24, 9, 4.2, Color(0.85, 0.7, 0.48), Color(0.68, 0.28, 0.2), 0, 24)
	_building("market", "סופרמרקט", -8, 12, 4.2, Color(0.78, 0.8, 0.84), Color(0.15, 0.55, 0.3), 7, 22)
	_building("cafe", "קפה ומסעדה", 8, 9, 4.2, Color(0.82, 0.72, 0.58), Color(0.7, 0.4, 0.18), 8, 23)
	_building("work", "המשרד", 24, 12, 10.5, Color(0.55, 0.62, 0.72), Color(0.25, 0.3, 0.4), 8, 24)

	# Street lamps.
	var pole_mat := _mat(Color(0.2, 0.2, 0.22))
	for x: float in [-32.0, -16.0, 0.0, 16.0, 32.0]:
		_box(Vector3(0.18, 4.2, 0.18), Vector3(x, 2.1, -1.9), pole_mat)
		_box(Vector3(0.9, 0.25, 0.5), Vector3(x, 4.2, -1.6), lamp_mat)

	# Park across the road.
	var pond := CylinderMesh.new()
	pond.top_radius = 4.5
	pond.bottom_radius = 4.5
	pond.height = 0.06
	var pond_mi := MeshInstance3D.new()
	pond_mi.mesh = pond
	pond_mi.material_override = _mat(Color(0.3, 0.6, 0.85))
	pond_mi.position = Vector3(4, 0.03, 14)
	add_child(pond_mi)
	_sign("הפארק", Vector3(-6, 2.6, 8.2), 72)
	_box(Vector3(0.15, 2.2, 0.15), Vector3(-6, 1.1, 8.2), pole_mat)
	var bench := _mat(Color(0.5, 0.33, 0.2))
	for x: float in [-3.0, 11.0]:
		_box(Vector3(2.4, 0.15, 0.7), Vector3(x, 0.55, 9.5), bench)
		_box(Vector3(2.4, 0.7, 0.12), Vector3(x, 0.95, 9.85), bench)
		_solid(Vector3(2.4, 1.2, 0.8), Vector3(x, 0.6, 9.6))
	for k in 34:
		var pos := Vector3(rng.randf_range(-45, 45), 0, rng.randf_range(8, 28))
		if pos.distance_to(Vector3(4, 0, 14)) < 6.5 or (pos.z < 11.0 and absf(pos.x - 4.0) < 9.0):
			continue
		_tree(pos)
	for k in 16:
		_tree(Vector3(rng.randf_range(-48, 48), 0, rng.randf_range(-26, -17)))
	for x: float in [-41.0, 41.0]:
		_tree(Vector3(x, 0, -8))

	# Passers-by on the pavements.
	for k in 6:
		var n := _make_person(Color.from_hsv(rng.randf(), 0.55, 0.85), Color.from_hsv(rng.randf(), 0.3, 0.4))
		n.dir = 1.0 if k % 2 == 0 else -1.0
		n.speed = rng.randf_range(1.6, 2.6)
		n.root.position = Vector3(rng.randf_range(-38, 38), 0, 5.6 if k % 3 == 0 else rng.randf_range(-2.6, -2.0))
		add_child(n.root)
		npcs.append(n)
	_build_store()


func _make_person(shirt: Color, pants: Color, into: Person = null) -> Person:
	var p := into if into else Person.new()
	p.root = Node3D.new()
	var skin := _mat(Color(0.93, 0.74, 0.58))
	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 0.95
	var t := MeshInstance3D.new()
	t.mesh = torso
	t.material_override = _mat(shirt)
	t.position.y = 1.15
	p.root.add_child(t)
	var head := SphereMesh.new()
	head.radius = 0.26
	head.height = 0.52
	var hd := MeshInstance3D.new()
	hd.mesh = head
	hd.material_override = skin
	hd.position.y = 1.86
	p.root.add_child(hd)
	_box(Vector3(0.5, 0.2, 0.5), Vector3(0, 2.03, -0.04), _mat(Color(0.2, 0.13, 0.08)), p.root)
	var dark := _mat(Color(0.08, 0.08, 0.1))
	for sx: float in [-0.1, 0.1]:
		_box(Vector3(0.06, 0.06, 0.04), Vector3(sx, 1.9, 0.25), dark, p.root)
	for sx: float in [-0.15, 0.15]:
		var hip := Node3D.new()
		hip.position = Vector3(sx, 0.75, 0)
		p.root.add_child(hip)
		_box(Vector3(0.22, 0.75, 0.24), Vector3(0, -0.375, 0), _mat(pants), hip)
		p.limbs.append(hip)
	for sx: float in [-0.4, 0.4]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(sx, 1.5, 0)
		p.root.add_child(shoulder)
		_box(Vector3(0.16, 0.7, 0.16), Vector3(0, -0.35, 0), skin, shoulder)
		p.limbs.append(shoulder)
	return p


func _animate(p: Person, moving: bool, dt: float) -> void:
	if moving:
		p.phase += dt * 9.0
	var swing := sin(p.phase) * 0.7 if moving else 0.0
	var signs := [1.0, -1.0, -1.0, 1.0]
	for k in 4:
		p.limbs[k].rotation.x = lerp_angle(p.limbs[k].rotation.x, swing * signs[k], 12.0 * dt)


func _build_player() -> void:
	player = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	player.add_child(cs)
	_make_person(Color(0.2, 0.5, 0.95), Color(0.15, 0.2, 0.4), me)
	player.add_child(me.root)
	basket_mesh = _box(Vector3(0.5, 0.32, 0.38), Vector3(0, -0.85, 0.12), _mat(Color(0.85, 0.2, 0.2)), me.limbs[2])
	basket_mesh.visible = false
	add_child(player)
	_reset_position()


func _reset_position() -> void:
	inside = false
	_return_all()
	player.position = places[0].door + Vector3(0, 0, 1.2)
	player.velocity = Vector3.ZERO
	me.root.rotation.y = 0.0
	cam_focus = player.position


## Sun, sky and lamps follow the clock.
func _apply_daylight() -> void:
	var hour := 12.0 if inside else clock                      # the shop is lit all day
	var elevation := sin((hour - 6.0) / 12.0 * PI)          # 1 at noon, <0 at night
	var light := clampf(elevation * 2.5 + 0.25, 0.0, 1.0)
	sun.rotation_degrees = Vector3(-clampf(elevation, 0.12, 1.0) * 65.0, (hour - 12.0) * 9.0 - 25.0, 0)
	sun.light_energy = 0.04 + light * 0.8
	sun.light_color = Color(1.0, 0.72, 0.5).lerp(Color(1, 0.98, 0.93), clampf(elevation * 2.0, 0.0, 1.0))
	var night_top := Color(0.03, 0.04, 0.12)
	var night_low := Color(0.08, 0.1, 0.2)
	sky_mat.sky_top_color = night_top.lerp(Color(0.25, 0.5, 0.9), light)
	var horizon := night_low.lerp(Color(0.75, 0.86, 0.96), light)
	if elevation > -0.2 and elevation < 0.35:
		horizon = horizon.lerp(Color(1.0, 0.6, 0.35), 0.6 * (1.0 - absf(elevation - 0.08) / 0.28))
	sky_mat.sky_horizon_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = night_top.lerp(Color(0.4, 0.5, 0.6), light)
	env.ambient_light_color = Color(0.22, 0.26, 0.42).lerp(Color(0.4, 0.43, 0.48), light)
	var glow := 1.0 - light
	lamp_mat.emission_energy_multiplier = glow * 3.0
	window_mat.emission_energy_multiplier = glow * 1.4


# ----------------------------------------------------------------- life ----

## Advance the simulation by `hours`. mode: "awake", "work" or "sleep".
func _tick(hours: float, mode: String) -> void:
	match mode:
		"work":
			hunger -= 5.5 * hours
			energy -= 7.5 * hours
		"sleep":
			hunger -= 1.5 * hours
			energy += 12.5 * hours
		_:
			hunger -= 4.0 * hours
			energy -= 4.5 * hours
	hunger = clampf(hunger, 0.0, 100.0)
	energy = clampf(energy, 0.0, 100.0)
	if hunger <= 0.0:
		health -= 9.0 * hours
	if energy <= 0.0:
		health -= 6.0 * hours
	if hunger > 40.0 and energy > 30.0:
		health += 3.0 * hours
	health = clampf(health, 0.0, 100.0)
	clock += hours
	if clock >= 24.0:
		clock -= 24.0
		day += 1
		_new_day()
	if health <= 0.0 and state == State.PLAY:
		_game_over("קרסת מרעב ומעייפות.\nצריך לאכול ולישון בזמן.")


func _skip(hours: float, mode: String) -> void:
	var left := hours
	while left > 0.0 and state == State.PLAY:
		var step := minf(0.25, left)
		_tick(step, mode)
		left -= step


func _new_day() -> void:
	if (day - 1) % RENT_DAYS == 0:
		if money >= RENT:
			money -= RENT
			_toast("שולם שכר דירה: ₪%d" % RENT)
			_play("pay")
		else:
			_game_over("לא היה מספיק כסף לשכר הדירה (₪%d).\nפינו אותך מהדירה." % RENT)
			return
	_save()


func _days_to_rent() -> int:
	return RENT_DAYS - ((day - 1) % RENT_DAYS)


func _is_open(p: Place) -> bool:
	return clock >= p.open_from and clock < p.open_to


func _time_text(h: float) -> String:
	var total := int(h * 60.0)
	return "%02d:%02d" % [(total / 60) % 24, total % 60]


# Actions -------------------------------------------------------------------

func _eat(pid: int) -> void:
	var at := fridge.find(pid)
	if at < 0:
		return
	fridge.remove_at(at)
	hunger = minf(hunger + float(PRODUCTS[pid]["food"]), 100.0)
	_skip(0.33, "awake")
	_play("eat")
	_toast("אכלת %s." % PRODUCTS[pid]["name"])
	_refresh_panel()


func _sleep() -> void:
	if energy > 85.0:
		_toast("אתה עוד לא עייף.")
		_play("no")
		return
	var hours := clampf(ceilf((100.0 - energy) / 12.5), 1.0, 9.0)
	_time_skip("לילה טוב...", func() -> void:
		_skip(hours, "sleep")
		_save()
		_toast("ישנת %d שעות. בוקר טוב!" % int(hours)))


func _cafe(price: int, food: float, boost: float, hours: float, msg: String) -> void:
	if money < price:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	money -= price
	hunger = minf(hunger + food, 100.0)
	energy = minf(energy + boost, 100.0)
	_skip(hours, "awake")
	_play("eat")
	_toast(msg)
	_refresh_panel()


func _work() -> void:
	if clock > 16.0:
		_toast("מאוחר מדי להתחיל משמרת. בוא מחר ב-8:00.")
		_play("no")
		return
	if energy < 25.0:
		_toast("אתה עייף מדי לעבוד. לך לישון.")
		_play("no")
		return
	if hunger < 15.0:
		_toast("אתה רעב מדי לעבוד. לך לאכול.")
		_play("no")
		return
	_time_skip("עובדים...", func() -> void:
		_skip(SHIFT_HOURS, "work")
		var pay := int(wage * SHIFT_HOURS)
		money += pay
		shifts += 1
		_play("pay")
		if shifts % 5 == 0:
			wage += 8
			_toast("קיבלת ₪%d, וגם העלאה! השכר עכשיו ₪%d לשעה." % [pay, wage])
		else:
			_toast("סיימת משמרת וקיבלת ₪%d." % pay))


func _time_skip(text: String, apply: Callable) -> void:
	busy = true
	_close_panel()
	fade_label.text = _h(text)
	fade.visible = true
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.35)
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void:
		apply.call()
		_apply_daylight()
		_update_hud())
	tw.tween_property(fade, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void:
		fade.visible = false
		busy = false)


# ---------------------------------------------------------------- panel ----

func _open_panel(p: Place) -> void:
	if busy or state != State.PLAY:
		return
	open_place = p
	stick_id = -1
	stick_vec = Vector2.ZERO
	pad.on = false
	panel_note.text = ""
	_play("door")
	_refresh_panel()
	panel.visible = true


func _close_panel() -> void:
	open_place = null
	panel.visible = false
	actions.clear()


func _add_action(text: String, action: Callable) -> void:
	actions.append(action)
	var b := Button.new()
	b.text = _h(text)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	panel_buttons.add_child(b)


func _refresh_panel() -> void:
	_update_hud()
	if open_place == null or state != State.PLAY:
		return
	for c in panel_buttons.get_children():
		c.queue_free()
	actions.clear()
	var p := open_place
	panel_title.text = _h(p.title)
	if not _is_open(p):
		panel_text.text = _h("סגור עכשיו. פתוח בין %s ל-%s." % [_time_text(p.open_from), _time_text(p.open_to)])
	else:
		match p.key:
			"home":
				panel_text.text = _h("המקרר ריק. צריך לקנות אוכל בסופר." if fridge.is_empty() else "מה לאכול מהמקרר?")
				for pid in PRODUCTS.size():
					var have := fridge.count(pid)
					if have > 0:
						_add_action("%s ×%d" % [PRODUCTS[pid]["name"], have], _eat.bind(pid))
				_add_action("לישון", _sleep)
			"checkout":
				if basket.is_empty():
					panel_text.text = _h("הסל ריק. קחו מוצרים מהמדפים.")
				else:
					var parts: PackedStringArray = []
					for pid in PRODUCTS.size():
						var have := _basket_count(pid)
						if have > 0:
							parts.append(_h("%s ×%d" % [PRODUCTS[pid]["name"], have]))
					panel_text.text = " · ".join(parts) + "\n" + _h("סך הכול: ₪%d" % _basket_total())
					_add_action("לשלם ₪%d" % _basket_total(), _pay)
					_add_action("להחזיר מוצר אחד", _return_last)
					_add_action("להחזיר הכול למדף", _return_all_action)
			"cafe":
				panel_text.text = _h("אוכלים כאן ועכשיו, בלי לחזור הביתה")
				_add_action("ארוחה חמה · ₪55", _cafe.bind(55, 60.0, 0.0, 0.75, "אכלת ארוחה חמה. טעים!"))
				_add_action("קפה · ₪14", _cafe.bind(14, 3.0, 15.0, 0.25, "שתית קפה. קצת יותר ערני."))
			"work":
				panel_text.text = _h("שכר: ₪%d לשעה · משמרות שעבדת: %d" % [wage, shifts])
				_add_action("לעבוד משמרת (%d שעות) · ₪%d" % [int(SHIFT_HOURS), int(wage * SHIFT_HOURS)], _work)
	var close := Button.new()
	close.text = _h("לצאת")
	close.focus_mode = Control.FOCUS_NONE
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(_close_panel)
	panel_buttons.add_child(close)
	panel_buttons.columns = 2 if actions.size() > 4 else 1


# ----------------------------------------------------------------- loop ----

func _move_input() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if v == Vector2.ZERO:
		v = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if v == Vector2.ZERO:
		v = stick_vec
	return v.limit_length(1.0)


func _physics_process(delta: float) -> void:
	for n in npcs:
		n.root.position.x += n.dir * n.speed * delta
		if absf(n.root.position.x) > 44.0:
			n.dir = -n.dir
		n.root.rotation.y = PI * 0.5 * n.dir
		_animate(n, true, delta)

	var walking := state == State.PLAY and open_place == null and not busy
	var input := _move_input() if walking else Vector2.ZERO
	# Tired or starving people walk slower.
	var speed := WALK_SPEED * (0.6 if (energy < 15.0 or hunger < 10.0) else 1.0)
	player.velocity = Vector3(input.x * speed, -4.0, input.y * speed)
	player.move_and_slide()
	if inside:
		player.position.x = clampf(player.position.x, STORE.x - 10.8, STORE.x + 10.8)
		player.position.z = clampf(player.position.z, STORE.z - 7.9, STORE.z + 8.2)
	else:
		player.position.x = clampf(player.position.x, -42.0, 42.0)
		player.position.z = clampf(player.position.z, -5.6, 26.0)
	if input.length_squared() > 0.01:
		me.root.rotation.y = lerp_angle(me.root.rotation.y, atan2(input.x, input.y), 12.0 * delta)
	_animate(me, input.length_squared() > 0.01, delta)
	reach = maxf(reach - delta, 0.0)
	if reach > 0.0:
		me.limbs[3].rotation.x = -1.9          # arm stretched out to the shelf

	if not walking:
		return
	_tick(delta / HOUR_SECONDS, "awake")
	_apply_daylight()
	near = null
	for p in places:
		if p.door.distance_to(player.position) < 2.2:
			near = p
	_update_focus()
	_update_hud()


func _process(delta: float) -> void:
	var view := get_viewport().get_visible_rect().size
	var portrait := view.y > view.x
	cam.fov = 75.0 if portrait else 50.0
	var want := player.position + Vector3(0, 1.0, -1.5)
	if state == State.MENU:
		want = Vector3(sin(Time.get_ticks_msec() * 0.0002) * 14.0, 1.0, -3.0)
	cam_focus = cam_focus.lerp(want, 1.0 - exp(-5.0 * delta))
	cam.position = cam_focus + (Vector3(0, 7.0, 6.5) if inside else Vector3(0, 11.5, 13.0))
	cam.look_at(cam_focus)
	pad.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and stick_id < 0 and state == State.PLAY and open_place == null:
			stick_id = e.index
			pad.origin = e.position
			pad.knob = Vector2.ZERO
			pad.on = true
		elif not e.pressed and e.index == stick_id:
			stick_id = -1
			stick_vec = Vector2.ZERO
			pad.on = false
	elif e is InputEventScreenDrag and e.index == stick_id:
		stick_vec = ((e.position - pad.origin) / 110.0).limit_length(1.0)
		pad.knob = stick_vec
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		# A click or tap that did not turn into a drag grabs the product under it.
		if e.pressed:
			press_pos = e.position
		else:
			if press_pos.distance_to(e.position) < 24.0:
				_tap(e.position)
			press_pos = Vector2.INF
	elif e is InputEventKey and e.pressed and not e.echo:
		var key: int = e.physical_keycode
		if state != State.PLAY:
			if key in [KEY_ENTER, KEY_SPACE]:
				if state == State.MENU and FileAccess.file_exists(SAVE_PATH):
					_continue_game()
				else:
					_new_game()
		elif open_place != null:
			if key == KEY_ESCAPE:
				_close_panel()
			elif key >= KEY_1 and key <= KEY_9 and key - KEY_1 < actions.size():
				actions[key - KEY_1].call()
		elif key in [KEY_E, KEY_ENTER, KEY_SPACE]:
			if near != null:
				_interact(near)
			elif focus != null:
				_pick(focus)


# ---------------------------------------------------------- game states ----

func _new_game() -> void:
	day = 1
	clock = 7.0
	money = 200
	hunger = 70.0
	energy = 85.0
	health = 100.0
	fridge = [0, 5]
	shifts = 0
	wage = 40
	_begin()
	_toast("בוקר טוב! לך לעבודה, קנה אוכל ושמור על עצמך.")


func _continue_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		_new_game()
		return
	day = int(cfg.get_value("life", "day", 1))
	clock = float(cfg.get_value("life", "clock", 7.0))
	money = int(cfg.get_value("life", "money", 200))
	hunger = float(cfg.get_value("life", "hunger", 70.0))
	energy = float(cfg.get_value("life", "energy", 85.0))
	health = float(cfg.get_value("life", "health", 100.0))
	fridge.clear()
	var stored: Variant = cfg.get_value("life", "fridge", [])
	if stored is Array:
		for v: Variant in stored:
			if int(v) >= 0 and int(v) < PRODUCTS.size():
				fridge.append(int(v))
	shifts = int(cfg.get_value("life", "shifts", 0))
	wage = int(cfg.get_value("life", "wage", 40))
	_begin()
	_toast("ברוך שובך! יום %d." % day)


func _begin() -> void:
	state = State.PLAY
	busy = false
	near = null
	_close_panel()
	_reset_position()
	overlay.visible = false
	me.root.visible = true
	_apply_daylight()
	_update_hud()
	_play("door")


func _save() -> void:
	if state != State.PLAY:
		return
	var cfg := ConfigFile.new()
	for pair: Array in [["day", day], ["clock", clock], ["money", money], ["hunger", hunger],
			["energy", energy], ["health", health], ["fridge", fridge], ["shifts", shifts], ["wage", wage]]:
		cfg.set_value("life", pair[0], pair[1])
	cfg.save(SAVE_PATH)


func _game_over(reason: String) -> void:
	state = State.OVER
	over_reason = reason
	_close_panel()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_play("no")
	_overlay("המשחק נגמר", reason + "\n" + "שרדת %d ימים · עבדת %d משמרות" % [day, shifts],
		[["להתחיל מחדש", _new_game]])


func _show_menu() -> void:
	state = State.MENU
	var buttons: Array = []
	if FileAccess.file_exists(SAVE_PATH):
		buttons.append(["להמשיך", _continue_game])
	buttons.append(["משחק חדש", _new_game])
	_overlay("חיים בעיר", "\n".join([
		"עבדו במשרד כדי להרוויח כסף, קנו אוכל בסופר,",
		"אכלו ושנו בבית, ושלמו ₪%d שכר דירה כל %d ימים." % [RENT, RENT_DAYS],
		"",
		"תנועה: חיצים או WASD · כניסה לבניין: E",
		"בטלפון: גוררים אצבע על המסך כדי ללכת",
		"בסופר: לוחצים על מוצר במדף כדי לקחת אותו, ומשלמים בקופה",
	]), buttons)


func _overlay(title: String, text: String, buttons: Array) -> void:
	overlay_title.text = _h(title)
	var lines: PackedStringArray = []
	for line in text.split("\n"):
		lines.append(_h(line))
	overlay_text.text = "\n".join(lines)
	for c in overlay_buttons.get_children():
		c.queue_free()
	for b: Array in buttons:
		var btn := Button.new()
		btn.text = _h(b[0])
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(420, 0)
		btn.pressed.connect(b[1])
		overlay_buttons.add_child(btn)
	overlay.visible = true
	_update_hud()


# ------------------------------------------------------------------ HUD ----

## Hebrew needs BiDi layout. If this build's text server lacks it, reverse the
## string ourselves (keeping numbers and Latin words readable).
func _h(s: String) -> String:
	if bidi or s.is_empty():
		return s
	var out := ""
	var run := ""
	for ch in s.reverse():
		var code := ch.unicode_at(0)
		if (code >= 48 and code <= 58) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			run = ch + run
		else:
			out += run + ch
			run = ""
	return out + run


func _label(size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.18))
	l.add_theme_constant_override("outline_size", maxi(size / 5, 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _flat(color: Color, radius: int = 14, margin: int = 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 34
	theme.set_font_size("font_size", "Button", 38)
	theme.set_stylebox("normal", "Button", _flat(Color(0.2, 0.45, 0.85)))
	theme.set_stylebox("hover", "Button", _flat(Color(0.28, 0.55, 0.95)))
	theme.set_stylebox("pressed", "Button", _flat(Color(0.14, 0.33, 0.66)))
	theme.set_stylebox("panel", "PanelContainer", _flat(Color(0.1, 0.13, 0.22, 0.94), 24, 32))
	hud.theme = theme
	layer.add_child(hud)

	pad = TouchPad.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(pad)

	# Top-left: day, clock, money, fridge, rent.
	info_label = _label(34)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	hud.add_child(info_label)

	# Top-right: need bars.
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	hud.add_child(box)
	stats_box = box
	for def: Array in [["hunger", "שובע", Color(1.0, 0.62, 0.2)], ["energy", "אנרגיה", Color(0.3, 0.7, 1.0)],
			["health", "בריאות", Color(0.95, 0.3, 0.4)]]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 14)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(240, 30)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", _flat(Color(0.05, 0.07, 0.12, 0.75), 10, 0))
		bar.add_theme_stylebox_override("fill", _flat(def[2], 10, 0))
		row.add_child(bar)
		var name_label := _label(30)
		name_label.text = _h(def[1])
		name_label.custom_minimum_size = Vector2(130, 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_label)
		box.add_child(row)
		bars[def[0]] = bar

	toast = _label(36, Color(1.0, 0.95, 0.7))
	toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_top = -300
	toast.offset_bottom = -150
	toast.offset_left = 40
	toast.offset_right = -40
	toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.modulate.a = 0.0
	hud.add_child(toast)

	prompt = Button.new()
	prompt.focus_mode = Control.FOCUS_NONE
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 40)
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt.pressed.connect(func() -> void:
		if near != null:
			_interact(near))
	prompt.visible = false
	hud.add_child(prompt)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.visible = false
	center.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 18)
	panel.add_child(pv)
	panel_title = _label(56, Color(1.0, 0.85, 0.3))
	pv.add_child(panel_title)
	panel_text = _label(32)
	panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(panel_text)
	panel_buttons = GridContainer.new()
	panel_buttons.add_theme_constant_override("h_separation", 14)
	panel_buttons.add_theme_constant_override("v_separation", 14)
	pv.add_child(panel_buttons)
	panel_note = _label(30, Color(1.0, 0.95, 0.7))
	panel_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(panel_note)

	fade = ColorRect.new()
	fade.color = Color(0.02, 0.03, 0.08)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	fade.visible = false
	hud.add_child(fade)
	fade_label = _label(72)
	fade_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fade.add_child(fade_label)

	overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.08, 0.16, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(oc)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 26)
	oc.add_child(ov)
	overlay_title = _label(104, Color(1.0, 0.85, 0.3))
	ov.add_child(overlay_title)
	overlay_text = _label(34)
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(overlay_text)
	overlay_buttons = VBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 14)
	overlay_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ov.add_child(overlay_buttons)


## Phones in portrait get a narrower virtual canvas so text stays readable.
func _layout() -> void:
	var win := get_window()
	var portrait := win.size.y > win.size.x
	win.content_scale_size = Vector2i(720, 1280) if portrait else Vector2i(1280, 720)
	var width := 660.0 if portrait else 760.0
	panel.custom_minimum_size.x = width
	overlay_text.custom_minimum_size.x = width if portrait else 1000.0
	for key: String in bars:
		(bars[key] as ProgressBar).custom_minimum_size.x = 170.0 if portrait else 240.0


func _update_hud() -> void:
	var playing := state == State.PLAY
	info_label.visible = playing
	stats_box.visible = playing
	var rent_days := _days_to_rent()
	var rent_when := "מחר" if rent_days == 1 else "עוד %d ימים" % rent_days
	info_label.text = "\n".join([
		_h("יום %d · %s" % [day, _time_text(clock)]),
		_h("כסף: ₪%d" % money),
		_h("אוכל בבית: %d" % fridge.size()),
		_h("שכר דירה: %s" % rent_when),
		_h("בסל: %d מוצרים · ₪%d" % [basket.size(), _basket_total()]) if inside else "",
	])
	basket_mesh.visible = not basket.is_empty()
	(bars["hunger"] as ProgressBar).value = hunger
	(bars["energy"] as ProgressBar).value = energy
	(bars["health"] as ProgressBar).value = health
	prompt.visible = playing and near != null and open_place == null and not busy
	if prompt.visible:
		prompt.text = _h(near.prompt)


func _toast(text: String) -> void:
	if open_place != null:
		panel_note.text = _h(text)
		return
	toast.text = _h(text)
	toast.modulate.a = 1.0
	if toast_tween:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(3.0)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- audio ----

## Sounds are synthesised at startup, so the game ships no audio files.
func _tone(f0: float, f1: float, dur: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(dur * rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var k := float(i) / count
		phase += TAU * lerpf(f0, f1, k) / rate
		data.encode_s16(i * 2, int(sin(phase) * vol * (1.0 - k) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


func _build_sounds() -> void:
	var defs := {
		"door": _tone(420, 520, 0.12, 0.25),
		"eat": _tone(300, 420, 0.25, 0.3),
		"pay": _tone(880, 1320, 0.3, 0.25),
		"no": _tone(220, 150, 0.3, 0.3),
		"pick": _tone(620, 760, 0.1, 0.25),
	}
	for key: String in defs:
		var p := AudioStreamPlayer.new()
		p.stream = defs[key]
		add_child(p)
		sfx[key] = p


func _play(key: String) -> void:
	(sfx[key] as AudioStreamPlayer).play()


# ---------------------------------------------------------- supermarket ----

func _ball(radius: float, pos: Vector3, mat: Material, parent: Node, squash: Vector3 = Vector3.ONE) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	parent.add_child(mi)


## A small model for each product, sitting on y = 0.
func _product_node(pid: int) -> Node3D:
	var n := Node3D.new()
	match pid:
		0:  # bread
			_ball(0.2, Vector3(0, 0.17, 0), _mat(Color(0.72, 0.48, 0.22)), n, Vector3(1.0, 0.85, 1.9))
		1:  # cheese
			_box(Vector3(0.42, 0.24, 0.34), Vector3(0, 0.12, 0), _mat(Color(0.98, 0.8, 0.2)), n)
		2:  # milk carton
			_box(Vector3(0.24, 0.42, 0.24), Vector3(0, 0.21, 0), _mat(Color(0.95, 0.95, 0.97)), n)
			_box(Vector3(0.25, 0.12, 0.25), Vector3(0, 0.46, 0), _mat(Color(0.2, 0.45, 0.9)), n)
		3:  # apple
			_ball(0.19, Vector3(0, 0.19, 0), _mat(Color(0.85, 0.12, 0.12)), n)
			_box(Vector3(0.03, 0.1, 0.03), Vector3(0, 0.4, 0), _mat(Color(0.3, 0.2, 0.1)), n)
		4:  # pasta box
			_box(Vector3(0.3, 0.46, 0.14), Vector3(0, 0.23, 0), _mat(Color(0.15, 0.3, 0.7)), n)
			_box(Vector3(0.2, 0.18, 0.15), Vector3(0, 0.26, 0), _mat(Color(0.98, 0.82, 0.4)), n)
		5:  # egg carton
			_box(Vector3(0.48, 0.14, 0.3), Vector3(0, 0.07, 0), _mat(Color(0.5, 0.45, 0.36)), n)
			for k in 3:
				_ball(0.07, Vector3(-0.15 + k * 0.15, 0.16, 0), _mat(Color(0.97, 0.93, 0.85)), n, Vector3(1, 1.2, 1))
		6:  # chicken on a tray
			_box(Vector3(0.5, 0.06, 0.36), Vector3(0, 0.03, 0), _mat(Color(0.9, 0.9, 0.9)), n)
			_ball(0.17, Vector3(0, 0.17, 0), _mat(Color(0.95, 0.72, 0.6)), n, Vector3(1.3, 0.8, 1.0))
		_:  # chocolate bar
			_box(Vector3(0.42, 0.08, 0.24), Vector3(0, 0.04, 0), _mat(Color(0.35, 0.18, 0.08)), n)
			_box(Vector3(0.2, 0.085, 0.245), Vector3(-0.08, 0.04, 0), _mat(Color(0.75, 0.1, 0.15)), n)
	return n


func _shelf(pid: int, pos: Vector3) -> void:
	var wood := _mat(Color(0.4, 0.29, 0.2))
	_box(Vector3(3.4, 1.0, 1.0), pos + Vector3(0, 0.5, 0), wood)
	_box(Vector3(3.4, 1.3, 0.15), pos + Vector3(0, 1.65, -0.42), _mat(Color(0.16, 0.34, 0.55)))
	_solid(Vector3(3.4, 2.0, 1.0), pos + Vector3(0, 1.0, 0))
	var tag := Label3D.new()
	tag.text = _h("%s ₪%d" % [PRODUCTS[pid]["name"], PRODUCTS[pid]["price"]])
	tag.font = font
	tag.font_size = 64
	tag.pixel_size = 0.01
	tag.outline_size = 16
	tag.outline_modulate = Color(0.05, 0.1, 0.2)
	tag.position = pos + Vector3(0, 1.75, -0.32)
	add_child(tag)
	for k in 4:
		var item := _product_node(pid)
		item.position = pos + Vector3(-1.2 + k * 0.8, 1.0, 0.12)
		item.scale = Vector3.ONE * ITEM_SCALE
		item.set_meta("pid", pid)
		item.set_meta("home", item.position)
		add_child(item)
		store_items.append(item)


func _build_store() -> void:
	_box(Vector3(24, 1, 18), STORE + Vector3(0, -0.5, 0), _mat(Color(0.5, 0.47, 0.42)))
	_solid(Vector3(24, 1, 18), STORE + Vector3(0, -0.5, 0))
	var wall := _mat(Color(0.6, 0.66, 0.62))
	_box(Vector3(24, 5, 0.5), STORE + Vector3(0, 2.5, -8.75), wall)
	_solid(Vector3(24, 5, 0.5), STORE + Vector3(0, 2.5, -8.75))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.5, 5, 18), STORE + Vector3(side * 11.75, 2.5, 0), wall)
		_solid(Vector3(0.5, 5, 18), STORE + Vector3(side * 11.75, 2.5, 0))
	var slots: Array[Vector3] = [
		Vector3(-8, 0, -7.6), Vector3(-4, 0, -7.6), Vector3(0, 0, -7.6), Vector3(4, 0, -7.6), Vector3(8, 0, -7.6),
		Vector3(1, 0, -1.5), Vector3(5, 0, -1.5), Vector3(9, 0, -1.5),
	]
	for pid in PRODUCTS.size():
		_shelf(pid, STORE + slots[pid])

	# Checkout: counter, till, cashier, and a mat to stand on.
	var desk := STORE + Vector3(-7, 0, 3.4)
	_box(Vector3(3.6, 1.1, 1.2), desk + Vector3(0, 0.55, 0), _mat(Color(0.3, 0.33, 0.4)))
	_solid(Vector3(3.6, 1.1, 1.2), desk + Vector3(0, 0.55, 0))
	_box(Vector3(0.7, 0.5, 0.6), desk + Vector3(-1.0, 1.35, 0), _mat(Color(0.15, 0.15, 0.18)))
	var cashier := _make_person(Color(0.15, 0.6, 0.35), Color(0.2, 0.2, 0.25))
	cashier.root.position = desk + Vector3(0, 0, -1.3)
	add_child(cashier.root)
	_sign("קופה", desk + Vector3(0, 3.2, -1.3), 72)
	_box(Vector3(2.4, 0.04, 1.4), desk + Vector3(0, 0.03, 1.7), _mat(Color(0.95, 0.75, 0.2)))
	var till := Place.new()
	till.key = "checkout"
	till.title = "קופה"
	till.prompt = "לשלם בקופה"
	till.door = desk + Vector3(0, 0, 1.7)
	places.append(till)

	_box(Vector3(2.6, 0.04, 1.4), STORE + Vector3(0, 0.03, 7.9), _mat(Color(0.25, 0.7, 0.4)))
	var out := Place.new()
	out.key = "store_exit"
	out.title = "יציאה"
	out.prompt = "לצאת מהסופר"
	out.door = STORE + Vector3(0, 0, 7.9)
	places.append(out)


func _interact(p: Place) -> void:
	if busy or state != State.PLAY:
		return
	match p.key:
		"market":
			if not _is_open(p):
				_toast("הסופר סגור. פתוח בין %s ל-%s." % [_time_text(p.open_from), _time_text(p.open_to)])
				_play("no")
				return
			inside = true
			for item in store_items:
				item.visible = true
			player.position = STORE + Vector3(0, 0, 5.5)
			me.root.rotation.y = PI
			cam_focus = player.position
			near = null
			_play("door")
			_apply_daylight()
			_toast("לחצו על מוצר במדף כדי לקחת אותו. משלמים בקופה.")
		"store_exit":
			if not basket.is_empty():
				_toast("קודם משלמים בקופה, או מחזירים את המוצרים למדף.")
				_play("no")
				return
			inside = false
			focus = null
			for place in places:
				if place.key == "market":
					player.position = place.door + Vector3(0, 0, 1.2)
			me.root.rotation.y = 0.0
			cam_focus = player.position
			near = null
			_play("door")
			_apply_daylight()
			_update_hud()
		_:
			_open_panel(p)


func _basket_total() -> int:
	var total := 0
	for item in basket:
		total += int(PRODUCTS[int(item.get_meta("pid"))]["price"])
	return total


func _basket_count(pid: int) -> int:
	var count := 0
	for item in basket:
		if int(item.get_meta("pid")) == pid:
			count += 1
	return count


func _on_shelf(item: Node3D) -> bool:
	return item.visible and not basket.has(item)


## The nearest shelf item within arm's reach gets a little "pick me" bump.
func _update_focus() -> void:
	focus = null
	if not inside:
		return
	var best := 2.3
	var hand := player.position + Vector3(0, 1.0, 0)
	for item in store_items:
		item.scale = Vector3.ONE * ITEM_SCALE
		if not _on_shelf(item):
			continue
		var d := hand.distance_to(item.get_meta("home"))
		if d < best:
			best = d
			focus = item
	if focus != null:
		focus.scale = Vector3.ONE * ITEM_SCALE * 1.3


## Click/tap position (canvas coordinates) -> the shelf item drawn under it.
func _tap(pos: Vector2) -> void:
	if not inside or state != State.PLAY or open_place != null or busy:
		return
	var hit: Node3D
	var best := 70.0
	for item in store_items:
		if not _on_shelf(item):
			continue
		var world: Vector3 = item.get_meta("home") + Vector3(0, 0.2, 0)
		if cam.is_position_behind(world):
			continue
		var d := cam.unproject_position(world).distance_to(pos)
		if d < best:
			best = d
			hit = item
	if hit == null:
		return
	if (player.position + Vector3(0, 1.0, 0)).distance_to(hit.get_meta("home")) > 3.0:
		_toast("צריך להתקרב למדף כדי לקחת.")
		return
	_pick(hit)


func _pick(item: Node3D) -> void:
	if not _on_shelf(item):
		return
	if fridge.size() + basket.size() >= FRIDGE_MAX:
		_toast("אין יותר מקום במקרר בבית (עד %d מוצרים)." % FRIDGE_MAX)
		_play("no")
		return
	basket.append(item)
	reach = 0.35
	var to_item: Vector3 = item.get_meta("home") - player.position
	me.root.rotation.y = atan2(to_item.x, to_item.z)
	_play("pick")
	var pid := int(item.get_meta("pid"))
	_toast("לקחת %s · ₪%d" % [PRODUCTS[pid]["name"], PRODUCTS[pid]["price"]])
	var tw := create_tween()
	tw.tween_property(item, "position", player.position + Vector3(0, 1.0, 0), 0.25)
	tw.tween_callback(func() -> void:
		item.visible = false
		item.position = item.get_meta("home")
		item.scale = Vector3.ONE * ITEM_SCALE)
	_update_hud()


func _pay() -> void:
	var total := _basket_total()
	if money < total:
		_toast("אין מספיק כסף (חסרים ₪%d). החזירו משהו למדף." % (total - money))
		_play("no")
		return
	money -= total
	for item in basket:
		fridge.append(int(item.get_meta("pid")))
	var bought := basket.size()
	basket.clear()
	_skip(0.25, "awake")
	_play("pay")
	_toast("שילמת ₪%d על %d מוצרים. הם יחכו לך במקרר בבית." % [total, bought])
	_refresh_panel()


func _return_last() -> void:
	if basket.is_empty():
		return
	var item: Node3D = basket.pop_back()
	item.visible = true
	_refresh_panel()


func _return_all() -> void:
	for item in basket:
		item.visible = true
	basket.clear()


func _return_all_action() -> void:
	_return_all()
	_refresh_panel()
