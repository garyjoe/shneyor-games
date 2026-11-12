extends Node3D
## Life in the City: a small everyday-life sim. Walk around town, work shifts
## for money, buy food, eat, sleep and pay the rent. The scene is built in code.

const HOUR_SECONDS := 180.0         # real seconds per game hour while walking
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
	"police": {"origin": Vector3(2000, 0, -200), "half": Vector2(9, 6.5)},
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
	"police": "תחנת המשטרה: מדווחים לשוטר בדלפק אם שדדו אותך.",
}
## Hand jobs: carry something from one spot to another. Pay scales with your wage.
const JOBS := {
	"work": {"pay": 20, "tire": 0.0, "from": 8.0, "to": 20.0, "tips": 0, "what": "חבילה"},
	"diner": {"pay": 15, "tire": 0.0, "from": 11.0, "to": 23.0, "tips": 12, "what": "מנה"},
	"build": {"pay": 30, "tire": 3.5, "from": 6.0, "to": 19.0, "tips": 0, "what": "לבנים"},
}
const CAR_HOME := Vector3(-18, 0, -0.5)
const WEST := -150.0                # the town fence
const EAST := 190.0
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
	{"name": "הרכב הישן", "price": 0, "model": "sedan", "color": Color(0.15, 0.4, 0.85), "top": 17.0, "use": 1.0, "note": ""},
	{"name": "משפחתית חדשה", "price": 200, "model": "suv-luxury", "color": Color(0.8, 0.12, 0.12), "top": 21.0, "use": 0.75, "note": "חסכונית בדלק"},
	{"name": "ג'יפ", "price": 250, "model": "suv", "color": Color(0.2, 0.38, 0.2), "top": 19.0, "use": 1.15, "note": "נוסע גם ביער"},
	{"name": "מכונית ספורט", "price": 300, "model": "sedan-sports", "color": Color(0.98, 0.78, 0.1), "top": 28.0, "use": 1.4, "note": "הכי מהירה"},
	{"name": "טרקטורון", "price": 150, "model": "atv", "color": Color(0.85, 0.32, 0.1), "top": 15.0, "use": 0.6, "note": "נוסע גם ביער ובשדות"},
]
const TRAFFIC_MODELS: Array[String] = ["sedan", "suv", "taxi", "van", "hatchback-sports", "truck", "delivery", "suv-luxury", "sedan"]
const LEAF_TREES: Array[String] = ["tree_default", "tree_oak", "tree_detailed", "tree_fat"]
const PINE_TREES: Array[String] = ["tree_pineTallA", "tree_pineTallB", "tree_pineDefaultA", "tree_pineRoundC"]
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
	var hill := false               # a sheep thief who hangs about the hill farm
	var target := Vector3.ZERO
	var wait := 0.0
	var name := ""
	var level := 0                  # how well you know each other; 3 = friend
	var talked_day := 0
	var pause := 0.0                # stands still while chatting
	var bubble: Label3D
	var bubble_t := 0.0
	var hello_cool := 0.0
	var down := 0.0                 # a robber who was shot stays away this long
	var air := false                # knocked flying by a car
	var fly := Vector3.ZERO
	var spin := 0.0
	var lying := 0.0                # seconds left on the ground after a knock
	var bounced := false
	var stars: Node3D               # dizzy stars round the head while lying


## Farm animals, riders and the ATV out at the hill farm. A car sends them tumbling; they get up again.
class Roamer:
	var node: Node3D
	var kind := ""
	var label := ""
	var home := Vector3.ZERO
	var reach := 7.0
	var path: Array[Vector3] = []   # riders follow a loop; the flock just wanders near home
	var step := 0
	var speed := 1.0
	var target := Vector3.ZERO
	var wait := 0.0
	var legs: Array[Node3D] = []
	var phase := 0.0
	var air := false
	var bounced := false
	var fly := Vector3.ZERO
	var spin := 0.0
	var lying := 0.0
	var rider: Person
	var voice := ""
	var voice_cool := 0.0


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
const LAKE := Vector3(-128, 0, 18)
const FARM := Vector3(166, 0, 16)
var play_home_day := 0
const PICNIC := Vector3(0, 0, FOREST_Z + 9.0)
var run_on := false                 # the touch "run" toggle
var running := false
var run_button: Button
const NORTH_Z := -44.0             # the second street, parallel to the first
const SEA_Z := -64.0               # where the sand of the sea beach begins
const NORTH_LIMIT := -73.0
const CROSSINGS: Array[float] = [-47.75, 15.25, 82.0]   # side streets joining the two
var cops: Array[Person] = []
var cam_offset := Vector3(0, 11.5, 13.0)
var stolen_last := 0               # money taken in the last robbery, not yet reported
var on_duty := false                # working a police shift
var beat := 0                       # which patrol point is next
var duty_done := 0                  # patrol points and arrests this shift
var beat_marker: Node3D
var duty_cap: Node3D
const BEATS: Array[Vector3] = [Vector3(-24, 0, -3.3), Vector3(56, 0, -3.3), Vector3(20, 0, 19), Vector3(126, 0, -3.5),
	Vector3(15.25, 0, -24), Vector3(-60, 0, -40), Vector3(60, 0, -40), Vector3(0, 0, -67), Vector3(-90, 0, -3.3),
	Vector3(-128, 0, 8), Vector3(160, 0, 12), Vector3(0, 0, 33), Vector3(-37, 0, 7.5), Vector3(82, 0, -22)]
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
var chase := true                  # camera behind the player outdoors; false = the old overhead view
var roamers: Array[Roamer] = []
var atv_rider: Node3D
var fov_kick := 0.0
const ATV := 4
const PEN := Vector3(107, 5, 24.5)       # the sheep's pasture on the hill
const MEADOW := Vector3(118, 0, 58)      # where they graze in the forest, south of the hill
var riding := false                      # you are on your donkey
var my_donkey: Roamer
var near_donkey := false
var herding := false
var herd_stage := 0                      # 0 = on the way out, 1 = grazing, 2 = on the way home
var graze_t := 0.0
var beacon: MeshInstance3D
const PARK := Vector3(-52, 0, 11)    # your own parking lot, next to the car lot
var owned: Array[bool] = [true, false, false, false, false]
var parked: Array[Node3D] = []
const HILL_H := 5.0                  # how high the hill farm stands above the town
var hill_me := false                 # you joined the hill boys: big kippah, sidelocks, hoodie
var entered_from := Vector3.ZERO
var hill_gear: Node3D
var phone_button: Button
var patrol_car: Node3D
var patrol_path: Array[Vector3] = []
var patrol_back := false
var siren_t := 0.0
const HILL := Vector3(120, 0, 21)    # the hill farm, between the street and the forest
var last_tick_pos := Vector3.ZERO
var cam_room := 1.0                 # how far out the chase camera is allowed, 0..1
var cam_yaw := PI                  # which way the camera looks (PI = north, as the overhead view does)
var cam_button: Button
var quality := 2                     # drops by itself on a slow device: 1 = no shadows, 0 = also lower resolution
var slow_strikes := 0
var fps_time := 0.0
var fps_frames := 0
var prints: Array[MeshInstance3D] = []   # your last footprints; the oldest is reused
var print_next := 0
var pine_groups := {}
var fps_label: Label
var paint_mat: StandardMaterial3D   # one shared material for everything that is merged; colours live in the mesh
var tex_cache := {}
var model_cache := {}
var water_mat: ShaderMaterial
var night_lights: Array[OmniLight3D] = []
var headlight: SpotLight3D
var light_tick := 0.0
var step_t := 0.0
const TEX_AVG := {"asphalt": Color(0.35, 0.35, 0.33), "brick": Color(0.42, 0.33, 0.3), "grass": Color(0.59, 0.52, 0.35),
	"paving": Color(0.5, 0.42, 0.34), "plaster": Color(0.67, 0.64, 0.63), "roof": Color(0.35, 0.2, 0.11),
	"sand": Color(0.51, 0.45, 0.36), "wood": Color(0.5, 0.38, 0.26)}
var car_vel := Vector3.ZERO        # the car's real velocity; it can differ from where the nose points
var car_damage := 0.0              # 0 = perfect, 100 = wrecked
var crash_cool := 0.0
var shake := 0.0
var props: Array[RigidBody3D] = [] # street furniture that can be knocked over
var skid_fx: CPUParticles3D
var smoke_fx: CPUParticles3D
var engine_player: AudioStreamPlayer
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
	# Smoothing between physics ticks is costly per node, so only you and your own car get it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rng.randomize()
	bidi = TextServerManager.get_primary_interface().has_feature(TextServer.FEATURE_BIDI_LAYOUT)
	font = load("res://font.ttf")
	_build_world()
	_build_player()
	_build_hud()
	_build_sounds()
	_build_car_effects()
	_build_lights()
	_build_hill_farm()
	_build_parking()
	_build_donkey()
	_merge_static()
	var gfx := ConfigFile.new()
	if gfx.load("user://life-city-gfx.cfg") == OK:
		quality = clampi(int(gfx.get_value("gfx", "quality", 2)), 0, 2)     # what this device managed last time
	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.modulate = Color(1, 1, 1, 0.45)
	fps_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 4)
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fps_label)
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


func _solid(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = pos
	if size.x > 2.5 and size.z > 2.5:
		body.set_meta("big", true)           # big enough to block the camera's view
	add_child(body)
	return body


func _sign(text: String, pos: Vector3, size: int = 96) -> void:
	var l := Label3D.new()
	l.text = _h(text)
	l.font = font
	l.font_size = size
	l.pixel_size = 0.012
	l.outline_size = 24
	l.modulate = Color.WHITE
	l.outline_modulate = Color(0.1, 0.1, 0.2)
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y    # readable from every side, now that the camera turns
	l.position = pos
	add_child(l)


func _building(key: String, title: String, x: float, w: float, h: float, wall: Color, roof: Color,
		open_from: float, open_to: float, z: float = -10.0) -> void:
	var depth := 8.0
	_box(Vector3(w, h, depth), Vector3(x, h * 0.5, z), _tex("brick" if key in ["work", "school", "build", "hall"] else "plaster", wall, 0.28))
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
	var trunk_body := _solid(Vector3(0.55, 2.4, 0.55), pos + Vector3(0, 1.2, 0))
	var r := rng.randf_range(1.3, 1.9)
	var ready := _model("nature/" + LEAF_TREES[rng.randi() % LEAF_TREES.size()])
	if ready != null:
		trunk_body.set_meta("tree", ready)
		ready.position = pos
		ready.rotation.y = rng.randf() * TAU
		ready.scale = Vector3.ONE * (2.6 + r)
		_regreen(ready, Color.from_hsv(rng.randf_range(0.27, 0.36), 0.6, rng.randf_range(0.42, 0.6)))
		_limit(ready, 190.0)
		return
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
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 80.0
	env.fog_depth_end = 200.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	cam = Camera3D.new()
	cam.far = 225.0
	cam.near = 0.3                          # a tight depth range stops far road markings shimmering
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cam)
	cam.make_current()

	window_mat = _mat(Color(0.55, 0.75, 0.9))
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.85, 0.5)
	lamp_mat = _mat(Color(1.0, 0.95, 0.75))
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.9, 0.6)

	# Ground, road, pavements.
	_box(Vector3(500, 1, 260), Vector3(20, -0.5, 35), _tex("grass", Color(0.3, 0.5, 0.24), 0.11))
	_solid(Vector3(500, 1, 260), Vector3(20, -0.5, 35))
	_box(Vector3(460, 0.04, 6), Vector3(20, 0.02, 1.5), _tex("asphalt", Color(0.26, 0.27, 0.29), 0.22))
	var dash := _mat(Color(0.9, 0.9, 0.85))
	for k in range(-51, 61):
		_box(Vector3(1.8, 0.02, 0.2), Vector3(k * 4.0, 0.05, 1.5), dash)
	var paving := _tex("paving", Color(0.56, 0.55, 0.53), 0.3)
	_box(Vector3(460, 0.04, 4.5), Vector3(20, 0.015, -3.75), paving)
	_box(Vector3(460, 0.04, 2.0), Vector3(20, 0.015, 5.5), paving)

	_building("home", "הבית שלי", -24, 9, 4.2, Color(0.85, 0.7, 0.48), Color(0.68, 0.28, 0.2), 0, 24)
	_building("market", "סופרמרקט", -8, 12, 4.2, Color(0.78, 0.8, 0.84), Color(0.15, 0.55, 0.3), 7, 22)
	_building("cafe", "קפה ומסעדה", 8, 9, 4.2, Color(0.82, 0.72, 0.58), Color(0.7, 0.4, 0.18), 8, 23)
	_building("work", "העבודה", 24, 12, 10.5, Color(0.55, 0.62, 0.72), Color(0.25, 0.3, 0.4), 8, 20)

	# Street lamps.
	var pole_mat := _mat(Color(0.2, 0.2, 0.22))
	for x: float in [-144.0, -128.0, -112.0, -96.0, -80.0, -64.0, -48.0, -32.0, -16.0, 0.0, 16.0, 32.0, 48.0, 64.0, 80.0, 96.0, 112.0, 128.0, 144.0, 160.0, 176.0]:
		_lamp_post(Vector3(x, 0, -1.9), 0.3)

	# Park across the road.
	var pond := CylinderMesh.new()
	pond.top_radius = 4.5
	pond.bottom_radius = 4.5
	pond.height = 0.06
	var pond_mi := MeshInstance3D.new()
	pond_mi.mesh = pond
	pond_mi.material_override = _water()
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
		var back_tree := Vector3(rng.randf_range(-48, 48), 0, rng.randf_range(-21, -16))
		var on_road := false
		for cx in CROSSINGS:
			if absf(back_tree.x - cx) < 5.0:
				on_road = true
		if not on_road:
			_tree(back_tree)
	_building("shul", "בית כנסת", -91, 11, 6.5, Color(0.9, 0.87, 0.78), Color(0.2, 0.3, 0.55), 6, 21)
	_building("music", "חנות מוזיקה", -74, 9, 4.2, Color(0.55, 0.4, 0.6), Color(0.3, 0.18, 0.4), 9, 20)
	_building("hall", "אולם הופעות", -58, 15, 8.5, Color(0.75, 0.3, 0.3), Color(0.35, 0.1, 0.12), 17, 24)
	_building("clinic", "מרפאה", -40, 10, 4.2, Color(0.9, 0.92, 0.94), Color(0.75, 0.15, 0.15), 8, 20)
	_building("diner", "מסעדה", 56, 11, 4.2, Color(0.8, 0.5, 0.35), Color(0.45, 0.15, 0.12), 11, 23)
	_building("build", "אתר בנייה", 72, 12, 7.0, Color(0.6, 0.58, 0.55), Color(0.9, 0.6, 0.1), 6, 19)
	_build_town_extras()
	_build_edges()
	_build_neighbourhood()
	_build_restroom()
	_build_school()
	_build_playground()
	_build_outskirts()
	_build_north()
	_building("guns", "חנות נשק", 40, 9, 4.2, Color(0.5, 0.52, 0.45), Color(0.25, 0.3, 0.2), 9, 19)

	# Passers-by on the pavements, each with a name.
	for k in 26:
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


func _cap(radius: float, height: float, pos: Vector3, mat: Material, parent: Node, squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
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
	return mi


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
	# Draw each person as a handful of pieces instead of forty.
	_fuse(p.root)
	for part in p.joints:
		_fuse(part)
	_limit(p.root, 70.0)
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
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
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
	duty_cap = Node3D.new()
	me.root.add_child(duty_cap)
	_ball(0.215, Vector3(0, 1.9, -0.02), _mat(Color(0.1, 0.14, 0.32)), duty_cap, Vector3(1.06, 0.48, 1.06))
	_box(Vector3(0.3, 0.03, 0.16), Vector3(0, 1.87, 0.2), _mat(Color(0.08, 0.1, 0.2)), duty_cap)
	_box(Vector3(0.07, 0.07, 0.02), Vector3(0, 1.94, 0.2), _mat(Color(0.95, 0.8, 0.2)), duty_cap)
	_box(Vector3(0.09, 0.1, 0.02), Vector3(0.1, 1.38, 0.2), _mat(Color(0.95, 0.8, 0.2)), duty_cap)
	duty_cap.visible = false
	parcel_mesh = _box(Vector3(0.6, 0.5, 0.6), Vector3(0, 1.15, 0.5), _mat(Color(0.72, 0.55, 0.32)), me.root)
	parcel_mesh.visible = false
	add_child(player)
	_reset_position()


func _reset_position() -> void:
	inside = false
	_reset_props()
	for n in npcs:
		n.air = false
		n.lying = 0.0
	on_duty = false
	if duty_cap != null:
		duty_cap.visible = false
	if beat_marker != null:
		beat_marker.visible = false
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
	var sun_hour := snappedf(hour, 0.05)                    # the sun moves in small steps: shadows that creep every frame shimmer
	var sun_up := sin((sun_hour - 6.0) / 12.0 * PI)
	sun.rotation_degrees = Vector3(-clampf(sun_up, 0.12, 1.0) * 65.0, (sun_hour - 12.0) * 9.0 - 25.0, 0)
	sun.light_energy = 0.04 + light * 0.8
	sun.light_color = Color(1.0, 0.72, 0.5).lerp(Color(1, 0.98, 0.93), clampf(elevation * 2.0, 0.0, 1.0))
	var night_top := Color(0.03, 0.04, 0.12)
	var night_low := Color(0.08, 0.1, 0.2)
	sky_mat.sky_top_color = night_top.lerp(Color(0.25, 0.5, 0.9), light)
	var horizon := night_low.lerp(Color(0.75, 0.86, 0.96), light)
	if elevation > -0.2 and elevation < 0.35:
		horizon = horizon.lerp(Color(1.0, 0.6, 0.35), 0.6 * (1.0 - absf(elevation - 0.08) / 0.28))
	sky_mat.sky_horizon_color = horizon
	env.fog_light_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = night_top.lerp(Color(0.4, 0.5, 0.6), light)
	env.ambient_light_color = Color(0.22, 0.26, 0.42).lerp(Color(0.4, 0.43, 0.48), light)
	var glow := 1.0 - light
	env.glow_enabled = glow > 0.6                         # bloom only for lamps at night; by day it made bright surfaces sparkle
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
	_reset_props()
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
	_skip(0.3, "work")
	energy = maxf(energy - 1.0, 0.0)
	hunger = maxf(hunger - 0.7, 0.0)
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
				if car_damage >= 5.0:
					_add_action("תיקון הרכב (נזק %d%%) · ₪%d" % [int(car_damage), _repair_price()], _repair)
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
			"police_desk":
				if stolen_last > 0:
					panel_text.text = _h("שדדו ממך ₪%d. אפשר להגיש תלונה, והמשטרה תנסה להחזיר את הכסף." % stolen_last)
					_add_action("להגיש תלונה על השוד", _report_robbery)
				else:
					panel_text.text = _h(("אתה במשמרת. עד עכשיו: %d משימות." % duty_done) if on_duty
						else "שלום! אפשר לדווח כאן על שוד, או להתנדב למשמרת סיור כשוטר.")
				if on_duty:
					_add_action("לסיים את המשמרת", _end_duty)
				else:
					_add_action("להתחיל משמרת כשוטר", _start_duty)
			"farm":
				panel_text.text = _h("ישר מהחווה, טרי וזול יותר מהסופר.")
				_add_action("ביצים טריות · ₪5", _farm_buy.bind(5, 5))
				_add_action("חלב טרי · ₪3", _farm_buy.bind(2, 3))
				_add_action("עגבניות מהשדה · ₪1", _farm_buy.bind(13, 1))
				if kids == 4:
					_add_action("להאכיל את הפרות עם הילדים", _feed_cows)
			"hill":
				panel_text.text = _h("חוות הגבעה: כבשים, חמורים, כרם וזיתים. תמיד שמחים לעזרה!")
				if herding:
					_add_action("להפסיק את המרעה", _stop_herd.bind(false))
				else:
					_add_action("לצאת למרעה עם הכבשים · ₪40", _herd_sheep)
				_add_action("לבצור ענבים בכרם (שעה) · ₪15", _pick_grapes)
				if not hill_me:
					_add_action("להצטרף לנערי הגבעה", _join_hill)
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
				panel_text.text = _h("אתה נוהג עכשיו ב: %s. כל רכב שתקנה נשאר שלך, והשאר מחכים בחנייה שלך." % CARS[car_model]["name"])
				for k in range(1, CARS.size()):
					if not owned[k]:
						_add_action("%s · %s · ₪%d" % [CARS[k]["name"], CARS[k]["note"], CARS[k]["price"]], _buy_car.bind(k))
			"parking":
				panel_text.text = _h("החנייה שלך. אתה נוהג עכשיו ב: %s." % CARS[car_model]["name"])
				var more := false
				for k in CARS.size():
					if owned[k] and k != car_model:
						more = true
						_add_action("לקחת את: %s" % CARS[k]["name"], _take_car.bind(k))
				if not more:
					panel_text.text += "\n" + _h("עוד אין לך רכבים נוספים. קונים במגרש הרכבים ליד.")
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
	if atv_rider != null and is_instance_valid(atv_rider):
		atv_rider.visible = driving
	_update_roamers(delta)
	_follow_ground()
	_update_patrol(delta)
	_update_herd(delta)
	near_donkey = my_donkey != null and not riding and not driving and not inside and my_donkey.node.position.distance_to(player.position) < 2.6
	if player.position.distance_to(last_tick_pos) > 2.5:
		player.reset_physics_interpolation()      # a teleport (door, wake-up): do not glide there
	last_tick_pos = player.position
	for n in npcs:
		if _tumble(n, delta):
			continue
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
	# Running: hold Shift, or switch on the run button. It is faster but tiring.
	running = walking and not driving and not riding and not carrying and energy >= 15.0 and input.length_squared() > 0.01 \
			and (run_on or Input.is_physical_key_pressed(KEY_SHIFT))
	if running:
		speed *= 1.75
		energy = maxf(energy - delta * 0.12, 0.0)
	if driving:
		_drive(input, delta)
	else:
		var go := _stick_world(input)
		if riding:
			speed = 9.5
		player.velocity = Vector3(go.x * speed, -4.0, go.z * speed)
		player.move_and_slide()
	_update_traffic(delta)
	if inside:
		player.position.x = clampf(player.position.x, room_origin.x - room_half.x, room_origin.x + room_half.x)
		player.position.z = clampf(player.position.z, room_origin.z - room_half.y, room_origin.z + room_half.y)
	else:
		player.position.x = clampf(player.position.x, WEST, EAST)
		player.position.z = clampf(player.position.z, NORTH_LIMIT, FOREST_END)
	if driving:
		if car_model != JEEP and car_model != ATV:
			player.position.z = minf(player.position.z, FOREST_Z - 6.0)   # only the jeep goes among the trees
		car.position = player.position
		# The body leans into corners and dips under braking.
		var nose := Vector3(sin(car_heading), 0, cos(car_heading))
		var side := car_vel.dot(Vector3(nose.z, 0, -nose.x))
		car.rotation = Vector3(0, car_heading, clampf(-side * 0.035, -0.22, 0.22))
		_car_hits()
	if input.length_squared() > 0.01:
		var facing := _stick_world(input)
		me.root.rotation.y = lerp_angle(me.root.rotation.y, atan2(facing.x, facing.z), 12.0 * delta)
		# Footsteps.
		if not driving:
			step_t -= delta * (1.7 if running else 1.0)
			if step_t <= 0.0:
				step_t = 0.36
				_play("step")
				_footprint()
	if riding:
		_ride_tick(input.length_squared() > 0.01, delta)
	else:
		_animate(me, input.length_squared() > 0.01, delta * (1.6 if running else 1.0))
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
		if edge_cool <= 0.0 and (player.position.x <= WEST + 0.05 or player.position.x >= EAST - 0.05 or player.position.z >= FOREST_END - 0.05 or player.position.z <= NORTH_LIMIT + 0.05):
			edge_cool = 12.0
			_toast("המים כאן כבר עמוקים. שוחים רק ליד המציל." if player.position.z <= NORTH_LIMIT + 0.05 else "כאן נגמרת העיר. הגדר סוגרת את הדרך.")
	_update_focus()
	_update_forest(delta)
	_update_hud()


func _process(delta: float) -> void:
	# If the device cannot keep up, give up the costly extras rather than stutter.
	fps_time += delta
	fps_frames += 1
	if fps_time >= 2.5:
		var fps := fps_frames / fps_time
		fps_label.text = "%d · %d" % [int(fps), quality]
		if state == State.PLAY and quality > 0 and fps < 40.0 and slow_strikes >= 0:
			slow_strikes += 1
			if slow_strikes >= 2:                # two slow spells in a row, not one hiccup
				slow_strikes = 0
				quality -= 1
				_apply_quality()
				var keep := ConfigFile.new()
				keep.set_value("gfx", "quality", quality)
				keep.save("user://life-city-gfx.cfg")
		else:
			slow_strikes = 0
		fps_time = 0.0
		fps_frames = 0
	var view := get_viewport().get_visible_rect().size
	var portrait := view.y > view.x
	shake = maxf(shake - delta * 2.2, 0.0)
	var at := player.get_global_transform_interpolated().origin   # where the player is drawn this frame
	var jitter := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake
	if inside or state == State.MENU or not chase:
		# Overhead view: indoors, on the menu, or when chosen.
		cam.fov = 75.0 if portrait else 50.0
		cam_yaw = PI
		var want := at + Vector3(0, 1.0, -1.5)
		if state == State.MENU:
			want = Vector3(sin(Time.get_ticks_msec() * 0.0002) * 14.0, 1.0, -3.0)
		cam_focus = cam_focus.lerp(want, 1.0 - exp(-5.0 * delta))
		var outdoor := Vector3(0, 15.0, 16.0) if driving else Vector3(0, 11.5, 13.0)
		if not inside and at.z < -6.0:
			var steep := clampf((-6.0 - at.z) / 6.0, 0.0, 1.0)
			outdoor = outdoor.lerp(Vector3(0, 19.0, 8.5) if driving else Vector3(0, 14.5, 6.0), steep)
		cam_offset = cam_offset.lerp(outdoor, 1.0 - exp(-4.0 * delta)) if not inside else Vector3(0, 7.0, 6.5)
		cam.position = cam_focus + cam_offset + jitter
		cam.look_at(cam_focus)
	else:
		# Chase view: the camera sits behind you and swings round to follow where you are heading.
		fov_kick = maxf(fov_kick - delta * 2.5, 0.0)
		cam.fov = (82.0 if portrait else 64.0) + fov_kick * 9.0
		var heading := car_heading if driving else me.root.rotation.y
		var moving := car_vel.length() > 1.0 if driving else Vector2(player.velocity.x, player.velocity.z).length() > 0.5
		if moving and absf(angle_difference(cam_yaw, heading)) < 2.2:
			cam_yaw = lerp_angle(cam_yaw, heading, 1.0 - exp(-(2.4 if driving else 1.5) * delta))
		var ahead := Vector3(sin(cam_yaw), 0, cos(cam_yaw))
		cam_focus = cam_focus.lerp(at + Vector3(0, 1.5, 0), 1.0 - exp(-12.0 * delta))
		var spot := cam_focus - ahead * (10.0 if driving else 5.8) + Vector3(0, 3.6 if driving else 2.3, 0)
		# If a building is in the way, bring the camera in front of it. Thin or moving things
		# (posts, trees, cars, people) are ignored, and the distance changes smoothly, so the view never jumps.
		var room := 1.0
		var ray := PhysicsRayQueryParameters3D.create(cam_focus, spot, 1, [player.get_rid()])
		var wall := get_world_3d().direct_space_state.intersect_ray(ray)
		if not wall.is_empty() and wall["collider"] is StaticBody3D and (wall["collider"] as Node).has_meta("big"):
			var hit: Vector3 = wall["position"]
			room = clampf((cam_focus.distance_to(hit) - 0.4) / cam_focus.distance_to(spot), 0.12, 1.0)
		cam_room = minf(room, lerpf(cam_room, room, 1.0 - exp(-(10.0 if room < cam_room else 2.5) * delta)))
		spot = cam_focus + (spot - cam_focus) * cam_room
		spot.y = maxf(spot.y, cam_focus.y + 0.5)
		cam.position = spot + jitter
		cam.look_at(cam_focus + ahead * 3.0)
	pad.queue_redraw()


## Turn a stick or arrow-key direction into a direction in the world, relative to where the camera looks.
func _stick_world(input: Vector2) -> Vector3:
	var yaw := cam_yaw if (chase and not inside) else PI
	var ahead := Vector3(sin(yaw), 0, cos(yaw))
	var right := Vector3(-ahead.z, 0, ahead.x)
	return ahead * -input.y + right * input.x


func _toggle_camera() -> void:
	chase = not chase
	cam_yaw = PI
	cam_button.text = _h("מצלמה: מאחור" if chase else "מצלמה: מלמעלה")


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
		elif key == KEY_P:
			_call_police()
		elif key == KEY_C:
			_toggle_camera()
		elif key in [KEY_E, KEY_ENTER, KEY_SPACE]:
			_use()


# ---------------------------------------------------------- game states ----

func _new_game() -> void:
	if riding:
		_dismount()
	if herding:
		_stop_herd(false)
	owned.assign([true, false, false, false, false])
	hill_me = false
	hill_gear.visible = false
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
	car_damage = 0.0
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
	hill_me = bool(cfg.get_value("life", "hill_me", false))
	var had: Array = cfg.get_value("life", "owned", [])
	for k in owned.size():
		owned[k] = k == 0 or (k < had.size() and bool(had[k]))
	owned[car_model] = true
	_show_parked()
	hill_gear.visible = hill_me
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
	car_damage = float(cfg.get_value("life", "car_damage", 0.0))
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
			["car_x", car.position.x], ["car_z", car.position.z], ["car_rot", car_heading], ["car_damage", car_damage],
			["can", has_can], ["car_model", car_model], ["hill_me", hill_me], ["owned", owned]]:
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
		"המצלמה הולכת מאחוריך. C או הכפתור משמאל למטה מחליפים למבט מלמעלה",
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

	run_button = Button.new()
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.toggle_mode = true
	run_button.text = _h("ריצה")
	run_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 30)
	run_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	run_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	run_button.toggled.connect(func(on: bool) -> void:
		run_on = on
		run_button.text = _h("ריצה ✓" if on else "ריצה"))
	hud.add_child(run_button)

	phone_button = Button.new()
	phone_button.focus_mode = Control.FOCUS_NONE
	phone_button.text = _h("טלפון למשטרה")
	phone_button.add_theme_font_size_override("font_size", 26)
	phone_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 30)
	phone_button.pressed.connect(_call_police)
	hud.add_child(phone_button)

	cam_button = Button.new()
	cam_button.focus_mode = Control.FOCUS_NONE
	cam_button.text = _h("מצלמה: מאחור")
	cam_button.add_theme_font_size_override("font_size", 26)
	cam_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 30)
	cam_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cam_button.pressed.connect(_toggle_camera)
	hud.add_child(cam_button)

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
	_apply_quality()
	var width := 660.0 if portrait else 760.0
	panel.custom_minimum_size.x = width
	overlay_text.custom_minimum_size.x = width if portrait else 1000.0
	for key: String in bars:
		(bars[key] as ProgressBar).custom_minimum_size.x = 170.0 if portrait else 240.0


func _update_hud() -> void:
	run_button.visible = state == State.PLAY and not driving and open_place == null and not busy
	cam_button.visible = state == State.PLAY and not inside and open_place == null and not busy
	phone_button.visible = cam_button.visible
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
		_h("משמרת שוטר · נקודת הסיור במרחק %d מ'" % int(player.position.distance_to(BEATS[beat]))) if on_duty and not inside else "",
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
	prompt.visible = playing and (near != null or near_car or driving or riding or near_donkey or near_npc != null or near_kin != null) and open_place == null and not busy
	if prompt.visible:
		if riding:
			prompt.text = _h("לרדת מהחמור")
		elif near != null:
			prompt.text = _h(near.prompt)
		elif near_donkey and not driving:
			prompt.text = _h("לעלות על החמור שלי")
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
		"siren": _tone(620, 930, 0.45, 0.22),
		"dial": _tone(1200, 1200, 0.12, 0.2),
		"engine": _tone(90, 180, 0.5, 0.35, 0.25),
		"crash": _tone(140, 35, 0.55, 0.8, 0.9),
		"ouch": _tone(880, 330, 0.38, 0.3),
		"boing": _tone(220, 520, 0.16, 0.3),
		"crack": _tone(320, 70, 0.3, 0.5, 0.85),
		"glass": _tone(2600, 1700, 0.3, 0.22, 0.7),
		"baa": _tone(540, 430, 0.42, 0.3, 0.3),
		"moo": _tone(190, 130, 0.75, 0.38, 0.1),
		"bray": _tone(700, 240, 0.55, 0.3, 0.25),
		"woof": _tone(420, 260, 0.14, 0.3, 0.4),
		"thump": _tone(95, 45, 0.22, 0.7, 0.55),
		"skid": _tone(950, 700, 0.35, 0.22, 0.9),
		"honk": _tone(430, 430, 0.4, 0.35),
		"step": _tone(110, 70, 0.05, 0.035, 0.35),      # a soft pad, barely there
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
		"home", "market", "cafe", "work", "guns", "clinic", "diner", "build", "music", "hall", "shul", "police":
			_enter_room(p)
		"store_exit", "exit":
			_leave_room()
		"school":
			_school_door()
		"sea":
			_swim()
		"beach":
			_beach()
		"farm", "hill", "parking":
			_open_panel(p)
		"play_home":
			_play_home()
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
	if riding:
		_dismount()
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
	entered_from = p.door
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
	if room == "home" and entered_from.y > 1.0:
		player.position = entered_from + Vector3(0, 0.2, -1.2)       # you came in through the caravan on the hill
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
		if not _tap_thug(pos):
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
	var trunk_body := _solid(Vector3(0.6, 2.0, 0.6), pos + Vector3(0, 1.0, 0))
	var ready := _model("nature/" + PINE_TREES[rng.randi() % PINE_TREES.size()])
	if ready != null:
		# Baked into one big mesh per patch of forest: hundreds of separate trees were too much to draw.
		remove_child(ready)
		trunk_body.set_meta("tree_at", pos)
		var place := Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(1.25, 1.0, 1.25) * (h + 1.2) / 1.6), pos)
		var green := Color.from_hsv(rng.randf_range(0.3, 0.38), 0.65, rng.randf_range(0.28, 0.42))
		var key := "%d|%d" % [int(floor(pos.x / 45.0)), int(floor(pos.z / 45.0))]
		if not pine_groups.has(key):
			pine_groups[key] = _new_parts()
		_bake(pine_groups[key], ready, place, green)
		ready.free()
		return
	_box(Vector3(0.35, 1.4, 0.35), pos + Vector3(0, 0.7, 0), _mat(Color(0.33, 0.22, 0.13)))
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
	for k in 420:
		var pos := Vector3(rng.randf_range(-175, 215), 0, rng.randf_range(FOREST_Z, FOREST_END + 25.0))
		if absf(pos.x) < 3.0 and pos.z < FOREST_Z + 14.0:
			continue                       # keep a path in from the sign
		if pos.x > 87.0 and pos.x < 157.0 and pos.z < 46.5:
			continue                       # the hill stands here
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
		if t.down > 0.0:
			# Shot: lies still for a moment, then is gone until the timer runs out.
			t.chasing = false
			t.down -= delta
			if t.down < 57.0:
				t.root.visible = false
			if t.down <= 0.0:
				t.root.rotation = Vector3.ZERO
				t.root.position = _thug_point(t)
				t.target = t.root.position
				t.root.visible = not t.town
			continue
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
		if t.hill:
			in_reach = not inside and not driving and here.x > 72.0 and here.x < 160.0 and here.z > 6.0 and here.z < 48.0 and here.y < 2.0   # up on the farm you are safe
		if patrol_car != null and patrol_car.visible and patrol_car.position.distance_to(t.root.position) < 30.0:
			t.chasing = false                # they freeze when they hear the siren
			in_reach = false
		if t.chasing and (not in_reach or dist > 24.0 or rob_cool > 0.0):
			t.chasing = false
		var watched := false                 # robbers keep away when a police officer is close
		for cop in cops:
			if cop.root.position.distance_to(t.root.position) < 14.0 or cop.root.position.distance_to(here) < 10.0:
				watched = true
		if watched:
			t.chasing = false
		elif not t.chasing and in_reach and dist < (9.0 if t.town else 13.0) and rob_cool <= 0.0:
			t.chasing = true
			if t.hill:
				_toast("גנב כבשים באדום רודף אחריך! התקשר למשטרה (כפתור הטלפון) או ברח!")
			else:
				_toast("אדם רע באדום רודף אחריך! היכנס לבניין או לרכב!" if t.town else "אדם רע באדום רודף אחריך! ברח מהיער!")
			_play("alarm")
		var step := Vector3.ZERO
		if t.chasing:
			step = to_me.normalized() * 5.6
			if dist < 1.3:
				if on_duty:
					_arrest(t)
				else:
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
		elif not t.hill:
			t.root.position.z = maxf(t.root.position.z, FOREST_Z + 2.0)
		if step != Vector3.ZERO:
			t.root.rotation.y = lerp_angle(t.root.rotation.y, atan2(step.x, step.z), 10.0 * delta)
		_animate(t, step != Vector3.ZERO, delta * (1.8 if t.chasing else 1.0))


func _robbed() -> void:
	var stolen := mini(money, maxi(50, int(money * 0.3)))
	stolen_last += stolen
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

func _make_car(color: Color, kind: String = "") -> Node3D:
	var n := Node3D.new()
	if kind == "atv":
		_atv_body(n, color)
		add_child(n)
		return n
	if kind == "":
		kind = TRAFFIC_MODELS[rng.randi() % TRAFFIC_MODELS.size()]
	var ready := _model("cars/" + kind, n)
	if ready != null:
		ready.scale = Vector3.ONE * 1.4          # the kit's cars are small next to our people
		add_child(n)
		return n
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
	car = _make_car(CARS[model]["color"], CARS[model]["model"])
	car.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	atv_rider = null
	if model == ATV:
		# On the ATV you can see yourself riding.
		var dummy := _make_person(Color(0.95, 0.95, 0.95), Color(0.15, 0.17, 0.25), Person.new())
		_kippah(dummy.root, Color(0.1, 0.12, 0.35))
		_sit_astride(dummy)
		dummy.root.position = Vector3(0, 0.05, -0.25)
		car.add_child(dummy.root)
		atv_rider = dummy.root
		atv_rider.visible = driving
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
	owned[model] = true
	_show_parked()


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
		var show := _make_car(CARS[k]["color"], CARS[k]["model"])
		if k == JEEP:
			show.scale = Vector3(1.08, 1.25, 1.0)
		show.position = CAR_LOT + Vector3(-7.8 + k * 3.25, 0, 1.0)
		show.rotation.y = PI
		_solid(Vector3(1.9, 1.6, 4.2), show.position + Vector3(0, 0.8, 0))
		_tag("%s ₪%d" % [CARS[k]["name"], CARS[k]["price"]], show.position + Vector3(0, 2.6, 0), 44)

	# Two lanes of traffic that loop along the street.
	for k in 13:
		var t := _make_car(Color.from_hsv(rng.randf(), rng.randf_range(0.2, 0.75), rng.randf_range(0.5, 0.95)))
		var east := k % 2 == 0
		t.position = Vector3(rng.randf_range(-190, 230), 0, 3.6 if east else 1.5)
		t.rotation.y = PI * 0.5 if east else -PI * 0.5
		t.set_meta("dir", 1.0 if east else -1.0)
		t.set_meta("top", rng.randf_range(7.0, 11.0))
		t.set_meta("speed", 8.0)
		_traffic_body(t)
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
	car_vel = Vector3.ZERO
	car_heading = heading
	if engine_player != null:
		engine_player.stop()
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
	elif riding:
		_dismount()
	elif near != null:
		_interact(near)
	elif near_donkey:
		_mount()
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
	elif _nearest_thug() != null:
		_shoot_thug(_nearest_thug())
	elif _in_forest():
		_shoot(_nearest_animal())


func _enter_car() -> void:
	if _shabbat_block():
		return
	if riding:
		_dismount()
	driving = true
	near_car = false
	car_speed = 0.0
	car_vel = Vector3.ZERO
	car_block.disabled = true
	body_shape.radius = 0.9
	player.position = car.position
	me.root.visible = false
	_play("engine")
	engine_player.play()
	if car_damage >= 100.0:
		_toast("הרכב הרוס. צריך תיקון בתחנת הדלק.")
	elif fuel <= 0.0:
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
	crash_cool = maxf(crash_cool - delta, 0.0)
	var want := _stick_world(input)
	if _is_shabbat():
		want = Vector3.ZERO              # the car stays parked until Shabbat is over
	var top := float(CARS[car_model]["top"]) * (1.0 - minf(car_damage, 100.0) / 160.0)
	var nose := Vector3(sin(car_heading), 0, cos(car_heading))
	var pushing := want.length() > 0.15 and fuel > 0.0 and car_damage < 100.0
	if pushing:
		var steer := clampf(absf(car_speed) / 4.0, 0.35, 1.0)
		car_heading = rotate_toward(car_heading, atan2(want.x, want.z), 2.8 * steer * delta)
		car_speed = move_toward(car_speed, top * minf(want.length(), 1.0), 9.0 * delta)
	else:
		car_speed = move_toward(car_speed, 0.0, 14.0 * delta)
	nose = Vector3(sin(car_heading), 0, cos(car_heading))
	# Tyres only pull the car's real motion round so fast: at speed it slides before it follows the nose.
	# The engine drives the car along its nose; any sideways motion is only scrubbed off as fast as the tyres grip.
	var grip := lerpf(9.0, 2.6, clampf(car_vel.length() / 26.0, 0.0, 1.0))
	var sideways := car_vel - nose * car_vel.dot(nose)
	sideways *= maxf(0.0, 1.0 - grip * delta)
	car_vel = nose * car_speed + sideways
	var slide := sideways.length()
	var before := player.position
	var incoming := car_vel
	player.velocity = car_vel + Vector3(0, -4.0, 0)
	player.move_and_slide()
	# What did we run into, and how hard?
	var worst := 0.0
	var worst_normal := Vector3.ZERO
	var worst_thing: Object
	for k in player.get_slide_collision_count():
		var hit := player.get_slide_collision(k)
		var normal := hit.get_normal()
		if absf(normal.y) > 0.6:
			continue                         # the ground
		var into := -incoming.dot(normal)
		if into > worst:
			worst = into
			worst_normal = normal
			worst_thing = hit.get_collider()
	if worst > 0.5:
		car_vel = (car_vel - worst_normal * car_vel.dot(worst_normal)) * 0.75
	if worst > 4.0 and crash_cool <= 0.0:
		_crash(worst, worst_normal, worst_thing)
	if worst > 0.5:
		car_speed = car_vel.dot(nose)
	var moved := Vector3(player.position.x - before.x, 0, player.position.z - before.z).length()
	var had_fuel := fuel > 0.0
	fuel = maxf(fuel - moved / 32.0 * float(CARS[car_model]["use"]), 0.0)
	if had_fuel and fuel <= 0.0:
		_toast("נגמר הדלק! צא מהרכב, קנה מיכל דלק בתחנה והבא אותו לרכב.")
		_play("no")
	# Tyre smoke and squeal while sliding; engine note follows the speed; a hurt car smokes.
	var sliding := slide > 3.0 and car_vel.length() > 6.0
	skid_fx.emitting = sliding
	skid_fx.global_position = player.position - nose * 1.6 + Vector3(0, 0.2, 0)
	if sliding and not (sfx["skid"] as AudioStreamPlayer).playing:
		_play("skid")
	smoke_fx.emitting = car_damage > 45.0
	smoke_fx.global_position = player.position + nose * 1.7 + Vector3(0, 1.0, 0)
	engine_player.pitch_scale = 0.7 + absf(car_speed) / 22.0
	engine_player.volume_db = -22.0 + minf(absf(car_speed), 12.0) * 0.6


## The moment of impact: bounce, noise, shake, damage, and whatever we hit reacts too.
func _crash(impact: float, normal: Vector3, thing: Object) -> void:
	crash_cool = 0.35
	var prop := thing as RigidBody3D
	if prop != null and props.has(prop) and impact > 5.0:
		_knock_prop(prop, -normal, impact)
		car_vel *= 0.8
		car_damage = minf(car_damage + impact * 0.35, 100.0)
		shake = maxf(shake, 0.25)
		_play("thump")
		return
	var other := thing as Node
	if other != null and other.has_meta("traffic"):
		# The other car is shoved aside and spun round; a moment later it straightens up and drives on.
		var their: Node3D = other.get_meta("traffic")
		their.set_meta("speed", 0.0)
		their.set_meta("stun", 3.0)
		their.set_meta("shove", -normal * minf(impact, 16.0) * 0.55)
		their.set_meta("twirl", rng.randf_range(2.0, 4.0) * (1.0 if rng.randf() < 0.5 else -1.0) * minf(impact / 10.0, 1.5))
		_play("honk")
		_play("glass")
		_car_parts(their.position + Vector3(0, 0.9, 0), -normal, impact)
	if other != null and other.has_meta("tree"):
		_shake_tree(other.get_meta("tree"), -normal, impact)
	elif other != null and other.has_meta("tree_at"):
		_play("crack")
		_leaf_burst(other.get_meta("tree_at"), impact)
	car_vel += normal * impact * 0.35                 # bounce back off it
	if impact > 8.0:
		_hit_stop(0.09 if impact < 13.0 else 0.16)
		_car_parts(player.position - normal * 1.8 + Vector3(0, 0.9, 0), normal, impact)
		fov_kick = minf(impact / 14.0, 1.2)
	shake = maxf(shake, clampf(impact / 22.0, 0.2, 1.1))
	_play("crash" if impact > 8.0 else "thump")
	_debris(player.position - normal * 1.6 + Vector3(0, 0.8, 0), impact)
	if impact > 6.0:
		car_damage = minf(car_damage + (impact - 4.0) * 2.4, 100.0)
	if impact > 11.0:
		health = maxf(health - (impact - 11.0) * 2.5, 0.0)
		_toast("התרסקת! נזק לרכב: %d%%. גם אתה נפגעת." % int(car_damage))
	elif impact > 6.0:
		_toast("התנגשות! נזק לרכב: %d%%." % int(car_damage))
	if car_damage >= 100.0:
		_toast("הרכב הרוס לגמרי. גוררים אותו לתיקון בתחנת הדלק.")
	_update_hud()


func _debris(pos: Vector3, impact: float) -> void:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.14, 0.14)
	var mat := _mat(Color(0.75, 0.75, 0.78))
	mesh.material = mat
	p.mesh = mesh
	p.amount = int(clampf(impact * 2.0, 8.0, 40.0))
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.0
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 3.0 + impact * 0.5
	p.gravity = Vector3(0, -18, 0)
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


## Whatever the moving car touches gets knocked: people, robbers, animals.
func _car_hits() -> void:
	var speed := car_vel.length()
	if speed < 3.5:
		return
	var nose := Vector3(sin(car_heading), 0, cos(car_heading))
	var right := Vector3(nose.z, 0, -nose.x)
	for n in npcs:
		if n.air or n.lying > 0.0 or not n.root.visible:
			continue
		var rel := n.root.position - player.position
		if absf(rel.dot(right)) < 1.25 and absf(rel.dot(nose)) < 2.5 and car_vel.dot(rel) > 0.0:
			n.target = n.root.position
			n.air = true
			n.fly = car_vel * 0.85 + right * signf(rel.dot(right) + 0.01) * 2.0 + Vector3(0, 3.5 + speed * 0.28, 0)
			n.spin = rng.randf_range(6.0, 11.0)
			n.bounced = false
			_say(n, ["איייי!", "אוי ואבוי!", "הצילו!", "וואו!"][rng.randi() % 4], 1.6)
			_play("ouch")
			_hit_stop(0.08)
			fov_kick = maxf(fov_kick, 0.5)
			var fine := mini(money, 250 if cops.has(n) else 100)
			money -= fine
			car_vel *= 0.7
			car_damage = minf(car_damage + 2.0, 100.0)
			shake = maxf(shake, 0.5)
			_play("thump")
			_toast("פגעת ב%s! האמבולנס בדרך, ושילמת קנס של ₪%d. סע בזהירות!" % [n.name, fine])
	for t in thugs:
		if t.down > 0.0 or not t.root.visible:
			continue
		var rel := t.root.position - player.position
		if absf(rel.dot(right)) < 1.25 and absf(rel.dot(nose)) < 2.5 and car_vel.dot(rel) > 0.0:
			t.down = 60.0
			t.chasing = false
			t.root.rotation.z = PI * 0.5
			_play("ouch")
			_hit_stop(0.08)
			car_vel *= 0.7
			shake = maxf(shake, 0.5)
			_play("thump")
			_toast("פגעת באיש רע עם הרכב. המשטרה לקחה אותו.")
	for a in animals:
		if a.dead or a.gone > 0.0:
			continue
		var rel := a.node.position - player.position
		if absf(rel.dot(right)) < 1.3 and absf(rel.dot(nose)) < 2.6 and car_vel.dot(rel) > 0.0:
			a.dead = true
			a.scared = 0.0
			a.node.rotation.z = PI * 0.5
			_hit_stop(0.06)
			car_vel *= 0.75
			car_damage = minf(car_damage + (5.0 if a.big else 1.0), 100.0)
			shake = maxf(shake, 0.4)
			_play("thump")
			_toast("פגעת בחיה עם הרכב.")
	for r in roamers:
		if r.air or r.lying > 0.0 or r == my_donkey:
			continue
		var rel := r.node.position - player.position
		if absf(rel.dot(right)) < 1.4 and absf(rel.dot(nose)) < 2.7 and car_vel.dot(rel) > 0.0:
			var heavy := r.kind in ["cow", "donkey", "mule", "atv"]
			r.air = true
			r.bounced = false
			r.fly = car_vel * (0.6 if heavy else 0.9) + right * signf(rel.dot(right) + 0.01) * 2.5 + Vector3(0, 4.0 + speed * 0.3, 0)
			r.spin = rng.randf_range(4.0, 8.0)
			car_vel *= 0.55 if heavy else 0.8
			car_damage = minf(car_damage + (7.0 if heavy else 1.5), 100.0)
			shake = maxf(shake, 0.7 if heavy else 0.4)
			fov_kick = maxf(fov_kick, 0.5)
			_hit_stop(0.1 if heavy else 0.06)
			_play("crash" if heavy else "thump")
			_play(r.voice)
			if heavy:
				_car_parts(player.position + nose * 1.8 + Vector3(0, 0.9, 0), -nose, 10.0)
			if r.rider != null:
				var fine := mini(money, 100)
				money -= fine
				_play("ouch")
				_toast("אוי! פגעת ב%s. הוא קם מיד, אבל שילמת קנס של ₪%d. סע בזהירות!" % [r.label, fine])
			else:
				_toast("אופס! פגעת ב%s. היא תקום בעוד רגע. סע בזהירות ליד החיות!" % r.label)
			_update_hud()


## A knocked person flies, tumbles, lies still for a while, and then is back on their feet.
func _tumble(n: Person, delta: float) -> bool:
	if n.air:
		n.fly.y -= 22.0 * delta
		n.root.position += n.fly * delta
		n.root.rotation.x += n.spin * delta
		var floor_y := _ground_y(n.root.position.x, n.root.position.z) + 0.25
		if n.root.position.y <= floor_y and n.fly.y < 0.0:
			n.root.position.y = floor_y
			if not n.bounced and n.fly.y < -5.0:
				# One bounce and a roll before coming to rest.
				n.bounced = true
				n.fly = Vector3(n.fly.x * 0.55, -n.fly.y * 0.42, n.fly.z * 0.55)
				n.spin *= 0.6
				_play("boing")
				return true
			n.air = false
			n.lying = 7.0
			n.root.rotation = Vector3(PI * 0.5, n.root.rotation.y, 0)
			n.stars = _dizzy_stars(n.root, 2.15)
			_play("thump")
		return true
	if n.lying > 0.0:
		n.lying -= delta
		if n.stars != null:
			n.stars.rotation.y += delta * 5.0
		if n.lying <= 0.0:
			if n.stars != null:
				n.stars.queue_free()
				n.stars = null
			n.root.position = n.target
			n.root.rotation = Vector3.ZERO
			n.root.reset_physics_interpolation()
		return true
	# On foot you cannot walk through people: you are nudged apart, and they pause.
	if not driving and not inside and n.root.visible:
		var gap := player.position - n.root.position
		gap.y = 0.0
		if gap.length() < 0.75 and gap.length() > 0.01:
			player.position += gap.normalized() * (0.75 - gap.length())
			n.pause = maxf(n.pause, 0.6)
	return false


# ---------------------------------------------------- knockable objects ----

## A piece of street furniture: solid until a car hits it hard, then it tumbles.
func _prop(pos: Vector3, size: Vector3, mass: float, parts: Array) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position.y = size.y * 0.5
	body.add_child(cs)
	for part: Array in parts:
		_box(part[0], part[1], part[2], body)
	add_child(body)
	body.set_meta("home", body.transform)
	props.append(body)
	return body


func _lamp_post(pos: Vector3, reach: float) -> void:
	var post := _prop(pos, Vector3(0.3, 4.3, 0.3), 45.0, [[Vector3(0.18, 4.2, 0.18), Vector3(0, 2.1, 0), _mat(Color(0.2, 0.2, 0.22))],
		[Vector3(0.9, 0.25, 0.5), Vector3(0, 4.2, reach), lamp_mat]])
	post.set_meta("lamp", true)


func _knock_prop(body: RigidBody3D, dir: Vector3, impact: float) -> void:
	body.freeze = false
	body.collision_layer = 2             # once down it no longer blocks you; you can still shove it about
	body.collision_mask = 1
	body.apply_central_impulse((dir * impact * 0.75 + Vector3(0, impact * 0.22, 0)) * body.mass)
	body.apply_torque_impulse(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * impact * body.mass * 0.3)
	_debris(body.global_position + Vector3(0, 0.6, 0), impact * 0.6)


## The council tidies up overnight.
func _reset_props() -> void:
	for body in props:
		body.freeze = true
		body.collision_layer = 1
		body.collision_mask = 1
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.transform = body.get_meta("home")


func _traffic_body(t: Node3D) -> void:
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.6, 4.2)
	cs.shape = shape
	cs.position.y = 0.8
	body.add_child(cs)
	body.set_meta("traffic", t)
	t.add_child(body)


func _repair_price() -> int:
	return int(ceilf(car_damage * 0.8))


func _repair() -> void:
	var price := _repair_price()
	if money < price:
		_toast("אין מספיק כסף לתיקון (₪%d)." % price)
		_play("no")
		return
	money -= price
	car_damage = 0.0
	_play("pay")
	_toast("הרכב תוקן, והוא כמו חדש.")
	_refresh_panel()


func _build_car_effects() -> void:
	skid_fx = _smoke(Color(0.85, 0.85, 0.85, 0.5), 0.5, 30)
	smoke_fx = _smoke(Color(0.2, 0.2, 0.22, 0.6), 1.4, 20)
	# Engine: a short buzzy loop whose pitch follows the speed.
	var rate := 22050
	var count := rate / 10
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var phase := float(i) / count
		var wave := fmod(phase * 8.0, 1.0) * 2.0 - 1.0 + sin(phase * TAU * 4.0) * 0.6
		data.encode_s16(i * 2, int(wave * 0.3 * 32000.0))
	var loop := AudioStreamWAV.new()
	loop.format = AudioStreamWAV.FORMAT_16_BITS
	loop.mix_rate = rate
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = count
	loop.data = data
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = loop
	engine_player.volume_db = -22.0
	add_child(engine_player)


func _smoke(color: Color, life: float, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := _mat(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.8
	p.gravity = Vector3(0, 1.2, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.emitting = false
	add_child(p)
	return p


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
		var stun: float = t.get_meta("stun", 0.0)
		if not t.has_meta("lane"):
			t.set_meta("lane", t.position.z)
			t.set_meta("face", t.rotation.y)
		if stun > 0.0:
			t.set_meta("stun", stun - delta)
			want = 0.0
			var shove: Vector3 = t.get_meta("shove", Vector3.ZERO)
			var twirl: float = t.get_meta("twirl", 0.0)
			t.position += Vector3(shove.x, 0, shove.z) * delta
			t.position.z = clampf(t.position.z, float(t.get_meta("lane")) - 3.5, float(t.get_meta("lane")) + 3.5)
			t.rotation.y += twirl * delta
			t.set_meta("shove", shove * maxf(0.0, 1.0 - 3.0 * delta))
			t.set_meta("twirl", twirl * maxf(0.0, 1.0 - 2.2 * delta))
		else:
			t.position.z = move_toward(t.position.z, float(t.get_meta("lane")), 2.0 * delta)
			t.rotation.y = lerp_angle(t.rotation.y, float(t.get_meta("face")), 3.0 * delta)
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
		if dir > 0.0 and t.position.x > 240.0:
			t.position.x = -200.0
			t.reset_physics_interpolation()
		elif dir < 0.0 and t.position.x < -200.0:
			t.position.x = 240.0
			t.reset_physics_interpolation()


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
	_box(Vector3(w, 1, d), o + Vector3(0, -0.5, 0), _tex("wood", floor_color, 0.3))
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
	_build_police_room()


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

	# --- Play corner: a mat with blocks where you play with the children.
	_box(Vector3(2.6, 0.04, 2.0), o + Vector3(1.6, 0.03, 3.4), _mat(Color(0.4, 0.75, 0.5)))
	for k in 5:
		_box(Vector3(0.3, 0.3, 0.3), o + Vector3(0.8 + (k % 3) * 0.4, 0.2 + (k / 3) * 0.3, 3.0 + (k % 2) * 0.3), _mat(Color.from_hsv(k * 0.19, 0.75, 0.95)))
	_spot("home", "play_home", "פינת משחקים", "לשחק עם הילדים", o + Vector3(2.4, 0, 3.8))

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
	owned[model] = true
	_set_car_model(model)
	fuel = 100.0
	_play("pay")
	_toast("קנית %s! הרכב הקודם שלך עבר לחנייה שלך, ליד מגרש הרכבים." % CARS[model]["name"])
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
	if t.hill:
		# Round the foot of the hill, never up on the farm itself.
		var spot := Vector3(80, 0, 12)
		for attempt in 12:
			var a := rng.randf() * TAU
			spot = Vector3(clampf(122.0 + cos(a) * 40.0, 79.0, 159.0), 0, clampf(25.75 + sin(a) * 24.0, 7.5, 46.5))
			if _ground_y(spot.x, spot.z) < 0.5:
				break
		return spot
	if t.town:
		return Vector3(rng.randf_range(WEST + 4.0, EAST - 4.0), 0, rng.randf_range(-3.5, 28.0))
	return _forest_point()


# ------------------------------------------------- a bigger, busier town ----

## An apartment block with rows of windows. Only scenery.
func _block(pos: Vector3, size: Vector3, color: Color) -> void:
	_box(size, pos + Vector3(0, size.y * 0.5, 0), _tex("plaster" if int(pos.x) % 3 != 0 else "brick", color, 0.22))
	_solid(size, pos + Vector3(0, size.y * 0.5, 0))
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
	for k in 26:
		var h := rng.randf_range(9.0, 19.0)
		var bx := -168 + k * 15.0 + rng.randf_range(-1.5, 1.5)
		var blocked := false
		for cx in CROSSINGS:
			if absf(bx - cx) < 9.5:
				blocked = true                   # leave the side streets open
		if not blocked:
			_block(Vector3(bx, 0, -27), Vector3(rng.randf_range(9, 11), h, 9), palette[k % 4])
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
	for x: float in [-30.0, -2.0, 30.0, 62.0, 100.0, -70.0]:
		_prop(Vector3(x, 0, -1.9), Vector3(0.6, 0.9, 0.6), 18.0, [[Vector3(0.6, 0.9, 0.6), Vector3(0, 0.45, 0), _mat(Color(0.15, 0.4, 0.25))]])
	for x: float in [-14.0, 18.0, 46.0]:
		_prop(Vector3(x, 0, -5.7), Vector3(0.5, 1.1, 0.5), 30.0, [[Vector3(0.5, 1.1, 0.5), Vector3(0, 0.55, 0), _mat(Color(0.8, 0.12, 0.1))]])
	# Traffic cones and crates near the building site, and bollards by the crossings.
	for k in 6:
		_prop(Vector3(64.5 + k * 1.6, 0, -1.2), Vector3(0.45, 0.7, 0.45), 4.0, [[Vector3(0.45, 0.08, 0.45), Vector3(0, 0.04, 0), _mat(Color(0.95, 0.45, 0.1))],
			[Vector3(0.22, 0.6, 0.22), Vector3(0, 0.38, 0), _mat(Color(0.95, 0.45, 0.1))], [Vector3(0.24, 0.12, 0.24), Vector3(0, 0.45, 0), _mat(Color(0.95, 0.95, 0.95))]])
	for k in 4:
		_prop(Vector3(80.5 + (k % 2) * 1.0, 0, -6.2 - (k / 2) * 1.0), Vector3(0.9, 0.9, 0.9), 14.0, [[Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0), _mat(Color(0.62, 0.45, 0.25))]])
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
		_fence(Vector3(x, 0, NORTH_LIMIT - 1.0), Vector3(x, 0, -2.2))
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
	_watch_duty()
	_update_lights(get_process_delta_time())
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
	_box(Vector3(15, 6.4, 8), at + Vector3(0, 3.2, 0), _tex("brick", Color(0.8, 0.62, 0.45), 0.28))
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
	_box(Vector3(14, 0.04, 10), at + Vector3(0, 0.02, 0), _tex("sand", Color(0.62, 0.54, 0.38), 0.2))          # sand
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


func _play_home() -> void:
	if kids != 0:
		_toast("הילדים לא בבית עכשיו.")
		return
	if energy < 10.0:
		_toast("אתה עייף מדי לשחק עכשיו.")
		return
	var first := play_home_day != day
	play_home_day = day
	_time_skip("משחקים עם הילדים...", func() -> void:
		_skip(0.75, "awake")
		energy = maxf(energy - 4.0, 0.0)
		family_joy = minf(family_joy + (10.0 if first else 4.0), 100.0)
		for k: int in KIDS:
			_say(family[k], ["ניצחתי!", "עוד משחק, אבא!", "תורי!", "אבא הכי טוב!"][k - 1], 5.0)
		_toast("שיחקת עם הילדים בבית. הם מאושרים!"))


func _beach() -> void:
	if kids == 4:
		_play_outside("בונים ארמונות בחול על שפת האגם...", "שיחקת עם הילדים על חוף האגם!")
		return
	if energy > 92.0:
		_toast("אתה לא עייף. אפשר סתם ליהנות מהנוף.")
		return
	_time_skip("נחים על חוף האגם...", func() -> void:
		_skip(1.0, "awake")
		energy = minf(energy + 18.0, 100.0)
		_toast("נחת שעה על החוף. מרגיע."))


func _farm_buy(pid: int, price: int) -> void:
	if _shabbat_block():
		return
	if money < price:
		_toast("אין מספיק כסף.")
		_play("no")
		return
	if fridge.size() >= FRIDGE_MAX:
		_toast("אין מקום במקרר בבית.")
		_play("no")
		return
	money -= price
	fridge.append(pid)
	_play("pay")
	_toast("קנית %s טרי מהחווה." % PRODUCTS[pid]["name"])
	_refresh_panel()


func _feed_cows() -> void:
	_close_panel()
	_play_outside("מאכילים את הפרות...", "האכלתם את הפרות בחווה. הילדים התלהבו!")


## More to see at both ends of town: a lake with a beach, and a farm.
func _build_outskirts() -> void:
	# --- The lake
	var water := CylinderMesh.new()
	water.top_radius = 11.0
	water.bottom_radius = 11.0
	water.height = 0.06
	var lake := MeshInstance3D.new()
	lake.mesh = water
	lake.material_override = _water()
	lake.position = LAKE + Vector3(0, 0.04, 6)
	add_child(lake)
	var shore := StaticBody3D.new()
	var shore_shape := CollisionShape3D.new()
	var round := CylinderShape3D.new()
	round.radius = 10.8
	round.height = 3.0
	shore_shape.shape = round
	shore.add_child(shore_shape)
	shore.position = LAKE + Vector3(0, 1.5, 6)
	add_child(shore)
	_box(Vector3(26, 0.04, 9), LAKE + Vector3(0, 0.02, -8.5), _tex("sand", Color(0.64, 0.57, 0.42), 0.14))        # sand
	_box(Vector3(1.6, 0.25, 9.0), LAKE + Vector3(6, 0.35, -1.0), _mat(Color(0.5, 0.35, 0.2)))      # pier
	for k in 4:
		_box(Vector3(0.2, 0.9, 0.2), LAKE + Vector3(6 + (0.7 if k % 2 == 0 else -0.7), 0.3, -4.5 + (k / 2) * 6.5), _mat(Color(0.4, 0.28, 0.16)))
	for k in 3:
		var px := LAKE + Vector3(-8 + k * 5.0, 0, -8.5)
		_box(Vector3(0.1, 2.2, 0.1), px + Vector3(0, 1.1, 0), _mat(Color(0.9, 0.9, 0.9)))
		_ball(1.2, px + Vector3(0, 2.3, 0), _mat(Color.from_hsv(k * 0.3, 0.7, 0.95)), self, Vector3(1.0, 0.3, 1.0))
		_box(Vector3(0.8, 0.12, 1.8), px + Vector3(1.2, 0.25, 0), _mat(Color(0.95, 0.95, 0.9)))    # sun bed
	_sign("חוף האגם", LAKE + Vector3(0, 3.2, -12.6), 80)
	_box(Vector3(0.15, 2.8, 0.15), LAKE + Vector3(0, 1.4, -12.6), _mat(Color(0.2, 0.2, 0.22)))
	_box(Vector3(2.4, 0.05, 1.6), LAKE + Vector3(-2, 0.05, -7.5), _mat(Color(0.95, 0.75, 0.2)))
	var beach := Place.new()
	beach.key = "beach"
	beach.title = "חוף האגם"
	beach.prompt = "לנוח או לשחק על החוף"
	beach.door = LAKE + Vector3(-2, 0, -7.5)
	places.append(beach)

	# --- The farm
	_box(Vector3(9, 5, 7), FARM + Vector3(-6, 2.5, 4), _mat(Color(0.7, 0.18, 0.15)))             # barn
	_box(Vector3(9.6, 0.5, 7.6), FARM + Vector3(-6, 5.2, 4), _mat(Color(0.35, 0.3, 0.28)))
	_box(Vector3(2.6, 3.2, 0.1), FARM + Vector3(-6, 1.6, 0.47), _mat(Color(0.95, 0.93, 0.85)))
	_solid(Vector3(9, 5, 7), FARM + Vector3(-6, 2.5, 4))
	_box(Vector3(14, 0.04, 10), FARM + Vector3(7, 0.02, 4), _mat(Color(0.5, 0.42, 0.25)))          # paddock
	_fence(FARM + Vector3(0, 0, -1), FARM + Vector3(14, 0, -1))
	_fence(FARM + Vector3(0, 0, 9), FARM + Vector3(14, 0, 9))
	_fence(FARM + Vector3(14, 0, -1), FARM + Vector3(14, 0, 9))
	for k in 4:
		var cow := Node3D.new()
		cow.position = FARM + Vector3(3 + k * 2.8, 0, 2 + (k % 2) * 4)
		cow.rotation.y = k * 1.3
		add_child(cow)
		var hide := _mat(Color(0.96, 0.96, 0.94))
		var patch := _mat(Color(0.12, 0.1, 0.1))
		_cap(0.5, 1.9, Vector3(0, 1.1, 0), hide, cow).rotation.x = PI * 0.5
		_ball(0.3, Vector3(0.2, 1.3, 0.2), patch, cow, Vector3(1.2, 0.8, 1.4))
		_ball(0.25, Vector3(-0.25, 1.25, -0.4), patch, cow, Vector3(1.0, 0.8, 1.2))
		_ball(0.3, Vector3(0, 1.35, 1.15), hide, cow, Vector3(0.9, 0.9, 1.3))
		for sx: float in [-0.3, 0.3]:
			for sz: float in [-0.6, 0.6]:
				_box(Vector3(0.16, 0.7, 0.16), Vector3(sx, 0.35, sz), hide, cow)
	for k in 3:
		_cap(0.6, 1.6, FARM + Vector3(-10.5 + k * 1.3, 0.6, -1.5), _mat(Color(0.9, 0.78, 0.35)), self).rotation.z = PI * 0.5
	_sign("החווה", FARM + Vector3(-6, 6.4, 0.6), 96)
	var farmer := _make_person(Color(0.3, 0.45, 0.7), Color(0.35, 0.3, 0.2))
	farmer.speed = 0.0
	farmer.root.position = FARM + Vector3(-2.2, 0, -1.8)
	_add_townsperson(farmer)
	farmer.name = "החוואי גדי"
	_box(Vector3(2.4, 0.05, 1.6), FARM + Vector3(-4.5, 0.05, -2.2), _mat(Color(0.95, 0.75, 0.2)))
	var stand := Place.new()
	stand.key = "farm"
	stand.title = "החווה"
	stand.prompt = "לקנות מהחווה"
	stand.door = FARM + Vector3(-4.5, 0, -2.2)
	places.append(stand)
	# A few more homes along the longer street.
	var palette: Array[Color] = [Color(0.82, 0.74, 0.6), Color(0.68, 0.76, 0.8), Color(0.8, 0.66, 0.62), Color(0.72, 0.78, 0.66)]
	for k in 5:
		var hp := Vector3([-112.0, -126.0, -140.0, 148.0, 162.0][k], 0, -10)
		_box(Vector3(8, 3.8, 7), hp + Vector3(0, 1.9, 0), _mat(palette[k % 4]))
		_box(Vector3(8.6, 0.4, 7.6), hp + Vector3(0, 4.0, 0), _mat(Color(0.55, 0.22, 0.18)))
		_box(Vector3(1.3, 2.3, 0.1), hp + Vector3(0, 1.15, 3.53), _mat(Color(0.3, 0.2, 0.12)))
		for sx: float in [-2.5, 2.5]:
			_box(Vector3(1.5, 1.2, 0.1), hp + Vector3(sx, 2.1, 3.53), window_mat)
		_solid(Vector3(8, 3.8, 7), hp + Vector3(0, 1.9, 0))
		_tree(hp + Vector3(5.5, 0, 2.0))


# ------------------------------------------------- fighting off robbers ----

## A robber you can see and reach with the rifle: awake, visible and not too far.
func _nearest_thug() -> Person:
	if inside or driving or not has_rifle:
		return null
	var best: Person
	var best_d := 22.0
	for t in thugs:
		if t.down > 0.0 or not t.root.visible:
			continue
		var d := t.root.position.distance_to(player.position)
		if d < best_d:
			best_d = d
			best = t
	return best


func _tap_thug(pos: Vector2) -> bool:
	if driving:
		return false
	var hit: Person
	var best := 80.0
	for t in thugs:
		if t.down > 0.0 or not t.root.visible:
			continue
		var world := t.root.position + Vector3(0, 1.1, 0)
		if cam.is_position_behind(world):
			continue
		var d := cam.unproject_position(world).distance_to(pos)
		if d < best:
			best = d
			hit = t
	if hit == null:
		return false
	_shoot_thug(hit)
	return true


func _shoot_thug(t: Person) -> void:
	if shot_cool > 0.0 or _shabbat_block():
		return
	if not has_rifle:
		_toast("בלי רובה אפשר רק לברוח. רובה קונים בחנות הנשק.")
		shot_cool = 1.0
		return
	if ammo <= 0:
		_toast("נגמרו הכדורים! ברח!")
		_play("no")
		shot_cool = 1.0
		return
	var to_thug := t.root.position - player.position
	to_thug.y = 0.0
	var dist := to_thug.length()
	if dist > 28.0:
		_toast("הוא רחוק מדי.")
		shot_cool = 0.5
		return
	ammo -= 1
	shot_cool = 0.9
	reach = 0.4
	me.root.rotation.y = atan2(to_thug.x, to_thug.z)
	_play("bang")
	if rng.randf() < clampf(1.25 - dist / 26.0, 0.15, 1.0):
		t.down = 60.0
		t.chasing = false
		t.root.rotation.z = PI * 0.5
		money += 60
		_toast("פגעת באיש הרע! המשטרה לקחה אותו, וקיבלת פרס של ₪60.")
		_play("pay")
	else:
		_toast("פספסת! הוא עדיין רודף אחריך.")
	_update_hud()


# ------------------------------------------- the north side and the sea ----

func _report_robbery() -> void:
	if _shabbat_block():
		return
	var back := int(stolen_last * 0.6)
	money += back
	stolen_last = 0
	_play("pay")
	_toast("השוטרים תפסו את השודד והחזירו לך ₪%d." % back)
	_refresh_panel()


func _build_police_room() -> void:
	var o := _room("police", Color(0.45, 0.47, 0.5), Color(0.75, 0.8, 0.86))
	var navy := Color(0.12, 0.2, 0.45)
	_box(Vector3(5.0, 1.1, 1.0), o + Vector3(0, 0.55, -3.0), _mat(navy))
	_box(Vector3(5.1, 0.08, 1.1), o + Vector3(0, 1.14, -3.0), _mat(Color(0.85, 0.85, 0.88)))
	_solid(Vector3(5.0, 1.1, 1.0), o + Vector3(0, 0.55, -3.0))
	var desk_cop := _officer()
	desk_cop.root.position = o + Vector3(0, 0, -4.2)
	add_child(desk_cop.root)
	_tag("יומנאי", desk_cop.root.position + Vector3(0, 2.7, 0))
	var spot := _spot("police", "police_desk", "תחנת משטרה", "לדבר עם השוטר", o + Vector3(0, 0, -1.6))
	_handle(desk_cop.root, "police", _interact.bind(spot))
	# Two holding cells with bars along the back wall.
	for side: float in [-1.0, 1.0]:
		var cell := o + Vector3(side * 6.2, 0, -5.2)
		_box(Vector3(3.6, 0.03, 2.6), cell + Vector3(0, 0.02, 0), _mat(Color(0.3, 0.3, 0.33)))
		for k in 8:
			_box(Vector3(0.08, 2.6, 0.08), cell + Vector3(-1.6 + k * 0.46, 1.3, 1.3), _mat(Color(0.2, 0.2, 0.22)))
		_box(Vector3(3.6, 0.1, 0.1), cell + Vector3(0, 2.6, 1.3), _mat(Color(0.2, 0.2, 0.22)))
		_box(Vector3(1.8, 0.4, 0.8), cell + Vector3(0, 0.2, -0.7), _mat(Color(0.5, 0.5, 0.52)))
		_solid(Vector3(3.6, 2.6, 0.2), cell + Vector3(0, 1.3, 1.3))
	# Notice board, filing cabinets and waiting chairs.
	_box(Vector3(2.4, 1.4, 0.08), o + Vector3(0, 2.4, -6.45), _mat(Color(0.55, 0.4, 0.25)))
	for k in 6:
		_box(Vector3(0.5, 0.4, 0.03), o + Vector3(-0.8 + (k % 3) * 0.8, 2.1 + (k / 3) * 0.6, -6.4), _mat(Color(0.95, 0.95, 0.9)))
	for k in 3:
		_box(Vector3(0.8, 1.6, 0.6), o + Vector3(6.5 + k * 0.85, 0.8, 2.5), _mat(Color(0.5, 0.52, 0.55)))
	for x: float in [-6.5, -5.3]:
		_chair(o + Vector3(x, 0, 2.5), 1.0, navy)


## A police officer: navy uniform, cap with a badge.
func _officer() -> Person:
	var cop := _make_person(Color(0.12, 0.2, 0.45), Color(0.1, 0.12, 0.25))
	_ball(0.21, Vector3(0, 1.88, -0.02), _mat(Color(0.1, 0.14, 0.32)), cop.root, Vector3(1.05, 0.45, 1.05))
	_box(Vector3(0.3, 0.03, 0.16), Vector3(0, 1.86, 0.2), _mat(Color(0.08, 0.1, 0.2)), cop.root)
	_box(Vector3(0.07, 0.07, 0.02), Vector3(0, 1.92, 0.2), _mat(Color(0.95, 0.8, 0.2)), cop.root)
	_box(Vector3(0.08, 0.09, 0.02), Vector3(0.1, 1.38, 0.19), _mat(Color(0.95, 0.8, 0.2)), cop.root)
	return cop


func _build_north() -> void:
	var asphalt := _tex("asphalt", Color(0.26, 0.27, 0.29), 0.22)
	var paving := _tex("paving", Color(0.56, 0.55, 0.53), 0.3)
	var white := _mat(Color(0.9, 0.9, 0.85))
	var span := EAST - WEST + 6.0
	var mid := (EAST + WEST) * 0.5
	# The second street.
	_box(Vector3(span, 0.04, 6), Vector3(mid, 0.02, NORTH_Z), asphalt)
	_box(Vector3(span, 0.04, 2.4), Vector3(mid, 0.015, NORTH_Z + 4.2), paving)
	_box(Vector3(span, 0.04, 2.4), Vector3(mid, 0.015, NORTH_Z - 4.2), paving)
	for k in range(int(WEST / 4.0), int(EAST / 4.0)):
		_box(Vector3(1.8, 0.02, 0.2), Vector3(k * 4.0, 0.05, NORTH_Z), white)
	for x in range(int(WEST) + 10, int(EAST), 20):
		_lamp_post(Vector3(x, 0, NORTH_Z + 3.3), -0.3)
	# Side streets joining the two streets.
	for cx in CROSSINGS:
		_box(Vector3(4.6, 0.04, -NORTH_Z - 4.5), Vector3(cx, 0.025, (NORTH_Z + 3.0 - 1.5) * 0.5), asphalt)
		for k in 9:
			_box(Vector3(0.2, 0.02, 1.6), Vector3(cx, 0.055, -5.0 - k * 4.0), white)

	# Police station, with a patrol car outside.
	_building("police", "תחנת משטרה", 0, 13, 6.0, Color(0.82, 0.86, 0.92), Color(0.12, 0.2, 0.45), 0, 24, NORTH_Z - 10.0)
	var patrol := _make_car(Color(0.95, 0.95, 0.97), "police")
	patrol.position = Vector3(9, 0, NORTH_Z - 4.6)
	patrol.rotation.y = PI * 0.5
	if patrol.get_child_count() > 1:             # the plain box car gets a blue stripe
		_box(Vector3(1.92, 0.3, 1.2), Vector3(0, 0.75, 0.9), _mat(Color(0.12, 0.2, 0.45)), patrol)
		_box(Vector3(0.9, 0.16, 0.3), Vector3(0, 1.75, -0.25), _mat(Color(0.2, 0.35, 0.95)), patrol)
	_solid(Vector3(4.2, 1.6, 1.9), patrol.position + Vector3(0, 0.8, 0))

	# Houses along the north side of the second street.
	var palette: Array[Color] = [Color(0.82, 0.74, 0.6), Color(0.68, 0.76, 0.8), Color(0.8, 0.66, 0.62), Color(0.72, 0.78, 0.66), Color(0.9, 0.85, 0.7)]
	var count := 0
	for x in range(int(WEST) + 12, int(EAST) - 6, 17):
		if absf(x) < 16.0:
			continue                         # the police station stands here
		var hp := Vector3(x, 0, NORTH_Z - 10.5)
		var tall := 3.8 + (count % 3) * 1.6
		_box(Vector3(9, tall, 7), hp + Vector3(0, tall * 0.5, 0), _mat(palette[count % 5]))
		_box(Vector3(9.6, 0.4, 7.6), hp + Vector3(0, tall + 0.2, 0), _mat(Color(0.55, 0.22, 0.18) if count % 2 == 0 else Color(0.3, 0.32, 0.38)))
		_box(Vector3(1.3, 2.3, 0.1), hp + Vector3(0, 1.15, 3.53), _mat(Color(0.3, 0.2, 0.12)))
		for f in int(tall / 3.0):
			for sx: float in [-2.8, 2.8]:
				_box(Vector3(1.5, 1.2, 0.1), hp + Vector3(sx, 2.1 + f * 3.0, 3.53), window_mat)
		_solid(Vector3(9, tall, 7), hp + Vector3(0, tall * 0.5, 0))
		if count % 2 == 0:
			_tree(hp + Vector3(6.3, 0, 1.5))
		count += 1

	# The sea: a long sandy beach, and water to the horizon.
	_box(Vector3(span, 0.04, 11.0), Vector3(mid, 0.02, SEA_Z - 5.0), _tex("sand", Color(0.62, 0.55, 0.4), 0.14))
	_box(Vector3(span + 200.0, 0.06, 96.0), Vector3(mid, 0.03, SEA_Z - 58.0), _water())
	_box(Vector3(span, 0.07, 1.2), Vector3(mid, 0.035, SEA_Z - 10.4), _mat(Color(0.85, 0.95, 1.0)))       # surf
	for k in 14:
		var px := Vector3(WEST + 14.0 + k * 24.0, 0, SEA_Z - 4.0 - (k % 2) * 2.0)
		_box(Vector3(0.1, 2.2, 0.1), px + Vector3(0, 1.1, 0), _mat(Color(0.9, 0.9, 0.9)))
		_ball(1.3, px + Vector3(0, 2.3, 0), _mat(Color.from_hsv(k * 0.17, 0.7, 0.95)), self, Vector3(1.0, 0.3, 1.0))
		_box(Vector3(0.8, 0.12, 1.8), px + Vector3(1.3, 0.25, 0), _mat(Color(0.95, 0.95, 0.9)))
	for k in 4:
		var boat := Vector3(WEST + 50.0 + k * 85.0, 0.2, SEA_Z - 24.0 - (k % 2) * 14.0)
		_box(Vector3(3.6, 0.6, 1.4), boat, _mat(Color(0.9, 0.9, 0.92)))
		_box(Vector3(0.08, 3.0, 0.08), boat + Vector3(0, 1.6, 0), _mat(Color(0.4, 0.3, 0.2)))
		_box(Vector3(0.04, 2.2, 1.6), boat + Vector3(0, 1.8, 0.4), _mat(Color.from_hsv(k * 0.25, 0.6, 0.95)))
	# Lifeguard tower and the swimming spot.
	var tower := Vector3(12, 0, SEA_Z - 3.0)
	for sx: float in [-0.9, 0.9]:
		for sz: float in [-0.9, 0.9]:
			_box(Vector3(0.14, 2.6, 0.14), tower + Vector3(sx, 1.3, sz), _mat(Color(0.5, 0.35, 0.2)))
	_box(Vector3(2.4, 0.15, 2.4), tower + Vector3(0, 2.6, 0), _mat(Color(0.5, 0.35, 0.2)))
	_box(Vector3(2.2, 1.4, 2.0), tower + Vector3(0, 3.4, -0.1), _mat(Color(0.95, 0.9, 0.2)))
	_box(Vector3(2.6, 0.15, 2.6), tower + Vector3(0, 4.2, 0), _mat(Color(0.85, 0.15, 0.12)))
	_solid(Vector3(2.4, 2.6, 2.4), tower + Vector3(0, 1.3, 0))
	_sign("חוף הים", Vector3(0, 3.4, SEA_Z + 1.6), 96)
	_box(Vector3(0.18, 3.0, 0.18), Vector3(0, 1.5, SEA_Z + 1.6), _mat(Color(0.2, 0.2, 0.22)))
	_box(Vector3(2.6, 0.05, 1.6), Vector3(0, 0.05, SEA_Z - 7.5), _mat(Color(0.95, 0.75, 0.2)))
	var swim := Place.new()
	swim.key = "sea"
	swim.title = "חוף הים"
	swim.prompt = "לשחות בים"
	swim.door = Vector3(0, 0, SEA_Z - 7.5)
	places.append(swim)

	# Traffic and people on the second street, and police officers on patrol.
	for k in 6:
		var t := _make_car(Color.from_hsv(rng.randf(), rng.randf_range(0.2, 0.75), rng.randf_range(0.5, 0.95)))
		var east := k % 2 == 0
		t.position = Vector3(rng.randf_range(WEST, EAST), 0, NORTH_Z + (1.5 if east else -1.5))
		t.rotation.y = PI * 0.5 if east else -PI * 0.5
		t.set_meta("dir", 1.0 if east else -1.0)
		t.set_meta("top", rng.randf_range(7.0, 11.0))
		t.set_meta("speed", 8.0)
		_traffic_body(t)
		traffic.append(t)
	for k in 14:
		var n := _make_person(Color.from_hsv(rng.randf(), 0.5, 0.88), Color.from_hsv(rng.randf(), 0.3, 0.42))
		n.dir = 1.0 if k % 2 == 0 else -1.0
		n.speed = rng.randf_range(1.6, 2.6)
		n.root.position = Vector3(rng.randf_range(WEST + 4.0, EAST - 4.0), 0, NORTH_Z + (4.2 if k % 2 == 0 else -4.2))
		_add_townsperson(n)
	var beats: Array[Vector3] = [Vector3(-30, 0, -2.4), Vector3(60, 0, 5.6), Vector3(-90, 0, NORTH_Z + 4.4), Vector3(40, 0, NORTH_Z - 4.4), Vector3(10, 0, -2.6)]
	for k in beats.size():
		var cop := _officer()
		cop.dir = 1.0 if k % 2 == 0 else -1.0
		cop.speed = 1.9
		cop.root.position = beats[k]
		_add_townsperson(cop)
		cop.name = "השוטר " + ["אבנר", "גלית", "שמעון", "נועם", "אורית"][k]
		cops.append(cop)


func _swim() -> void:
	if energy < 12.0:
		_toast("אתה עייף מדי לשחות עכשיו.")
		return
	var with_kids := kids == 4
	_time_skip("שוחים בים...", func() -> void:
		_skip(1.0, "awake")
		energy = maxf(energy - 5.0, 0.0)
		health = minf(health + 6.0, 100.0)
		if with_kids:
			family_joy = minf(family_joy + 12.0, 100.0)
			for k: int in KIDS:
				_say(family[k], "המים נעימים!", 5.0)
		_toast("שחית בים עם הילדים. איזה יום!" if with_kids else "שחית בים. מרענן ובריא."))


# ------------------------------------------------- working as a police officer ----

func _start_duty() -> void:
	if _shabbat_block():
		return
	if energy < 20.0:
		_toast("אתה עייף מדי למשמרת. לך לישון קודם.")
		_play("no")
		return
	if kids != 0:
		_toast("קודם מחזירים את הילדים הביתה.")
		return
	on_duty = true
	duty_done = 0
	beat = rng.randi_range(0, BEATS.size() - 1)
	duty_cap.visible = true
	_close_panel()
	_play("pay")
	_toast("התחלת משמרת! לך אל העמוד הכחול המהבהב, ועצור אנשים רעים באדום: פשוט תיגע בהם.")
	_place_marker()


func _end_duty() -> void:
	on_duty = false
	duty_cap.visible = false
	if beat_marker != null:
		beat_marker.visible = false
	_close_panel()
	_toast("סיימת את המשמרת. ביצעת %d משימות. כל הכבוד!" % duty_done)
	_update_hud()


func _place_marker() -> void:
	if beat_marker == null:
		beat_marker = Node3D.new()
		add_child(beat_marker)
		var beam := _emit_mat(Color(0.2, 0.5, 1.0))
		var pillar := CylinderMesh.new()
		pillar.top_radius = 0.5
		pillar.bottom_radius = 0.5
		pillar.height = 9.0
		var mi := MeshInstance3D.new()
		mi.mesh = pillar
		mi.material_override = beam
		mi.position.y = 4.5
		beat_marker.add_child(mi)
		_box(Vector3(2.4, 0.05, 2.4), Vector3(0, 0.04, 0), beam, beat_marker)
	beat_marker.position = BEATS[beat]
	beat_marker.visible = true


func _emit_mat(color: Color) -> StandardMaterial3D:
	var m := _mat(color)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.55
	return m


func _watch_duty() -> void:
	if not on_duty:
		return
	if _is_shabbat() or energy < 5.0 or clock >= 23.0:
		_end_duty()
		return
	beat_marker.visible = int(Time.get_ticks_msec() / 400.0) % 4 != 0
	var flat := Vector3(player.position.x, 0, player.position.z)
	if not inside and flat.distance_to(BEATS[beat]) < (4.5 if driving else 2.6):
		var pay := int(24 * wage / 40.0)
		money += pay
		duty_done += 1
		parcels += 1
		_play("pay")
		if parcels % 40 == 0:
			wage += 8
			_toast("נקודת סיור הושלמה: ₪%d. וגם קיבלת העלאה בכל העבודות!" % pay)
		else:
			_toast("נקודת סיור הושלמה: הרווחת ₪%d. לנקודה הבאה!" % pay)
		var next := beat
		while next == beat:
			next = rng.randi_range(0, BEATS.size() - 1)
		beat = next
		_place_marker()
		_update_hud()


func _arrest(t: Person) -> void:
	t.down = 60.0
	t.chasing = false
	t.root.rotation.z = PI * 0.5
	duty_done += 1
	money += 90
	_play("pay")
	_toast("עצרת איש רע! הניידת לקחה אותו, והרווחת ₪90.")
	_update_hud()


# ------------------------------------------------ materials and lighting ----

## A photographed surface (colour and normal map), tinted to the colour you ask for.
## It is mapped in world space, so it tiles across any box without stretching. Static things only.
func _tex(kind: String, want: Color, tile: float) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [kind, want.to_html(false), tile]
	if tex_cache.has(key):
		return tex_cache[key]
	var m := StandardMaterial3D.new()
	var avg: Color = TEX_AVG[kind]
	m.albedo_color = Color(minf(want.r / avg.r, 2.6), minf(want.g / avg.g, 2.6), minf(want.b / avg.b, 2.6))
	m.albedo_texture = load("res://tex/%s_d.jpg" % kind)
	m.normal_enabled = true
	m.normal_texture = load("res://tex/%s_n.jpg" % kind)
	m.normal_scale = 0.9
	m.roughness = 1.0
	m.metallic_specular = 0.15                # no glints: tiny highlights on bumpy surfaces flicker as you move
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(tile, tile, tile)
	tex_cache[key] = m
	return m


## Moving water: two layers of ripples sliding over each other, brighter where you look across it.
func _water() -> ShaderMaterial:
	if water_mat != null:
		return water_mat
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var ripples := NoiseTexture2D.new()
	ripples.width = 256
	ripples.height = 256
	ripples.seamless = true
	ripples.as_normal_map = true
	ripples.bump_strength = 6.0
	ripples.noise = noise
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform sampler2D ripples : hint_normal, repeat_enable, filter_linear_mipmap;
uniform vec3 deep : source_color = vec3(0.04, 0.22, 0.42);
uniform vec3 shallow : source_color = vec3(0.12, 0.42, 0.58);
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = world_pos.xz * 0.07;
	vec3 a = texture(ripples, uv + TIME * vec2(0.021, 0.013)).rgb;
	vec3 b = texture(ripples, uv * 1.9 - TIME * vec2(0.017, 0.024)).rgb;
	NORMAL_MAP = mix(a, b, 0.5);
	NORMAL_MAP_DEPTH = 1.4;
	float glance = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(deep, shallow, clamp(glance + (a.r - 0.5) * 0.6, 0.0, 1.0));
	ROUGHNESS = 0.18;
	SPECULAR = 0.4;
}
"""
	water_mat = ShaderMaterial.new()
	water_mat.shader = shader
	water_mat.set_shader_parameter("ripples", ripples)
	return water_mat


## Do not draw small things that are far away.
func _limit(node: Node, far: float) -> void:
	var g := node as GeometryInstance3D
	if g != null:
		g.visibility_range_end = far
		g.visibility_range_end_margin = 6.0
	for child in node.get_children():
		_limit(child, far)


func _build_lights() -> void:
	for k in 6:
		var lamp := OmniLight3D.new()
		lamp.omni_range = 16.0
		lamp.light_color = Color(1.0, 0.86, 0.6)
		lamp.light_energy = 0.0
		lamp.visible = false
		add_child(lamp)
		night_lights.append(lamp)
	headlight = SpotLight3D.new()
	headlight.spot_range = 34.0
	headlight.spot_angle = 40.0
	headlight.light_energy = 9.0
	headlight.light_color = Color(1.0, 0.96, 0.85)
	headlight.visible = false
	add_child(headlight)


## At night the street lamps nearest to you really light the ground, and the car has headlights.
func _update_lights(delta: float) -> void:
	var dark := clampf(1.0 - clampf(sin((clock - 6.0) / 12.0 * PI) * 2.5 + 0.25, 0.0, 1.0), 0.0, 1.0)
	if inside:
		dark = 0.0
	headlight.visible = driving and dark > 0.3
	if headlight.visible:
		var nose := Vector3(sin(car_heading), 0, cos(car_heading))
		headlight.position = player.position + nose * 2.0 + Vector3(0, 1.1, 0)
		headlight.look_at(headlight.position + nose * 10.0 + Vector3(0, -2.2, 0))
	light_tick -= delta
	if light_tick > 0.0:
		return
	light_tick = 0.5
	if dark <= 0.25:
		for lamp in night_lights:
			lamp.visible = false
		return
	var near_lamps: Array = []
	for body in props:
		if body.freeze and body.has_meta("lamp"):
			near_lamps.append([body.global_position.distance_to(player.position), body.global_position])
	near_lamps.sort()
	near_lamps = near_lamps.slice(0, night_lights.size())
	# A light stays on its lamp while that lamp is still one of the nearest, so lights do not hop about.
	var free_lights: Array[OmniLight3D] = []
	for lamp in night_lights:
		var keep := false
		for k in near_lamps.size():
			var at: Vector3 = near_lamps[k][1]
			if lamp.visible and lamp.position.distance_to(at + Vector3(0, 3.9, 0)) < 0.1:
				near_lamps.remove_at(k)
				keep = true
				break
		if not keep:
			free_lights.append(lamp)
		lamp.light_energy = dark * 2.4
	for lamp in free_lights:
		lamp.visible = not near_lamps.is_empty()
		if lamp.visible:
			var at: Vector3 = near_lamps.pop_front()[1]
			lamp.position = at + Vector3(0, 3.9, 0)


## A ready-made model from the models folder, added to the scene (or to "into").
## Returns null when the file is missing, and the caller then builds the simple shape instead.
func _model(path: String, into: Node = null) -> Node3D:
	var file := "res://models/%s.glb" % path
	if not model_cache.has(file):
		model_cache[file] = load(file) if ResourceLoader.exists(file) else null
	var scene: PackedScene = model_cache[file]
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	if into == null:
		add_child(node)
	else:
		into.add_child(node)
	return node


## The kit's leaves are turquoise; paint them a natural green (trunks keep their own colour).
func _regreen(node: Node, green: Color) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for k in mi.mesh.get_surface_count():
			var was := mi.mesh.surface_get_material(k) as BaseMaterial3D
			if was != null and was.albedo_color.b > was.albedo_color.r * 1.15:
				mi.set_surface_override_material(k, _mat(green))
	for child in node.get_children():
		_regreen(child, green)


# ------------------------------------------------------- crash effects ----

## A split second of slow motion, so a big hit really lands.
func _hit_stop(seconds: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.15
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


## Bits of car (bumper, door, wheel, panel) fly off, bounce about on the road and are swept up after a while.
func _car_parts(pos: Vector3, dir: Vector3, impact: float) -> void:
	var kinds: Array[String] = ["debris-bumper", "debris-tire", "debris-plate-a", "debris-door"]
	for k in clampi(int(impact / 5.0), 1, 4):
		var part := RigidBody3D.new()
		part.mass = 6.0
		part.collision_layer = 2
		part.collision_mask = 1
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.7, 0.3, 0.5)
		cs.shape = shape
		part.add_child(cs)
		var look := _model("cars/" + kinds[(k + rng.randi()) % kinds.size()], part)
		if look != null:
			look.scale = Vector3.ONE * 1.4
		else:
			_box(Vector3(0.6, 0.2, 0.4), Vector3.ZERO, _mat(Color(0.7, 0.7, 0.74)), part)
		part.position = pos + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.0, 0.5), rng.randf_range(-0.6, 0.6))
		add_child(part)
		var out := (dir + Vector3(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8))).normalized()
		part.apply_central_impulse((out * rng.randf_range(3.0, 6.0) + Vector3(0, rng.randf_range(4.0, 7.5), 0)) * part.mass)
		part.apply_torque_impulse(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 14.0)
		get_tree().create_timer(7.0).timeout.connect(part.queue_free)


## A tree that is hit creaks, whips back and forth, and drops a shower of leaves.
func _shake_tree(tree: Node3D, dir: Vector3, impact: float) -> void:
	if not is_instance_valid(tree):
		return
	_play("crack")
	var lean := clampf(impact / 40.0, 0.08, 0.38)
	var tilt := Vector3(dir.z, 0, -dir.x) * lean           # tips away from the car
	var yaw := tree.rotation.y
	var sway := create_tween()
	sway.tween_property(tree, "rotation", Vector3(tilt.x, yaw, tilt.z), 0.08)
	sway.tween_property(tree, "rotation", Vector3(-tilt.x * 0.6, yaw, -tilt.z * 0.6), 0.22)
	sway.tween_property(tree, "rotation", Vector3(tilt.x * 0.3, yaw, tilt.z * 0.3), 0.22)
	sway.tween_property(tree, "rotation", Vector3(0, yaw, 0), 0.3)
	_leaf_burst(tree.position, impact)


## Little yellow stars that circle the head of someone who has been knocked over.
func _dizzy_stars(parent: Node3D, height: float) -> Node3D:
	var ring := Node3D.new()
	ring.position = Vector3(0, height, 0)
	var gold := _mat(Color(1.0, 0.85, 0.15))
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.8, 0.1)
	gold.emission_energy_multiplier = 0.8
	for k in 4:
		var a := k * TAU / 4.0
		_box(Vector3(0.1, 0.1, 0.1), Vector3(cos(a) * 0.38, 0, sin(a) * 0.38), gold, ring).rotation = Vector3(0.6, a, 0.6)
	parent.add_child(ring)
	return ring


# ----------------------------------------------------------- hill farm ----

## The look of the hill-farm boys: a big knitted kippah, long sidelocks, a hoodie and tzitzit.
func _hill_look(p: Person, hoodie: Color, kippah: Color, hair: Color) -> void:
	var cloth := _mat(hoodie)
	_ball(0.17, Vector3(0, 1.56, -0.14), cloth, p.root, Vector3(1.15, 0.9, 0.8))           # the hood, down on the back
	_box(Vector3(0.3, 0.13, 0.03), Vector3(0, 1.08, 0.172), _mat(hoodie.darkened(0.2)), p.root)   # front pocket
	for sx: float in [-0.04, 0.04]:
		_box(Vector3(0.012, 0.17, 0.012), Vector3(sx, 1.4, 0.19), _mat(Color(0.95, 0.95, 0.95)), p.root)   # hood strings
	_ball(0.165, Vector3(0, 1.915, -0.03), _mat(kippah), p.root, Vector3(1.0, 0.36, 1.0))    # big knitted kippah
	_ball(0.168, Vector3(0, 1.9, -0.03), _mat(Color(0.95, 0.95, 0.9)), p.root, Vector3(1.0, 0.16, 1.0))   # its white rim
	var lock := _mat(hair)
	for sx: float in [-0.185, 0.185]:                                                   # sidelocks
		_cap(0.024, 0.24, Vector3(sx, 1.64, 0.07), lock, p.root)
		_ball(0.03, Vector3(sx, 1.53, 0.075), lock, p.root)
		for sz: float in [-0.12, 0.12]:                                                 # tzitzit
			_box(Vector3(0.02, 0.3, 0.02), Vector3(sx * 1.08, 0.86, sz), _mat(Color(1, 1, 1)), p.root)


func _hill_boy(hoodie: Color, kippah: Color, hair_pick: int, size: float) -> Person:
	var hairs: Array[Color] = [Color(0.12, 0.09, 0.07), Color(0.3, 0.19, 0.1), Color(0.55, 0.38, 0.18), Color(0.85, 0.7, 0.4)]
	var p := _make_person(hoodie, Color(0.28, 0.33, 0.45), Person.new(), 0, hair_pick)
	_hill_look(p, hoodie, kippah, hairs[hair_pick])
	p.root.scale = Vector3.ONE * size
	return p


## Legs either side and hands forward, for sitting on a donkey or an ATV.
func _sit_astride(p: Person) -> void:
	p.limbs[0].rotation = Vector3(-1.0, 0, -0.5)
	p.limbs[1].rotation = Vector3(-1.0, 0, 0.5)
	p.limbs[2].rotation.x = -1.0
	p.limbs[3].rotation.x = -1.0
	p.joints[0].rotation.x = 1.1
	p.joints[1].rotation.x = 1.1


func _leg(parent: Node3D, pos: Vector3, length: float, thick: float, mat: Material, legs: Array[Node3D]) -> void:
	var hip := Node3D.new()
	hip.position = pos
	parent.add_child(hip)
	_box(Vector3(thick, length, thick), Vector3(0, -length * 0.5, 0), mat, hip)
	legs.append(hip)


func _make_beast(kind: String) -> Roamer:
	var r := Roamer.new()
	r.kind = kind
	r.node = Node3D.new()
	var n := r.node
	match kind:
		"sheep":
			var wool := _mat(Color(0.93, 0.91, 0.84))
			var face := _mat(Color(0.2, 0.17, 0.15))
			_ball(0.4, Vector3(0, 0.68, 0), wool, n, Vector3(1.0, 0.9, 1.4))
			_ball(0.22, Vector3(0, 0.95, 0.38), wool, n)
			_ball(0.15, Vector3(0, 0.88, 0.62), face, n, Vector3(0.85, 0.95, 1.3))
			for sx: float in [-0.15, 0.15]:
				_ball(0.06, Vector3(sx, 0.93, 0.55), face, n, Vector3(1.4, 0.5, 0.8))
				for sz: float in [-0.32, 0.32]:
					_leg(n, Vector3(sx, 0.42, sz), 0.42, 0.08, face, r.legs)
			r.label = "כבשה"
			r.voice = "baa"
			r.speed = 0.7
		"cow":
			var hide := _mat(Color(0.96, 0.96, 0.94))
			var patch := _mat(Color(0.14, 0.11, 0.1) if rng.randf() < 0.6 else Color(0.5, 0.3, 0.16))
			_cap(0.5, 1.9, Vector3(0, 1.1, 0), hide, n).rotation.x = PI * 0.5
			_ball(0.3, Vector3(0.2, 1.3, 0.2), patch, n, Vector3(1.2, 0.8, 1.4))
			_ball(0.25, Vector3(-0.25, 1.25, -0.4), patch, n, Vector3(1.0, 0.8, 1.2))
			_ball(0.3, Vector3(0, 1.35, 1.15), hide, n, Vector3(0.9, 0.9, 1.3))
			_ball(0.14, Vector3(0, 1.25, 1.5), _mat(Color(0.95, 0.7, 0.7)), n, Vector3(1.3, 0.9, 0.8))
			for sx: float in [-0.3, 0.3]:
				for sz: float in [-0.6, 0.6]:
					_leg(n, Vector3(sx, 0.7, sz), 0.7, 0.16, hide, r.legs)
			r.label = "פרה"
			r.voice = "moo"
			r.speed = 0.5
		"dog":
			var coat := _mat(Color(0.75, 0.6, 0.4))
			_cap(0.17, 0.75, Vector3(0, 0.45, 0), coat, n).rotation.x = PI * 0.5
			_ball(0.16, Vector3(0, 0.62, 0.42), coat, n, Vector3(0.9, 0.9, 1.2))
			_ball(0.07, Vector3(0, 0.58, 0.6), _mat(Color(0.15, 0.12, 0.1)), n)
			_cap(0.04, 0.35, Vector3(0, 0.62, -0.42), coat, n).rotation.x = -0.8
			for sx: float in [-0.1, 0.1]:
				_ball(0.06, Vector3(sx, 0.75, 0.38), coat, n, Vector3(0.6, 1.2, 0.6))
				for sz: float in [-0.25, 0.25]:
					_leg(n, Vector3(sx, 0.32, sz), 0.32, 0.06, coat, r.legs)
			r.label = "כלב הרועים"
			r.voice = "woof"
			r.speed = 1.6
		"atv":
			_atv_body(n, Color(0.2, 0.45, 0.2))
			r.label = "נהג הטרקטורון"
			r.voice = "honk"
			r.speed = 6.0
		_:  # donkey or mule
			var mule := kind == "mule"
			var coat := _mat(Color(0.42, 0.3, 0.22) if mule else Color(0.6, 0.57, 0.53))
			var pale := _mat(Color(0.88, 0.85, 0.8))
			_cap(0.3, 1.35, Vector3(0, 1.0, 0), coat, n).rotation.x = PI * 0.5
			_cap(0.16, 0.6, Vector3(0, 1.28, 0.62), coat, n).rotation.x = 0.8          # neck
			_ball(0.19, Vector3(0, 1.5, 0.88), coat, n, Vector3(0.85, 0.9, 1.5))            # head
			_ball(0.12, Vector3(0, 1.44, 1.1), pale, n, Vector3(0.9, 0.85, 1.0))            # pale muzzle
			_ball(0.3, Vector3(0, 0.84, 0), pale, n, Vector3(0.75, 0.3, 1.6))               # pale belly
			for sx: float in [-0.1, 0.1]:
				_cap(0.045, 0.36, Vector3(sx, 1.78, 0.8), coat, n).rotation.z = -sx * 2.0   # long ears
				_ball(0.03, Vector3(sx * 1.4, 1.55, 1.0), _mat(Color(0.08, 0.07, 0.07)), n)
				for sz: float in [-0.48, 0.48]:
					_leg(n, Vector3(sx * 1.9, 0.78, sz), 0.78, 0.11, coat, r.legs)
			_cap(0.04, 0.5, Vector3(0, 0.85, -0.72), _mat(Color(0.2, 0.17, 0.15)), n)       # tail
			# A woven saddle blanket.
			_box(Vector3(0.66, 0.05, 0.7), Vector3(0, 1.31, -0.05), _mat(Color(0.7, 0.2, 0.18)), n)
			_box(Vector3(0.67, 0.052, 0.14), Vector3(0, 1.311, -0.05), _mat(Color(0.95, 0.85, 0.5)), n)
			if mule:
				n.scale = Vector3.ONE * 1.12
			r.label = "פרד" if mule else "חמור"
			r.voice = "bray"
			r.speed = 1.5
	_limit(n, 110.0)
	add_child(n)
	roamers.append(r)
	return r


func _atv_body(n: Node3D, color: Color) -> void:
	var paint := _mat(color)
	var black := _mat(Color(0.09, 0.09, 0.1))
	var grey := _mat(Color(0.35, 0.36, 0.4))
	_box(Vector3(0.75, 0.3, 1.7), Vector3(0, 0.62, 0), grey, n)                    # frame
	_box(Vector3(0.6, 0.16, 0.8), Vector3(0, 0.88, -0.25), black, n)               # seat
	_box(Vector3(0.7, 0.26, 0.6), Vector3(0, 0.9, 0.5), paint, n)                  # tank and nose
	for sx: float in [-0.52, 0.52]:
		_box(Vector3(0.42, 0.07, 0.75), Vector3(sx, 0.8, 0.72), paint, n)          # mudguards
		_box(Vector3(0.42, 0.07, 0.75), Vector3(sx, 0.8, -0.72), paint, n)
		for sz: float in [-0.72, 0.72]:
			_cap(0.32, 0.66, Vector3(sx * 1.05, 0.34, sz), black, n).rotation.z = PI * 0.5   # fat tyres
	_box(Vector3(0.9, 0.05, 0.05), Vector3(0, 1.22, 0.42), black, n)               # handlebars
	_box(Vector3(0.06, 0.34, 0.06), Vector3(0, 1.06, 0.45), grey, n)
	_box(Vector3(0.26, 0.14, 0.06), Vector3(0, 0.98, 0.84), lamp_mat, n)           # headlamp
	_box(Vector3(0.7, 0.04, 0.5), Vector3(0, 0.82, -0.95), grey, n)                # rear rack


func _put_rider(r: Roamer, boy: Person, seat: Vector3) -> void:
	_sit_astride(boy)
	boy.root.position = seat
	r.node.add_child(boy.root)
	r.rider = boy
	_limit(boy.root, 110.0)


func _build_hill_farm() -> void:
	var first_new := get_child_count()
	var first_roamer := roamers.size()
	var earth := _tex("sand", Color(0.52, 0.4, 0.26), 0.2)
	var stone := _tex("plaster", Color(0.72, 0.68, 0.58), 0.5)
	var wood := _mat(Color(0.45, 0.32, 0.2))
	# Dirt tracks: one loop round the pasture, one round the farmyard.
	var loops: Array = [[96.0, 118.0], [122.0, 146.0]]
	for loop: Array in loops:
		var x0: float = loop[0]
		var x1: float = loop[1]
		for z: float in [11.0, 32.0]:
			_box(Vector3(x1 - x0 + 2.4, 0.06, 2.4), Vector3((x0 + x1) * 0.5, 0.03, z), earth)
		for x: float in [x0, x1]:
			_box(Vector3(2.4, 0.06, 18.6), Vector3(x, 0.03, 21.5), earth)
	# Low dry-stone terraces along the south edge, with olive trees behind them.
	for k in 6:
		var wx := 99.0 + k * 9.0
		_box(Vector3(7.0, 0.6, 0.7), Vector3(wx, 0.3, 34.2), stone)
		_solid(Vector3(7.0, 0.6, 0.7), Vector3(wx, 0.3, 34.2))
		var olive := _model("nature/tree_oak")
		if olive != null:
			olive.position = Vector3(wx, 0, 35.6)
			olive.rotation.y = rng.randf() * TAU
			olive.scale = Vector3(4.2, 2.9, 4.2)
			_regreen(olive, Color(0.42, 0.5, 0.36))
			_limit(olive, 190.0)
	# The pasture: a flock, a watering trough, a shepherd boy and his dog.
	for k in 7:
		var ewe := _make_beast("sheep")
		ewe.home = Vector3(107, 0, 21.5)
		ewe.reach = 6.5
		ewe.node.position = ewe.home + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
		ewe.node.rotation.y = rng.randf() * TAU
		if k >= 5:
			ewe.node.scale = Vector3.ONE * 0.6          # lambs
			ewe.label = "טלה"
	for k in 2:
		var cow := _make_beast("cow")
		cow.home = Vector3(103 + k * 8, 0, 26.0)
		cow.reach = 3.0
		cow.node.position = cow.home
		cow.node.rotation.y = 1.0 + k * 2.0
	var dog := _make_beast("dog")
	dog.home = Vector3(107, 0, 21.5)
	dog.reach = 8.0
	dog.node.position = Vector3(110, 0, 17)
	_box(Vector3(2.2, 0.45, 0.7), Vector3(100.5, 0.23, 15.0), wood)
	_box(Vector3(2.0, 0.06, 0.5), Vector3(100.5, 0.44, 15.0), _mat(Color(0.3, 0.55, 0.8)))
	_solid(Vector3(2.2, 0.6, 0.7), Vector3(100.5, 0.3, 15.0))
	var shepherd := _hill_boy(Color(0.55, 0.6, 0.35), Color(0.2, 0.35, 0.6), 2, 0.86)
	shepherd.speed = 0.0
	shepherd.root.position = Vector3(113.5, 0, 15.5)
	shepherd.root.rotation.y = -2.2
	_cap(0.03, 1.7, Vector3(0.36, 0.85, 0.12), wood, shepherd.root)           # his staff
	_add_townsperson(shepherd)
	shepherd.name = "הרועה אליה"
	# The farmyard: two caravans with a pergola, a water tank, hay, a vineyard.
	for k in 2:
		var at := Vector3(129.5 + k * 9.5, 0, 27.5)
		for sx: float in [-2.6, 2.6]:
			_box(Vector3(0.5, 0.4, 2.2), at + Vector3(sx, 0.2, 0), _mat(Color(0.5, 0.5, 0.52)))    # blocks it stands on
		_box(Vector3(7.0, 2.5, 2.8), at + Vector3(0, 1.65, 0), _mat(Color(0.93, 0.92, 0.88)))
		_box(Vector3(7.2, 0.14, 3.0), at + Vector3(0, 2.97, 0), _mat(Color(0.6, 0.62, 0.65)))
		_box(Vector3(0.9, 1.9, 0.08), at + Vector3(-1.6, 1.4, -1.42), _mat(Color(0.4, 0.28, 0.18)))
		for sx: float in [0.4, 2.2]:
			_box(Vector3(1.1, 0.8, 0.08), at + Vector3(sx, 1.9, -1.42), window_mat)
		_box(Vector3(1.4, 0.2, 0.9), at + Vector3(-1.6, 0.3, -1.9), wood)                          # step
		_solid(Vector3(7.0, 3.0, 2.8), at + Vector3(0, 1.5, 0))
	# Pergola with a table between the caravans' doors.
	for sx: float in [-1.6, 1.6]:
		for sz: float in [-1.2, 1.2]:
			_box(Vector3(0.12, 2.3, 0.12), Vector3(134.3 + sx, 1.15, 23.2 + sz), wood)
	for k in 6:
		_box(Vector3(3.6, 0.06, 0.2), Vector3(134.3, 2.33, 22.1 + k * 0.44), wood)
	_box(Vector3(1.8, 0.08, 0.9), Vector3(134.3, 0.75, 23.2), wood)
	for sx: float in [-0.75, 0.75]:
		_box(Vector3(0.1, 0.72, 0.8), Vector3(134.3 + sx, 0.36, 23.2), wood)
	_solid(Vector3(1.8, 0.8, 0.9), Vector3(134.3, 0.4, 23.2))
	# Water tank on a stand.
	for sx: float in [-0.7, 0.7]:
		for sz: float in [-0.7, 0.7]:
			_box(Vector3(0.14, 2.4, 0.14), Vector3(143.5 + sx, 1.2, 23.5 + sz), _mat(Color(0.35, 0.36, 0.4)))
	_cap(1.0, 2.2, Vector3(143.5, 3.4, 23.5), _mat(Color(0.12, 0.12, 0.13)), self)
	_solid(Vector3(1.8, 4.5, 1.8), Vector3(143.5, 2.25, 23.5))
	# Hay bales.
	for k in 5:
		_cap(0.6, 1.5, Vector3(125.2 + (k % 3) * 1.4, 0.6 + (k / 3) * 1.1, 28.6), _mat(Color(0.9, 0.78, 0.35)), self).rotation.z = PI * 0.5
	_solid(Vector3(4.2, 1.6, 1.4), Vector3(126.6, 0.8, 28.6))
	# The vineyard: rows of posts and wires heavy with grapes.
	var vine := _mat(Color(0.25, 0.48, 0.2))
	var grape := _mat(Color(0.38, 0.15, 0.45))
	for row in 3:
		var z := 14.2 + row * 2.3
		_box(Vector3(17.0, 0.03, 0.03), Vector3(134.5, 1.25, z), _mat(Color(0.6, 0.6, 0.6)))
		for k in 8:
			var x := 126.5 + k * 2.3
			_box(Vector3(0.1, 1.4, 0.1), Vector3(x, 0.7, z), wood)
			_ball(0.45, Vector3(x + 1.1, 1.05, z), vine, self, Vector3(1.9, 0.8, 0.6))
			_ball(0.11, Vector3(x + 0.9, 0.78, z + 0.12), grape, self, Vector3(1.0, 1.5, 1.0))
			_ball(0.11, Vector3(x + 1.4, 0.8, z - 0.12), grape, self, Vector3(1.0, 1.5, 1.0))
	# Riders: two boys on donkeys and one on a mule plod round the pasture; a youth rides the ATV round the yard.
	var ride: Array[Vector3] = [Vector3(96, 0, 11), Vector3(118, 0, 11), Vector3(118, 0, 32), Vector3(96, 0, 32)]
	var looks: Array = [[Color(0.3, 0.42, 0.62), Color(0.85, 0.85, 0.8), 1, 0.74], [Color(0.62, 0.25, 0.22), Color(0.25, 0.45, 0.3), 3, 0.7], [Color(0.4, 0.4, 0.44), Color(0.55, 0.3, 0.55), 0, 0.8]]
	for k in 3:
		var mount := _make_beast("mule" if k == 2 else "donkey")
		mount.path = ride
		mount.step = (k + 1) % 4
		mount.node.position = ride[k].lerp(ride[(k + 1) % 4], 0.3)
		var look: Array = looks[k]
		var boy := _hill_boy(look[0], look[1], look[2], look[3])
		_put_rider(mount, boy, Vector3(0, 1.36 - 0.92 * float(look[3]), -0.05))
		mount.label = "ילד שרוכב על " + mount.label
	var quad := _make_beast("atv")
	quad.path = [Vector3(146, 0, 11), Vector3(122, 0, 11), Vector3(122, 0, 32), Vector3(146, 0, 32)]
	quad.node.position = Vector3(140, 0, 11)
	var youth := _hill_boy(Color(0.2, 0.22, 0.26), Color(0.9, 0.9, 0.85), 1, 0.95)
	_put_rider(quad, youth, Vector3(0, 0.05, -0.25))
	# Two more hill boys walk in town like everyone else.
	for k in 2:
		var boy := _hill_boy([Color(0.25, 0.5, 0.45), Color(0.6, 0.45, 0.2)][k], [Color(0.5, 0.2, 0.2), Color(0.2, 0.3, 0.55)][k], k + 1, 0.82)
		boy.root.position = Vector3(60.0 + k * 40.0, 0, 6.2)
		boy.dir = 1.0 if k == 0 else -1.0
		_add_townsperson(boy)
		boy.name = ["נתנאל", "אביתר"][k]
	# Sign and the spot where you can lend a hand.
	_sign("חוות הגבעה", Vector3(120, 4.3, 9.4), 96)
	for sx: float in [-3.2, 3.2]:
		_box(Vector3(0.2, 4.0, 0.2), Vector3(120 + sx, 2.0, 9.4), wood)
	_box(Vector3(6.6, 0.25, 0.2), Vector3(120, 3.6, 9.4), wood)
	_box(Vector3(2.4, 0.05, 1.6), Vector3(120, 0.075, 13.4), _mat(Color(0.95, 0.75, 0.2)))
	var hill := Place.new()
	hill.key = "hill"
	hill.title = "חוות הגבעה"
	hill.prompt = "לעזור בחוות הגבעה"
	hill.door = Vector3(120, 0, 13.4)
	places.append(hill)
	# Everything above was laid out on flat ground; now carry it up onto the hill.
	var lift := Vector3(0, HILL_H, 3.0)
	for k in range(first_new, get_child_count()):
		var thing := get_child(k) as Node3D
		if thing != null and thing.position.x > 90.0 and thing.position.x < 150.0 and thing.position.z > 8.0:
			thing.position += lift
	for k in range(first_roamer, roamers.size()):
		var r := roamers[k]
		r.home += lift
		r.target = r.node.position
		for j in r.path.size():
			r.path[j] += lift
	hill.door += lift
	# Your own caravan on the farm: the same home, with a door up here.
	var mine := Place.new()
	mine.key = "home"
	mine.title = "הקרוואן שלי בחווה"
	mine.prompt = "להיכנס הביתה"
	mine.room = ""
	mine.door = Vector3(127.9, HILL_H, 28.2)
	places.append(mine)
	_box(Vector3(2.0, 0.05, 1.3), mine.door + Vector3(0, 0.08, 0), _mat(Color(0.3, 0.6, 0.9)))
	_tag("הבית שלי", mine.door + Vector3(0, 3.4, 0.6), 44)
	_build_hill()
	# Sheep thieves in red lurk round the hill. Shoot at them, run, or phone the police.
	for k in 5:
		var t := _make_person(Color(0.85, 0.08, 0.08), Color(0.6, 0.05, 0.05))
		t.hill = true
		t.name = "גנב כבשים"
		add_child(t.root)
		t.root.position = _thug_point(t)
		t.target = t.root.position
		thugs.append(t)
	# The gear you wear once you join the hill boys.
	hill_gear = Node3D.new()
	me.root.add_child(hill_gear)
	var gear := Person.new()
	gear.root = hill_gear
	_hill_look(gear, Color(0.93, 0.93, 0.95), Color(0.2, 0.35, 0.65), Color(0.3, 0.19, 0.1))
	hill_gear.visible = false


func _update_roamers(delta: float) -> void:
	var resting := _is_shabbat()
	var mine := player.position if not inside else Vector3(0, 0, 9999)
	for idx in roamers.size():
		var r := roamers[idx]
		var n := r.node
		if r == my_donkey:
			continue
		if r.air:
			r.fly.y -= 22.0 * delta
			n.position += r.fly * delta
			n.rotation.x += r.spin * delta
			var floor_y := _ground_y(n.position.x, n.position.z)
			if n.position.y <= floor_y and r.fly.y < 0.0:
				n.position.y = floor_y
				if not r.bounced and r.fly.y < -5.0:
					r.bounced = true
					r.fly = Vector3(r.fly.x * 0.5, -r.fly.y * 0.4, r.fly.z * 0.5)
					r.spin *= 0.6
					_play("boing")
				else:
					r.air = false
					r.lying = 4.0
					n.rotation = Vector3(0, n.rotation.y, PI * 0.5)
					n.position.y = floor_y + 0.3
					_play("thump")
			continue
		if r.lying > 0.0:
			r.lying -= delta
			if r.lying <= 0.0:
				n.rotation = Vector3(0, n.rotation.y, 0)
				n.position.y = _ground_y(n.position.x, n.position.z)
				n.position.x = clampf(n.position.x, WEST + 2.0, EAST - 2.0)
				_play(r.voice)
			continue
		r.voice_cool -= delta
		var gap := mine - n.position
		gap.y = 0.0
		var d := gap.length()
		var goal := n.position
		var pace := r.speed
		if not r.path.is_empty():
			if resting:
				continue                      # no riding on Shabbat
			goal = r.path[r.step]
			if n.position.distance_to(goal) < 1.3:
				r.step = (r.step + 1) % r.path.size()
			if d < 4.5 and gap.dot(goal - n.position) > 0.0:
				pace = 0.0                    # wait for you to get out of the way
				if r.kind == "atv" and r.voice_cool <= 0.0:
					r.voice_cool = 4.0
					_play("honk")
		elif herding and r.kind == "sheep" and herd_stage != 1:
			# The flock trots after you, each ewe in her own place behind.
			goal = mine + Vector3(cos(idx * 2.4), 0, sin(idx * 2.4)) * (2.2 + (idx % 3) * 1.1)
			var gap_to := goal - n.position
			gap_to.y = 0.0
			pace = 0.0 if gap_to.length() < 0.8 else clampf(gap_to.length() * 1.6, 2.0, 10.5)
		else:
			var scare := 9.0 if driving and car_vel.length() > 3.0 else 3.0
			if herding and r.kind == "sheep":
				scare = 0.0                   # grazing: they are used to you
			if d < scare and r.kind != "dog":
				goal = n.position - gap.normalized() * 4.0          # scatter away from you
				pace = r.speed * (4.0 if driving else 2.2)
				if r.voice_cool <= 0.0:
					r.voice_cool = rng.randf_range(2.5, 5.0)
					_play(r.voice)
			else:
				r.wait -= delta
				if r.wait <= 0.0:
					r.wait = rng.randf_range(2.0, 7.0)
					r.target = r.home + Vector3(rng.randf_range(-r.reach, r.reach), 0, rng.randf_range(-r.reach, r.reach))
				goal = r.target
		var way := goal - n.position
		way.y = 0.0
		var moving := way.length() > 0.25 and pace > 0.0
		if moving:
			var dir := way.normalized()
			n.position += dir * pace * delta
			n.position.y = _ground_y(n.position.x, n.position.z)
			n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), 5.0 * delta)
			r.phase += delta * (4.0 + pace * 3.0)
		if r.path.is_empty() and not (herding and r.kind == "sheep" and herd_stage != 1):
			n.position.x = clampf(n.position.x, r.home.x - r.reach - 5.0, r.home.x + r.reach + 5.0)
			n.position.z = clampf(n.position.z, r.home.z - r.reach - 5.0, r.home.z + r.reach + 5.0)
		for k in r.legs.size():
			var swing := sin(r.phase + (0.0 if k % 3 == 0 else PI)) * 0.5 if moving else 0.0
			r.legs[k].rotation.x = lerp_angle(r.legs[k].rotation.x, swing, 10.0 * delta)
		# On foot you bump into them rather than walk through.
		if not driving and d < 0.9 and d > 0.01:
			player.position += gap.normalized() * (0.9 - d)


func _hill_job(doing: String, done: String, pay: int, thanks: String) -> void:
	_close_panel()
	if _shabbat_block():
		return
	if energy < 12.0:
		_toast("אתה עייף מדי בשביל זה עכשיו.")
		_play("no")
		return
	_time_skip(doing, func() -> void:
		_skip(1.0, "work")
		money += pay
		_play("pay")
		_toast(done % pay)
		for n in npcs:
			if n.name == "הרועה אליה":
				_say(n, thanks, 5.0))


func _herd_sheep() -> void:
	_close_panel()
	if _shabbat_block():
		return
	herding = true
	herd_stage = 0
	beacon.visible = true
	beacon.position = MEADOW + Vector3(0, 6.0, 0)
	_play("baa")
	_toast("יוצאים למרעה! הכבשים הולכות אחריך. רדו מההר והובל אותן לעמוד הירוק ביער, מדרום להר.")


func _pick_grapes() -> void:
	_hill_job("בוצרים ענבים בכרם...", "בצרת ארגזים של ענבים מתוקים. הרווחת ₪%d.", 15, "יישר כוח! יהיה יין טוב לקידוש.")


# ------------------------------------------------------- fewer draw calls ----

func _is_plain(mat: Material) -> bool:
	var m := mat as StandardMaterial3D
	return m != null and m.albedo_texture == null and not m.emission_enabled and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
		and m.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and m != lamp_mat and m != window_mat


func _paint() -> StandardMaterial3D:
	if paint_mat == null:
		paint_mat = StandardMaterial3D.new()
		paint_mat.vertex_color_use_as_albedo = true
		paint_mat.vertex_color_is_srgb = true
		paint_mat.roughness = 0.85
	return paint_mat


## Add one mesh, moved by `xf`, to the arrays of a bigger mesh that is being put together.
func _append_mesh(into: Array, mesh: Mesh, xf: Transform3D, color: Color, surface: int = 0) -> void:
	var arrays := mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null:
		index = arrays[Mesh.ARRAY_INDEX]
	else:
		for k in verts.size():
			index.append(k)
	var base: int = into[0].size()
	var turn := xf.basis.inverse().transposed()
	for k in verts.size():
		into[0].append(xf * verts[k])
		into[1].append((turn * normals[k]).normalized())
		into[2].append(color)
	for k in index:
		into[3].append(base + k)


func _finish_mesh(parts: Array, mat: Material) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = parts[0]
	arrays[Mesh.ARRAY_NORMAL] = parts[1]
	arrays[Mesh.ARRAY_COLOR] = parts[2]
	arrays[Mesh.ARRAY_INDEX] = parts[3]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


func _new_parts() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedColorArray(), PackedInt32Array()]


## Melt the plain-coloured pieces directly under `node` into a single mesh.
func _fuse(node: Node3D) -> void:
	var parts := _new_parts()
	var done: Array[Node] = []
	for child in node.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.get_child_count() > 0 or not mi.visible or not _is_plain(mi.material_override):
			continue
		_append_mesh(parts, mi.mesh, mi.transform, (mi.material_override as StandardMaterial3D).albedo_color)
		done.append(mi)
	if done.size() < 2:
		return
	for mi in done:
		node.remove_child(mi)
		mi.free()
	node.add_child(_finish_mesh(parts, _paint()))


## Once the town is built, join its thousands of fixed boxes into a few big meshes per stretch of street.
func _merge_static() -> void:
	var groups := {}
	for child in get_children():
		var mi := child as MeshInstance3D
		if mi == null or not (mi.mesh is BoxMesh) or mi.get_child_count() > 0 or not mi.visible or mi.has_meta("keep"):
			continue
		if mi.position.z < -100.0 or mi.material_override == null or mi.visibility_range_end > 0.0:
			continue                              # the far-away rooms keep their separate pieces
		if not mi.transform.basis.is_equal_approx(Basis.IDENTITY):
			continue
		var size: Vector3 = (mi.mesh as BoxMesh).size
		if maxf(size.x, size.z) > 60.0:
			continue                              # the ground, the roads, the sea
		var plain := _is_plain(mi.material_override)
		var key := "%d|%d|%s" % [int(floor(mi.position.x / 45.0)), int(floor(mi.position.z / 45.0)), "plain" if plain else str(mi.material_override.get_instance_id())]
		if not groups.has(key):
			groups[key] = [_new_parts(), _paint() if plain else mi.material_override, []]
		var color := (mi.material_override as StandardMaterial3D).albedo_color if plain else Color.WHITE
		_append_mesh(groups[key][0], mi.mesh, mi.transform, color)
		groups[key][2].append(mi)
	for key: String in groups:
		var group: Array = groups[key]
		if group[2].size() < 2:
			continue
		for mi: MeshInstance3D in group[2]:
			remove_child(mi)
			mi.free()
		add_child(_finish_mesh(group[0], group[1]))
	for key: String in pine_groups:
		var wood := _finish_mesh(pine_groups[key], _paint())
		wood.visibility_range_end = 190.0
		add_child(wood)
	pine_groups.clear()


# ------------------------------------------------------------ the hill ----

## Height of the ground. Flat everywhere except the hill: a flat top with steep sides and one road up from the west.
func _ground_y(x: float, z: float) -> float:
	if x < 76.0 or x > 157.0 or z < 5.0 or z > 46.5:
		return 0.0
	var dx := maxf(maxf(94.0 - x, x - 150.0), 0.0)
	var dz := maxf(maxf(12.0 - z, z - 39.5), 0.0)
	var t := clampf(1.0 - sqrt(dx * dx + dz * dz) / 5.0, 0.0, 1.0)
	var h := HILL_H * t * t * (3.0 - 2.0 * t)
	if x < 95.0 and z > 18.0 and z < 33.0:
		var side := clampf(minf(z - 18.0, 33.0 - z) / 2.5, 0.0, 1.0)
		h = maxf(h, HILL_H * clampf((x - 80.0) / 14.0, 0.0, 1.0) * side)
	return h


func _build_hill() -> void:
	var grass := SurfaceTool.new()
	var road := SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell := 1.5
	var x := 76.0
	while x < 157.0:
		var z := 5.0
		while z < 46.5:
			var corners: Array[Vector3] = []
			var top := 0.0
			for c: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px := x + c.x * cell
				var pz := z + c.y * cell
				var h := _ground_y(px, pz)
				top = maxf(top, h)
				corners.append(Vector3(px, h if h > 0.01 else -0.06, pz))    # dips just under the flat ground, so the two never shimmer
			if top > 0.01:
				var on_road := x + cell * 0.5 < 97.0 and z > 20.5 and z < 30.5
				var st := road if on_road else grass
				for k: int in [0, 1, 2, 0, 2, 3]:
					st.add_vertex(corners[k])
			z += cell
		x += cell
	grass.generate_normals()
	road.generate_normals()
	var mesh := grass.commit()
	mesh.surface_set_material(0, _tex("grass", Color(0.3, 0.5, 0.24), 0.11))
	road.commit(mesh)
	mesh.surface_set_material(1, _tex("sand", Color(0.52, 0.4, 0.26), 0.2))
	var land := MeshInstance3D.new()
	land.mesh = mesh
	add_child(land)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)
	# Boulders on the slopes.
	for k in 26:
		var a := rng.randf() * TAU
		var pos := Vector3(122.0 + cos(a) * 31.5, 0, 25.75 + sin(a) * 17.5)
		if pos.x < 97.0 and pos.z > 17.0 and pos.z < 34.0:
			continue                              # not on the road up
		pos.y = _ground_y(pos.x, pos.z) - 0.2
		var rock := _model("nature/" + ("rock_tallA" if k % 3 == 0 else "rock_largeA"))
		if rock != null:
			rock.position = pos
			rock.rotation.y = rng.randf() * TAU
			rock.scale = Vector3.ONE * rng.randf_range(3.0, 6.5)
			_regreen(rock, Color(0.55, 0.53, 0.5))       # plain grey stone
			_limit(rock, 190.0)
	_sign("לחוות הגבעה", Vector3(79.0, 3.0, 25.5), 64)
	_box(Vector3(0.18, 2.6, 0.18), Vector3(79.0, 1.3, 25.5), _mat(Color(0.45, 0.32, 0.2)))


## People and animals near the hill stand on it, not inside it.
func _follow_ground() -> void:
	for list: Array in [npcs, thugs, cops, family]:
		for n: Person in list:
			if n.root == null or n.air or n.lying > 0.0:
				continue
			var at := n.root.position
			if at.x > 76.0 and at.x < 157.0 and at.z > 5.0 and at.z < 46.5:
				n.root.position.y = _ground_y(at.x, at.z)
			elif at.y > 0.0 and at.y < HILL_H + 0.5 and at.z > -100.0:
				n.root.position.y = 0.0
	for a in animals:
		var at := a.node.position
		if at.x > 76.0 and at.x < 157.0 and at.z < 46.5:
			a.node.position.y = _ground_y(at.x, at.z)


func _join_hill() -> void:
	_close_panel()
	hill_me = true
	hill_gear.visible = true
	_play("level" if sfx.has("level") else "pay")
	_toast("ברוך הבא לנערי הגבעה! קיבלת כיפה סרוגה גדולה, פאות וקפוצ'ון.")
	_save()


# ------------------------------------------------- phoning the police ----

func _call_police() -> void:
	if state != State.PLAY or inside or busy:
		return
	if patrol_car != null and patrol_car.visible:
		_toast("הניידת כבר בדרך!")
		return
	var worst: Person
	var best := 45.0
	for t in thugs:
		if t.down > 0.0 or not t.root.visible:
			continue
		var d := t.root.position.distance_to(player.position)
		if d < best:
			best = d
			worst = t
	_play("dial")
	if worst == null:
		_toast("התקשרת למשטרה, אבל אין כאן אנשים רעים עכשיו. מתקשרים רק כשצריך.")
		return
	if patrol_car == null:
		patrol_car = _make_car(Color(0.95, 0.95, 0.97), "police")
		var flash := _mat(Color(0.2, 0.4, 1.0))
		flash.emission_enabled = true
		flash.emission = Color(0.2, 0.4, 1.0)
		flash.emission_energy_multiplier = 2.5
		_box(Vector3(0.9, 0.18, 0.3), Vector3(0, 1.95, -0.2), flash, patrol_car)
	var goal := worst.root.position
	var from_x := goal.x - 60.0 if goal.x > 20.0 else goal.x + 60.0
	patrol_car.position = Vector3(from_x, 0, 2.5)
	patrol_car.visible = true
	patrol_car.reset_physics_interpolation()
	patrol_path.assign([Vector3(goal.x - signf(goal.x - from_x) * 8.0, 0, 2.5), goal])
	patrol_back = false
	rob_cool = maxf(rob_cool, 14.0)          # the thieves hear you phoning and back off
	for t in thugs:
		t.chasing = false
	_toast("התקשרת למשטרה! הניידת בדרך אליך, עם סירנה.")


func _update_patrol(delta: float) -> void:
	if patrol_car == null or not patrol_car.visible:
		return
	siren_t -= delta
	if siren_t <= 0.0:
		siren_t = 0.5
		_play("siren")
	var goal := patrol_path[0]
	var way := goal - patrol_car.position
	way.y = 0.0
	if way.length() > 2.5:
		var dir := way.normalized()
		patrol_car.position += dir * 19.0 * delta
		patrol_car.position.y = _ground_y(patrol_car.position.x, patrol_car.position.z)
		patrol_car.rotation.y = lerp_angle(patrol_car.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
		return
	patrol_path.pop_front()
	if not patrol_path.is_empty():
		return
	if patrol_back:
		patrol_car.visible = false
		return
	# Arrived: everyone bad within reach is taken away.
	var caught := 0
	for t in thugs:
		if t.down <= 0.0 and t.root.visible and t.root.position.distance_to(patrol_car.position) < 16.0:
			t.down = 60.0
			t.chasing = false
			t.root.rotation.z = PI * 0.5
			caught += 1
	if caught > 0:
		money += caught * 30
		_play("pay")
		_toast("הניידת הגיעה! השוטרים עצרו %s, וקיבלת פרס של ₪%d." % ["איש רע אחד" if caught == 1 else "%d אנשים רעים" % caught, caught * 30])
	else:
		_toast("הניידת הגיעה, אבל האנשים הרעים כבר ברחו.")
	_update_hud()
	patrol_back = true
	var away := patrol_car.position.x + (70.0 if patrol_car.position.x < 20.0 else -70.0)
	patrol_path.assign([Vector3(patrol_car.position.x, 0, 2.5), Vector3(away, 0, 2.5)])


func _leaf_burst(at: Vector3, impact: float) -> void:
	var leaves := CPUParticles3D.new()
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.16, 0.02, 0.1)
	leaf.material = _mat(Color(0.3, 0.55, 0.2))
	leaves.mesh = leaf
	leaves.amount = int(clampf(impact * 5.0, 25.0, 90.0))
	leaves.one_shot = true
	leaves.explosiveness = 0.9
	leaves.lifetime = 2.4
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	leaves.emission_sphere_radius = 1.6
	leaves.direction = Vector3.UP
	leaves.spread = 180.0
	leaves.initial_velocity_min = 0.5
	leaves.initial_velocity_max = 3.0
	leaves.gravity = Vector3(0, -3.2, 0)
	leaves.angular_velocity_min = -300.0
	leaves.angular_velocity_max = 300.0
	leaves.position = at + Vector3(0, 3.6, 0)
	add_child(leaves)
	leaves.emitting = true
	get_tree().create_timer(3.2).timeout.connect(leaves.queue_free)


## Add every piece of a model to a mesh that is being put together; the kit's turquoise leaves become `green`.
func _bake(into: Array, node: Node, xf: Transform3D, green: Color) -> void:
	var here := xf
	if node is Node3D:
		here = xf * (node as Node3D).transform
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for k in mi.mesh.get_surface_count():
			var was := mi.mesh.surface_get_material(k) as BaseMaterial3D
			var color := Color(0.4, 0.28, 0.18)
			if was != null:
				color = green if was.albedo_color.b > was.albedo_color.r * 1.15 else was.albedo_color
			_append_mesh(into, mi.mesh, here, color, k)
	for child in node.get_children():
		_bake(into, child, here, green)


## quality 2: shadows. 1: no shadows. 0: also a shorter view and a softer picture.
## On a sharp screen the 3D picture is drawn at no more than about 900 lines; the text stays crisp.
func _apply_quality() -> void:
	if sun == null:
		return
	var tall := float(mini(get_window().size.x, get_window().size.y))
	var sharp := clampf(900.0 / maxf(tall, 1.0), 0.5, 1.0)
	sun.shadow_enabled = quality >= 2
	get_viewport().scaling_3d_scale = sharp * (1.0 if quality >= 1 else 0.75)
	cam.far = 225.0 if quality >= 1 else 150.0
	env.fog_depth_end = 200.0 if quality >= 1 else 135.0
	env.fog_depth_begin = 80.0 if quality >= 1 else 50.0


# ------------------------------------------------------------- parking ----

func _build_parking() -> void:
	_box(Vector3(15.5, 0.06, 7.0), PARK + Vector3(0, 0.03, 0), _tex("asphalt", Color(0.3, 0.31, 0.34), 0.22))
	for k in CARS.size() + 1:
		_box(Vector3(0.12, 0.02, 5.2), PARK + Vector3(-6.75 + k * 2.7, 0.07, 0.3), _mat(Color(0.95, 0.95, 0.95)))
	_sign("החנייה שלי", PARK + Vector3(0, 4.0, 3.6), 80)
	for sx: float in [-6.5, 6.5]:
		_box(Vector3(0.2, 3.8, 0.2), PARK + Vector3(sx, 1.9, 3.6), _mat(Color(0.2, 0.2, 0.22)))
	for k in CARS.size():
		var spare := _make_car(CARS[k]["color"], CARS[k]["model"])
		if k == JEEP:
			spare.scale = Vector3(1.08, 1.25, 1.0)
		spare.position = PARK + Vector3(-5.4 + k * 2.7, 0, 0.3)
		spare.rotation.y = PI
		var body := _solid(Vector3(1.9, 1.6, 4.2), Vector3(0, 0.8, 0))
		body.reparent(spare, false)
		spare.visible = false
		parked.append(spare)
	_box(Vector3(2.4, 0.05, 1.4), PARK + Vector3(0, 0.09, -3.9), _mat(Color(0.95, 0.75, 0.2)))
	var lot := Place.new()
	lot.key = "parking"
	lot.title = "החנייה שלי"
	lot.prompt = "להחליף רכב"
	lot.door = PARK + Vector3(0, 0, -3.9)
	places.append(lot)
	_show_parked()


## The cars you own but are not driving wait in their bays.
func _show_parked() -> void:
	for k in parked.size():
		var here: bool = owned[k] and k != car_model
		parked[k].visible = here
		for child in parked[k].get_children():
			if child is StaticBody3D:
				(child.get_child(0) as CollisionShape3D).disabled = not here


func _take_car(model: int) -> void:
	_close_panel()
	if _shabbat_block():
		return
	if driving:
		_toast("קודם יוצאים מהרכב.")
		return
	_set_car_model(model)
	_play("door")
	_toast("לקחת את %s. הרכב הקודם חונה עכשיו בחנייה." % CARS[model]["name"])
	_save()


## You leave a trail of footprints outdoors: left, right, left... The oldest fade away as new ones appear.
func _footprint() -> void:
	if inside:
		return
	if prints.size() < 60:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.13, 0.012, 0.3)
		var mat := _mat(Color(0.12, 0.1, 0.08, 0.55))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var made := MeshInstance3D.new()
		made.mesh = mesh
		made.material_override = mat
		made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(made)
		prints.append(made)
	var mark := prints[print_next % prints.size()]
	var side := 0.13 if print_next % 2 == 0 else -0.13
	print_next += 1
	var turn := me.root.rotation.y
	var right := Vector3(cos(turn), 0, -sin(turn))
	mark.position = player.position + right * side + Vector3(0, 0.1, 0)
	mark.rotation.y = turn


# ------------------------------------------- your donkey and the flock ----

func _build_donkey() -> void:
	my_donkey = _make_beast("donkey")
	my_donkey.label = "החמור שלך"
	my_donkey.node.position = Vector3(123.5, HILL_H, 19.0)
	my_donkey.node.rotation.y = -1.2
	_tag("החמור שלי", my_donkey.node.position + Vector3(0, 2.6, 0), 40)
	beacon = _box(Vector3(0.5, 12.0, 0.5), MEADOW + Vector3(0, 6.0, 0), _mat(Color(0.3, 0.95, 0.4)))
	var glow := beacon.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color(0.3, 0.95, 0.4)
	glow.emission_energy_multiplier = 1.5
	beacon.visible = false


func _mount() -> void:
	if _shabbat_block():
		return
	riding = true
	me.root.position = Vector3(0, 0.52, -0.05)
	_sit_astride(me)
	_play("bray")
	_toast("אתה רוכב על החמור! מכוונים כמו בהליכה. לרדת: אותו כפתור.")


func _dismount() -> void:
	riding = false
	me.root.position = Vector3.ZERO
	for limb in me.limbs:
		limb.rotation = Vector3.ZERO
	for joint in me.joints:
		joint.rotation = Vector3.ZERO
	var side := Vector3(cos(me.root.rotation.y), 0, -sin(me.root.rotation.y))
	my_donkey.node.position = player.position
	player.position += side * 1.2
	_play("door")


## While you ride, the donkey is under you and its legs do the walking.
func _ride_tick(moving: bool, delta: float) -> void:
	var d := my_donkey.node
	d.position = player.position
	d.rotation.y = me.root.rotation.y
	if moving:
		my_donkey.phase += delta * 13.0
	for k in my_donkey.legs.size():
		var swing := sin(my_donkey.phase + (0.0 if k % 3 == 0 else PI)) * 0.55 if moving else 0.0
		my_donkey.legs[k].rotation.x = lerp_angle(my_donkey.legs[k].rotation.x, swing, 10.0 * delta)


## Real shepherding: lead the flock down to the forest meadow, let them graze, and bring them home.
func _update_herd(delta: float) -> void:
	if not herding or state != State.PLAY:
		return
	var close := 0
	for r in roamers:
		if r.kind == "sheep" and r.node.position.distance_to(player.position) < 16.0:
			close += 1
	match herd_stage:
		0:
			if player.position.distance_to(MEADOW) < 8.0 and close >= 4:
				herd_stage = 1
				graze_t = 18.0
				for r in roamers:
					if r.kind == "sheep":
						r.home = MEADOW
						r.wait = 0.0
				_play("baa")
				_toast("הגעתם למרעה! הכבשים אוכלות עשב טרי. חכה לידן עד שישבעו.")
		1:
			graze_t -= delta
			if graze_t <= 0.0:
				herd_stage = 2
				beacon.position = PEN + Vector3(0, 6.0, 0)
				_play("baa")
				_toast("הכבשים שבעות! עכשיו החזר אותן לדיר בחווה, אל העמוד הירוק שעל ההר.")
		2:
			if player.position.distance_to(PEN) < 8.0 and close >= 4:
				_stop_herd(true)


func _stop_herd(done: bool) -> void:
	_close_panel()
	herding = false
	beacon.visible = false
	for r in roamers:
		if r.kind == "sheep":
			r.home = PEN
			r.wait = 0.0
			if not done:
				r.node.position = PEN + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
	if done:
		money += 40
		family_joy = minf(family_joy + 3.0, 100.0)
		_play("pay")
		_toast("כל הכבוד, רועה! כל העדר חזר שבע לדיר, והרווחת ₪40.")
		for n in npcs:
			if n.name == "הרועה אליה":
				_say(n, "תודה רבה! הכבשים אוהבות אותך.", 5.0)
	else:
		_toast("המרעה הופסק. הכבשים חזרו לדיר.")
	_update_hud()
