extends Node3D
## Life in the City: a small everyday-life sim. Walk around town, work shifts
## for money, buy food, eat, sleep and pay the rent. The scene is built in code.

const HOUR_SECONDS := 40.0         # real seconds per game hour while walking
const WALK_SPEED := 7.0
const RENT := 300
const RENT_DAYS := 3
const SHIFT_HOURS := 4.0
const FRIDGE_MAX := 20
const ITEM_SCALE := 1.5
const STORE := Vector3(0, 0, -200)   # the supermarket interior lives far from the street
const PRODUCTS: Array[Dictionary] = [
	{"name": "לחם", "price": 6, "food": 22.0},
	{"name": "גבינה", "price": 9, "food": 18.0},
	{"name": "חלב", "price": 5, "food": 12.0},
	{"name": "תפוח", "price": 2, "food": 8.0},
	{"name": "פסטה", "price": 5, "food": 30.0},
	{"name": "ביצים", "price": 8, "food": 28.0},
	{"name": "עוף", "price": 20, "food": 55.0},
	{"name": "שוקולד", "price": 4, "food": 10.0},
	{"name": "בשר ציד", "price": 80, "food": 45.0},   # only from hunting, never on a shelf
	{"name": "חלה", "price": 7, "food": 25.0},
	{"name": "מיץ ענבים", "price": 9, "food": 8.0},
	{"name": "אורז", "price": 5, "food": 30.0},
	{"name": "בננה", "price": 2, "food": 9.0},
	{"name": "עגבנייה", "price": 2, "food": 6.0},
	{"name": "יוגורט", "price": 4, "food": 12.0},
	{"name": "דג", "price": 18, "food": 45.0},
	{"name": "עוגה", "price": 12, "food": 20.0},
]
const SHELF_PIDS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16]
const CHALLAH := 9
const GRAPE_JUICE := 10
const WEEKDAYS: Array[String] = ["יום ראשון", "יום שני", "יום שלישי", "יום רביעי", "יום חמישי", "יום שישי", "שבת"]
const MEAT := 8
const RIFLE_PRICE := 350
const AMMO_PRICE := 20
const FOREST_Z := 36.0             # the forest starts this far south of the street
const FOREST_END := 100.0
const ROOMS := {
	"home": {"origin": Vector3(-200, 0, -200), "half": Vector2(19.5, 8)},
	"market": {"origin": Vector3(0, 0, -200), "half": Vector2(14.8, 8.2)},
	"cafe": {"origin": Vector3(200, 0, -200), "half": Vector2(8, 6)},
	"work": {"origin": Vector3(400, 0, -200), "half": Vector2(10, 7)},
	"guns": {"origin": Vector3(600, 0, -200), "half": Vector2(6, 5)},
	"clinic": {"origin": Vector3(800, 0, -200), "half": Vector2(7, 5.5)},
	"diner": {"origin": Vector3(1000, 0, -200), "half": Vector2(9, 6.5)},
	"build": {"origin": Vector3(1200, 0, -200), "half": Vector2(10, 7)},
	"music": {"origin": Vector3(1400, 0, -200), "half": Vector2(6, 5)},
	"hall": {"origin": Vector3(1600, 0, -200), "half": Vector2(11, 8)},
	"shul": {"origin": Vector3(1800, 0, -200), "half": Vector2(9, 7)},
}
const ROOM_HINTS := {
	"home": "בבית: מיטה, מקרר, ספה, שולחן אוכל, שירותים ומקלחת — לוחצים כדי להשתמש.",
	"market": "לחצו על מוצר במדף כדי לקחת אותו. משלמים בקופה.",
	"cafe": "לחצו על הצלחת או על הכוס שעל הדלפק כדי להזמין.",
	"work": "עבודה: לוקחים חבילה מהשולחן ושמים אותה על המדף.",
	"guns": "לחצו על הרובה או על קופסת הכדורים שעל הדלפק.",
	"clinic": "לחצו על הרופאה כדי לקבל טיפול.",
	"diner": "עבודה במסעדה: לוקחים מנה מהמטבח ומגישים לשולחן.",
	"build": "עבודה בבנייה: לוקחים לבנים מהערימה ומניחים בקיר.",
	"music": "לחצו על הגיטרה כדי לקנות אותה, או דברו עם המוכר על שיעור.",
	"hall": "עולים לבמה ומופיעים עם הגיטרה. חברים שלך יבואו לראות.",
	"shul": "בית הכנסת: עומדים ליד הבימה כדי להתפלל.",
}
## Hand jobs: carry something from one spot to another. Pay scales with your wage.
const JOBS := {
	"work": {"pay": 20, "tire": 0.0, "from": 8.0, "to": 20.0, "tips": 0, "what": "חבילה"},
	"diner": {"pay": 15, "tire": 0.0, "from": 11.0, "to": 23.0, "tips": 12, "what": "מנה"},
	"build": {"pay": 30, "tire": 3.5, "from": 6.0, "to": 16.0, "tips": 0, "what": "לבנים"},
}
const CAR_HOME := Vector3(-18, 0, -0.5)
const WEST := -100.0                # the town fence
const EAST := 140.0
const GUITAR_PRICE := 400
const LESSON_PRICE := 40
const NAMES: Array[String] = ["דני", "מיכל", "יוסי", "נועה", "אבי", "תמר", "רון", "שירה", "איתי", "מאיה", "עומר", "יעל",
	"גיל", "ליאת", "אורי", "הדס", "נדב", "רותי", "אלון", "דנה", "משה", "ענת", "בועז", "קרן", "עידו", "טל"]
const CHATS: Array[String] = ["שלום! איזה יום יפה.", "מה שלומך? טוב לראות אותך.", "שמעת? במסעדה מחפשים עובדים.", "ביער יש הרבה צבאים השנה.",
	"בלילה עדיף להיזהר מהאנשים באדום.", "אני אוהב לשבת בפארק ליד האגם.", "הרופאה במרפאה ממש נחמדה.", "באולם ההופעות יש מופעים כל ערב.",
	"שיהיה לך יום נהדר!", "אם תופיע באולם, אני אבוא לראות."]
const CAN_PRICE := 15
const CAN_FUEL := 25.0
const JEEP := 2
const CAR_LOT := Vector3(-37, 0, 10.5)
const CARS: Array[Dictionary] = [
	{"name": "הרכב הישן", "price": 0, "color": Color(0.15, 0.4, 0.85), "top": 17.0, "use": 1.0, "note": ""},
	{"name": "משפחתית חדשה", "price": 1200, "color": Color(0.8, 0.12, 0.12), "top": 21.0, "use": 0.75, "note": "חסכונית בדלק"},
	{"name": "ג'יפ", "price": 2000, "color": Color(0.2, 0.38, 0.2), "top": 19.0, "use": 1.15, "note": "נוסע גם ביער"},
	{"name": "מכונית ספורט", "price": 3500, "color": Color(0.98, 0.78, 0.1), "top": 28.0, "use": 1.4, "note": "הכי מהירה"},
]
const GAS_PUMP := Vector3(15, 0, 5.6)
const SAVE_PATH := "user://life-city.cfg"

enum State { MENU, PLAY, OVER }


class Person:
	var root: Node3D
	var limbs: Array[Node3D] = []   # leg, leg, arm, arm
	var joints: Array[Node3D] = []  # knee, knee, elbow, elbow
	var phase := 0.0
	var dir := 1.0
	var speed := 2.0
	var chasing := false            # robbers only
	var town := false               # a robber who works the streets at night
	var target := Vector3.ZERO
	var wait := 0.0
	var name := ""
	var level := 0                  # how well you know each other; 3 = friend
	var talked_day := 0
	var pause := 0.0                # stands still while chatting
	var bubble: Label3D
	var bubble_t := 0.0
	var hello_cool := 0.0


class Animal:
	var node: Node3D
	var big := false                # deer or rabbit
	var dead := false
	var gone := 0.0                 # seconds until it comes back after being collected
	var heading := Vector3.ZERO
	var timer := 0.0
	var scared := 0.0


class Place:
	var key: String
	var title: String
	var prompt: String
	var room := ""                  # "" = out on the street
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
var has_rifle := false
var ammo := 0
var shot_cool := 0.0
var rob_cool := 0.0
var room := ""                     # which building interior the player is in
var room_origin := Vector3.ZERO
var room_half := Vector2(10.8, 8.2)
var handles: Array[Dictionary] = []   # things you can click with your hand
var carrying := false              # holding a parcel at work
var parcels := 0
var parcel_mesh: MeshInstance3D
var parcel_pile: Array[Node3D] = []
var shelf_boxes: Array[Node3D] = []
var car: Node3D                    # the player's own car
var car_block: CollisionShape3D
var body_shape: CapsuleShape3D
var driving := false
var near_car := false
var car_speed := 0.0
var car_heading := PI * 0.5
var fuel := 60.0
var traffic: Array[Node3D] = []
var car_model := 0
var bladder := 0.0                 # 0 = fine, 100 = desperate for the toilet
var bladder_warned := false
var was_shabbat := false
var friday_note_day := 0
var candles_day := 0               # the Friday the candles were lit on
var kiddush_day := 0
var prayed_day := 0
var prayed_slot := 0               # day * 3 + (0 morning, 1 afternoon, 2 evening)
var family: Array[Person] = []     # wife, son, daughter, baby
var family_joy := 70.0
var near_kin: Person
var kids := 0                      # 0 at home, 1 on the way to school, 2 at school, 3 on the way home
var school_missed_day := 0
var teacher: Person
var outing_day := 0                # the day you last played outside with the children
const PLAYGROUND := Vector3(20, 0, 21)
const PICNIC := Vector3(0, 0, FOREST_Z + 9.0)
const KIDS: Array[int] = [1, 2, 3, 4]      # places of the children in `family`
const KID_ROOMS: Array[float] = [13.6, 17.6, -13.6, -17.6]   # x of each child's bedroom
const SCHOOL_DOOR := Vector3(126, 0, -4.7)
var joy_warned := false
var flames: Array[Node3D] = []
var near_npc: Person               # a townsperson close enough to talk to
var has_guitar := false
var skill := 0                     # guitar skill, 0..15
var last_show_day := 0
var guitar_mesh: Node3D
var audience: Array[Person] = []
var edge_cool := 0.0
var rent_owed := 0                 # unpaid rent; the flat stays locked until it is renewed
var has_can := false               # carrying a jerry can of petrol
var can_mesh: MeshInstance3D
var rifle_mesh: MeshInstance3D
var animals: Array[Animal] = []
var thugs: Array[Person] = []
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
	_box(Vector3(360, 1, 260), Vector3(20, -0.5, 35), _mat(Color(0.34, 0.56, 0.3)))
	_solid(Vector3(360, 1, 260), Vector3(20, -0.5, 35))
	_box(Vector3(320, 0.04, 6), Vector3(20, 0.02, 1.5), _mat(Color(0.25, 0.26, 0.29)))
	var dash := _mat(Color(0.9, 0.9, 0.85))
	for k in range(-34, 44):
		_box(Vector3(1.8, 0.02, 0.2), Vector3(k * 4.0, 0.05, 1.5), dash)
	var paving := _mat(Color(0.58, 0.56, 0.53))
	_box(Vector3(320, 0.04, 4.5), Vector3(20, 0.015, -3.75), paving)
	_box(Vector3(320, 0.04, 2.0), Vector3(20, 0.015, 5.5), paving)

	_building("home", "הבית שלי", -24, 9, 4.2, Color(0.85, 0.7, 0.48), Color(0.68, 0.28, 0.2), 0, 24)
	_building("market", "סופרמרקט", -8, 12, 4.2, Color(0.78, 0.8, 0.84), Color(0.15, 0.55, 0.3), 7, 22)
	_building("cafe", "קפה ומסעדה", 8, 9, 4.2, Color(0.82, 0.72, 0.58), Color(0.7, 0.4, 0.18), 8, 23)
	_building("work", "העבודה", 24, 12, 10.5, Color(0.55, 0.62, 0.72), Color(0.25, 0.3, 0.4), 8, 20)

	# Street lamps.
	var pole_mat := _mat(Color(0.2, 0.2, 0.22))
	for x: float in [-96.0, -80.0, -64.0, -48.0, -32.0, -16.0, 0.0, 16.0, 32.0, 48.0, 64.0, 80.0, 96.0, 112.0, 128.0]:
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
	# The pond is real water: a stone bank around it, reeds, and no walking or driving in.
	var bank := CylinderMesh.new()
	bank.top_radius = 5.0
	bank.bottom_radius = 5.2
	bank.height = 0.05
	var bank_mi := MeshInstance3D.new()
	bank_mi.mesh = bank
	bank_mi.material_override = _mat(Color(0.62, 0.6, 0.55))
	bank_mi.position = Vector3(4, 0.02, 14)
	add_child(bank_mi)
	var water := StaticBody3D.new()
	var water_shape := CollisionShape3D.new()
	var round := CylinderShape3D.new()
	round.radius = 4.6
	round.height = 3.0
	water_shape.shape = round
	water.add_child(water_shape)
	water.position = Vector3(4, 1.5, 14)
	add_child(water)
	for k in 10:
		var angle := k * TAU / 10.0 + 0.3
		_box(Vector3(0.08, rng.randf_range(0.7, 1.2), 0.08), Vector3(4 + cos(angle) * 4.3, 0.45, 14 + sin(angle) * 4.3), _mat(Color(0.3, 0.5, 0.2)))
	_sign("הפארק", Vector3(-6, 2.6, 8.2), 72)
	_box(Vector3(0.15, 2.2, 0.15), Vector3(-6, 1.1, 8.2), pole_mat)
	var bench := _mat(Color(0.5, 0.33, 0.2))
	for x: float in [-3.0, 11.0]:
		_box(Vector3(2.4, 0.15, 0.7), Vector3(x, 0.55, 9.5), bench)
		_box(Vector3(2.4, 0.7, 0.12), Vector3(x, 0.95, 9.85), bench)
		_solid(Vector3(2.4, 1.2, 0.8), Vector3(x, 0.6, 9.6))
		var seat := Place.new()
		seat.key = "bench"
		seat.title = "ספסל"
		seat.prompt = "לישון על הספסל"
		seat.door = Vector3(x, 0, 8.4)
		places.append(seat)
	for k in 34:
		var pos := Vector3(rng.randf_range(-45, 45), 0, rng.randf_range(8, 28))
		if pos.distance_to(Vector3(4, 0, 14)) < 6.5 or (pos.z < 11.0 and absf(pos.x - 4.0) < 9.0) \
				or pos.distance_to(CAR_LOT) < 10.0 or pos.distance_to(PLAYGROUND) < 10.5 or pos.distance_to(Vector3(-14, 0, 17)) < 4.0:
			continue
		_tree(pos)
	for k in 16:
		_tree(Vector3(rng.randf_range(-48, 48), 0, rng.randf_range(-26, -17)))
	_building("shul", "בית כנסת", -91, 11, 6.5, Color(0.9, 0.87, 0.78), Color(0.2, 0.3, 0.55), 6, 21)
	_building("music", "חנות מוזיקה", -74, 9, 4.2, Color(0.55, 0.4, 0.6), Color(0.3, 0.18, 0.4), 9, 20)
	_building("hall", "אולם הופעות", -58, 15, 8.5, Color(0.75, 0.3, 0.3), Color(0.35, 0.1, 0.12), 17, 24)
	_building("clinic", "מרפאה", -40, 10, 4.2, Color(0.9, 0.92, 0.94), Color(0.75, 0.15, 0.15), 8, 20)
	_building("diner", "מסעדה", 56, 11, 4.2, Color(0.8, 0.5, 0.35), Color(0.45, 0.15, 0.12), 11, 23)
	_building("build", "אתר בנייה", 72, 12, 7.0, Color(0.6, 0.58, 0.55), Color(0.9, 0.6, 0.1), 6, 16)
	_build_town_extras()
	_build_edges()
	_build_neighbourhood()
	_build_restroom()
	_build_school()
	_build_playground()
	_building("guns", "חנות נשק", 40, 9, 4.2, Color(0.5, 0.52, 0.45), Color(0.25, 0.3, 0.2), 9, 19)

	# Passers-by on the pavements, each with a name.
	for k in 18:
		var n := _make_person(Color.from_hsv(rng.randf(), 0.5, 0.88), Color.from_hsv(rng.randf(), 0.3, 0.42))
		n.dir = 1.0 if k % 2 == 0 else -1.0
		n.speed = rng.randf_range(1.6, 2.6)
		n.root.position = Vector3(rng.randf_range(WEST + 4.0, EAST - 4.0), 0, 5.6 if k % 3 == 0 else rng.randf_range(-2.6, -2.0))
		_add_townsperson(n)
	_build_store()
	_build_interiors()
	_sign("ליער ↓", Vector3(8, 2.6, 7.4), 80)
	_box(Vector3(0.15, 2.2, 0.15), Vector3(8, 1.1, 7.4), _mat(Color(0.2, 0.2, 0.22)))
	_build_forest()
	_build_cars()


func _cap(radius: float, height: float, pos: Vector3, mat: Material, parent: Node, squash: Vector3 = Vector3.ONE) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	parent.add_child(mi)


## A person built from rounded parts, with knees and elbows that bend.
func _make_person(shirt: Color, pants: Color, into: Person = null, tone: int = -1, hair_pick: int = -1) -> Person:
	var p := into if into else Person.new()
	p.root = Node3D.new()
	var tones: Array[Color] = [Color(0.96, 0.8, 0.66), Color(0.9, 0.72, 0.56), Color(0.78, 0.58, 0.42), Color(0.6, 0.42, 0.3), Color(0.45, 0.31, 0.22)]
	var hairs: Array[Color] = [Color(0.12, 0.09, 0.07), Color(0.3, 0.19, 0.1), Color(0.55, 0.38, 0.18), Color(0.85, 0.7, 0.4), Color(0.6, 0.6, 0.62), Color(0.55, 0.2, 0.1)]
	var skin := _mat(tones[tone] if tone >= 0 else (tones[rng.randi_range(0, 4)] if into == null else tones[0]))
	var hair := _mat(hairs[hair_pick] if hair_pick >= 0 else (hairs[rng.randi_range(0, 5)] if into == null else hairs[1]))
	var shirt_mat := _mat(shirt)
	var pants_mat := _mat(pants)
	# Body: chest wider at the shoulders, hips in the trouser colour.
	_cap(0.2, 0.62, Vector3(0, 1.24, 0), shirt_mat, p.root, Vector3(1.3, 1.0, 0.85))
	_ball(0.2, Vector3(0, 0.96, 0), pants_mat, p.root, Vector3(1.2, 0.8, 0.85))
	_cap(0.065, 0.16, Vector3(0, 1.57, 0), skin, p.root)
	# Head, slightly longer than wide, with ears.
	_ball(0.2, Vector3(0, 1.74, 0), skin, p.root, Vector3(0.95, 1.12, 1.0))
	for sx: float in [-0.19, 0.19]:
		_ball(0.045, Vector3(sx, 1.73, 0.0), skin, p.root, Vector3(0.5, 1.0, 0.8))
	_ball(0.205, Vector3(0, 1.81, -0.035), hair, p.root, Vector3(1.0, 0.82, 1.0))
	if into == null and rng.randf() < 0.45:
		_cap(0.17, 0.5, Vector3(0, 1.62, -0.13), hair, p.root, Vector3(1.1, 1.0, 0.5))    # long hair
	# Face: eyes set flat into the head, soft brows, a small nose and a gentle smile.
	var dark := _mat(Color(0.16, 0.12, 0.1))
	var lips := _mat(Color(0.75, 0.42, 0.4))
	for sx: float in [-0.07, 0.07]:
		_ball(0.022, Vector3(sx, 1.762, 0.181), _mat(Color(0.97, 0.97, 0.95)), p.root, Vector3(1.3, 0.75, 0.2))
		_ball(0.012, Vector3(sx, 1.762, 0.185), dark, p.root, Vector3(1.0, 1.0, 0.25))
		_box(Vector3(0.055, 0.01, 0.012), Vector3(sx, 1.797, 0.181), hair, p.root)
	_ball(0.02, Vector3(0, 1.725, 0.193), skin, p.root, Vector3(0.75, 1.1, 0.7))
	_box(Vector3(0.07, 0.011, 0.012), Vector3(0, 1.672, 0.184), lips, p.root)
	# Legs: thigh, knee, shin, shoe.
	var shoe := _mat(Color(0.12, 0.1, 0.1))
	var knees: Array[Node3D] = []
	for sx: float in [-0.12, 0.12]:
		var hip := Node3D.new()
		hip.position = Vector3(sx, 0.92, 0)
		p.root.add_child(hip)
		_cap(0.1, 0.5, Vector3(0, -0.23, 0), pants_mat, hip)
		var knee := Node3D.new()
		knee.position = Vector3(0, -0.46, 0)
		hip.add_child(knee)
		_cap(0.085, 0.46, Vector3(0, -0.2, 0), pants_mat, knee)
		_ball(0.1, Vector3(0, -0.42, 0.07), shoe, knee, Vector3(0.9, 0.6, 1.6))
		p.limbs.append(hip)
		knees.append(knee)
	# Arms: sleeve, elbow, forearm, hand.
	var elbows: Array[Node3D] = []
	for sx: float in [-0.31, 0.31]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(sx, 1.46, 0)
		p.root.add_child(shoulder)
		_cap(0.075, 0.36, Vector3(0, -0.15, 0), shirt_mat, shoulder)
		var elbow := Node3D.new()
		elbow.position = Vector3(0, -0.31, 0)
		shoulder.add_child(elbow)
		_cap(0.06, 0.32, Vector3(0, -0.14, 0), skin, elbow)
		_ball(0.065, Vector3(0, -0.32, 0), skin, elbow, Vector3(0.8, 1.1, 1.0))
		p.limbs.append(shoulder)
		elbows.append(elbow)
	p.joints = knees + elbows
	if into == null:
		var tall := rng.randf_range(0.93, 1.07)
		p.root.scale = Vector3(tall * rng.randf_range(0.95, 1.08), tall, tall)
	return p


func _animate(p: Person, moving: bool, dt: float) -> void:
	if moving:
		p.phase += dt * 8.5
	var s := sin(p.phase) if moving else 0.0
	var c := cos(p.phase) if moving else 0.0
	var blend := 12.0 * dt
	p.limbs[0].rotation.x = lerp_angle(p.limbs[0].rotation.x, 0.55 * s, blend)
	p.limbs[1].rotation.x = lerp_angle(p.limbs[1].rotation.x, -0.55 * s, blend)
	p.limbs[2].rotation.x = lerp_angle(p.limbs[2].rotation.x, -0.4 * s, blend)
	p.limbs[3].rotation.x = lerp_angle(p.limbs[3].rotation.x, 0.4 * s, blend)
	if p.joints.size() == 4:
		# Each knee folds while its leg swings forward; elbows stay a little bent.
		p.joints[0].rotation.x = lerp_angle(p.joints[0].rotation.x, 0.9 * maxf(0.0, -c) if moving else 0.0, blend)
		p.joints[1].rotation.x = lerp_angle(p.joints[1].rotation.x, 0.9 * maxf(0.0, c) if moving else 0.0, blend)
		p.joints[2].rotation.x = lerp_angle(p.joints[2].rotation.x, -0.25 - 0.3 * maxf(0.0, -s), blend)
		p.joints[3].rotation.x = lerp_angle(p.joints[3].rotation.x, -0.25 - 0.3 * maxf(0.0, s), blend)


func _build_player() -> void:
	player = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	body_shape = cap
	cap.radius = 0.4
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	player.add_child(cs)
	_make_person(Color(0.95, 0.95, 0.97), Color(0.12, 0.13, 0.2), me)
	_kippah(me.root, Color(0.1, 0.12, 0.35))
	for sx: float in [-0.2, 0.2]:                # tzitzit at the hips
		for sz: float in [-0.12, 0.12]:
			_box(Vector3(0.02, 0.3, 0.02), Vector3(sx, 0.86, sz), _mat(Color(1, 1, 1)), me.root)
	player.add_child(me.root)
	basket_mesh = _box(Vector3(0.5, 0.32, 0.38), Vector3(0, -0.72, 0.14), _mat(Color(0.85, 0.2, 0.2)), me.limbs[2])
	basket_mesh.visible = false
	can_mesh = _box(Vector3(0.4, 0.5, 0.22), Vector3(0, -0.74, 0.06), _mat(Color(0.85, 0.12, 0.1)), me.limbs[2])
	can_mesh.visible = false
	guitar_mesh = Node3D.new()
	guitar_mesh.position = Vector3(0, 1.15, -0.34)
	guitar_mesh.rotation.z = 0.5
	me.root.add_child(guitar_mesh)
	_box(Vector3(0.42, 0.5, 0.1), Vector3(0, -0.2, 0), _mat(Color(0.7, 0.42, 0.18)), guitar_mesh)
	_box(Vector3(0.1, 0.7, 0.06), Vector3(0, 0.35, 0), _mat(Color(0.3, 0.18, 0.1)), guitar_mesh)
	guitar_mesh.visible = false
	rifle_mesh = _box(Vector3(0.1, 0.1, 1.3), Vector3(0, -0.6, 0.35), _mat(Color(0.25, 0.17, 0.1)), me.limbs[3])
	rifle_mesh.visible = false
	parcel_mesh = _box(Vector3(0.6, 0.5, 0.6), Vector3(0, 1.15, 0.5), _mat(Color(0.72, 0.55, 0.32)), me.root)
	parcel_mesh.visible = false
	add_child(player)
	_reset_position()


func _reset_position() -> void:
	inside = false
	room = ""
	carrying = false
	_park_car(CAR_HOME, PI * 0.5)
	_return_all()
	_reset_forest()
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
			hunger -= 3.6 * hours
			energy -= 5.0 * hours
		"sleep":
			hunger -= 1.0 * hours
			energy += 12.5 * hours
		_:
			hunger -= 2.4 * hours
			energy -= 2.8 * hours
	hunger = clampf(hunger, 0.0, 100.0)
	energy = clampf(energy, 0.0, 100.0)
	bladder = minf(bladder + (1.5 if mode == "sleep" else 4.5) * hours, 100.0)
	if bladder >= 100.0:
		health -= 3.0 * hours
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
		_hospital()


func _skip(hours: float, mode: String) -> void:
	var left := hours
	while left > 0.0 and state == State.PLAY:
		var step := minf(0.25, left)
		_tick(step, mode)
		left -= step


func _new_day() -> void:
	if (day - 1) % RENT_DAYS == 0:
		rent_owed += RENT
		_toast("הגיע הזמן לחדש שכר דירה: ₪%d. משלמים בדלת של הבית." % rent_owed)
		_play("alarm")
	_family_day()
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
	bladder = minf(bladder + 5.0, 100.0)
	hunger = minf(hunger + float(PRODUCTS[pid]["food"]), 100.0)
	_skip(0.33, "awake")
	_play("eat")
	_toast("בירכת ואכלת %s." % PRODUCTS[pid]["name"])
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
	if _shabbat_block():
		return
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


func _rest() -> void:
	if energy > 90.0:
		_toast("אתה לא עייף עכשיו.")
		return
	_time_skip("נחים על הספה...", func() -> void:
		_skip(1.0, "awake")
		energy = minf(energy + 16.0, 100.0)
		_toast("נחת שעה על הספה."))


func _take_parcel() -> void:
	if _shabbat_block():
		return
	var job: Dictionary = JOBS[room]
	if carrying:
		_toast("כבר יש לך %s ביד." % job["what"])
		return
	if clock < float(job["from"]) or clock >= float(job["to"]):
		_toast("העבודה כאן רק בין %s ל-%s." % [_time_text(job["from"]), _time_text(job["to"])])
		_play("no")
		return
	if energy < 10.0:
		_toast("אתה עייף מדי לעבוד. לך לישון.")
		_play("no")
		return
	if hunger < 5.0:
		_toast("אתה רעב מדי לעבוד. לך לאכול.")
		_play("no")
		return
	carrying = true
	reach = 0.35
	_play("pick")
	_update_hud()


func _drop_parcel() -> void:
	var job: Dictionary = JOBS[room]
	if not carrying:
		_toast("קודם לוקחים %s." % job["what"])
		return
	carrying = false
	reach = 0.35
	parcels += 1
	shifts = parcels / 8
	_skip(0.5, "work")
	energy = maxf(energy - float(job["tire"]), 0.0)
	var pay := int(int(job["pay"]) * wage / 40.0)
	var tip := rng.randi_range(0, int(job["tips"])) if int(job["tips"]) > 0 else 0
	money += pay + tip
	_play("pay")
	if parcels % 40 == 0:
		wage += 8
		_toast("הרווחת ₪%d, וגם קיבלת העלאה של 20%% בכל העבודות!" % (pay + tip))
	elif tip > 0:
		_toast("הרווחת ₪%d ועוד ₪%d טיפ." % [pay, tip])
	else:
		_toast("הרווחת ₪%d. (משימה מספר %d)" % [pay, parcels])
	_update_hud()


func _treat(price: int, heal: float, hours: float) -> void:
	if health >= 99.0:
		_toast("אתה בריא לגמרי.")
		return
	if money < price:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	money -= price
	health = minf(health + heal, 100.0)
	_skip(hours, "awake")
	_play("pay")
	_toast("הרופאה טיפלה בך. בריאות: %d." % int(health))
	_refresh_panel()


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
			"fridge":
				panel_text.text = _h("המקרר ריק. צריך לקנות אוכל בסופר." if fridge.is_empty() else "מה לאכול מהמקרר?")
				for pid in PRODUCTS.size():
					var have := fridge.count(pid)
					if have > 0:
						_add_action("%s ×%d" % [PRODUCTS[pid]["name"], have], _eat.bind(pid))
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
			"cafe_counter":
				panel_text.text = _h("אוכלים כאן ועכשיו, בלי לחזור הביתה")
				_add_action("ארוחה חמה · ₪30", _cafe.bind(30, 60.0, 0.0, 0.75, "אכלת ארוחה חמה. טעים!"))
				_add_action("קפה · ₪8", _cafe.bind(8, 3.0, 15.0, 0.25, "שתית קפה. קצת יותר ערני."))
			"gas":
				var price := _fuel_price()
				if not driving:
					if has_can:
						panel_text.text = _h("יש לך מיכל דלק מלא. קח אותו לרכב ומלא שם.")
					else:
						panel_text.text = _h("נתקעת בלי דלק? קנה מיכל, לך לרכב ומלא אותו.")
						_add_action("מיכל דלק (%d%%) · ₪%d" % [int(CAN_FUEL), CAN_PRICE], _buy_can)
				elif price <= 0:
					panel_text.text = _h("המכל מלא.")
				else:
					panel_text.text = _h("דלק במכל: %d%%" % int(fuel))
					_add_action("למלא מכל · ₪%d" % price, _refuel)
			"home":
				panel_text.text = _h("כדי להיכנס הביתה צריך לחדש את שכר הדירה. בינתיים אפשר לישון על ספסל בפארק.")
				_add_action("לחדש שכר דירה · ₪%d" % rent_owed, _pay_rent)
			"music_counter":
				panel_text.text = _h(("רמת הנגינה שלך: %d מתוך 15" % skill) if has_guitar else "גיטרה פותחת לך הופעות באולם ונגינה ברחוב.")
				if not has_guitar:
					_add_action("גיטרה · ₪%d" % GUITAR_PRICE, _buy_guitar)
				elif skill < 15:
					_add_action("שיעור נגינה (שעה) · ₪%d" % LESSON_PRICE, _lesson)
			"kids_out":
				if kids != 0:
					panel_text.text = _h("הילדים כבר לא בבית.")
				else:
					panel_text.text = _h("לאן יוצאים עם הילדים?")
					if _is_school_day() and clock < 13.0:
						_add_action("לבית הספר (עם אוכל מהמקרר)", _take_kids)
					_add_action("לטיול: לגינת המשחקים או ליער", _take_outing)
			"doctor":
				panel_text.text = _h("בריאות: %d מתוך 100" % int(health))
				_add_action("בדיקה וטיפול מלא · ₪60", _treat.bind(60, 100.0, 1.0))
				_add_action("ויטמינים · ₪20", _treat.bind(20, 25.0, 0.25))
			"dealer":
				panel_text.text = _h("הרכב שלך: %s. רכב חדש מחליף אותו ומגיע עם מכל מלא." % CARS[car_model]["name"])
				for k in range(1, CARS.size()):
					if k != car_model:
						_add_action("%s · %s · ₪%d" % [CARS[k]["name"], CARS[k]["note"], CARS[k]["price"]], _buy_car.bind(k))
			"gun_counter":
				panel_text.text = _h(("יש לך רובה ציד · כדורים: %d" % ammo) if has_rifle else "כדי לצוד ביער צריך רובה ציד וכדורים")
				if not has_rifle:
					_add_action("רובה ציד · ₪%d" % RIFLE_PRICE, _buy_rifle)
				else:
					_add_action("10 כדורים · ₪%d" % AMMO_PRICE, _buy_ammo)
				if fridge.has(MEAT):
					_add_action("למכור בשר ציד (יש %d) · ₪%d" % [fridge.count(MEAT), PRODUCTS[MEAT]["price"]], _sell_meat)
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
		n.pause = maxf(n.pause - delta, 0.0)
		n.hello_cool = maxf(n.hello_cool - delta, 0.0)
		if n.bubble_t > 0.0:
			n.bubble_t -= delta
			if n.bubble_t <= 0.0:
				n.bubble.visible = false
		if n.speed <= 0.0 or n.pause > 0.0:
			_animate(n, false, delta)
			continue
		n.root.position.x += n.dir * n.speed * delta
		if n.root.position.x > EAST - 2.0:
			n.dir = -1.0
		elif n.root.position.x < WEST + 2.0:
			n.dir = 1.0
		n.root.rotation.y = PI * 0.5 * n.dir
		_animate(n, true, delta)

	var walking := state == State.PLAY and open_place == null and not busy
	var input := _move_input() if walking else Vector2.ZERO
	# Tired or starving people walk slower.
	var speed := WALK_SPEED * (0.6 if (energy < 15.0 or hunger < 10.0 or bladder >= 95.0) else 1.0)
	if driving:
		_drive(input, delta)
	else:
		player.velocity = Vector3(input.x * speed, -4.0, input.y * speed)
		player.move_and_slide()
	_update_traffic(delta)
	if inside:
		player.position.x = clampf(player.position.x, room_origin.x - room_half.x, room_origin.x + room_half.x)
		player.position.z = clampf(player.position.z, room_origin.z - room_half.y, room_origin.z + room_half.y)
	else:
		player.position.x = clampf(player.position.x, WEST, EAST)
		player.position.z = clampf(player.position.z, -5.6, FOREST_END)
	if driving:
		if car_model != JEEP:
			player.position.z = minf(player.position.z, FOREST_Z - 6.0)   # only the jeep goes among the trees
		car.position = player.position
		car.rotation.y = car_heading
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
		if driving:
			if p.key == "gas" and fuel < 95.0 and p.door.distance_to(player.position) < 5.0:
				near = p
		elif p.room == room and p.door.distance_to(player.position) < 2.2:
			near = p
	near_car = not driving and not inside and car.position.distance_to(player.position) < 3.2
	_watch_week()
	_update_family(delta)
	near_npc = null
	if not driving and not inside:
		var closest := 2.6
		for n in npcs:
			var d := n.root.position.distance_to(player.position)
			if d < closest:
				closest = d
				near_npc = n
			if d < 3.5 and n.hello_cool <= 0.0 and n.bubble_t <= 0.0:
				_say(n, "שבת שלום!" if _is_shabbat() else ("שלום %s!" % ("חבר" if n.level >= 3 else "")), 2.0)
				n.hello_cool = 40.0
		edge_cool = maxf(edge_cool - delta, 0.0)
		if edge_cool <= 0.0 and (player.position.x <= WEST + 0.05 or player.position.x >= EAST - 0.05 or player.position.z >= FOREST_END - 0.05):
			edge_cool = 12.0
			_toast("כאן נגמרת העיר. הגדר סוגרת את הדרך.")
	_update_focus()
	_update_forest(delta)
	_update_hud()


func _process(delta: float) -> void:
	var view := get_viewport().get_visible_rect().size
	var portrait := view.y > view.x
	cam.fov = 75.0 if portrait else 50.0
	var want := player.position + Vector3(0, 1.0, -1.5)
	if state == State.MENU:
		want = Vector3(sin(Time.get_ticks_msec() * 0.0002) * 14.0, 1.0, -3.0)
	cam_focus = cam_focus.lerp(want, 1.0 - exp(-5.0 * delta))
	cam.position = cam_focus + (Vector3(0, 7.0, 6.5) if inside else (Vector3(0, 15.0, 16.0) if driving else Vector3(0, 11.5, 13.0)))
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
			_use()


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
	parcels = 0
	rent_owed = 0
	has_guitar = false
	skill = 0
	last_show_day = 0
	bladder = 0.0
	candles_day = 0
	kiddush_day = 0
	prayed_day = 0
	prayed_slot = 0
	family_joy = 70.0
	kids = 0
	school_missed_day = 0
	for kin in family:
		kin.talked_day = 0
	friday_note_day = 0
	was_shabbat = false
	for n in npcs:
		n.level = 0
		n.talked_day = 0
	has_rifle = false
	ammo = 0
	fuel = 60.0
	has_can = false
	_set_car_model(0)
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
	has_rifle = bool(cfg.get_value("life", "rifle", false))
	has_can = bool(cfg.get_value("life", "can", false))
	_set_car_model(clampi(int(cfg.get_value("life", "car_model", 0)), 0, CARS.size() - 1))
	ammo = int(cfg.get_value("life", "ammo", 0))
	fuel = float(cfg.get_value("life", "fuel", 60.0))
	parcels = int(cfg.get_value("life", "parcels", shifts * 8))
	rent_owed = int(cfg.get_value("life", "rent_owed", 0))
	has_guitar = bool(cfg.get_value("life", "guitar", false))
	skill = int(cfg.get_value("life", "skill", 0))
	last_show_day = int(cfg.get_value("life", "last_show", 0))
	bladder = float(cfg.get_value("life", "bladder", 0.0))
	family_joy = float(cfg.get_value("life", "family", 70.0))
	candles_day = int(cfg.get_value("life", "candles", 0))
	kiddush_day = int(cfg.get_value("life", "kiddush", 0))
	was_shabbat = _is_shabbat()
	var known: Variant = cfg.get_value("life", "known", [])
	for k in npcs.size():
		npcs[k].level = int(known[k]) if known is Array and k < (known as Array).size() else 0
		npcs[k].talked_day = 0
	_begin()
	_park_car(Vector3(float(cfg.get_value("life", "car_x", CAR_HOME.x)), 0, float(cfg.get_value("life", "car_z", CAR_HOME.z))),
		float(cfg.get_value("life", "car_rot", PI * 0.5)))
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
			["energy", energy], ["health", health], ["fridge", fridge], ["shifts", shifts], ["wage", wage],
			["rifle", has_rifle], ["ammo", ammo], ["fuel", fuel], ["parcels", parcels], ["rent_owed", rent_owed],
			["guitar", has_guitar], ["skill", skill], ["last_show", last_show_day], ["known", _known_levels()], ["bladder", bladder], ["family", family_joy], ["candles", candles_day], ["kiddush", kiddush_day],
			["car_x", car.position.x], ["car_z", car.position.z], ["car_rot", car_heading],
			["can", has_can], ["car_model", car_model]]:
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
		"עבדו בעבודה כדי להרוויח כסף, קנו אוכל בסופר,",
		"אכלו ושנו בבית, ושלמו ₪%d שכר דירה כל %d ימים." % [RENT, RENT_DAYS],
		"",
		"תנועה: חיצים או WASD · כניסה לבניין: E",
		"בטלפון: גוררים אצבע על המסך כדי ללכת",
		"נכנסים לכל בניין, ובפנים לוחצים על דברים כדי להשתמש בהם",
		"ביער שמדרום: צדים עם רובה מחנות הנשק, ובורחים מהאנשים באדום",
		"הרכב שלך חונה ליד הבית: נכנסים עם E ונוסעים עם החיצים",
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
			["health", "בריאות", Color(0.95, 0.3, 0.4)], ["toilet", "שירותים", Color(0.55, 0.8, 0.4)],
			["family", "משפחה", Color(0.9, 0.5, 0.85)]]:
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
		_use())
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
		_h("%s · %s" % [WEEKDAYS[_weekday()], _time_text(clock)]) + ("  " + _h("שבת שלום!") if _is_shabbat() else ""),
		_h("כסף: ₪%d" % money),
		_h("אוכל בבית: %d" % fridge.size()),
		_h("שכר דירה: %s" % (("לשלם ₪%d!" % rent_owed) if rent_owed > 0 else rent_when)),
		_h("בסל: %d מוצרים · ₪%d" % [basket.size(), _basket_total()]) if room == "market" else "",
		_h("כדורים: %d" % ammo) if has_rifle and not inside else "",
		_h("דלק: %d%%" % int(fuel)) if driving else "",
	])
	rifle_mesh.visible = has_rifle and _in_forest()
	basket_mesh.visible = not basket.is_empty()
	parcel_mesh.visible = carrying
	can_mesh.visible = has_can and not driving
	guitar_mesh.visible = has_guitar
	for k in audience.size():
		audience[k].root.visible = k < 2 + _friends() * 2
	for k in parcel_pile.size():
		parcel_pile[k].visible = not (carrying and k == 0)
	for k in shelf_boxes.size():
		shelf_boxes[k].visible = k < parcels % (shelf_boxes.size() + 1)
	(bars["hunger"] as ProgressBar).value = hunger
	(bars["energy"] as ProgressBar).value = energy
	(bars["health"] as ProgressBar).value = health
	(bars["toilet"] as ProgressBar).value = 100.0 - bladder
	(bars["family"] as ProgressBar).value = family_joy
	var lit := candles_day > 0 and (day == candles_day or (day == candles_day + 1 and clock < 19.0))
	for f in flames:
		f.visible = lit
	prompt.visible = playing and (near != null or near_car or driving or near_npc != null or near_kin != null) and open_place == null and not busy
	if prompt.visible:
		if near != null:
			prompt.text = _h(near.prompt)
		else:
			if driving:
				prompt.text = _h("לצאת מהרכב")
			elif near_car:
				prompt.text = _h("למלא דלק מהמיכל" if _can_pour() else "להיכנס לרכב שלי")
			else:
				prompt.text = _h("לדבר עם %s" % (near_kin.name if near_kin != null else near_npc.name))


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
func _tone(f0: float, f1: float, dur: float, vol: float, noise: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(dur * rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var k := float(i) / count
		phase += TAU * lerpf(f0, f1, k) / rate
		var wave := lerpf(sin(phase), rng.randf_range(-1.0, 1.0), noise)
		data.encode_s16(i * 2, int(wave * vol * (1.0 - k) * 32000.0))
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
		"bang": _tone(140, 40, 0.35, 0.6, 0.8),
		"alarm": _tone(500, 900, 0.5, 0.3),
		"engine": _tone(90, 180, 0.5, 0.35, 0.25),
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
		7:  # chocolate bar
			_box(Vector3(0.42, 0.08, 0.24), Vector3(0, 0.04, 0), _mat(Color(0.35, 0.18, 0.08)), n)
			_box(Vector3(0.2, 0.085, 0.245), Vector3(-0.08, 0.04, 0), _mat(Color(0.75, 0.1, 0.15)), n)
		9:  # challah
			for k in 3:
				_ball(0.12, Vector3(-0.14 + k * 0.14, 0.12, 0), _mat(Color(0.8, 0.55, 0.22)), n, Vector3(1.0, 0.9, 1.5))
		10:  # grape juice bottle
			_cap(0.09, 0.4, Vector3(0, 0.2, 0), _mat(Color(0.35, 0.08, 0.3)), n)
			_cap(0.04, 0.16, Vector3(0, 0.44, 0), _mat(Color(0.35, 0.08, 0.3)), n)
			_box(Vector3(0.19, 0.12, 0.19), Vector3(0, 0.2, 0), _mat(Color(0.95, 0.9, 0.7)), n)
		11:  # bag of rice
			_ball(0.17, Vector3(0, 0.19, 0), _mat(Color(0.95, 0.94, 0.88)), n, Vector3(1.0, 1.15, 0.6))
			_box(Vector3(0.2, 0.12, 0.2), Vector3(0, 0.2, 0), _mat(Color(0.2, 0.55, 0.3)), n)
		12:  # bananas
			for k in 3:
				_cap(0.04, 0.34, Vector3(-0.06 + k * 0.06, 0.07, 0), _mat(Color(0.98, 0.85, 0.2)), n, Vector3(1, 1, 1))
		13:  # tomato
			_ball(0.15, Vector3(0, 0.14, 0), _mat(Color(0.9, 0.15, 0.1)), n, Vector3(1, 0.85, 1))
			_box(Vector3(0.06, 0.03, 0.06), Vector3(0, 0.27, 0), _mat(Color(0.2, 0.5, 0.15)), n)
		14:  # yoghurt pot
			_box(Vector3(0.2, 0.24, 0.2), Vector3(0, 0.12, 0), _mat(Color(0.97, 0.97, 0.97)), n)
			_box(Vector3(0.22, 0.03, 0.22), Vector3(0, 0.255, 0), _mat(Color(0.9, 0.4, 0.6)), n)
		15:  # fish on a tray
			_box(Vector3(0.5, 0.05, 0.3), Vector3(0, 0.025, 0), _mat(Color(0.85, 0.9, 0.95)), n)
			_ball(0.11, Vector3(0, 0.12, 0), _mat(Color(0.55, 0.65, 0.75)), n, Vector3(2.0, 0.7, 0.8))
		_:  # cake
			_box(Vector3(0.38, 0.2, 0.38), Vector3(0, 0.1, 0), _mat(Color(0.55, 0.32, 0.18)), n)
			_box(Vector3(0.4, 0.05, 0.4), Vector3(0, 0.22, 0), _mat(Color(0.98, 0.9, 0.85)), n)
			_ball(0.045, Vector3(0, 0.27, 0), _mat(Color(0.85, 0.1, 0.15)), n)
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
	_box(Vector3(32, 1, 18), STORE + Vector3(0, -0.5, 0), _mat(Color(0.5, 0.47, 0.42)))
	_solid(Vector3(32, 1, 18), STORE + Vector3(0, -0.5, 0))
	var wall := _mat(Color(0.6, 0.66, 0.62))
	_box(Vector3(32, 5, 0.5), STORE + Vector3(0, 2.5, -8.75), wall)
	_solid(Vector3(32, 5, 0.5), STORE + Vector3(0, 2.5, -8.75))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.5, 5, 18), STORE + Vector3(side * 15.75, 2.5, 0), wall)
		_solid(Vector3(0.5, 5, 18), STORE + Vector3(side * 15.75, 2.5, 0))
	var slots: Array[Vector3] = [
		Vector3(-12, 0, -7.6), Vector3(-8, 0, -7.6), Vector3(-4, 0, -7.6), Vector3(0, 0, -7.6),
		Vector3(4, 0, -7.6), Vector3(8, 0, -7.6), Vector3(12, 0, -7.6),
		Vector3(-11, 0, -1.5), Vector3(-3, 0, -1.5), Vector3(1, 0, -1.5), Vector3(5, 0, -1.5), Vector3(9, 0, -1.5), Vector3(13, 0, -1.5),
		Vector3(5, 0, 3.0), Vector3(9, 0, 3.0), Vector3(13, 0, 3.0),
	]
	for k in slots.size():
		_shelf(SHELF_PIDS[k], STORE + slots[k])

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
	till.room = "market"
	till.key = "checkout"
	till.title = "קופה"
	till.prompt = "לשלם בקופה"
	till.door = desk + Vector3(0, 0, 1.7)
	places.append(till)

	_box(Vector3(2.6, 0.04, 1.4), STORE + Vector3(0, 0.03, 7.9), _mat(Color(0.25, 0.7, 0.4)))
	var out := Place.new()
	out.room = "market"
	out.key = "store_exit"
	out.title = "יציאה"
	out.prompt = "לצאת מהסופר"
	out.door = STORE + Vector3(0, 0, 7.9)
	places.append(out)


func _interact(p: Place) -> void:
	if busy or state != State.PLAY:
		return
	match p.key:
		"home", "market", "cafe", "work", "guns", "clinic", "diner", "build", "music", "hall", "shul":
			_enter_room(p)
		"store_exit", "exit":
			_leave_room()
		"school":
			_school_door()
		"playground":
			_play_outside("מתנדנדים ומתגלשים בגינה...", "שיחקת עם הילדים בגינה. הם נהנו מאוד!")
		"picnic":
			_play_outside("מטיילים ועושים פיקניק ביער...", "טיילת עם הילדים ביער. איזה כיף היה!")
		"bench":
			_bench_sleep()
		"toilet":
			_use_toilet()
		"shower":
			_shower()
		"table":
			_table_action()
		"pray":
			_pray()
		"stage":
			_perform()
		"busk":
			_busk()
		"bed":
			_sleep()
		"sofa":
			_rest()
		"parcel_in":
			_take_parcel()
		"parcel_out":
			_drop_parcel()
		_:
			_open_panel(p)


func _enter_room(p: Place) -> void:
	if _is_shabbat() and p.key not in ["home", "shul", "clinic"]:
		_toast("שבת היום, %s סגור. שבת שלום!" % p.title)
		return
	if p.key == "home" and rent_owed > 0 and not _is_shabbat():
		_open_panel(p)
		return
	if not _is_open(p):
		_toast("%s: סגור עכשיו. פתוח בין %s ל-%s." % [p.title, _time_text(p.open_from), _time_text(p.open_to)])
		_play("no")
		return
	inside = true
	room = p.key
	room_origin = ROOMS[room]["origin"]
	room_half = ROOMS[room]["half"]
	if room == "market":
		for item in store_items:
			item.visible = true
	player.position = room_origin + Vector3(0, 0, room_half.y - 2.7)
	me.root.rotation.y = PI
	cam_focus = player.position
	near = null
	_play("door")
	_apply_daylight()
	_toast(ROOM_HINTS[room])


func _leave_room() -> void:
	if room == "market" and not basket.is_empty():
		_toast("קודם משלמים בקופה, או מחזירים את המוצרים למדף.")
		_play("no")
		return
	for place in places:
		if place.key == room and place.room == "":
			player.position = place.door + Vector3(0, 0, 1.2)
	inside = false
	room = ""
	carrying = false
	_place_kids()
	focus = null
	me.root.rotation.y = 0.0
	cam_focus = player.position
	near = null
	_play("door")
	_apply_daylight()
	_update_hud()


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
	if state != State.PLAY or open_place != null or busy:
		return
	if not inside:
		_tap_forest(pos)
		return
	if room != "market":
		_tap_handles(pos)
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
	if _shabbat_block():
		return
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


# --------------------------------------------------------------- forest ----

func _in_forest() -> bool:
	return not inside and player.position.z > FOREST_Z - 2.0


func _forest_point() -> Vector3:
	return Vector3(rng.randf_range(WEST + 5.0, EAST - 5.0), 0, rng.randf_range(FOREST_Z + 6.0, FOREST_END - 4.0))


func _pine(pos: Vector3) -> void:
	var h := rng.randf_range(4.0, 7.0)
	_box(Vector3(0.35, 1.4, 0.35), pos + Vector3(0, 0.7, 0), _mat(Color(0.33, 0.22, 0.13)))
	_solid(Vector3(0.6, 2.0, 0.6), pos + Vector3(0, 1.0, 0))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = h * 0.3
	cone.height = h
	cone.radial_segments = 8
	var c := MeshInstance3D.new()
	c.mesh = cone
	c.material_override = _mat(Color.from_hsv(rng.randf_range(0.3, 0.38), 0.65, rng.randf_range(0.28, 0.42)))
	c.position = pos + Vector3(0, 1.2 + h * 0.5, 0)
	add_child(c)


func _make_animal(big: bool) -> Animal:
	var a := Animal.new()
	a.big = big
	a.node = Node3D.new()
	if big:  # deer
		var fur := _mat(Color(0.55, 0.36, 0.2))
		_box(Vector3(0.55, 0.6, 1.3), Vector3(0, 1.05, 0), fur, a.node)
		_box(Vector3(0.3, 0.7, 0.3), Vector3(0, 1.55, 0.65), fur, a.node)
		_box(Vector3(0.32, 0.3, 0.5), Vector3(0, 1.95, 0.8), fur, a.node)
		for sx: float in [-0.2, 0.2]:
			_box(Vector3(0.06, 0.45, 0.06), Vector3(sx, 2.3, 0.7), _mat(Color(0.85, 0.8, 0.7)), a.node)
			for sz: float in [-0.5, 0.5]:
				_box(Vector3(0.14, 0.8, 0.14), Vector3(sx, 0.4, sz), fur, a.node)
	else:    # rabbit
		var fur := _mat(Color(0.8, 0.78, 0.74))
		_ball(0.28, Vector3(0, 0.3, 0), fur, a.node, Vector3(1, 1, 1.4))
		_ball(0.18, Vector3(0, 0.55, 0.3), fur, a.node)
		for sx: float in [-0.08, 0.08]:
			_box(Vector3(0.07, 0.35, 0.05), Vector3(sx, 0.85, 0.28), fur, a.node)
	add_child(a.node)
	animals.append(a)
	return a


func _build_forest() -> void:
	_sign("היער", Vector3(0, 3.0, FOREST_Z - 3.0), 110)
	_box(Vector3(0.2, 2.6, 0.2), Vector3(0, 1.3, FOREST_Z - 3.0), _mat(Color(0.3, 0.2, 0.12)))
	for k in 310:
		var pos := Vector3(rng.randf_range(-125, 165), 0, rng.randf_range(FOREST_Z, FOREST_END + 25.0))
		if absf(pos.x) < 3.0 and pos.z < FOREST_Z + 14.0:
			continue                       # keep a path in from the sign
		_pine(pos)
	for k in 20:
		_make_animal(k < 9)
	for k in 6:
		var t := _make_person(Color(0.85, 0.08, 0.08), Color(0.6, 0.05, 0.05))
		t.town = k >= 3
		add_child(t.root)
		thugs.append(t)
	_reset_forest()


func _reset_forest() -> void:
	rob_cool = 0.0
	for a in animals:
		a.dead = false
		a.gone = 0.0
		a.scared = 0.0
		a.node.visible = true
		a.node.rotation = Vector3.ZERO
		a.node.position = _forest_point()
	for t in thugs:
		t.chasing = false
		t.wait = 0.0
		t.root.position = _thug_point(t)
		t.target = t.root.position


func _update_forest(delta: float) -> void:
	shot_cool = maxf(shot_cool - delta, 0.0)
	rob_cool = maxf(rob_cool - delta, 0.0)
	var here := player.position
	for a in animals:
		if a.gone > 0.0:
			a.gone -= delta
			if a.gone <= 0.0:
				a.dead = false
				a.node.visible = true
				a.node.rotation = Vector3.ZERO
				a.node.position = _forest_point()
			continue
		if a.dead:
			if a.node.position.distance_to(here) < 1.9:
				_collect(a)
			continue
		var away := a.node.position - here
		away.y = 0.0
		a.scared = maxf(a.scared - delta, 0.0)
		if away.length() < 7.0 and not inside:
			a.scared = 1.5
		var speed := 0.0
		if a.scared > 0.0:
			a.heading = away.normalized()
			speed = 7.5 if a.big else 6.0
		else:
			a.timer -= delta
			if a.timer <= 0.0:
				a.timer = rng.randf_range(1.5, 4.5)
				var angle := rng.randf() * TAU
				a.heading = Vector3(cos(angle), 0, sin(angle)) if rng.randf() < 0.65 else Vector3.ZERO
			speed = 1.6
		if a.heading != Vector3.ZERO:
			a.node.position += a.heading * speed * delta
			a.node.rotation.y = lerp_angle(a.node.rotation.y, atan2(a.heading.x, a.heading.z), 8.0 * delta)
		a.node.position.x = clampf(a.node.position.x, WEST + 2.0, EAST - 2.0)
		a.node.position.z = clampf(a.node.position.z, FOREST_Z + 3.0, FOREST_END - 2.0)

	for t in thugs:
		var to_me := here - t.root.position
		to_me.y = 0.0
		var dist := to_me.length()
		var in_reach := _in_forest() and here.z > FOREST_Z + 1.0 and not driving
		if t.town:
			# Street robbers only come out at night, and give up at any doorway or car.
			var night := clock >= 20.0 or clock < 5.0
			t.root.visible = night
			if not night:
				t.chasing = false
				continue
			in_reach = not inside and not driving and here.z < FOREST_Z - 2.0
		if t.chasing and (not in_reach or dist > 24.0 or rob_cool > 0.0):
			t.chasing = false
		elif not t.chasing and in_reach and dist < (9.0 if t.town else 13.0) and rob_cool <= 0.0:
			t.chasing = true
			_toast("אדם רע באדום רודף אחריך! היכנס לבניין או לרכב!" if t.town else "אדם רע באדום רודף אחריך! ברח מהיער!")
			_play("alarm")
		var step := Vector3.ZERO
		if t.chasing:
			step = to_me.normalized() * 5.6
			if dist < 1.3:
				_robbed()
		else:
			var to_target := t.target - t.root.position
			if to_target.length() < 1.0:
				t.wait -= delta
				if t.wait <= 0.0:
					t.wait = rng.randf_range(1.0, 4.0)
					t.target = _thug_point(t)
			else:
				step = to_target.normalized() * 2.0
		t.root.position += step * delta
		if t.town:
			t.root.position.z = clampf(t.root.position.z, -4.5, FOREST_Z - 3.0)
		else:
			t.root.position.z = maxf(t.root.position.z, FOREST_Z + 2.0)
		if step != Vector3.ZERO:
			t.root.rotation.y = lerp_angle(t.root.rotation.y, atan2(step.x, step.z), 10.0 * delta)
		_animate(t, step != Vector3.ZERO, delta * (1.8 if t.chasing else 1.0))


func _robbed() -> void:
	var stolen := mini(money, maxi(50, int(money * 0.3)))
	money -= stolen
	health = maxf(health - 12.0, 1.0)
	rob_cool = 18.0
	for t in thugs:
		t.chasing = false
		t.target = _thug_point(t)
	_play("no")
	_toast("שדדו אותך! לקחו לך ₪%d. התרחק מהם!" % stolen)


func _nearest_animal() -> Animal:
	var best: Animal
	var best_d := 30.0
	for a in animals:
		if a.dead or a.gone > 0.0:
			continue
		var d := a.node.position.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = a
	return best


## Tap or click on an animal on screen to shoot at it.
func _tap_forest(pos: Vector2) -> void:
	if not _in_forest():
		return
	var hit: Animal
	var best := 80.0
	for a in animals:
		if a.dead or a.gone > 0.0:
			continue
		var world := a.node.position + Vector3(0, 1.0 if a.big else 0.4, 0)
		if cam.is_position_behind(world):
			continue
		var d := cam.unproject_position(world).distance_to(pos)
		if d < best:
			best = d
			hit = a
	if hit != null:
		_shoot(hit)


func _shoot(a: Animal) -> void:
	if a != null and _shabbat_block():
		return
	if a == null or shot_cool > 0.0:
		return
	if not has_rifle:
		_toast("כדי לצוד צריך רובה ציד. קונים אותו בחנות הנשק ברחוב.")
		shot_cool = 1.0
		return
	if ammo <= 0:
		_toast("נגמרו הכדורים. קונים עוד בחנות הנשק.")
		_play("no")
		shot_cool = 1.0
		return
	var to_animal := a.node.position - player.position
	to_animal.y = 0.0
	var dist := to_animal.length()
	if dist > 30.0:
		_toast("רחוק מדי. צריך להתקרב בשקט.")
		shot_cool = 0.5
		return
	ammo -= 1
	shot_cool = 0.9
	reach = 0.4
	me.root.rotation.y = atan2(to_animal.x, to_animal.z)
	_play("bang")
	for other in animals:                  # the shot startles everything nearby
		if other.node.position.distance_to(player.position) < 35.0:
			other.scared = 4.0
			var flee: Vector3 = other.node.position - player.position
			flee.y = 0.0
			other.heading = flee.normalized()
	# Close shots always hit; far ones often miss, more so at small targets.
	var chance := clampf(1.25 - dist / (32.0 if a.big else 24.0), 0.1, 1.0)
	if rng.randf() < chance:
		a.dead = true
		a.scared = 0.0
		a.node.rotation.z = PI * 0.5
		_toast("פגעת! לך לאסוף את הבשר.")
	else:
		_toast("פספסת! החיה בורחת.")
	_update_hud()


func _collect(a: Animal) -> void:
	var pieces := 2 if a.big else 1
	var room := FRIDGE_MAX - fridge.size()
	if room <= 0:
		if a.timer <= 0.0:                 # do not repeat the message every frame
			_toast("אין מקום במקרר לבשר. מכור או אכול משהו קודם.")
		a.timer = 3.0
		return
	pieces = mini(pieces, room)
	for k in pieces:
		fridge.append(MEAT)
	a.gone = 50.0
	a.node.visible = false
	_play("pick")
	_toast("אספת %d נתחי בשר ציד. אפשר לאכול בבית או למכור בחנות הנשק." % pieces)


func _buy_rifle() -> void:
	if _shabbat_block():
		return
	if has_rifle:
		_toast("כבר יש לך רובה ציד.")
		return
	if money < RIFLE_PRICE:
		_toast("אין מספיק כסף (חסרים ₪%d)." % (RIFLE_PRICE - money))
		_play("no")
		return
	money -= RIFLE_PRICE
	has_rifle = true
	ammo += 5
	_play("pay")
	_toast("קנית רובה ציד, וקיבלת 5 כדורים. היער נמצא מדרום לפארק.")
	_refresh_panel()


func _buy_ammo() -> void:
	if _shabbat_block():
		return
	if not has_rifle:
		_toast("קודם צריך לקנות רובה ציד.")
		return
	if money < AMMO_PRICE:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	money -= AMMO_PRICE
	ammo += 10
	_play("pay")
	_toast("קנית 10 כדורים.")
	_refresh_panel()


func _sell_meat() -> void:
	if _shabbat_block():
		return
	var at := fridge.find(MEAT)
	if at < 0:
		return
	fridge.remove_at(at)
	money += int(PRODUCTS[MEAT]["price"])
	_play("pay")
	_toast("מכרת נתח בשר ציד.")
	_refresh_panel()


# ----------------------------------------------------------------- cars ----

func _make_car(color: Color) -> Node3D:
	var n := Node3D.new()
	_box(Vector3(1.9, 0.6, 4.2), Vector3(0, 0.7, 0), _mat(color), n)
	_box(Vector3(1.7, 0.6, 2.2), Vector3(0, 1.3, -0.25), _mat(Color(0.2, 0.3, 0.42)), n)
	_box(Vector3(1.72, 0.1, 2.22), Vector3(0, 1.62, -0.25), _mat(color.darkened(0.15)), n)
	var wheel := CylinderMesh.new()
	wheel.top_radius = 0.38
	wheel.bottom_radius = 0.38
	wheel.height = 0.3
	var rubber := _mat(Color(0.08, 0.08, 0.09))
	for sx: float in [-0.95, 0.95]:
		for sz: float in [-1.35, 1.35]:
			var w := MeshInstance3D.new()
			w.mesh = wheel
			w.material_override = rubber
			w.rotation.z = PI * 0.5
			w.position = Vector3(sx, 0.38, sz)
			n.add_child(w)
		_box(Vector3(0.4, 0.2, 0.08), Vector3(sx * 0.65, 0.78, 2.11), lamp_mat, n)
		_box(Vector3(0.4, 0.2, 0.08), Vector3(sx * 0.65, 0.78, -2.11), _mat(Color(0.8, 0.05, 0.05)), n)
	add_child(n)
	return n


## Swap the player's car for another model, keeping where it stands.
func _set_car_model(model: int) -> void:
	var pos := CAR_HOME
	if car != null:
		pos = car.position
		car.queue_free()
	car_model = model
	car = _make_car(CARS[model]["color"])
	if model == JEEP:
		car.scale = Vector3(1.08, 1.25, 1.0)
	var block := StaticBody3D.new()
	car_block = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.6, 4.2)
	car_block.shape = shape
	car_block.position.y = 0.8
	block.add_child(car_block)
	car.add_child(block)
	car.position = pos
	car.rotation.y = car_heading


func _build_cars() -> void:
	_set_car_model(0)

	# Car lot across the road, with the models you can buy.
	_box(Vector3(14, 0.04, 8), CAR_LOT + Vector3(0, 0.02, 0), _mat(Color(0.3, 0.31, 0.34)))
	_sign("מגרש רכבים", CAR_LOT + Vector3(0, 4.2, 3.2), 96)
	for sx: float in [-6.0, 6.0]:
		_box(Vector3(0.2, 4.0, 0.2), CAR_LOT + Vector3(sx, 2.0, 3.2), _mat(Color(0.2, 0.2, 0.22)))
	var dealer := Place.new()
	dealer.key = "dealer"
	dealer.title = "מגרש רכבים"
	dealer.prompt = "לקנות רכב חדש"
	dealer.door = CAR_LOT + Vector3(0, 0, -3.2)
	places.append(dealer)
	_box(Vector3(2.4, 0.04, 1.4), dealer.door + Vector3(0, 0.05, 0), _mat(Color(0.95, 0.75, 0.2)))
	for k in range(1, CARS.size()):
		var show := _make_car(CARS[k]["color"])
		if k == JEEP:
			show.scale = Vector3(1.08, 1.25, 1.0)
		show.position = CAR_LOT + Vector3(-8.5 + k * 4.25, 0, 1.0)
		show.rotation.y = PI
		_solid(Vector3(1.9, 1.6, 4.2), show.position + Vector3(0, 0.8, 0))
		_tag("%s ₪%d" % [CARS[k]["name"], CARS[k]["price"]], show.position + Vector3(0, 2.6, 0), 44)

	# Two lanes of traffic that loop along the street.
	for k in 9:
		var t := _make_car(Color.from_hsv(rng.randf(), rng.randf_range(0.2, 0.75), rng.randf_range(0.5, 0.95)))
		var east := k % 2 == 0
		t.position = Vector3(rng.randf_range(-130, 165), 0, 3.6 if east else 1.5)
		t.rotation.y = PI * 0.5 if east else -PI * 0.5
		t.set_meta("dir", 1.0 if east else -1.0)
		t.set_meta("top", rng.randf_range(7.0, 11.0))
		t.set_meta("speed", 8.0)
		traffic.append(t)

	# Petrol pump on the far pavement.
	_box(Vector3(0.8, 1.8, 0.6), GAS_PUMP + Vector3(0, 0.9, 0), _mat(Color(0.85, 0.15, 0.12)))
	_box(Vector3(0.6, 0.5, 0.62), GAS_PUMP + Vector3(0, 1.3, 0), _mat(Color(0.92, 0.92, 0.9)))
	_box(Vector3(2.6, 0.2, 2.0), GAS_PUMP + Vector3(0, 3.2, 0), _mat(Color(0.85, 0.15, 0.12)))
	for sx: float in [-1.1, 1.1]:
		_box(Vector3(0.15, 3.2, 0.15), GAS_PUMP + Vector3(sx, 1.6, 0.6), _mat(Color(0.3, 0.3, 0.32)))
	_solid(Vector3(0.8, 1.8, 0.6), GAS_PUMP + Vector3(0, 0.9, 0))
	_sign("דלק", GAS_PUMP + Vector3(0, 3.9, 0), 80)
	var gas := Place.new()
	gas.key = "gas"
	gas.title = "תחנת דלק"
	gas.prompt = "לתדלק"
	gas.door = GAS_PUMP + Vector3(0, 0, -1.6)
	places.append(gas)


func _park_car(pos: Vector3, heading: float) -> void:
	driving = false
	near_car = false
	car_speed = 0.0
	car_heading = heading
	if car != null:
		car.position = pos
		car.rotation.y = heading
		car_block.disabled = false
	body_shape.radius = 0.4
	body_shape.height = 1.9
	if me.root != null:
		me.root.visible = true


## The one "do the obvious thing here" button: E, Enter, Space or the prompt.
func _use() -> void:
	if state != State.PLAY or open_place != null or busy:
		return
	if driving:
		if near != null:
			_interact(near)
		elif absf(car_speed) > 3.0:
			_toast("קודם עוצרים את הרכב.")
		else:
			_exit_car()
	elif near != null:
		_interact(near)
	elif focus != null:
		_pick(focus)
	elif near_car and _can_pour():
		_pour_can()
	elif near_car:
		_enter_car()
	elif near_kin != null:
		_family_talk(near_kin)
	elif near_npc != null:
		_talk(near_npc)
	elif _in_forest():
		_shoot(_nearest_animal())


func _enter_car() -> void:
	if _shabbat_block():
		return
	driving = true
	near_car = false
	car_speed = 0.0
	car_block.disabled = true
	body_shape.radius = 0.9
	player.position = car.position
	me.root.visible = false
	_play("engine")
	if fuel <= 0.0:
		_toast("אין דלק ברכב.")
	else:
		_toast("נוסעים! מכוונים עם החיצים או עם האצבע.")


func _exit_car() -> void:
	var left := Vector3(cos(car_heading), 0, -sin(car_heading))
	var spot := car.position
	_park_car(car.position, car_heading)
	player.position = spot + left * 1.9
	if player.position.z < -5.4:               # never step out into a building
		player.position = spot - left * 1.9
	_play("door")
	_save()


func _drive(input: Vector2, delta: float) -> void:
	var want := Vector3(input.x, 0, input.y)
	if _is_shabbat():
		want = Vector3.ZERO              # the car stays parked until Shabbat is over
	if want.length() > 0.15 and fuel > 0.0:
		var grip := clampf(absf(car_speed) / 4.0, 0.35, 1.0)
		car_heading = rotate_toward(car_heading, atan2(want.x, want.z), 2.8 * grip * delta)
		car_speed = move_toward(car_speed, float(CARS[car_model]["top"]) * minf(want.length(), 1.0), 9.0 * delta)
	else:
		car_speed = move_toward(car_speed, 0.0, 14.0 * delta)
	var before := player.position
	player.velocity = Vector3(sin(car_heading), 0, cos(car_heading)) * car_speed + Vector3(0, -4.0, 0)
	player.move_and_slide()
	var moved := Vector3(player.position.x - before.x, 0, player.position.z - before.z).length()
	if delta > 0.0 and moved < absf(car_speed) * delta * 0.5:
		car_speed = moved / delta                # ran into something
	var had_fuel := fuel > 0.0
	fuel = maxf(fuel - moved / 32.0 * float(CARS[car_model]["use"]), 0.0)
	if had_fuel and fuel <= 0.0:
		_toast("נגמר הדלק! צא מהרכב, קנה מיכל דלק בתחנה והבא אותו לרכב.")
		_play("no")


func _update_traffic(delta: float) -> void:
	var resting := _is_shabbat()
	for t in traffic:
		t.visible = not resting          # no one drives on Shabbat
	if resting:
		return
	var mine := player.position if not inside else Vector3(0, 0, 999)
	for t in traffic:
		var dir: float = t.get_meta("dir")
		var want: float = t.get_meta("top")
		# Brake for the player (on foot or in the car), a parked car, or the car ahead.
		var blockers: Array[Vector3] = [mine, car.position]
		for other in traffic:
			if other != t:
				blockers.append(other.position)
		for b in blockers:
			var ahead := (b.x - t.position.x) * dir
			if ahead > 0.0 and ahead < 9.0 and absf(b.z - t.position.z) < 2.0:
				want = 0.0
		var now: float = move_toward(t.get_meta("speed"), want, 12.0 * delta)
		t.set_meta("speed", now)
		t.position.x += dir * now * delta
		if dir > 0.0 and t.position.x > 172.0:
			t.position.x = -135.0
		elif dir < 0.0 and t.position.x < -135.0:
			t.position.x = 172.0


func _fuel_price() -> int:
	return int(ceilf((100.0 - fuel) * 0.4))


func _refuel() -> void:
	if _shabbat_block():
		return
	var price := _fuel_price()
	if money < price:
		_toast("אין מספיק כסף לתדלוק מלא (₪%d)." % price)
		_play("no")
		return
	money -= price
	fuel = 100.0
	_play("pay")
	_toast("המכל מלא.")
	_refresh_panel()


# ------------------------------------------------------------ interiors ----

## Floor, three walls (the camera side stays open) and a way out.
func _room(key: String, floor_color: Color, wall_color: Color) -> Vector3:
	var o: Vector3 = ROOMS[key]["origin"]
	var half: Vector2 = ROOMS[key]["half"]
	var w := half.x * 2.0 + 2.0
	var d := half.y * 2.0 + 2.0
	_box(Vector3(w, 1, d), o + Vector3(0, -0.5, 0), _mat(floor_color))
	_solid(Vector3(w, 1, d), o + Vector3(0, -0.5, 0))
	var wall := _mat(wall_color)
	_box(Vector3(w, 4.5, 0.5), o + Vector3(0, 2.25, -half.y - 0.75), wall)
	_solid(Vector3(w, 4.5, 0.5), o + Vector3(0, 2.25, -half.y - 0.75))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.5, 4.5, d), o + Vector3(side * (half.x + 0.75), 2.25, 0), wall)
		_solid(Vector3(0.5, 4.5, d), o + Vector3(side * (half.x + 0.75), 2.25, 0))
	_box(Vector3(2.6, 0.04, 1.4), o + Vector3(0, 0.03, half.y - 0.3), _mat(Color(0.25, 0.7, 0.4)))
	var out := Place.new()
	out.room = key
	out.key = "exit"
	out.title = "יציאה"
	out.prompt = "לצאת החוצה"
	out.door = o + Vector3(0, 0, half.y - 0.3)
	places.append(out)
	return o


## A place to stand (marked on the floor) where E or the prompt button acts.
func _spot(room_key: String, key: String, title: String, prompt_text: String, pos: Vector3) -> Place:
	_box(Vector3(1.6, 0.04, 1.2), pos + Vector3(0, 0.03, 0), _mat(Color(0.95, 0.75, 0.2)))
	var p := Place.new()
	p.room = room_key
	p.key = key
	p.title = title
	p.prompt = prompt_text
	p.door = pos
	places.append(p)
	return p


## Something you can click or tap with your hand when you stand close to it.
func _handle(node: Node3D, room_key: String, action: Callable) -> void:
	handles.append({"node": node, "room": room_key, "action": action})


func _tap_handles(pos: Vector2) -> void:
	var hit: Dictionary = {}
	var best := 90.0
	for h in handles:
		if h["room"] != room:
			continue
		var node: Node3D = h["node"]
		if not node.visible or cam.is_position_behind(node.global_position):
			continue
		var d := cam.unproject_position(node.global_position).distance_to(pos)
		if d < best:
			best = d
			hit = h
	if hit.is_empty():
		return
	var target: Node3D = hit["node"]
	var to_target := target.global_position - player.position
	if Vector3(to_target.x, 0, to_target.z).length() > 3.4:
		_toast("צריך להתקרב כדי להגיע עם היד.")
		return
	reach = 0.35
	me.root.rotation.y = atan2(to_target.x, to_target.z)
	(hit["action"] as Callable).call()


func _tag(text: String, pos: Vector3, size: int = 52) -> void:
	var l := Label3D.new()
	l.text = _h(text)
	l.font = font
	l.font_size = size
	l.pixel_size = 0.01
	l.outline_size = 14
	l.outline_modulate = Color(0.05, 0.08, 0.15)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	add_child(l)


func _chair(pos: Vector3, back_side: float, color: Color) -> void:
	var m := _mat(color)
	_box(Vector3(0.6, 0.1, 0.6), pos + Vector3(0, 0.55, 0), m)
	_box(Vector3(0.6, 0.7, 0.1), pos + Vector3(0, 0.95, back_side * 0.25), m)
	for sx: float in [-0.25, 0.25]:
		for sz: float in [-0.25, 0.25]:
			_box(Vector3(0.08, 0.5, 0.08), pos + Vector3(sx, 0.25, sz), m)


func _table(pos: Vector3, size: Vector2, color: Color) -> void:
	var m := _mat(color)
	_box(Vector3(size.x, 0.1, size.y), pos + Vector3(0, 0.95, 0), m)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(Vector3(0.12, 0.9, 0.12), pos + Vector3(sx * (size.x * 0.5 - 0.12), 0.45, sz * (size.y * 0.5 - 0.12)), m)
	_solid(Vector3(size.x, 1.0, size.y), pos + Vector3(0, 0.5, 0))


func _build_interiors() -> void:
	_build_home()
	_build_cafe()
	_build_work()
	_build_gun_shop()
	_build_clinic()
	_build_diner()
	_build_site()
	_build_music_shop()
	_build_hall()
	_build_shul()


func _build_home() -> void:
	var o := _room("home", Color(0.62, 0.48, 0.34), Color(0.86, 0.8, 0.68))
	var wood := Color(0.45, 0.3, 0.18)
	var wall := _mat(Color(0.86, 0.8, 0.68))

	# Inner walls: bedroom on the left, bathroom on the right, kitchen between them.
	for wx: float in [-4.2, 5.4]:
		_box(Vector3(0.25, 3.2, 4.6), o + Vector3(wx, 1.6, -6.2), wall)
		_solid(Vector3(0.25, 3.2, 4.6), o + Vector3(wx, 1.6, -6.2))

	# --- Bedroom
	_box(Vector3(5.6, 0.03, 3.6), o + Vector3(-8.0, 0.02, -5.6), _mat(Color(0.35, 0.42, 0.6)))
	var bed := o + Vector3(-9.6, 0, -6.2)
	_box(Vector3(2.4, 0.5, 3.8), bed + Vector3(0, 0.25, 0), _mat(wood))
	var mattress := _box(Vector3(2.2, 0.25, 3.6), bed + Vector3(0, 0.62, 0), _mat(Color(0.93, 0.93, 0.9)))
	_box(Vector3(2.22, 0.27, 2.1), bed + Vector3(0, 0.64, 0.75), _mat(Color(0.25, 0.4, 0.75)))
	for sx: float in [-0.5, 0.5]:
		_box(Vector3(0.85, 0.2, 0.6), bed + Vector3(sx, 0.85, -1.35), _mat(Color(1, 1, 1)))
	_box(Vector3(2.4, 1.3, 0.2), bed + Vector3(0, 0.65, -1.95), _mat(wood))
	_solid(Vector3(2.4, 1.0, 3.8), bed + Vector3(0, 0.5, 0))
	_tag("מיטה", bed + Vector3(0, 2.0, 0))
	var bed_spot := _spot("home", "bed", "מיטה", "לישון במיטה", bed + Vector3(2.1, 0, 0.8))
	_handle(mattress, "home", _interact.bind(bed_spot))
	_box(Vector3(0.7, 0.6, 0.6), bed + Vector3(1.7, 0.3, -1.6), _mat(wood))                    # nightstand
	_box(Vector3(0.25, 0.35, 0.25), bed + Vector3(1.7, 0.78, -1.6), lamp_mat)
	_box(Vector3(2.2, 2.6, 0.8), o + Vector3(-5.6, 1.3, -8.0), _mat(wood.darkened(0.1)))        # wardrobe
	_solid(Vector3(2.2, 2.6, 0.8), o + Vector3(-5.6, 1.3, -8.0))

	# --- Kitchen
	var fridge_pos := o + Vector3(-3.2, 0, -7.9)
	var fridge_box := _box(Vector3(1.2, 2.3, 0.9), fridge_pos + Vector3(0, 1.15, 0), _mat(Color(0.82, 0.85, 0.88)))
	_box(Vector3(0.06, 0.8, 0.06), fridge_pos + Vector3(0.42, 1.35, 0.48), _mat(Color(0.3, 0.3, 0.32)))
	_solid(Vector3(1.2, 2.3, 0.9), fridge_pos + Vector3(0, 1.15, 0))
	_tag("מקרר", fridge_pos + Vector3(0, 2.8, 0))
	var fridge_spot := _spot("home", "fridge", "המקרר", "לפתוח את המקרר", fridge_pos + Vector3(0, 0, 1.4))
	_handle(fridge_box, "home", _interact.bind(fridge_spot))
	_box(Vector3(4.6, 1.0, 0.8), o + Vector3(0.2, 0.5, -8.0), _mat(Color(0.9, 0.9, 0.86)))
	_box(Vector3(4.6, 0.08, 0.85), o + Vector3(0.2, 1.04, -8.0), _mat(Color(0.3, 0.3, 0.33)))
	_box(Vector3(0.9, 0.05, 0.5), o + Vector3(-0.9, 1.09, -8.0), _mat(Color(0.6, 0.65, 0.7)))    # sink
	_box(Vector3(1.0, 0.04, 0.7), o + Vector3(1.4, 1.1, -8.0), _mat(Color(0.1, 0.1, 0.12)))     # hob
	_solid(Vector3(4.6, 1.1, 0.8), o + Vector3(0.2, 0.55, -8.0))
	for k in 3:
		_box(Vector3(1.3, 0.7, 0.4), o + Vector3(-1.1 + k * 1.4, 2.5, -8.25), _mat(wood.lightened(0.1)))

	# --- Bathroom
	_box(Vector3(6.0, 0.03, 4.4), o + Vector3(8.6, 0.02, -6.2), _mat(Color(0.75, 0.85, 0.9)))
	var loo := o + Vector3(7.0, 0, -7.9)
	var bowl := _box(Vector3(0.55, 0.45, 0.7), loo + Vector3(0, 0.23, 0.1), _mat(Color(0.97, 0.97, 0.97)))
	_box(Vector3(0.6, 0.06, 0.74), loo + Vector3(0, 0.48, 0.1), _mat(Color(0.9, 0.9, 0.92)))
	_box(Vector3(0.6, 0.6, 0.25), loo + Vector3(0, 0.75, -0.35), _mat(Color(0.97, 0.97, 0.97)))
	_solid(Vector3(0.6, 1.0, 1.0), loo + Vector3(0, 0.5, 0))
	_tag("שירותים", loo + Vector3(0, 1.9, 0))
	var loo_spot := _spot("home", "toilet", "שירותים", "להשתמש בשירותים", loo + Vector3(0, 0, 1.5))
	_handle(bowl, "home", _interact.bind(loo_spot))
	_box(Vector3(1.0, 0.85, 0.6), o + Vector3(8.8, 0.43, -8.1), _mat(Color(0.95, 0.95, 0.95)))   # basin
	_box(Vector3(0.9, 0.9, 0.05), o + Vector3(8.8, 1.8, -8.45), _mat(Color(0.7, 0.85, 0.95)))   # mirror
	_solid(Vector3(1.0, 0.9, 0.6), o + Vector3(8.8, 0.45, -8.1))
	var shower := o + Vector3(10.5, 0, -5.4)
	var tray := _box(Vector3(1.6, 0.12, 1.6), shower + Vector3(0, 0.06, 0), _mat(Color(0.55, 0.75, 0.9)))
	_box(Vector3(0.06, 2.3, 0.06), shower + Vector3(0.6, 1.15, -0.6), _mat(Color(0.75, 0.75, 0.78)))
	_box(Vector3(0.4, 0.06, 0.3), shower + Vector3(0.4, 2.25, -0.5), _mat(Color(0.75, 0.75, 0.78)))
	_tag("מקלחת", shower + Vector3(0, 2.8, 0))
	var shower_spot := _spot("home", "shower", "מקלחת", "להתקלח", shower + Vector3(-1.8, 0, 0))
	_handle(tray, "home", _interact.bind(shower_spot))

	# --- Living room
	_box(Vector3(5.4, 0.03, 4.2), o + Vector3(6.6, 0.02, 0.6), _mat(Color(0.6, 0.2, 0.22)))
	var sofa := o + Vector3(6.6, 0, -1.8)
	var fabric := _mat(Color(0.3, 0.5, 0.45))
	var seat := _box(Vector3(3.6, 0.5, 1.1), sofa + Vector3(0, 0.35, 0), fabric)
	_box(Vector3(3.6, 1.0, 0.3), sofa + Vector3(0, 0.8, -0.45), fabric)
	for sx: float in [-1.7, 1.7]:
		_box(Vector3(0.3, 0.8, 1.1), sofa + Vector3(sx, 0.5, 0), fabric)
	for sx: float in [-0.9, 0.9]:
		_box(Vector3(0.7, 0.3, 0.3), sofa + Vector3(sx, 0.75, -0.2), _mat(Color(0.9, 0.75, 0.3)))
	_solid(Vector3(3.6, 1.0, 1.1), sofa + Vector3(0, 0.5, 0))
	_tag("ספה", sofa + Vector3(0, 2.0, 0))
	var sofa_spot := _spot("home", "sofa", "ספה", "לנוח על הספה", sofa + Vector3(0, 0, 1.4))
	_handle(seat, "home", _interact.bind(sofa_spot))
	_box(Vector3(1.6, 0.4, 0.8), o + Vector3(6.6, 0.2, 1.6), _mat(wood))                         # coffee table
	_solid(Vector3(1.6, 0.4, 0.8), o + Vector3(6.6, 0.2, 1.6))
	_box(Vector3(2.4, 0.5, 0.5), o + Vector3(6.6, 0.25, 3.9), _mat(wood.darkened(0.2)))          # TV stand
	_box(Vector3(2.0, 1.2, 0.08), o + Vector3(6.6, 1.15, 3.9), _mat(Color(0.05, 0.05, 0.07)))
	_solid(Vector3(2.4, 1.6, 0.5), o + Vector3(6.6, 0.8, 3.9))
	_box(Vector3(0.6, 2.4, 2.6), o + Vector3(11.2, 1.2, 1.0), _mat(wood))                        # bookcase
	for k in 12:
		_box(Vector3(0.1, 0.5, 0.16), o + Vector3(10.87, 0.55 + (k / 4) * 0.75, 0.1 + (k % 4) * 0.5), _mat(Color.from_hsv(k * 0.08, 0.6, 0.8)))
	_solid(Vector3(0.6, 2.4, 2.6), o + Vector3(11.2, 1.2, 1.0))
	_cap(0.25, 0.6, o + Vector3(10.8, 0.3, -2.6), _mat(Color(0.6, 0.35, 0.2)), self)             # plant pot
	_ball(0.5, o + Vector3(10.8, 1.0, -2.6), _mat(Color(0.2, 0.55, 0.25)), self, Vector3(1, 1.3, 1))

	# --- Dining area: a table for six, with the Shabbat candlesticks.
	var table := o + Vector3(-4.2, 0, 1.6)
	_table(table, Vector2(3.2, 1.4), wood)
	for sx: float in [-1.0, 0.0, 1.0]:
		_chair(table + Vector3(sx, 0, 1.1), 1.0, wood.lightened(0.15))
		_chair(table + Vector3(sx, 0, -1.1), -1.0, wood.lightened(0.15))
	_box(Vector3(2.2, 0.02, 0.9), table + Vector3(0, 1.01, 0), _mat(Color(0.97, 0.97, 0.95)))    # tablecloth
	var sticks := Node3D.new()
	sticks.position = table + Vector3(0, 1.02, 0)
	add_child(sticks)
	for sx: float in [-0.18, 0.18]:
		_box(Vector3(0.06, 0.3, 0.06), Vector3(sx, 0.15, 0), _mat(Color(0.8, 0.8, 0.85)), sticks)
		_box(Vector3(0.04, 0.16, 0.04), Vector3(sx, 0.38, 0), _mat(Color(1, 1, 0.95)), sticks)
		var flame := Node3D.new()
		flame.position = Vector3(sx, 0.52, 0)
		sticks.add_child(flame)
		_ball(0.05, Vector3.ZERO, lamp_mat, flame, Vector3(0.8, 1.6, 0.8))
		flame.visible = false
		flames.append(flame)
	_tag("נרות שבת", table + Vector3(0, 2.1, 0), 40)
	_handle(sticks, "home", _light_candles)
	_spot("home", "table", "שולחן האוכל", "לשבת לשולחן", table + Vector3(-2.5, 0, 0))

	_build_family(o)

	# --- Desk by the wall
	_table(o + Vector3(-10.4, 0, 3.6), Vector2(1.4, 2.4), wood.lightened(0.1))
	_box(Vector3(0.08, 0.6, 0.9), o + Vector3(-10.7, 1.35, 3.6), _mat(Color(0.1, 0.12, 0.16)))
	_chair(o + Vector3(-9.2, 0, 3.6), 0.0, Color(0.2, 0.22, 0.28))


func _build_cafe() -> void:
	var o := _room("cafe", Color(0.5, 0.36, 0.26), Color(0.9, 0.82, 0.68))
	var wood := Color(0.4, 0.26, 0.15)
	_box(Vector3(6.0, 1.1, 1.0), o + Vector3(0, 0.55, -4.2), _mat(wood))
	_box(Vector3(6.1, 0.08, 1.1), o + Vector3(0, 1.14, -4.2), _mat(Color(0.85, 0.8, 0.7)))
	_solid(Vector3(6.0, 1.1, 1.0), o + Vector3(0, 0.55, -4.2))
	var barista := _make_person(Color(0.25, 0.25, 0.28), Color(0.15, 0.15, 0.18))
	barista.root.position = o + Vector3(0, 0, -5.4)
	add_child(barista.root)

	var meal := Node3D.new()
	meal.position = o + Vector3(-1.6, 1.18, -4.1)
	add_child(meal)
	_box(Vector3(0.7, 0.05, 0.7), Vector3.ZERO, _mat(Color(0.96, 0.96, 0.93)), meal)
	_ball(0.2, Vector3(-0.1, 0.15, 0), _mat(Color(0.7, 0.4, 0.2)), meal, Vector3(1.2, 0.7, 1))
	_ball(0.12, Vector3(0.2, 0.1, 0.1), _mat(Color(0.3, 0.65, 0.25)), meal)
	_tag("ארוחה חמה ₪30", meal.position + Vector3(0, 1.0, 0))
	_handle(meal, "cafe", _cafe.bind(30, 60.0, 0.0, 0.75, "אכלת ארוחה חמה. טעים!"))

	var cup := Node3D.new()
	cup.position = o + Vector3(1.6, 1.18, -4.1)
	add_child(cup)
	_box(Vector3(0.28, 0.3, 0.28), Vector3(0, 0.15, 0), _mat(Color(0.95, 0.95, 0.95)), cup)
	_box(Vector3(0.22, 0.02, 0.22), Vector3(0, 0.31, 0), _mat(Color(0.3, 0.18, 0.1)), cup)
	_tag("קפה ₪8", cup.position + Vector3(0, 1.0, 0))
	_handle(cup, "cafe", _cafe.bind(8, 3.0, 15.0, 0.25, "שתית קפה. קצת יותר ערני."))

	_spot("cafe", "cafe_counter", "קפה ומסעדה", "להזמין בדלפק", o + Vector3(0, 0, -2.8))
	for x: float in [-5.0, 5.0]:
		var t := o + Vector3(x, 0, 0.5)
		_table(t, Vector2(1.4, 1.4), wood.lightened(0.2))
		_chair(t + Vector3(0, 0, 1.15), 1.0, wood)
		_chair(t + Vector3(0, 0, -1.15), -1.0, wood)


func _build_work() -> void:
	var o := _room("work", Color(0.5, 0.52, 0.55), Color(0.7, 0.74, 0.8))
	var metal := Color(0.4, 0.42, 0.46)
	var carton := _mat(Color(0.72, 0.55, 0.32))

	# Table with the parcels waiting to be shelved.
	var desk := o + Vector3(-7, 0, -2.5)
	_table(desk, Vector2(3.0, 1.5), metal)
	for k in 4:
		var box := _box(Vector3(0.6, 0.5, 0.6), desk + Vector3(-0.95 + k * 0.65, 1.25, 0), carton)
		parcel_pile.append(box)
		_handle(box, "work", _take_parcel)
	_tag("חבילות", desk + Vector3(0, 2.3, 0))
	_spot("work", "parcel_in", "חבילות", "לקחת חבילה", desk + Vector3(0, 0, 1.6))

	# Shelf where they go.
	var shelf := o + Vector3(7, 0, -6.3)
	_box(Vector3(4.2, 3.0, 0.15), shelf + Vector3(0, 1.5, -0.35), _mat(metal))
	var board: MeshInstance3D
	for y: float in [0.6, 1.6, 2.6]:
		board = _box(Vector3(4.2, 0.1, 0.9), shelf + Vector3(0, y, 0), _mat(metal))
		if is_equal_approx(y, 1.6):
			_handle(board, "work", _drop_parcel)
	_solid(Vector3(4.2, 3.0, 0.9), shelf + Vector3(0, 1.5, 0))
	for k in 8:
		var stored := _box(Vector3(0.6, 0.5, 0.6), shelf + Vector3(-1.5 + (k % 4) * 1.0, 0.9 + (k / 4) * 1.0, 0), carton)
		stored.visible = false
		shelf_boxes.append(stored)
	_tag("מדף", shelf + Vector3(0, 3.6, 0))
	_spot("work", "parcel_out", "מדף", "לשים חבילה על המדף", shelf + Vector3(0, 0, 1.4))

	# Office corner: two desks with screens, and the manager.
	for x: float in [-2.0, 1.5]:
		var d := o + Vector3(x, 0, -5.6)
		_table(d, Vector2(2.2, 1.1), Color(0.75, 0.72, 0.66))
		_box(Vector3(0.9, 0.6, 0.08), d + Vector3(0, 1.4, -0.2), _mat(Color(0.1, 0.12, 0.16)))
		_box(Vector3(0.1, 0.2, 0.1), d + Vector3(0, 1.1, -0.2), _mat(Color(0.1, 0.12, 0.16)))
		_chair(d + Vector3(0, 0, 1.0), 1.0, Color(0.2, 0.22, 0.28))
	var boss := _make_person(Color(0.9, 0.9, 0.92), Color(0.15, 0.17, 0.25))
	boss.root.position = o + Vector3(-4.2, 0, -5.2)
	add_child(boss.root)
	_tag("המנהל", boss.root.position + Vector3(0, 2.6, 0))


func _build_gun_shop() -> void:
	var o := _room("guns", Color(0.36, 0.34, 0.3), Color(0.55, 0.57, 0.5))
	_box(Vector3(5.0, 1.1, 1.0), o + Vector3(0, 0.55, -3.2), _mat(Color(0.3, 0.24, 0.18)))
	_solid(Vector3(5.0, 1.1, 1.0), o + Vector3(0, 0.55, -3.2))
	var seller := _make_person(Color(0.35, 0.4, 0.25), Color(0.2, 0.2, 0.18))
	seller.root.position = o + Vector3(0, 0, -4.4)
	add_child(seller.root)

	var rifle := Node3D.new()
	rifle.position = o + Vector3(-1.5, 1.2, -3.1)
	add_child(rifle)
	_box(Vector3(1.5, 0.1, 0.1), Vector3(0.15, 0.05, 0), _mat(Color(0.15, 0.15, 0.17)), rifle)
	_box(Vector3(0.6, 0.18, 0.12), Vector3(-0.7, 0.03, 0), _mat(Color(0.4, 0.26, 0.14)), rifle)
	_tag("רובה ציד ₪%d" % RIFLE_PRICE, rifle.position + Vector3(0, 0.9, 0))
	_handle(rifle, "guns", _buy_rifle)

	var box := Node3D.new()
	box.position = o + Vector3(1.5, 1.2, -3.1)
	add_child(box)
	for k in 3:
		_box(Vector3(0.3, 0.2, 0.22), Vector3(-0.35 + k * 0.35, 0.1, 0), _mat(Color(0.75, 0.6, 0.15)), box)
	_tag("10 כדורים ₪%d" % AMMO_PRICE, box.position + Vector3(0, 0.9, 0))
	_handle(box, "guns", _buy_ammo)

	_spot("guns", "gun_counter", "חנות נשק", "לדבר עם המוכר", o + Vector3(0, 0, -1.8))
	# Display racks along the walls.
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.4, 2.4, 3.0), o + Vector3(side * 5.6, 1.2, -2.0), _mat(Color(0.25, 0.2, 0.15)))
		_solid(Vector3(0.4, 2.4, 3.0), o + Vector3(side * 5.6, 1.2, -2.0))


func _buy_car(model: int) -> void:
	if _shabbat_block():
		return
	var price := int(CARS[model]["price"])
	if driving:
		_toast("קודם יוצאים מהרכב.")
		return
	if money < price:
		_toast("אין מספיק כסף (חסרים ₪%d)." % (price - money))
		_play("no")
		return
	money -= price
	_set_car_model(model)
	fuel = 100.0
	_play("pay")
	_toast("קנית %s! היא מחכה לך במקום שבו חנה הרכב הקודם." % CARS[model]["name"])
	_save()
	_refresh_panel()


func _buy_can() -> void:
	if _shabbat_block():
		return
	if money < CAN_PRICE:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	money -= CAN_PRICE
	has_can = true
	_play("pay")
	_toast("קנית מיכל דלק. לך לרכב ומלא אותו.")
	_refresh_panel()


func _can_pour() -> bool:
	return has_can and near_car and fuel < 99.0


func _pour_can() -> void:
	has_can = false
	fuel = minf(fuel + CAN_FUEL, 100.0)
	reach = 0.4
	_play("pick")
	_toast("מילאת דלק מהמיכל. עכשיו יש %d%% במכל." % int(fuel))
	_update_hud()


func _pay_rent() -> void:
	if _shabbat_block():
		return
	if money < rent_owed:
		_toast("אין מספיק כסף (חסרים ₪%d). לך לעבוד, ובינתיים ישנים על ספסל בפארק." % (rent_owed - money))
		_play("no")
		return
	money -= rent_owed
	rent_owed = 0
	_play("pay")
	var home := open_place
	_close_panel()
	_save()
	_enter_room(home)
	_toast("שכר הדירה חודש. ברוך הבא הביתה!")


## Sleeping rough: slower, and you never wake up fully rested.
func _bench_sleep() -> void:
	if energy > 60.0:
		_toast("אתה לא מספיק עייף כדי לישון על ספסל.")
		return
	var hours := clampf(ceilf((70.0 - energy) / 8.0), 1.0, 8.0)
	var before := energy
	_time_skip("ישנים על הספסל...", func() -> void:
		_skip(hours, "sleep")
		energy = minf(before + hours * 8.0, 70.0)
		_save()
		_toast("ישנת %d שעות על הספסל. לא הכי נוח." % int(hours)))


## Collapsing no longer ends the game: you wake up outside your home, poorer.
func _hospital() -> void:
	var fee := mini(money, 150)
	money -= fee
	health = 50.0
	hunger = maxf(hunger, 60.0)
	energy = maxf(energy, 70.0)
	var car_at := car.position
	var heading := car_heading
	_close_panel()
	_reset_position()
	_park_car(car_at, heading)
	_apply_daylight()
	_play("no")
	_toast("התעלפת מרעב ומעייפות, וטיפלו בך בבית החולים. שילמת ₪%d." % fee)


func _thug_point(t: Person) -> Vector3:
	if t.town:
		return Vector3(rng.randf_range(WEST + 4.0, EAST - 4.0), 0, rng.randf_range(-3.5, 28.0))
	return _forest_point()


# ------------------------------------------------- a bigger, busier town ----

## An apartment block with rows of windows. Only scenery.
func _block(pos: Vector3, size: Vector3, color: Color) -> void:
	_box(size, pos + Vector3(0, size.y * 0.5, 0), _mat(color))
	_box(Vector3(size.x + 0.4, 0.3, size.z + 0.4), pos + Vector3(0, size.y + 0.15, 0), _mat(color.darkened(0.3)))
	var floors := int(size.y / 3.0)
	var columns := int(size.x / 2.6)
	for f in floors:
		for c in columns:
			var x := (c - (columns - 1) * 0.5) * 2.6
			_box(Vector3(1.3, 1.4, 0.1), pos + Vector3(x, 1.9 + f * 3.0, size.z * 0.5 + 0.03), window_mat)


func _build_town_extras() -> void:
	# A second row of apartment blocks behind the street.
	var palette: Array[Color] = [Color(0.78, 0.74, 0.66), Color(0.66, 0.7, 0.76), Color(0.8, 0.68, 0.6), Color(0.7, 0.75, 0.68)]
	for k in 19:
		var h := rng.randf_range(9.0, 19.0)
		_block(Vector3(-118 + k * 15.0 + rng.randf_range(-1.5, 1.5), 0, -27), Vector3(rng.randf_range(9, 12), h, 9), palette[k % 4])
	# Houses south of the road, east of the park.
	for k in 4:
		var hp := Vector3(52 + k * 9.5, 0, 14)
		_box(Vector3(7, 3.6, 6), hp + Vector3(0, 1.8, 0), _mat(palette[(k + 1) % 4]))
		_box(Vector3(7.6, 0.4, 6.6), hp + Vector3(0, 3.8, 0), _mat(Color(0.6, 0.25, 0.2)))
		_box(Vector3(1.3, 2.2, 0.1), hp + Vector3(0, 1.1, -3.03), _mat(Color(0.3, 0.2, 0.12)))
		for sx: float in [-2.2, 2.2]:
			_box(Vector3(1.4, 1.2, 0.1), hp + Vector3(sx, 2.0, -3.03), window_mat)
		_solid(Vector3(7, 3.6, 6), hp + Vector3(0, 1.8, 0))
		_tree(hp + Vector3(4.6, 0, 3.5))
	# Zebra crossings.
	var white := _mat(Color(0.92, 0.92, 0.9))
	for x: float in [-16.0, 16.0, 48.0]:
		for k in 6:
			_box(Vector3(2.2, 0.03, 0.55), Vector3(x, 0.06, -1.0 + k * 1.0), white)
	# Bus stop with a shelter and bench.
	var stop := Vector3(32, 0, 5.6)
	var steel := _mat(Color(0.3, 0.32, 0.36))
	_box(Vector3(4.0, 0.12, 1.6), stop + Vector3(0, 2.6, 0), steel)
	_box(Vector3(4.0, 2.4, 0.08), stop + Vector3(0, 1.3, 0.75), _mat(Color(0.55, 0.75, 0.85)))
	for sx: float in [-1.9, 1.9]:
		_box(Vector3(0.1, 2.6, 0.1), stop + Vector3(sx, 1.3, -0.7), steel)
	_box(Vector3(2.6, 0.12, 0.5), stop + Vector3(0, 0.55, 0.4), _mat(Color(0.5, 0.33, 0.2)))
	_sign("תחנת אוטובוס", stop + Vector3(0, 3.3, 0), 56)
	# Bins, post boxes and flower beds along the pavement.
	for x: float in [-30.0, -2.0, 30.0, 62.0]:
		_box(Vector3(0.6, 0.9, 0.6), Vector3(x, 0.45, -1.9), _mat(Color(0.15, 0.4, 0.25)))
	for x: float in [-14.0, 18.0, 46.0]:
		_box(Vector3(0.5, 1.1, 0.5), Vector3(x, 0.55, -5.7), _mat(Color(0.8, 0.12, 0.1)))
	for x: float in [-46.0, 0.0, 66.0]:
		_box(Vector3(3.0, 0.3, 0.9), Vector3(x, 0.15, -5.4), _mat(Color(0.4, 0.3, 0.2)))
		for k in 5:
			_ball(0.22, Vector3(x - 1.1 + k * 0.55, 0.45, -5.4), _mat(Color.from_hsv(rng.randf(), 0.7, 0.95)), self)


func _build_clinic() -> void:
	var o := _room("clinic", Color(0.78, 0.84, 0.86), Color(0.92, 0.95, 0.96))
	_box(Vector3(3.0, 1.1, 0.9), o + Vector3(-3.5, 0.55, -3.6), _mat(Color(0.85, 0.87, 0.9)))
	_solid(Vector3(3.0, 1.1, 0.9), o + Vector3(-3.5, 0.55, -3.6))
	_box(Vector3(0.5, 0.2, 0.5), o + Vector3(-3.5, 1.35, -3.6), _mat(Color(0.85, 0.1, 0.1)))
	_box(Vector3(0.2, 0.5, 0.5), o + Vector3(-3.5, 1.35, -3.6), _mat(Color(0.85, 0.1, 0.1)))
	# Examination bed
	var bed := o + Vector3(3.8, 0, -3.8)
	_box(Vector3(1.4, 0.7, 3.0), bed + Vector3(0, 0.35, 0), _mat(Color(0.5, 0.55, 0.6)))
	_box(Vector3(1.3, 0.15, 2.9), bed + Vector3(0, 0.78, 0), _mat(Color(0.95, 0.97, 1.0)))
	_solid(Vector3(1.4, 0.9, 3.0), bed + Vector3(0, 0.45, 0))
	# Medicine cabinet
	_box(Vector3(2.0, 2.4, 0.6), o + Vector3(0.5, 1.2, -5.1), _mat(Color(0.95, 0.95, 0.95)))
	for k in 6:
		_box(Vector3(0.25, 0.35, 0.1), o + Vector3(-0.2 + (k % 3) * 0.7, 1.0 + (k / 3) * 0.8, -4.77), _mat(Color.from_hsv(k * 0.15, 0.6, 0.9)))
	_solid(Vector3(2.0, 2.4, 0.6), o + Vector3(0.5, 1.2, -5.1))
	var doctor := _make_person(Color(0.97, 0.97, 0.99), Color(0.2, 0.45, 0.55))
	doctor.root.position = o + Vector3(1.8, 0, -2.6)
	add_child(doctor.root)
	_tag("הרופאה", doctor.root.position + Vector3(0, 2.6, 0))
	var spot := _spot("clinic", "doctor", "מרפאה", "לדבר עם הרופאה", o + Vector3(1.8, 0, -1.0))
	_handle(doctor.root, "clinic", _interact.bind(spot))
	for x: float in [-5.5, -4.2]:
		_chair(o + Vector3(x, 0, 1.5), 1.0, Color(0.3, 0.5, 0.7))


func _job_spots(room_key: String, from: Vector3, from_text: String, to: Vector3, to_text: String) -> void:
	_spot(room_key, "parcel_in", from_text, from_text, from)
	_spot(room_key, "parcel_out", to_text, to_text, to)


func _build_diner() -> void:
	var o := _room("diner", Color(0.42, 0.3, 0.24), Color(0.85, 0.75, 0.62))
	var wood := Color(0.42, 0.27, 0.16)
	# Kitchen pass with plates waiting.
	var kitchen := o + Vector3(-6.5, 0, -4.5)
	_box(Vector3(4.0, 1.1, 1.0), kitchen + Vector3(0, 0.55, 0), _mat(Color(0.75, 0.76, 0.78)))
	_solid(Vector3(4.0, 1.1, 1.0), kitchen + Vector3(0, 0.55, 0))
	for k in 3:
		var plate := Node3D.new()
		plate.position = kitchen + Vector3(-1.1 + k * 1.1, 1.13, 0.1)
		add_child(plate)
		_box(Vector3(0.6, 0.05, 0.6), Vector3.ZERO, _mat(Color(0.96, 0.96, 0.93)), plate)
		_ball(0.17, Vector3(0, 0.14, 0), _mat(Color.from_hsv(0.05 + k * 0.1, 0.7, 0.8)), plate, Vector3(1.2, 0.7, 1))
		_handle(plate, "diner", _take_parcel)
	var cook := _make_person(Color(0.97, 0.97, 0.97), Color(0.2, 0.2, 0.22))
	cook.root.position = kitchen + Vector3(0, 0, -1.2)
	add_child(cook.root)
	_tag("מטבח", kitchen + Vector3(0, 2.7, 0))
	# The table that is waiting for its food.
	var table := o + Vector3(6.0, 0, -2.0)
	_table(table, Vector2(2.4, 1.4), wood)
	var top := _box(Vector3(2.0, 0.04, 1.0), table + Vector3(0, 1.02, 0), _mat(Color(0.9, 0.3, 0.3)))
	_handle(top, "diner", _drop_parcel)
	for sx: float in [-0.65, 0.65]:
		var guest := _make_person(Color.from_hsv(rng.randf(), 0.5, 0.8), Color(0.25, 0.25, 0.3))
		guest.root.position = table + Vector3(sx, 0, -1.3)
		add_child(guest.root)
	_tag("שולחן מחכה", table + Vector3(0, 2.7, -1.0))
	_job_spots("diner", kitchen + Vector3(0, 0, 1.5), "לקחת מנה", table + Vector3(0, 0, 1.5), "להגיש לשולחן")
	for x: float in [-2.5, 1.5]:
		var t := o + Vector3(x, 0, 1.2)
		_table(t, Vector2(1.4, 1.4), wood.lightened(0.15))
		_chair(t + Vector3(0, 0, 1.15), 1.0, wood)
		_chair(t + Vector3(0, 0, -1.15), -1.0, wood)


func _build_site() -> void:
	var o := _room("build", Color(0.6, 0.52, 0.4), Color(0.62, 0.62, 0.6))
	var brick := _mat(Color(0.7, 0.3, 0.2))
	# Pile of bricks.
	var pile := o + Vector3(-7, 0, -3)
	for k in 9:
		var b := _box(Vector3(0.9, 0.4, 0.5), pile + Vector3(-0.95 + (k % 3) * 0.95, 0.2 + (k / 3) * 0.42, 0), brick)
		if k >= 6:
			_handle(b, "build", _take_parcel)
	_solid(Vector3(3.0, 1.3, 0.6), pile + Vector3(0, 0.65, 0))
	_tag("לבנים", pile + Vector3(0, 2.2, 0))
	# The wall being built.
	var wall := o + Vector3(6.5, 0, -5.5)
	var last: MeshInstance3D
	for k in 12:
		last = _box(Vector3(0.95, 0.42, 0.5), wall + Vector3(-1.5 + (k % 4) * 1.0 + (0.5 if (k / 4) % 2 == 1 else 0.0), 0.21 + (k / 4) * 0.44, 0), brick)
		_handle(last, "build", _drop_parcel)
	_solid(Vector3(4.6, 1.4, 0.6), wall + Vector3(0.2, 0.7, 0))
	_tag("הקיר", wall + Vector3(0, 2.4, 0))
	_job_spots("build", pile + Vector3(0, 0, 1.4), "לקחת לבנים", wall + Vector3(0, 0, 1.4), "להניח בקיר")
	# Scaffolding, a cement mixer and the foreman.
	var steel := _mat(Color(0.75, 0.6, 0.15))
	for sx: float in [-1.5, 1.5]:
		for sz: float in [-0.6, 0.6]:
			_box(Vector3(0.12, 4.0, 0.12), o + Vector3(sx, 2.0, -6.0 + sz), steel)
	_box(Vector3(3.4, 0.12, 1.5), o + Vector3(0, 2.2, -6.0), _mat(Color(0.55, 0.4, 0.25)))
	_box(Vector3(1.2, 1.2, 1.2), o + Vector3(-2.5, 0.9, 2.0), _mat(Color(0.85, 0.5, 0.1)))
	_solid(Vector3(1.2, 1.5, 1.2), o + Vector3(-2.5, 0.75, 2.0))
	var foreman := _make_person(Color(0.95, 0.75, 0.1), Color(0.25, 0.3, 0.45))
	foreman.root.position = o + Vector3(2.5, 0, -2.5)
	add_child(foreman.root)
	_tag("מנהל העבודה", foreman.root.position + Vector3(0, 2.6, 0))


# -------------------------------------------- neighbours, music and edges ----

func _add_townsperson(n: Person) -> void:
	n.name = NAMES[npcs.size() % NAMES.size()]
	n.bubble = Label3D.new()
	n.bubble.font = font
	n.bubble.font_size = 44
	n.bubble.pixel_size = 0.01
	n.bubble.outline_size = 14
	n.bubble.outline_modulate = Color(0.05, 0.08, 0.15)
	n.bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.bubble.no_depth_test = true
	n.bubble.position = Vector3(0, 2.75, 0)
	n.bubble.visible = false
	n.root.add_child(n.bubble)
	add_child(n.root)
	npcs.append(n)


func _say(n: Person, text: String, seconds: float) -> void:
	n.bubble.text = _h(text.strip_edges().replace(" !", "!"))
	n.bubble.visible = true
	n.bubble_t = seconds


func _friends() -> int:
	var count := 0
	for n in npcs:
		if n.level >= 3:
			count += 1
	return count


func _known_levels() -> Array:
	var out: Array = []
	for n in npcs:
		out.append(n.level)
	return out


func _talk(n: Person) -> void:
	n.pause = 4.0
	n.hello_cool = 40.0
	var to_me := player.position - n.root.position
	n.root.rotation.y = atan2(to_me.x, to_me.z)
	me.root.rotation.y = atan2(-to_me.x, -to_me.z)
	_play("pick")
	if n.talked_day == day:
		_say(n, "כבר דיברנו היום. נתראה מחר!", 3.5)
		return
	n.talked_day = day
	n.level += 1
	if n.level == 1:
		_say(n, "נעים מאוד, אני %s!" % n.name, 4.0)
		_toast("הכרת את %s. דברו שוב בימים הבאים כדי להתיידד." % n.name)
	elif n.level == 3:
		_say(n, "אנחנו חברים עכשיו!", 4.0)
		_toast("%s ואתה חברים עכשיו! חברים באים להופעות שלך. (חברים: %d)" % [n.name, _friends()])
		_play("pay")
	else:
		_say(n, CHATS[rng.randi_range(0, CHATS.size() - 1)], 4.5)


func _buy_guitar() -> void:
	if _shabbat_block():
		return
	if has_guitar:
		_toast("כבר יש לך גיטרה.")
		return
	if money < GUITAR_PRICE:
		_toast("אין מספיק כסף (חסרים ₪%d)." % (GUITAR_PRICE - money))
		_play("no")
		return
	money -= GUITAR_PRICE
	has_guitar = true
	_play("pay")
	_toast("קנית גיטרה! אפשר לנגן בפינת הנגינה ברחוב, ולהופיע באולם בערב.")
	_refresh_panel()


func _lesson() -> void:
	if _shabbat_block():
		return
	if money < LESSON_PRICE:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	money -= LESSON_PRICE
	_time_skip("לומדים לנגן...", func() -> void:
		_skip(1.0, "awake")
		skill = mini(skill + 1, 15)
		_toast("השתפרת! רמת הנגינה שלך: %d." % skill))


func _busk() -> void:
	if _shabbat_block():
		return
	if not has_guitar:
		_toast("כדי לנגן צריך גיטרה. קונים אותה בחנות המוזיקה.")
		return
	if energy < 12.0:
		_toast("אתה עייף מדי לנגן.")
		return
	_time_skip("מנגנים ברחוב...", func() -> void:
		_skip(1.0, "awake")
		energy = maxf(energy - 5.0, 0.0)
		var coins := 10 + skill * 3 + rng.randi_range(0, 18)
		money += coins
		if rng.randf() < 0.35:
			skill = mini(skill + 1, 15)
		_play("pay")
		_toast("ניגנת שעה, ועוברים ושבים נתנו לך ₪%d." % coins))


func _perform() -> void:
	if _shabbat_block():
		return
	if not has_guitar:
		_toast("כדי להופיע צריך גיטרה. קונים אותה בחנות המוזיקה.")
		return
	if last_show_day == day:
		_toast("כבר הופעת היום. ההופעה הבאה מחר בערב.")
		return
	if energy < 20.0:
		_toast("אתה עייף מדי להופיע.")
		return
	var crowd := 2 + _friends() * 2
	_time_skip("מופיעים על הבמה...", func() -> void:
		last_show_day = day
		_skip(2.0, "awake")
		energy = maxf(energy - 12.0, 0.0)
		var pay := 60 + skill * 12 + _friends() * 30 + rng.randi_range(0, 40)
		money += pay
		skill = mini(skill + 1, 15)
		_play("pay")
		_save()
		_toast("איזו הופעה! היו %d אנשים בקהל, והרווחת ₪%d." % [mini(crowd, audience.size()), pay]))


func _build_music_shop() -> void:
	var o := _room("music", Color(0.4, 0.32, 0.26), Color(0.72, 0.62, 0.74))
	_box(Vector3(4.6, 1.1, 1.0), o + Vector3(0, 0.55, -3.2), _mat(Color(0.3, 0.2, 0.3)))
	_solid(Vector3(4.6, 1.1, 1.0), o + Vector3(0, 0.55, -3.2))
	var seller := _make_person(Color(0.55, 0.3, 0.6), Color(0.2, 0.2, 0.25))
	seller.root.position = o + Vector3(0, 0, -4.4)
	add_child(seller.root)
	var guitar := Node3D.new()
	guitar.position = o + Vector3(-3.6, 1.0, -1.0)
	add_child(guitar)
	_box(Vector3(0.7, 0.85, 0.16), Vector3(0, -0.2, 0), _mat(Color(0.75, 0.45, 0.18)), guitar)
	_ball(0.14, Vector3(0, -0.15, 0.08), _mat(Color(0.12, 0.08, 0.05)), guitar, Vector3(1, 1, 0.3))
	_box(Vector3(0.14, 1.0, 0.08), Vector3(0, 0.7, 0), _mat(Color(0.3, 0.18, 0.1)), guitar)
	_box(Vector3(0.9, 0.5, 0.5), o + Vector3(-3.6, 0.25, -1.0), _mat(Color(0.2, 0.2, 0.22)))
	_tag("גיטרה ₪%d" % GUITAR_PRICE, guitar.position + Vector3(0, 1.7, 0))
	_handle(guitar, "music", _buy_guitar)
	# A keyboard and a drum kit, just for show.
	_box(Vector3(2.2, 0.15, 0.6), o + Vector3(3.8, 1.0, -1.2), _mat(Color(0.1, 0.1, 0.12)))
	_box(Vector3(2.1, 0.03, 0.4), o + Vector3(3.8, 1.09, -1.15), _mat(Color(0.95, 0.95, 0.95)))
	for sx: float in [-0.9, 0.9]:
		_box(Vector3(0.08, 0.95, 0.08), o + Vector3(3.8 + sx, 0.47, -1.2), _mat(Color(0.3, 0.3, 0.32)))
	for k in 3:
		var drum := CylinderMesh.new()
		drum.top_radius = 0.4 - k * 0.07
		drum.bottom_radius = drum.top_radius
		drum.height = 0.5
		var d := MeshInstance3D.new()
		d.mesh = drum
		d.material_override = _mat(Color(0.75, 0.1, 0.15))
		d.position = o + Vector3(3.0 + k * 0.85, 0.5 + k * 0.2, 2.2)
		add_child(d)
	_spot("music", "music_counter", "חנות מוזיקה", "לדבר עם המוכר", o + Vector3(0, 0, -1.8))


func _build_hall() -> void:
	var o := _room("hall", Color(0.3, 0.2, 0.2), Color(0.42, 0.14, 0.16))
	# Stage with curtains, a microphone and speakers.
	_box(Vector3(16, 0.08, 4.6), o + Vector3(0, 0.04, -5.6), _mat(Color(0.5, 0.36, 0.22)))
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(3.0, 4.4, 0.3), o + Vector3(sx * 8.5, 2.2, -8.2), _mat(Color(0.65, 0.08, 0.1)))
		_box(Vector3(1.0, 1.6, 0.9), o + Vector3(sx * 6.6, 0.8, -7.2), _mat(Color(0.1, 0.1, 0.12)))
		_solid(Vector3(1.0, 1.6, 0.9), o + Vector3(sx * 6.6, 0.8, -7.2))
	_box(Vector3(0.06, 1.5, 0.06), o + Vector3(0, 0.75, -4.4), _mat(Color(0.2, 0.2, 0.22)))
	_ball(0.1, o + Vector3(0, 1.55, -4.4), _mat(Color(0.3, 0.3, 0.32)), self)
	for sx: float in [-4.0, 0.0, 4.0]:
		_box(Vector3(0.5, 0.3, 0.5), o + Vector3(sx, 4.2, -5.0), lamp_mat)
	_tag("הבמה", o + Vector3(0, 3.2, -6.5), 72)
	_spot("hall", "stage", "הבמה", "לעלות לבמה ולהופיע", o + Vector3(0, 0, -5.4))
	# Rows of seats; your friends fill them.
	for row in 2:
		for col in 6:
			var seat := o + Vector3(-6.25 + col * 2.5, 0, 0.5 + row * 2.4)
			_chair(seat, 1.0, Color(0.5, 0.1, 0.12))
			var fan := _make_person(Color.from_hsv(rng.randf(), 0.5, 0.85), Color.from_hsv(rng.randf(), 0.3, 0.4))
			fan.root.position = seat + Vector3(0, 0, -0.75)
			fan.root.rotation.y = PI
			fan.root.visible = false
			add_child(fan.root)
			audience.append(fan)


func _fence(from: Vector3, to: Vector3) -> void:
	var wood := _mat(Color(0.45, 0.32, 0.2))
	var span := to - from
	var count := int(span.length() / 4.0)
	for k in count + 1:
		_box(Vector3(0.25, 1.6, 0.25), from + span * (float(k) / count) + Vector3(0, 0.8, 0), wood)
	var mid := (from + to) * 0.5
	var size := Vector3(absf(span.x) + 0.2, 0.14, 0.12) if absf(span.x) > absf(span.z) else Vector3(0.12, 0.14, absf(span.z) + 0.2)
	for y: float in [0.6, 1.2]:
		_box(size, mid + Vector3(0, y, 0), wood)


## The edge of town: a fence all round, and a gate with a raised boom where the road leaves.
func _build_edges() -> void:
	for x: float in [WEST - 1.6, EAST + 1.6]:
		_fence(Vector3(x, 0, -6.5), Vector3(x, 0, -2.2))
		_fence(Vector3(x, 0, 5.2), Vector3(x, 0, FOREST_END + 1.6))
		var steel := _mat(Color(0.3, 0.32, 0.36))
		for z: float in [-1.9, 4.9]:
			_box(Vector3(0.4, 4.6, 0.4), Vector3(x, 2.3, z), steel)
		_box(Vector3(0.5, 0.5, 7.4), Vector3(x, 4.6, 1.5), steel)
		_sign("יציאה מהעיר", Vector3(x, 5.5, 1.5), 72)
		var boom := _box(Vector3(0.16, 0.16, 5.6), Vector3(x, 2.6, 0.2), _mat(Color(0.9, 0.15, 0.12)))
		boom.rotation.x = -0.6
		_box(Vector3(1.4, 2.4, 1.4), Vector3(x, 1.2, -4.0), _mat(Color(0.85, 0.82, 0.7)))     # guard booth
		_box(Vector3(1.6, 0.2, 1.6), Vector3(x, 2.5, -4.0), steel)
	_fence(Vector3(WEST - 1.6, 0, FOREST_END + 1.6), Vector3(EAST + 1.6, 0, FOREST_END + 1.6))


func _build_neighbourhood() -> void:
	# Houses at the east end, and a neighbour standing outside each home in town.
	var palette: Array[Color] = [Color(0.82, 0.74, 0.6), Color(0.68, 0.76, 0.8), Color(0.8, 0.66, 0.62)]
	var doorsteps: Array[Vector3] = []
	for k in 3:
		var hp := Vector3(90 + k * 11.0, 0, -10)
		_box(Vector3(8, 3.8, 7), hp + Vector3(0, 1.9, 0), _mat(palette[k]))
		_box(Vector3(8.6, 0.4, 7.6), hp + Vector3(0, 4.0, 0), _mat(Color(0.55, 0.22, 0.18)))
		_box(Vector3(1.3, 2.3, 0.1), hp + Vector3(0, 1.15, 3.53), _mat(Color(0.3, 0.2, 0.12)))
		for sx: float in [-2.5, 2.5]:
			_box(Vector3(1.5, 1.2, 0.1), hp + Vector3(sx, 2.1, 3.53), window_mat)
		_solid(Vector3(8, 3.8, 7), hp + Vector3(0, 1.9, 0))
		doorsteps.append(hp + Vector3(1.8, 0, 5.0))
	for k in 4:
		doorsteps.append(Vector3(52 + k * 9.5 + 1.6, 0, 9.6))
	for k in doorsteps.size():
		var n := _make_person(Color.from_hsv(rng.randf(), 0.5, 0.88), Color.from_hsv(rng.randf(), 0.3, 0.42))
		n.speed = 0.0
		n.root.position = doorsteps[k]
		n.root.rotation.y = 0.0 if k < 3 else PI
		_add_townsperson(n)
	# A music corner on the pavement for playing in the street.
	var corner := Vector3(22, 0, 5.6)
	_box(Vector3(2.2, 0.05, 1.6), corner + Vector3(0, 0.04, 0), _mat(Color(0.6, 0.3, 0.6)))
	_sign("פינת נגינה", corner + Vector3(0, 2.4, 0.9), 56)
	_box(Vector3(0.12, 2.0, 0.12), corner + Vector3(0, 1.0, 0.9), _mat(Color(0.2, 0.2, 0.22)))
	var busk := Place.new()
	busk.key = "busk"
	busk.title = "פינת נגינה"
	busk.prompt = "לנגן ברחוב"
	busk.door = corner
	places.append(busk)


# ------------------------------------------------ the week, and Shabbat ----

func _weekday() -> int:
	return (day - 1) % 7              # 0 = Sunday ... 5 = Friday, 6 = Shabbat


## Shabbat runs from Friday evening until Saturday night.
func _is_shabbat() -> bool:
	var wd := _weekday()
	return (wd == 5 and clock >= 18.0) or (wd == 6 and clock < 19.0)


func _shabbat_block() -> bool:
	if not _is_shabbat():
		return false
	_toast("שבת היום. את זה עושים אחרי צאת השבת. שבת שלום!")
	return true


func _watch_week() -> void:
	var now := _is_shabbat()
	if now and not was_shabbat:
		car_speed = 0.0
		_toast("שבת נכנסה. החנויות סגורות, לא עובדים ולא נוסעים. שבת שלום!")
		_play("level" if sfx.has("level") else "pay")
	elif was_shabbat and not now:
		_toast("השבת יצאה. שבוע טוב!")
		_play("pay")
	was_shabbat = now
	if _weekday() == 5 and clock >= 12.0 and clock < 18.0 and friday_note_day != day:
		friday_note_day = day
		_toast("היום יום שישי. שבת נכנסת ב-18:00: קנו חלה ומיץ ענבים, והדליקו נרות בבית.")
	_watch_school()
	if bladder >= 85.0 and not bladder_warned:
		bladder_warned = true
		_toast("צריך ללכת לשירותים! יש בבית, ויש שירותים ציבוריים בפארק.")
	elif bladder < 50.0:
		bladder_warned = false


func _light_candles() -> void:
	if _is_shabbat():
		_toast("לא מדליקים אש בשבת.")
	elif _weekday() != 5:
		_toast("נרות שבת מדליקים ביום שישי, לפני כניסת השבת.")
	elif candles_day == day:
		_toast("הנרות כבר דולקים.")
	else:
		candles_day = day
		_play("pay")
		_toast("הדלקת נרות שבת. שבת שלום!")
		_update_hud()


func _table_action() -> void:
	if not _is_shabbat():
		for p in places:
			if p.key == "fridge":
				_open_panel(p)
		return
	var this_shabbat := day if _weekday() == 6 else day + 1
	var meal := this_shabbat * 2 + (1 if _weekday() == 6 else 0)   # Friday night, then Shabbat day
	if kiddush_day == meal:
		_toast("כבר אכלת את הסעודה הזאת. שבת שלום!")
		return
	if not fridge.has(CHALLAH) or not fridge.has(GRAPE_JUICE):
		_toast("לקידוש ולסעודת שבת צריך חלה ומיץ ענבים. קונים אותם בסופר לפני שבת.")
		return
	kiddush_day = meal
	fridge.remove_at(fridge.find(CHALLAH))
	fridge.remove_at(fridge.find(GRAPE_JUICE))
	_time_skip("קידוש וסעודת שבת...", func() -> void:
		_skip(1.0, "awake")
		hunger = minf(hunger + 60.0, 100.0)
		health = minf(health + 8.0, 100.0)
		family_joy = minf(family_joy + 15.0, 100.0)
		for kin in family:
			_say(kin, "שבת שלום!", 5.0)
		_toast("עשית קידוש ואכלת סעודת שבת עם המשפחה. שבת שלום!"))


func _pray() -> void:
	# Three prayers a day: morning, afternoon and evening.
	var part := 0 if clock < 12.0 else (1 if clock < 17.0 else 2)
	var names: Array[String] = ["שחרית", "מנחה", "ערבית"]
	if prayed_slot == day * 3 + part:
		_toast("כבר התפללת %s היום." % names[part])
		return
	prayed_slot = day * 3 + part
	prayed_day = day
	var shabbat := _is_shabbat()
	_time_skip("תפילת %s..." % names[part], func() -> void:
		_skip(1.0 if shabbat else 0.4, "awake")
		health = minf(health + (6.0 if shabbat else 2.0), 100.0)
		_toast(("התפללת %s בבית הכנסת. שבת שלום!" if shabbat else "התפללת %s בבית הכנסת.") % names[part]))


func _use_toilet() -> void:
	if bladder < 15.0:
		_toast("אתה לא צריך לשירותים עכשיו.")
		return
	bladder = 0.0
	_skip(0.15, "awake")
	_play("door")
	_toast("הקלה! עכשיו הרבה יותר נוח.")
	_update_hud()


func _shower() -> void:
	_time_skip("מתקלחים...", func() -> void:
		_skip(0.3, "awake")
		energy = minf(energy + 6.0, 100.0)
		_toast("התקלחת. מרגיש רענן."))


func _build_shul() -> void:
	var o := _room("shul", Color(0.55, 0.45, 0.35), Color(0.92, 0.9, 0.82))
	var wood := Color(0.42, 0.28, 0.16)
	# The ark with its curtain, on a step at the front.
	_box(Vector3(5.0, 0.2, 1.6), o + Vector3(0, 0.1, -6.6), _mat(wood.lightened(0.1)))
	_box(Vector3(2.4, 3.2, 0.7), o + Vector3(0, 1.8, -7.1), _mat(wood))
	_box(Vector3(1.8, 2.4, 0.08), o + Vector3(0, 1.7, -6.72), _mat(Color(0.2, 0.25, 0.6)))
	_box(Vector3(1.2, 0.12, 0.09), o + Vector3(0, 2.3, -6.68), _mat(Color(0.9, 0.75, 0.25)))
	_box(Vector3(0.3, 0.3, 0.3), o + Vector3(0, 3.7, -7.0), lamp_mat)                             # eternal light
	_solid(Vector3(2.4, 3.2, 0.9), o + Vector3(0, 1.6, -7.0))
	# The reading table in the middle.
	_table(o + Vector3(0, 0, -2.4), Vector2(2.2, 1.4), wood)
	_box(Vector3(2.3, 0.04, 1.5), o + Vector3(0, 1.02, -2.4), _mat(Color(0.2, 0.25, 0.6)))
	_box(Vector3(0.9, 0.08, 0.6), o + Vector3(0, 1.08, -2.4), _mat(Color(0.95, 0.93, 0.85)))
	_tag("בימה", o + Vector3(0, 2.3, -2.4))
	_spot("shul", "pray", "בית כנסת", "להתפלל", o + Vector3(0, 0, -0.8))
	# Benches, a bookcase and a few people at prayer.
	for side: float in [-1.0, 1.0]:
		for row in 3:
			var b := o + Vector3(side * 5.4, 0, -3.5 + row * 2.3)
			_box(Vector3(3.6, 0.12, 0.6), b + Vector3(0, 0.55, 0), _mat(wood.lightened(0.15)))
			_box(Vector3(3.6, 0.7, 0.1), b + Vector3(0, 0.9, 0.3), _mat(wood.lightened(0.15)))
			_solid(Vector3(3.6, 1.0, 0.7), b + Vector3(0, 0.5, 0))
	_box(Vector3(0.6, 2.6, 2.4), o + Vector3(8.4, 1.3, 3.0), _mat(wood))
	for k in 12:
		_box(Vector3(0.1, 0.5, 0.16), o + Vector3(8.07, 0.6 + (k / 4) * 0.8, 2.2 + (k % 4) * 0.5), _mat(Color(0.25, 0.2, 0.15).lightened(k * 0.03)))
	for side: float in [-1.0, 1.0]:
		var man := _make_person(Color(0.95, 0.95, 0.95), Color(0.12, 0.12, 0.15))
		man.root.position = o + Vector3(side * 5.4, 0, -4.3)
		man.root.rotation.y = PI
		_ball(0.12, Vector3(0, 1.93, -0.02), _mat(Color(0.1, 0.1, 0.3)), man.root, Vector3(1.0, 0.35, 1.0))   # kippah
		add_child(man.root)


func _build_restroom() -> void:
	# Public toilets in the park.
	var at := Vector3(-14, 0, 17)
	_box(Vector3(3.2, 2.8, 2.6), at + Vector3(0, 1.4, 0), _mat(Color(0.8, 0.82, 0.78)))
	_box(Vector3(3.6, 0.25, 3.0), at + Vector3(0, 2.9, 0), _mat(Color(0.3, 0.45, 0.55)))
	_box(Vector3(1.0, 2.1, 0.1), at + Vector3(0, 1.05, -1.33), _mat(Color(0.25, 0.4, 0.5)))
	_solid(Vector3(3.2, 2.8, 2.6), at + Vector3(0, 1.4, 0))
	_sign("שירותים", at + Vector3(0, 3.6, -1.2), 64)
	_box(Vector3(1.8, 0.04, 1.2), at + Vector3(0, 0.03, -2.2), _mat(Color(0.95, 0.75, 0.2)))
	var loo := Place.new()
	loo.key = "toilet"
	loo.title = "שירותים ציבוריים"
	loo.prompt = "להיכנס לשירותים"
	loo.door = at + Vector3(0, 0, -2.2)
	places.append(loo)


# --------------------------------------------------------------- family ----

func _kippah(root: Node3D, color: Color) -> void:
	_ball(0.13, Vector3(0, 1.93, -0.03), _mat(color), root, Vector3(1.0, 0.32, 1.0))


func _bubble_for(n: Person, height: float) -> void:
	n.bubble = Label3D.new()
	n.bubble.font = font
	n.bubble.font_size = 44
	n.bubble.pixel_size = 0.01
	n.bubble.outline_size = 14
	n.bubble.outline_modulate = Color(0.05, 0.08, 0.15)
	n.bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.bubble.no_depth_test = true
	n.bubble.position = Vector3(0, height, 0)
	n.bubble.visible = false
	n.root.add_child(n.bubble)


func _build_family(o: Vector3) -> void:
	# Mother: hair covered, long sleeves and a long skirt. The whole family is fair-skinned.
	var mother := _make_person(Color(0.55, 0.3, 0.55), Color(0.3, 0.2, 0.35), null, 0)
	mother.name = "רחל"
	# A headscarf: cloth over the hair, a band at the forehead and a tail tied at the back.
	var cloth := _mat(Color(0.2, 0.3, 0.5))
	_ball(0.215, Vector3(0, 1.82, -0.04), cloth, mother.root, Vector3(1.03, 0.9, 1.06))
	_box(Vector3(0.36, 0.045, 0.3), Vector3(0, 1.865, 0.05), _mat(Color(0.92, 0.9, 0.82)), mother.root)
	_cap(0.07, 0.3, Vector3(0, 1.66, -0.2), cloth, mother.root, Vector3(1.4, 1.0, 0.5))
	_modest(mother, Color(0.55, 0.3, 0.55), Color(0.3, 0.2, 0.35))
	mother.root.scale = Vector3(0.97, 0.97, 0.97)
	mother.speed = 1.3
	# Son with a kippah, and daughter in her school uniform with its badge.
	var son := _make_person(Color(0.95, 0.95, 0.95), Color(0.15, 0.2, 0.4), null, 0, 1)
	son.name = "דוד"
	_kippah(son.root, Color(0.15, 0.4, 0.75))
	son.root.scale = Vector3(0.68, 0.68, 0.68)
	son.speed = 2.2
	var daughter := _make_person(Color(0.6, 0.78, 0.95), Color(0.12, 0.16, 0.38), null, 0, 3)
	daughter.name = "שרה"
	_modest(daughter, Color(0.6, 0.78, 0.95), Color(0.12, 0.16, 0.38))
	_box(Vector3(0.09, 0.1, 0.02), Vector3(0.11, 1.36, 0.185), _mat(Color(0.95, 0.8, 0.15)), daughter.root)   # school badge
	_box(Vector3(0.05, 0.05, 0.022), Vector3(0.11, 1.36, 0.186), _mat(Color(0.12, 0.16, 0.38)), daughter.root)
	daughter.root.scale = Vector3(0.58, 0.58, 0.58)
	daughter.speed = 2.0
	# Two younger children.
	var boy := _make_person(Color(0.3, 0.7, 0.4), Color(0.2, 0.22, 0.3), null, 0, 0)
	boy.name = "יעקב"
	_kippah(boy.root, Color(0.75, 0.2, 0.2))
	boy.root.scale = Vector3(0.5, 0.5, 0.5)
	boy.speed = 2.3
	var girl := _make_person(Color(0.98, 0.85, 0.5), Color(0.55, 0.2, 0.3), null, 0, 2)
	girl.name = "רבקה"
	_modest(girl, Color(0.98, 0.85, 0.5), Color(0.55, 0.2, 0.3))
	girl.root.scale = Vector3(0.44, 0.44, 0.44)
	girl.speed = 1.9
	var spots: Array[Vector3] = [Vector3(1.5, 0, -5.0), Vector3(2.5, 0, 4.0), Vector3(-1.5, 0, 4.5), Vector3(4.0, 0, 5.5), Vector3(-6.5, 0, 5.0)]
	var walkers: Array[Person] = [mother, son, daughter, boy, girl]
	# A bedroom for each child, two on each side of the home.
	var room_colors: Array[Color] = [Color(0.3, 0.5, 0.85), Color(0.9, 0.55, 0.7), Color(0.35, 0.7, 0.45), Color(0.95, 0.8, 0.4)]
	var inner := _mat(Color(0.86, 0.8, 0.68))
	for wx: float in [-15.6, -11.6, 11.6, 15.6]:
		_box(Vector3(0.25, 3.2, 4.6), o + Vector3(wx, 1.6, -6.2), inner)
		_solid(Vector3(0.25, 3.2, 4.6), o + Vector3(wx, 1.6, -6.2))
	for k in 4:
		var rc := o + Vector3(KID_ROOMS[k], 0, -6.2)
		_box(Vector3(3.5, 0.03, 4.2), rc + Vector3(0, 0.02, 0), _mat(room_colors[k].lightened(0.45)))
		_box(Vector3(1.4, 0.45, 2.8), rc + Vector3(-0.8, 0.23, -0.9), _mat(Color(0.45, 0.3, 0.18)))
		_box(Vector3(1.3, 0.2, 2.6), rc + Vector3(-0.8, 0.55, -0.9), _mat(Color(0.95, 0.95, 0.92)))
		_box(Vector3(1.32, 0.22, 1.6), rc + Vector3(-0.8, 0.57, -0.4), _mat(room_colors[k]))
		_box(Vector3(0.9, 0.16, 0.5), rc + Vector3(-0.8, 0.72, -1.9), _mat(Color(1, 1, 1)))
		_solid(Vector3(1.4, 0.8, 2.8), rc + Vector3(-0.8, 0.4, -0.9))
		_box(Vector3(0.8, 0.5, 0.6), rc + Vector3(1.1, 0.25, -1.9), _mat(room_colors[k].darkened(0.2)))     # toy box
		_ball(0.2, rc + Vector3(1.1, 0.2, 0.2), _mat(Color.from_hsv(k * 0.23, 0.8, 0.95)), self)           # ball
		_tag("החדר של %s" % walkers[k + 1].name, rc + Vector3(0, 2.6, -1.8), 40)
	for k in 5:
		walkers[k].root.position = o + spots[k]
		walkers[k].target = walkers[k].root.position
		add_child(walkers[k].root)
		_bubble_for(walkers[k], 2.75)
		_handle(walkers[k].root, "home", _family_talk.bind(walkers[k]))
		family.append(walkers[k])
	_spot("home", "kids_out", "לצאת עם הילדים", "לצאת עם הילדים", o + Vector3(3.0, 0, 6.6))
	_box(Vector3(0.5, 0.5, 0.25), o + Vector3(3.6, 0.25, 7.6), _mat(Color(0.2, 0.45, 0.8)))       # schoolbags by the door
	_box(Vector3(0.45, 0.45, 0.25), o + Vector3(4.2, 0.23, 7.6), _mat(Color(0.85, 0.4, 0.6)))
	# The baby, in a cot in the bedroom.
	var cot := o + Vector3(-6.0, 0, -4.4)
	var rail := _mat(Color(0.95, 0.93, 0.85))
	_box(Vector3(1.3, 0.1, 0.8), cot + Vector3(0, 0.5, 0), rail)
	for sx: float in [-0.6, 0.6]:
		_box(Vector3(0.08, 0.9, 0.8), cot + Vector3(sx, 0.55, 0), rail)
	for sz: float in [-0.36, 0.36]:
		_box(Vector3(1.3, 0.5, 0.06), cot + Vector3(0, 0.8, sz), rail)
	_solid(Vector3(1.3, 1.0, 0.8), cot + Vector3(0, 0.5, 0))
	var baby := Person.new()
	baby.name = "התינוק יוסי"
	baby.root = Node3D.new()
	baby.root.position = cot + Vector3(0, 0.6, 0)
	add_child(baby.root)
	_cap(0.14, 0.5, Vector3(0.1, 0.12, 0), _mat(Color(0.65, 0.85, 0.95)), baby.root, Vector3(1, 1, 1))
	baby.root.get_child(0).rotation.z = PI * 0.5
	_ball(0.13, Vector3(-0.3, 0.14, 0), _mat(Color(0.96, 0.8, 0.66)), baby.root)
	_bubble_for(baby, 1.6)
	_handle(baby.root, "home", _family_talk.bind(baby))
	family.append(baby)
	# Mezuzah by the way out.
	_box(Vector3(0.06, 0.28, 0.06), o + Vector3(1.5, 1.6, ROOMS["home"]["half"].y + 0.2), _mat(Color(0.75, 0.7, 0.5)))


func _update_family(delta: float) -> void:
	near_kin = null
	if room != "home":
		return
	var o: Vector3 = ROOMS["home"]["origin"]
	var stops: Array[Vector3] = [Vector3(-1, 0, 3.5), Vector3(2.5, 0, 4.5), Vector3(3, 0, -3.5), Vector3(-7, 0, -1.5), Vector3(0, 0, -0.5),
		Vector3(-8, 0, 5.5), Vector3(1.5, 0, -5.5), Vector3(9.5, 0, 5.5), Vector3(-1.5, 0, 6.0), Vector3(3.5, 0, 1.0)]
	var closest := 2.3
	for kin in family:
		if kin.bubble_t > 0.0:
			kin.bubble_t -= delta
			if kin.bubble_t <= 0.0:
				kin.bubble.visible = false
		var d := kin.root.position.distance_to(player.position)
		if d < closest:
			closest = d
			near_kin = kin
		if kin.limbs.is_empty():
			continue                     # the baby stays in the cot
		if kids != 0 and family.find(kin) in KIDS:
			continue                     # out at school
		kin.pause = maxf(kin.pause - delta, 0.0)
		var to_target := kin.target - kin.root.position
		to_target.y = 0.0
		if kin.pause > 0.0 or to_target.length() < 0.4:
			_animate(kin, false, delta)
			kin.wait -= delta
			if kin.wait <= 0.0 and kin.pause <= 0.0:
				kin.wait = rng.randf_range(2.0, 7.0)
				kin.target = o + stops[rng.randi_range(0, stops.size() - 1)]
				var place := family.find(kin)
				if place in KIDS and (clock >= 20.5 or clock < 6.5):
					kin.target = o + Vector3(KID_ROOMS[place - 1] + 0.6, 0, -5.4)        # bedtime: off to their own room
			continue
		var step := to_target.normalized() * kin.speed
		kin.root.position += step * delta
		kin.root.rotation.y = lerp_angle(kin.root.rotation.y, atan2(step.x, step.z), 8.0 * delta)
		_animate(kin, true, delta)


func _family_talk(kin: Person) -> void:
	kin.pause = 4.0
	var to_me := player.position - kin.root.position
	if not kin.limbs.is_empty():
		kin.root.rotation.y = atan2(to_me.x, to_me.z)
	me.root.rotation.y = atan2(-to_me.x, -to_me.z)
	_play("pick")
	var lines: Array[String]
	match family.find(kin):
		0:
			lines = ["שלום! איך היה היום שלך?", "הילדים חיכו לך.", "תודה שאתה דואג לנו.", "אל תשכח לקנות חלה לשבת."]
		1, 3:
			lines = ["אבא! בוא נשחק!", "אבא, למדתי היום בחומש.", "אפשר לבוא איתך לבית הכנסת?", "אבא, ראית את החדר שלי?"]
		2, 4:
			lines = ["אבא! ציירתי לך ציור.", "אבא, תקרא לי סיפור?", "אני אוהבת אותך, אבא.", "אבא, סידרתי את המיטה שלי!"]
		_:
			lines = ["גו גו!", "(התינוק מחייך אליך)", "(התינוק צוחק)"]
	_say(kin, "שבת שלום, אבא!" if (_is_shabbat() and family.find(kin) in KIDS) else lines[rng.randi_range(0, lines.size() - 1)], 4.5)
	if kin.talked_day != day:
		kin.talked_day = day
		family_joy = minf(family_joy + 6.0, 100.0)
		_update_hud()


## Once a day the family eats from the fridge, and misses you a little.
func _family_day() -> void:
	kids = 0
	_place_kids()
	family_joy = maxf(family_joy - 6.0, 0.0)
	var eaten := 0
	while eaten < 4 and not fridge.is_empty():
		var pick := -1
		for k in fridge.size():                  # leave the Shabbat challah and grape juice alone
			if fridge[k] != CHALLAH and fridge[k] != GRAPE_JUICE:
				pick = k
				break
		if pick < 0:
			break
		fridge.remove_at(pick)
		eaten += 1
	if eaten < 4:
		family_joy = maxf(family_joy - 12.0, 0.0)
		_toast("לא היה מספיק אוכל בבית למשפחה. צריך למלא את המקרר.")
	if family_joy < 25.0 and not joy_warned:
		joy_warned = true
		_toast("המשפחה מתגעגעת אליך. בוא הביתה, דבר איתם והבא אוכל.")
	elif family_joy >= 40.0:
		joy_warned = false


# --------------------------------------------------------------- school ----

## Long sleeves and a long skirt over the standard figure.
func _modest(p: Person, shirt: Color, skirt: Color) -> void:
	_cap(0.17, 0.82, Vector3(0, 0.6, 0), _mat(skirt), p.root, Vector3(1.45, 1.0, 1.15))
	for k: int in [2, 3]:
		_cap(0.068, 0.3, Vector3(0, -0.13, 0), _mat(shirt), p.joints[k])


func _is_school_day() -> bool:
	return _weekday() <= 5 and not _is_shabbat()


func _build_school() -> void:
	var at := Vector3(126, 0, -10)
	_box(Vector3(15, 6.4, 8), at + Vector3(0, 3.2, 0), _mat(Color(0.93, 0.85, 0.6)))
	_box(Vector3(15.6, 0.4, 8.6), at + Vector3(0, 6.6, 0), _mat(Color(0.25, 0.4, 0.65)))
	_solid(Vector3(15, 6.4, 8), at + Vector3(0, 3.2, 0))
	_box(Vector3(2.2, 2.6, 0.12), at + Vector3(0, 1.3, 4.05), _mat(Color(0.25, 0.4, 0.65)))
	for f in 2:
		for c in 4:
			_box(Vector3(1.6, 1.3, 0.1), at + Vector3(-5.4 + c * 3.6 + (0.0 if c < 2 else 0.0), 2.1 + f * 3.0, 4.05), window_mat)
	_sign("בית ספר", at + Vector3(0, 7.8, 4.3))
	_box(Vector3(0.9, 0.9, 0.06), at + Vector3(0, 5.2, 4.06), _mat(Color(0.95, 0.8, 0.15)))       # the school emblem
	_box(Vector3(0.5, 0.5, 0.07), at + Vector3(0, 5.2, 4.07), _mat(Color(0.12, 0.16, 0.38)))
	_box(Vector3(3.0, 0.04, 1.6), SCHOOL_DOOR + Vector3(0, 0.03, 0), _mat(Color(0.95, 0.75, 0.2)))
	var gate := Place.new()
	gate.key = "school"
	gate.title = "בית ספר"
	gate.prompt = "בית הספר"
	gate.door = SCHOOL_DOOR
	places.append(gate)
	# The teacher waits by the door.
	teacher = _make_person(Color(0.35, 0.55, 0.5), Color(0.2, 0.2, 0.3))
	teacher.speed = 0.0
	teacher.root.position = SCHOOL_DOOR + Vector3(2.6, 0, -0.4)
	_modest(teacher, Color(0.35, 0.55, 0.5), Color(0.2, 0.2, 0.3))
	_add_townsperson(teacher)
	teacher.name = "המורה מרים"
	# A small yard with a slide and a swing frame.
	var yard := at + Vector3(11.5, 0, 4.5)
	_box(Vector3(5.0, 0.04, 4.0), yard + Vector3(0, 0.02, 0), _mat(Color(0.85, 0.75, 0.5)))
	_box(Vector3(0.9, 0.12, 3.0), yard + Vector3(-1.2, 0.9, 0), _mat(Color(0.9, 0.2, 0.2))).rotation.x = 0.5
	for sz: float in [-1.0, 1.0]:
		_box(Vector3(0.12, 2.4, 0.12), yard + Vector3(1.4, 1.2, sz), _mat(Color(0.25, 0.4, 0.65)))
	_box(Vector3(0.12, 0.12, 2.2), yard + Vector3(1.4, 2.4, 0), _mat(Color(0.25, 0.4, 0.65)))


## Where the two children are drawn: at home, walking behind you, or out of sight at school.
func _place_kids() -> void:
	if family.size() < 6:
		return
	for k: int in KIDS:
		var kid := family[k]
		if kids == 0:
			kid.root.visible = true
			kid.root.position = ROOMS["home"]["origin"] + Vector3(-1.0 + k * 1.2, 0, 3.8)
			kid.target = kid.root.position
		else:
			kid.root.visible = kids in [1, 3, 4] and not inside and not driving


func _take_kids() -> void:
	_close_panel()
	if kids != 0:
		_toast("הילדים כבר לא בבית.")
		return
	if not _is_school_day():
		_toast("היום אין בית ספר.")
		return
	if clock >= 13.0:
		_toast("מאוחר מדי לבית הספר היום.")
		return
	kids = 1
	var packed := 0
	for n in 4:
		for k in fridge.size():
			if fridge[k] != CHALLAH and fridge[k] != GRAPE_JUICE:
				fridge.remove_at(k)
				packed += 1
				break
	if packed == 4:
		_toast("ארזת לילדים אוכל לבית הספר. עכשיו מסיעים אותם: בית הספר בקצה הימני של הרחוב.")
	else:
		family_joy = maxf(family_joy - 6.0, 0.0)
		_toast("אין מספיק אוכל לארוז לילדים! קנה אוכל. בינתיים מסיעים אותם לבית הספר.")
	_play("pick")
	_place_kids()
	_update_hud()


func _school_door() -> void:
	if kids == 4:
		_toast("היום אתם בטיול, לא בבית הספר.")
		return
	if kids == 1:
		kids = 2
		family_joy = minf(family_joy + 8.0, 100.0)
		_say(teacher, "בוקר טוב ילדים! להתראות אבא.", 5.0)
		_toast("הילדים בבית הספר. אוספים אותם אחרי %s." % ("11:00" if _weekday() == 5 else "13:00"))
		_play("pay")
	elif kids == 2:
		if clock < (11.0 if _weekday() == 5 else 13.0):
			_say(teacher, "הילדים עוד לומדים. בוא אחר כך.", 4.0)
			return
		kids = 3
		_say(teacher, "הם למדו יפה היום!", 5.0)
		_toast("אספת את הילדים. עכשיו מחזירים אותם הביתה.")
		_play("pick")
	elif kids == 3:
		_toast("הילדים איתך. קח אותם הביתה.")
	else:
		_say(teacher, "שלום! הילדים שלך בבית." if _is_school_day() else "היום אין לימודים.", 4.0)
	_place_kids()
	_update_hud()


func _watch_school() -> void:
	# The children trail behind you on foot, and ride along unseen in the car.
	if kids in [1, 3, 4]:
		for k: int in KIDS:
			var kid := family[k]
			kid.root.visible = not inside and not driving
			if kid.root.visible:
				var back := Vector3(-sin(me.root.rotation.y), 0, -cos(me.root.rotation.y))
				var want := player.position + back * (0.9 + 0.5 * k) + Vector3(0.6 if k % 2 == 1 else -0.6, 0, 0)
				var moving := kid.root.position.distance_to(want) > 0.3
				if kid.root.position.distance_to(want) > 12.0:
					kid.root.position = want
				kid.root.position = kid.root.position.move_toward(want, 9.0 * get_physics_process_delta_time())
				var dir := want - kid.root.position
				if dir.length() > 0.05:
					kid.root.rotation.y = atan2(dir.x, dir.z)
				_animate(kid, moving, get_physics_process_delta_time())
		if kids in [3, 4] and room == "home":
			var from_school := kids == 3
			kids = 0
			family_joy = minf(family_joy + (6.0 if from_school else 2.0), 100.0)
			_place_kids()
			_toast("הילדים חזרו הביתה מבית הספר." if from_school else "חזרתם הביתה מהטיול.")
	if kids == 0 and _is_school_day() and clock >= 9.0 and clock < 13.0 and school_missed_day != day:
		school_missed_day = day
		family_joy = maxf(family_joy - 8.0, 0.0)
		_toast("הילדים עוד לא בבית הספר! קח אותם מהבית (ליד הדלת).")
	if kids == 2 and clock >= 18.5:
		kids = 0
		family_joy = maxf(family_joy - 8.0, 0.0)
		_place_kids()
		_toast("לא אספת את הילדים, והם חזרו הביתה לבד.")
	if kids != 0 and _is_shabbat():
		kids = 0
		_place_kids()


# ------------------------------------------- playing outside with the kids ----

func _take_outing() -> void:
	_close_panel()
	if kids != 0:
		_toast("הילדים כבר לא בבית.")
		return
	if clock >= 20.0 or clock < 6.0:
		_toast("מאוחר מדי לצאת עכשיו. הילדים צריכים לישון.")
		return
	kids = 4
	_play("pick")
	_place_kids()
	_toast("יוצאים לטיול! גינת המשחקים בפארק, ופינת הפיקניק בכניסה ליער.")
	_update_hud()


func _play_outside(doing: String, done: String) -> void:
	if kids != 4:
		_toast("לכאן באים עם הילדים. קח אותם מהבית (ליד הדלת): \"לצאת עם הילדים\".")
		return
	if energy < 12.0:
		_toast("אתה עייף מדי לשחק עכשיו.")
		return
	var first := outing_day != day
	outing_day = day
	_time_skip(doing, func() -> void:
		_skip(1.0, "awake")
		energy = maxf(energy - 6.0, 0.0)
		family_joy = minf(family_joy + (14.0 if first else 5.0), 100.0)
		for k: int in KIDS:
			_say(family[k], ["איזה כיף!", "עוד פעם, אבא!", "תודה אבא!", "אני הכי גבוה!"][k - 1], 5.0)
		_toast(done))


func _build_playground() -> void:
	var at := PLAYGROUND
	_box(Vector3(14, 0.04, 10), at + Vector3(0, 0.02, 0), _mat(Color(0.86, 0.76, 0.52)))          # sand
	_sign("גינת משחקים", at + Vector3(0, 3.4, -5.4), 80)
	for sx: float in [-3.0, 3.0]:
		_box(Vector3(0.15, 3.0, 0.15), at + Vector3(sx, 1.5, -5.4), _mat(Color(0.2, 0.2, 0.22)))
	var blue := _mat(Color(0.2, 0.45, 0.8))
	var red := _mat(Color(0.85, 0.2, 0.2))
	var yellow := _mat(Color(0.95, 0.8, 0.2))
	# Swings: an A-frame with two seats.
	var swing := at + Vector3(-4.2, 0, -1.5)
	for sx: float in [-1.6, 1.6]:
		_box(Vector3(0.14, 2.8, 0.14), swing + Vector3(sx, 1.4, 0), blue)
	_box(Vector3(3.4, 0.14, 0.14), swing + Vector3(0, 2.8, 0), blue)
	for sx: float in [-0.7, 0.7]:
		for side: float in [-0.25, 0.25]:
			_box(Vector3(0.03, 1.9, 0.03), swing + Vector3(sx + side, 1.85, 0), _mat(Color(0.3, 0.3, 0.32)))
		_box(Vector3(0.6, 0.06, 0.3), swing + Vector3(sx, 0.9, 0), red)
	# Slide: steps, a platform and a chute.
	var slide := at + Vector3(2.5, 0, -1.5)
	_box(Vector3(1.2, 0.12, 1.2), slide + Vector3(0, 1.8, 0), yellow)
	for sx: float in [-0.55, 0.55]:
		for sz: float in [-0.55, 0.55]:
			_box(Vector3(0.1, 1.8, 0.1), slide + Vector3(sx, 0.9, sz), blue)
	for step in 4:
		_box(Vector3(1.0, 0.08, 0.3), slide + Vector3(0, 0.4 + step * 0.4, -0.9 - (3 - step) * 0.25), blue)
	var chute := _box(Vector3(1.0, 0.1, 3.4), slide + Vector3(0, 0.95, 2.1), red)
	chute.rotation.x = 0.55
	_solid(Vector3(1.2, 1.9, 1.2), slide + Vector3(0, 0.95, 0))
	# Seesaw, sandbox toys, and a bench for the parents.
	var saw := at + Vector3(-1.0, 0, 2.6)
	_box(Vector3(0.3, 0.6, 0.3), saw + Vector3(0, 0.3, 0), blue)
	var plank := _box(Vector3(3.6, 0.1, 0.4), saw + Vector3(0, 0.66, 0), yellow)
	plank.rotation.z = 0.18
	for k in 4:
		_ball(0.18, at + Vector3(4.5 + (k % 2) * 0.6, 0.18, 2.4 + (k / 2) * 0.6), _mat(Color.from_hsv(k * 0.22, 0.8, 0.95)), self)
	_box(Vector3(2.6, 0.14, 0.6), at + Vector3(5.2, 0.55, -3.6), _mat(Color(0.5, 0.33, 0.2)))
	_box(Vector3(2.6, 0.6, 0.1), at + Vector3(5.2, 0.9, -3.9), _mat(Color(0.5, 0.33, 0.2)))
	_box(Vector3(2.4, 0.05, 1.6), at + Vector3(0, 0.05, 0.4), _mat(Color(0.95, 0.75, 0.2)))
	var park := Place.new()
	park.key = "playground"
	park.title = "גינת משחקים"
	park.prompt = "לשחק עם הילדים בגינה"
	park.door = at + Vector3(0, 0, 0.4)
	places.append(park)

	# Picnic corner just inside the forest.
	var pic := PICNIC
	_box(Vector3(3.0, 0.04, 2.2), pic + Vector3(0, 0.03, 0), _mat(Color(0.85, 0.2, 0.25)))
	for k in 6:
		_box(Vector3(0.5, 0.045, 0.37), pic + Vector3(-1.25 + (k % 3) * 1.0 + (0.5 if k >= 3 else 0.0) - 0.25, 0.035, -0.55 + (k / 3) * 1.1), _mat(Color(0.97, 0.97, 0.95)))
	_box(Vector3(0.6, 0.4, 0.4), pic + Vector3(0.9, 0.23, 0.3), _mat(Color(0.6, 0.42, 0.22)))      # basket
	_sign("פינת פיקניק", pic + Vector3(2.6, 2.4, -1.0), 64)
	_box(Vector3(0.14, 2.0, 0.14), pic + Vector3(2.6, 1.0, -1.0), _mat(Color(0.3, 0.2, 0.12)))
	var hike := Place.new()
	hike.key = "picnic"
	hike.title = "פינת פיקניק"
	hike.prompt = "לטייל עם הילדים ביער"
	hike.door = pic
	places.append(hike)
