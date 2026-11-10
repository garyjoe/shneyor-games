extends Node3D
## Sky Chaos: survive on a floating arena while meteors knock out the floor,
## giant balls roll through, a laser arm sweeps around and random "crazy
## events" change the rules. The whole scene is built from code.

const N := 9                       # tiles per side
const TILE := 3.0
const HALF := (N - 1) * TILE * 0.5
const GRAVITY := 28.0
const SPEED := 8.5
const JUMP := 11.5
const PLAYER_HALF_HEIGHT := 0.8
const FALL_Y := -14.0
const EVENT_GAP := 13.0
const EVENT_TIME := 8.0

enum State { MENU, PLAY, OVER }
enum Ev { NONE, MOON, TURBO, SHOWER, STAMPEDE, MIRROR }

const EVENT_NAMES := {
	Ev.MOON: "כבידת ירח!",
	Ev.TURBO: "טורבו!",
	Ev.SHOWER: "מטר מטאורים!",
	Ev.STAMPEDE: "כדורי ענק!",
	Ev.MIRROR: "הכול הפוך!",
}


class Tile:
	var body: StaticBody3D
	var shape: CollisionShape3D
	var mat: StandardMaterial3D
	var base: Color
	var gone := false
	var timer := 0.0
	var fall_speed := 0.0
	var warn := 0


class Meteor:
	var node: Node3D
	var tile: int
	var from: Vector3
	var to: Vector3
	var t := 0.0
	var dur := 1.0


class Roller:
	var node: Node3D
	var dir: Vector3
	var speed: float
	var radius: float


## On-screen joystick and jump button, drawn only while useful.
class TouchPad:
	extends Control
	var stick_on := false
	var origin := Vector2.ZERO
	var knob := Vector2.ZERO
	var show_jump := false

	func _draw() -> void:
		if stick_on:
			draw_circle(origin, 110.0, Color(1, 1, 1, 0.12))
			draw_arc(origin, 110.0, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 4.0, true)
			draw_circle(origin + knob * 110.0, 48.0, Color(1, 1, 1, 0.55))
		if show_jump:
			var c := size - Vector2(170, 170)
			draw_circle(c, 95.0, Color(1, 1, 1, 0.14))
			draw_arc(c, 95.0, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 4.0, true)
			draw_colored_polygon(
				PackedVector2Array([c + Vector2(0, -45), c + Vector2(42, 20), c + Vector2(-42, 20)]),
				Color(1, 1, 1, 0.6))


var state := State.MENU
var tiles: Array[Tile] = []
var meteors: Array[Meteor] = []
var rollers: Array[Roller] = []
var stars: Array[Node3D] = []

var player: CharacterBody3D
var rig: Node3D
var cam: Camera3D
var arm: Node3D
var arm_b: MeshInstance3D
var sky_mat: ProceduralSkyMaterial
var clouds: Array[Node3D] = []

var move_vel := Vector3.ZERO
var knock := Vector3.ZERO
var jumps_left := 2
var jump_buffer := 0.0
var invuln := 0.0
var squash := 1.0

var lives := 3
var stars_got := 0
var level := 1
var score := 0
var best := 0
var play_time := 0.0
var meteor_timer := 2.0
var roller_timer := 4.0
var event := Ev.NONE
var event_timer := EVENT_GAP
var arm_angle := 0.0
var shake := 0.0
var cam_focus := Vector3.ZERO
var hue := 0.55

# HUD
var bidi := true
var hud: Control
var score_label: Label
var lives_label: Label
var level_label: Label
var event_label: Label
var announce: Label
var overlay: Control
var title_label: Label
var info_label: Label
var hint_label: Label
var pad: TouchPad
var stick_id := -1
var stick_vec := Vector2.ZERO

var sfx := {}
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	bidi = TextServerManager.get_primary_interface().has_feature(TextServer.FEATURE_BIDI_LAYOUT)
	_load_best()
	_build_world()
	_build_player()
	_build_hud()
	_build_sounds()
	_show_menu()


# ---------------------------------------------------------------- world ----

func _build_world() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.light_energy = 1.0
	add_child(sun)

	cam = Camera3D.new()
	cam.fov = 55.0
	cam.far = 400.0
	add_child(cam)
	cam.make_current()

	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(TILE - 0.14, 0.8, TILE - 0.14)
	var tile_shape := BoxShape3D.new()
	tile_shape.size = Vector3(TILE, 0.8, TILE)
	for j in N:
		for i in N:
			var t := Tile.new()
			t.body = StaticBody3D.new()
			t.body.position = Vector3(i * TILE - HALF, -0.4, j * TILE - HALF)
			t.mat = StandardMaterial3D.new()
			t.mat.roughness = 0.6
			var mi := MeshInstance3D.new()
			mi.mesh = tile_mesh
			mi.material_override = t.mat
			t.body.add_child(mi)
			t.shape = CollisionShape3D.new()
			t.shape.shape = tile_shape
			t.body.add_child(t.shape)
			add_child(t.body)
			tiles.append(t)
	_recolor()

	# Laser arm: pivot in the middle, one or two glowing bars.
	arm = Node3D.new()
	add_child(arm)
	var glow := _emissive(Color(1.0, 0.15, 0.5), 2.5)
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.7
	hub_mesh.bottom_radius = 0.9
	hub_mesh.height = 1.4
	var hub := MeshInstance3D.new()
	hub.mesh = hub_mesh
	hub.material_override = _plain(Color(0.2, 0.2, 0.3))
	hub.position.y = 0.7
	arm.add_child(hub)
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(12.5, 0.45, 0.45)
	for side in 2:
		var bar := MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.material_override = glow
		bar.position = Vector3(7.25 * (1.0 if side == 0 else -1.0), 0.6, 0.0)
		arm.add_child(bar)
		if side == 1:
			arm_b = bar
	arm.visible = false

	# Clouds far below and around, for a sense of height.
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 12
	cloud_mesh.rings = 6
	var cloud_mat := _plain(Color(1, 1, 1, 0.85))
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in 26:
		var c := MeshInstance3D.new()
		c.mesh = cloud_mesh
		c.material_override = cloud_mat
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.scale = Vector3(rng.randf_range(6, 14), rng.randf_range(1.5, 3), rng.randf_range(4, 9))
		c.position = Vector3(rng.randf_range(-90, 90), rng.randf_range(-45, -18), rng.randf_range(-110, 30))
		add_child(c)
		clouds.append(c)


func _plain(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := _plain(color)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _recolor() -> void:
	for idx in tiles.size():
		var checker := ((idx % N) + (idx / N)) % 2 == 0
		var t := tiles[idx]
		t.base = Color.from_hsv(fposmod(hue + (0.0 if checker else 0.07), 1.0), 0.72, 0.9 if checker else 0.62)
		t.mat.albedo_color = t.base
	var sky_hue := fposmod(hue + 0.1, 1.0)
	sky_mat.sky_top_color = Color.from_hsv(sky_hue, 0.7, 0.8)
	sky_mat.sky_horizon_color = Color.from_hsv(sky_hue, 0.35, 0.95)
	sky_mat.ground_horizon_color = Color.from_hsv(sky_hue, 0.35, 0.95)
	sky_mat.ground_bottom_color = Color.from_hsv(fposmod(sky_hue + 0.08, 1.0), 0.75, 0.45)


func _tile_at(pos: Vector3) -> int:
	var i := int(round((pos.x + HALF) / TILE))
	var j := int(round((pos.z + HALF) / TILE))
	if i < 0 or i >= N or j < 0 or j >= N:
		return -1
	return j * N + i


func _tile_pos(idx: int) -> Vector3:
	return Vector3((idx % N) * TILE - HALF, 0.0, (idx / N) * TILE - HALF)


func _restore_tile(t: Tile) -> void:
	t.gone = false
	t.timer = 0.0
	t.body.visible = true
	t.body.position.y = -0.4
	t.shape.disabled = false


func _drop_tile(t: Tile) -> void:
	if t.gone:
		return
	t.gone = true
	t.timer = 5.0 + minf(level * 0.3, 3.0)
	t.fall_speed = 0.0
	t.shape.disabled = true


func _update_tiles(dt: float) -> void:
	var flash := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025)
	for t in tiles:
		t.mat.albedo_color = t.base.lerp(Color(1.0, 0.1, 0.1), flash) if t.warn > 0 else t.base
		if not t.gone:
			continue
		t.timer -= dt
		if t.timer <= 0.0:
			_restore_tile(t)
		elif t.timer < 0.6:
			t.body.visible = true
			t.body.position.y = lerpf(-7.0, -0.4, 1.0 - t.timer / 0.6)
		elif t.body.visible:
			t.fall_speed += 40.0 * dt
			t.body.position.y -= t.fall_speed * dt
			t.body.rotation.x += dt * 1.5
			if t.body.position.y < -45.0:
				t.body.visible = false
				t.body.rotation = Vector3.ZERO


# --------------------------------------------------------------- player ----

func _build_player() -> void:
	player = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = PLAYER_HALF_HEIGHT * 2.0
	cs.shape = cap
	player.add_child(cs)

	rig = Node3D.new()
	player.add_child(rig)
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.45
	body_mesh.height = PLAYER_HALF_HEIGHT * 2.0
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = _plain(Color(0.25, 0.75, 1.0))
	rig.add_child(body)
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.16
	eye_mesh.height = 0.32
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.08
	pupil_mesh.height = 0.16
	var white := _plain(Color.WHITE)
	var black := _plain(Color(0.05, 0.05, 0.1))
	for sx: float in [-0.18, 0.18]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = white
		eye.position = Vector3(sx, 0.35, 0.36)
		rig.add_child(eye)
		var pupil := MeshInstance3D.new()
		pupil.mesh = pupil_mesh
		pupil.material_override = black
		pupil.position = Vector3(sx, 0.35, 0.49)
		rig.add_child(pupil)
	add_child(player)
	player.position = Vector3(0, PLAYER_HALF_HEIGHT, 0)


func _move_input() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if v == Vector2.ZERO:
		v = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if v == Vector2.ZERO:
		v = stick_vec
	if event == Ev.MIRROR:
		v = -v
	return v.limit_length(1.0)


func _update_player(dt: float) -> void:
	var on_floor := player.is_on_floor()
	var gravity := GRAVITY * (0.3 if event == Ev.MOON else 1.0)
	if on_floor:
		jumps_left = 2
	jump_buffer -= dt
	if jump_buffer > 0.0 and jumps_left > 0:
		player.velocity.y = JUMP if jumps_left == 2 else JUMP * 0.9
		jumps_left -= 1
		jump_buffer = 0.0
		squash = 1.35
		_play("jump")
	else:
		player.velocity.y -= gravity * dt

	var input := _move_input()
	var target := Vector3(input.x, 0, input.y) * SPEED
	move_vel = move_vel.move_toward(target, (70.0 if on_floor else 30.0) * dt)
	knock = knock.move_toward(Vector3.ZERO, 22.0 * dt)
	player.velocity.x = move_vel.x + knock.x
	player.velocity.z = move_vel.z + knock.z
	var was_falling := player.velocity.y < -8.0
	player.move_and_slide()
	if was_falling and player.is_on_floor():
		squash = 0.7

	if input.length_squared() > 0.01:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(input.x, input.y), 14.0 * dt)
	squash = lerpf(squash, 1.0, 10.0 * dt)
	rig.scale = Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))
	invuln = maxf(invuln - dt, 0.0)
	rig.visible = invuln <= 0.0 or int(Time.get_ticks_msec() / 70.0) % 2 == 0

	if player.position.y < FALL_Y:
		_lose_life()


func _hit_player(push: Vector3, up: float) -> void:
	if invuln > 0.0:
		return
	knock = push
	player.velocity.y = up
	jumps_left = maxi(jumps_left, 1)
	invuln = 0.45
	shake = maxf(shake, 0.6)
	_play("hit")


func _lose_life() -> void:
	lives -= 1
	_play("fall")
	if lives <= 0:
		_game_over()
		return
	for idx in [N * N / 2, N * N / 2 - 1, N * N / 2 + 1, N * N / 2 - N, N * N / 2 + N]:
		_restore_tile(tiles[idx])
	player.position = Vector3(0, 7, 0)
	player.velocity = Vector3.ZERO
	move_vel = Vector3.ZERO
	knock = Vector3.ZERO
	invuln = 2.5
	_update_hud()


# -------------------------------------------------------------- hazards ----

func _spawn_meteor() -> void:
	var idx := rng.randi_range(0, N * N - 1)
	if rng.randf() < 0.55:
		var under := _tile_at(player.position + Vector3(move_vel.x, 0, move_vel.z) * 0.5)
		if under >= 0:
			idx = under
	var m := Meteor.new()
	m.tile = idx
	m.to = _tile_pos(idx) + Vector3(0, 0.8, 0)
	m.from = m.to + Vector3(rng.randf_range(-10, 10), 48, rng.randf_range(-14, -4))
	m.dur = maxf(1.5 - level * 0.07, 0.8)
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _emissive(Color(1.0, 0.45, 0.1), 2.0)
	mi.position = m.from
	add_child(mi)
	m.node = mi
	tiles[idx].warn += 1
	meteors.append(m)


func _update_meteors(dt: float) -> void:
	var interval := maxf(1.7 - level * 0.12, 0.55)
	if event == Ev.SHOWER:
		interval = 0.2
	meteor_timer -= dt
	if meteor_timer <= 0.0:
		meteor_timer = interval * rng.randf_range(0.7, 1.3)
		_spawn_meteor()

	for k in range(meteors.size() - 1, -1, -1):
		var m := meteors[k]
		m.t += dt / m.dur
		if m.t < 1.0:
			m.node.position = m.from.lerp(m.to, m.t * m.t)
			continue
		var t := tiles[m.tile]
		t.warn -= 1
		_drop_tile(t)
		_burst(m.to, Color(1.0, 0.55, 0.15), 22)
		_play("boom")
		var away := player.position - m.to
		away.y = 0.0
		var dist := away.length()
		shake = maxf(shake, clampf(1.2 - dist * 0.06, 0.15, 1.0))
		if dist < 3.6 and player.position.y < 3.5:
			var dir := away.normalized() if dist > 0.05 else Vector3(1, 0, 0)
			_hit_player(dir * 11.0, 9.0)
		m.node.queue_free()
		meteors.remove_at(k)


func _spawn_roller() -> void:
	var r := Roller.new()
	r.radius = rng.randf_range(1.3, 2.0) * (1.4 if event == Ev.STAMPEDE else 1.0)
	r.speed = rng.randf_range(9.0, 13.0) + level * 0.4
	var along_x := rng.randf() < 0.5
	var sign := 1.0 if rng.randf() < 0.5 else -1.0
	var lane := rng.randf_range(-HALF, HALF)
	if rng.randf() < 0.5:
		lane = clampf(player.position.z if along_x else player.position.x, -HALF, HALF)
	r.dir = Vector3(sign, 0, 0) if along_x else Vector3(0, 0, sign)
	var start := -r.dir * (HALF + 12.0)
	if along_x:
		start.z = lane
	else:
		start.x = lane
	start.y = r.radius
	var node := Node3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r.radius
	mesh.height = r.radius * 2.0
	var ball := MeshInstance3D.new()
	ball.mesh = mesh
	var color := Color.from_hsv(rng.randf(), 0.75, 1.0)
	ball.material_override = _plain(color)
	node.add_child(ball)
	# Spots make the rolling visible.
	var spot_mesh := SphereMesh.new()
	spot_mesh.radius = r.radius * 0.28
	spot_mesh.height = r.radius * 0.56
	var spot_mat := _plain(Color.WHITE)
	for s in 8:
		var spot := MeshInstance3D.new()
		spot.mesh = spot_mesh
		spot.material_override = spot_mat
		spot.position = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * r.radius * 0.86
		node.add_child(spot)
	node.position = start
	add_child(node)
	r.node = node
	rollers.append(r)


func _update_rollers(dt: float) -> void:
	if level >= 2 or event == Ev.STAMPEDE:
		roller_timer -= dt
		if roller_timer <= 0.0:
			roller_timer = 0.45 if event == Ev.STAMPEDE else maxf(5.5 - level * 0.4, 1.8)
			_spawn_roller()

	for k in range(rollers.size() - 1, -1, -1):
		var r := rollers[k]
		r.node.position += r.dir * r.speed * dt
		r.node.rotate(r.dir.cross(Vector3.DOWN).normalized(), r.speed * dt / r.radius)
		var diff := player.position - r.node.position
		if diff.length() < r.radius + 0.6:
			diff.y = 0.0
			_hit_player(r.dir * 12.0 + diff.normalized() * 5.0, 9.5)
		if absf(r.node.position.x) > HALF + 14.0 or absf(r.node.position.z) > HALF + 14.0:
			r.node.queue_free()
			rollers.remove_at(k)


func _update_arm(dt: float) -> void:
	arm.visible = level >= 3
	arm_b.visible = level >= 6
	if not arm.visible:
		return
	var w := minf(1.1 + level * 0.1, 2.4)
	arm_angle += w * dt
	arm.rotation.y = arm_angle
	if player.position.y - PLAYER_HALF_HEIGHT > 0.85:
		return
	var flat := Vector3(player.position.x, 0, player.position.z)
	var d := Vector3(cos(arm_angle), 0, -sin(arm_angle))
	for side in (2 if arm_b.visible else 1):
		var dir := d if side == 0 else -d
		var along := flat.dot(dir)
		if along < 1.0 or along > 13.5:
			continue
		if (flat - dir * along).length() < 0.7:
			var tangent := Vector3(-sin(arm_angle), 0, -cos(arm_angle)) * (1.0 if side == 0 else -1.0)
			_hit_player(tangent * 13.0, 9.0)


# ---------------------------------------------------------------- stars ----

func _spawn_star() -> void:
	var idx := -1
	for attempt in 30:
		var c := rng.randi_range(0, N * N - 1)
		if tiles[c].gone or tiles[c].warn > 0:
			continue
		if _tile_pos(c).distance_to(player.position) < 7.0:
			continue
		idx = c
		break
	if idx < 0:
		idx = rng.randi_range(0, N * N - 1)
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	mesh.radial_segments = 6
	mesh.rings = 3
	var star := MeshInstance3D.new()
	star.mesh = mesh
	star.scale = Vector3(1.0, 1.25, 0.35)
	star.material_override = _emissive(Color(1.0, 0.85, 0.1), 1.6)
	star.position = _tile_pos(idx) + Vector3(0, 1.3, 0)
	add_child(star)
	stars.append(star)


func _update_stars(dt: float) -> void:
	var wanted := mini(1 + level / 3, 3)
	while stars.size() < wanted:
		_spawn_star()
	for k in range(stars.size() - 1, -1, -1):
		var s := stars[k]
		s.rotation.y += dt * 3.0
		s.position.y = 1.3 + sin(Time.get_ticks_msec() * 0.004 + k) * 0.2
		if s.position.distance_to(player.position) < 1.5:
			_burst(s.position, Color(1.0, 0.9, 0.2), 16)
			s.queue_free()
			stars.remove_at(k)
			stars_got += 1
			_play("star")
			var new_level := 1 + stars_got / 4
			if new_level > level:
				level = new_level
				hue = fposmod(hue + 0.13, 1.0)
				_recolor()
				_announce("שלב %d!" % level, Color(1, 1, 1))
				_play("level")


# --------------------------------------------------------------- events ----

func _update_events(dt: float) -> void:
	event_timer -= dt
	if event_timer > 0.0:
		return
	if event == Ev.NONE:
		event = [Ev.MOON, Ev.TURBO, Ev.SHOWER, Ev.STAMPEDE, Ev.MIRROR][rng.randi_range(0, 4)]
		event_timer = EVENT_TIME
		Engine.time_scale = 1.4 if event == Ev.TURBO else 1.0
		roller_timer = minf(roller_timer, 0.5)
		_announce(EVENT_NAMES[event], Color(1.0, 0.9, 0.3))
		_play("event")
	else:
		event = Ev.NONE
		event_timer = maxf(EVENT_GAP - level * 0.5, 7.0)
		Engine.time_scale = 1.0
	event_label.text = _h(EVENT_NAMES[event]) if event != Ev.NONE else ""


# ----------------------------------------------------------------- loop ----

func _physics_process(delta: float) -> void:
	_update_tiles(delta)
	if state != State.PLAY:
		return
	play_time += delta / Engine.time_scale
	_update_events(delta)
	_update_meteors(delta)
	_update_rollers(delta)
	_update_arm(delta)
	_update_stars(delta)
	_update_player(delta)
	var new_score := stars_got * 10 + int(play_time)
	if new_score != score:
		score = new_score
		_update_hud()


func _process(delta: float) -> void:
	var view := get_viewport().get_visible_rect().size
	cam.fov = 55.0 if view.x >= view.y else 80.0
	var want := player.position * (0.8 if view.x >= view.y else 0.92)
	want.y = clampf(player.position.y * 0.3, -2.0, 4.0)
	if state == State.MENU:
		want = Vector3(sin(Time.get_ticks_msec() * 0.0004) * 4.0, 0, 0)
	cam_focus = cam_focus.lerp(want, 1.0 - exp(-5.0 * delta))
	shake = maxf(shake - delta * 2.5, 0.0)
	var jitter := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * shake * 0.6
	cam.position = cam_focus + Vector3(0, 14, 11.5) + jitter
	cam.look_at(cam_focus + jitter * 0.5)
	for c in clouds:
		c.position.x += delta * 1.5
		if c.position.x > 95.0:
			c.position.x = -95.0
	pad.queue_redraw()


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			if state != State.PLAY:
				_start()
			elif e.position.x < get_viewport().get_visible_rect().size.x * 0.5 and stick_id < 0:
				stick_id = e.index
				pad.origin = e.position
				pad.knob = Vector2.ZERO
				pad.stick_on = true
			else:
				jump_buffer = 0.15
			pad.show_jump = true
		elif e.index == stick_id:
			stick_id = -1
			stick_vec = Vector2.ZERO
			pad.stick_on = false
	elif e is InputEventScreenDrag and e.index == stick_id:
		stick_vec = ((e.position - pad.origin) / 110.0).limit_length(1.0)
		pad.knob = stick_vec
	elif e is InputEventMouseButton and e.pressed and state != State.PLAY:
		_start()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode in [KEY_SPACE, KEY_ENTER]:
			if state == State.PLAY:
				jump_buffer = 0.15
			else:
				_start()


func _start() -> void:
	for m in meteors:
		m.node.queue_free()
	for r in rollers:
		r.node.queue_free()
	for s in stars:
		s.queue_free()
	meteors.clear()
	rollers.clear()
	stars.clear()
	for t in tiles:
		t.warn = 0
		t.body.rotation = Vector3.ZERO
		_restore_tile(t)
	lives = 3
	stars_got = 0
	level = 1
	score = 0
	play_time = 0.0
	meteor_timer = 2.0
	roller_timer = 4.0
	event = Ev.NONE
	event_timer = EVENT_GAP
	event_label.text = ""
	hue = 0.55
	_recolor()
	Engine.time_scale = 1.0
	player.position = Vector3(0, PLAYER_HALF_HEIGHT, 0)
	player.velocity = Vector3.ZERO
	move_vel = Vector3.ZERO
	knock = Vector3.ZERO
	invuln = 1.0
	state = State.PLAY
	overlay.visible = false
	_update_hud()
	_play("level")


func _game_over() -> void:
	state = State.OVER
	Engine.time_scale = 1.0
	event = Ev.NONE
	rig.visible = false
	var record := score > best
	if record:
		best = score
		_save_best()
	title_label.text = _h("שיא חדש!" if record else "נפלתם!")
	info_label.text = _h("ניקוד: %d" % score) + "\n" + _h("שיא: %d" % best)
	hint_label.text = _h("לחצו כדי לשחק שוב")
	overlay.visible = true
	_update_hud()


func _show_menu() -> void:
	state = State.MENU
	title_label.text = _h("טירוף בשמיים")
	info_label.text = "\n".join([
		_h("אספו כוכבים, ואל תיפלו מהזירה!"),
		_h("תנועה: חיצים או WASD · קפיצה כפולה: רווח"),
		_h("בטלפון: ג'ויסטיק בצד שמאל, קפיצה בצד ימין"),
		_h("שיא: %d" % best) if best > 0 else "",
	])
	hint_label.text = _h("לחצו כדי להתחיל")
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
		if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			run = ch + run
		else:
			out += run + ch
			run = ""
	return out + run


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.25))
	l.add_theme_constant_override("outline_size", maxi(size / 5, 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = load("res://font.ttf")
	hud.theme = theme
	layer.add_child(hud)

	pad = TouchPad.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(pad)

	lives_label = _label(44, Color(1.0, 0.3, 0.4))
	lives_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	hud.add_child(lives_label)

	score_label = _label(44, Color.WHITE)
	score_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	score_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(score_label)

	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 24)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	level_label = _label(36, Color(0.85, 0.95, 1.0))
	top.add_child(level_label)
	event_label = _label(40, Color(1.0, 0.9, 0.3))
	top.add_child(event_label)

	announce = _label(96, Color.WHITE)
	announce.set_anchors_preset(Control.PRESET_FULL_RECT)
	announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	announce.modulate.a = 0.0
	hud.add_child(announce)

	overlay = ColorRect.new()
	overlay.color = Color(0.08, 0.04, 0.2, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(box)
	title_label = _label(110, Color(1.0, 0.85, 0.2))
	box.add_child(title_label)
	info_label = _label(38, Color.WHITE)
	box.add_child(info_label)
	hint_label = _label(48, Color(0.5, 1.0, 0.85))
	box.add_child(hint_label)


func _update_hud() -> void:
	lives_label.text = "♥".repeat(maxi(lives, 0))
	score_label.text = _h("ניקוד: %d" % score)
	level_label.text = _h("שלב %d" % level)
	var playing := state == State.PLAY
	lives_label.visible = playing
	level_label.visible = playing
	score_label.visible = playing


func _announce(text: String, color: Color) -> void:
	announce.text = _h(text)
	announce.add_theme_color_override("font_color", color)
	announce.modulate.a = 1.0
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_interval(0.9)
	tw.tween_property(announce, "modulate:a", 0.0, 0.5)


func _burst(pos: Vector3, color: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.3, 0.3)
	var mat := _plain(color)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector3(0, -22, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


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
		var s := signf(sin(phase)) * 0.5 + sin(phase) * 0.5
		s = lerpf(s, rng.randf_range(-1.0, 1.0), noise)
		data.encode_s16(i * 2, int(clampf(s * vol * (1.0 - k) * (1.0 - k), -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


func _build_sounds() -> void:
	var defs := {
		"jump": _tone(320, 720, 0.16, 0.25),
		"star": _tone(880, 1760, 0.25, 0.3),
		"boom": _tone(160, 40, 0.45, 0.5, 0.7),
		"hit": _tone(240, 90, 0.25, 0.45, 0.3),
		"fall": _tone(600, 80, 0.7, 0.4),
		"level": _tone(520, 1040, 0.5, 0.3),
		"event": _tone(200, 900, 0.6, 0.3, 0.15),
	}
	for key: String in defs:
		var p := AudioStreamPlayer.new()
		p.stream = defs[key]
		add_child(p)
		sfx[key] = p


func _play(key: String) -> void:
	(sfx[key] as AudioStreamPlayer).play()


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://sky-chaos.cfg") == OK:
		best = int(cfg.get_value("game", "best", 0))


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.save("user://sky-chaos.cfg")
