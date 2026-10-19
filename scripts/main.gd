extends Node3D

var cash: int = 2500
var officers: int = 4
var vehicles: int = 1
var safety: int = 12
var station_level: int = 1
var calls_done: int = 0
var upgrade_level: Dictionary = {"HQ": 0, "Garage": 0, "Lab": 0}
var active_call: Dictionary = {}
var income_timer: float = 0.0
var ui: CanvasLayer
var cash_label: Label
var staff_label: Label
var safety_label: Label
var status_label: Label
var call_title: Label
var call_desc: Label
var call_button: Button
var upgrade_buttons: Array[Button] = []
var car_nodes: Array[Node3D] = []
var world_root: Node3D
var event_label: Label
var event_text: String = "Смена началась. Добро пожаловать, начальник!"
var admin_panel: Panel
var admin_status_label: Label

const INCIDENTS := [
	{"title":"Кража в магазине", "desc":"Подозреваемый замечен у выхода. Направь патруль.", "reward":360, "risk":10},
	{"title":"Дорожное происшествие", "desc":"Столкновение на центральной улице. Нужна помощь.", "reward":280, "risk":5},
	{"title":"Нарушение порядка", "desc":"Драка на площади. Жители ждут полицию.", "reward":420, "risk":15},
	{"title":"Тревога в банке", "desc":"Сработала сигнализация. Нужен быстрый ответ.", "reward":650, "risk":28},
	{"title":"Поиск подозреваемого", "desc":"Поступила ориентировка. Проверь район.", "reward":480, "risk":12},
	{"title":"Опасный преступник", "desc":"Высокий риск. Желательно усилить экипаж.", "reward":900, "risk":40}
]

func _ready() -> void:
	_build_world()
	_build_ui()
	_refresh_ui()
	_new_call()

func _process(delta: float) -> void:
	income_timer += delta
	if income_timer >= 1.0:
		income_timer = 0.0
		cash += _income_per_second()
		_refresh_ui()
	for i in range(car_nodes.size()):
		var car := car_nodes[i]
		if is_instance_valid(car):
			car.position.x = -8.0 + fposmod(Time.get_ticks_msec() / 1000.0 * (0.45 + i * 0.12) + i * 5.0, 16.0)

func _mat(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, label: String = "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = _mat(color)
	parent.add_child(node)
	if label != "":
		var text := Label3D.new()
		text.text = label
		text.font_size = 30
		text.pixel_size = 0.006
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.position = pos + Vector3(0, size.y * 0.65 + 0.25, 0)
		text.modulate = Color(0.96, 0.98, 1)
		parent.add_child(text)
	return node

func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "CityAndStation"
	add_child(world_root)
	var ground := _box(world_root, Vector3(38, 0.2, 25), Vector3(0, -0.15, 0), Color(0.16, 0.34, 0.27))
	_box(world_root, Vector3(38, 0.12, 4.5), Vector3(0, 0, 5.8), Color(0.20, 0.24, 0.28))
	_box(world_root, Vector3(4.5, 0.13, 25), Vector3(10.5, 0.01, 0), Color(0.20, 0.24, 0.28))
	for x in range(-17, 18, 3):
		_box(world_root, Vector3(1.2, 0.03, 0.12), Vector3(x, 0.09, 5.8), Color(0.88, 0.83, 0.63))
	# Police headquarters: foundations, main block, roof and sign.
	_box(world_root, Vector3(9.0, 0.55, 5.5), Vector3(-5.0, 0.28, -2.8), Color(0.68, 0.75, 0.79))
	_box(world_root, Vector3(8.4, 2.8, 5.0), Vector3(-5.0, 1.9, -2.8), Color(0.34, 0.48, 0.59), "POLICE")
	_box(world_root, Vector3(8.8, 0.25, 5.4), Vector3(-5.0, 3.35, -2.8), Color(0.10, 0.20, 0.31))
	_box(world_root, Vector3(2.5, 1.6, 0.16), Vector3(-5.0, 1.15, -0.25), Color(0.13, 0.65, 0.91))
	# Garage and forensics lab.
	_box(world_root, Vector3(5.2, 0.35, 4.5), Vector3(3.5, 0.18, -3.0), Color(0.65, 0.73, 0.77))
	_box(world_root, Vector3(4.8, 2.0, 4.1), Vector3(3.5, 1.25, -3.0), Color(0.39, 0.53, 0.63), "GARAGE")
	_box(world_root, Vector3(4.4, 0.2, 3.8), Vector3(3.5, 2.35, -3.0), Color(0.12, 0.25, 0.37))
	_box(world_root, Vector3(4.0, 0.35, 3.7), Vector3(-12.0, 0.18, -8.0), Color(0.65, 0.73, 0.77))
	_box(world_root, Vector3(3.7, 1.7, 3.4), Vector3(-12.0, 1.15, -8.0), Color(0.40, 0.64, 0.68), "FORENSICS")
	# Trees and low-rise city blocks.
	for p in [Vector3(-16,0,-2), Vector3(-16,0,3), Vector3(-14,0,8), Vector3(16,0,-7), Vector3(16,0,-2), Vector3(15,0,9), Vector3(-7,0,-10), Vector3(0,0,-10), Vector3(6,0,9)]:
		_box(world_root, Vector3(0.35, 1.0, 0.35), p + Vector3(0,0.5,0), Color(0.30,0.20,0.13))
		var crown := _box(world_root, Vector3(1.4, 1.4, 1.4), p + Vector3(0,1.5,0), Color(0.19,0.48,0.30))
		crown.mesh = SphereMesh.new()
	for i in range(3):
		var car := Node3D.new()
		world_root.add_child(car)
		_box(car, Vector3(1.5,0.45,0.8), Vector3.ZERO, Color(0.82,0.88,0.94))
		_box(car, Vector3(0.75,0.3,0.83), Vector3(0,0.32,0), Color(0.10,0.22,0.34))
		_box(car, Vector3(0.35,0.12,0.22), Vector3(0,0.53,0), Color(0.95,0.18,0.20) if i % 2 == 0 else Color(0.12,0.55,1.0))
		car.position = Vector3(-8 + i * 3, 0.35, 5.8 + (i % 2) * 1.0)
		car_nodes.append(car)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_energy = 1.25
	add_child(sun)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58,0.68,0.78)
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 20, 22)
	camera.rotation_degrees = Vector3(-42, 0, 0)
	camera.fov = 48
	camera.current = true
	add_child(camera)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.07, 0.11, 0.93)
	bg.position = Vector2(0,0)
	bg.size = Vector2(960, 92)
	ui.add_child(bg)
	var title := Label.new()
	title.text = "POLICE DEPARTMENT  /  TYCOON"
	title.position = Vector2(22,8)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.87,0.94,1))
	ui.add_child(title)
	cash_label = _label("Бюджет: $2,500", Vector2(22,42), 18, Color(0.98,0.79,0.34))
	staff_label = _label("👮 4 сотрудника", Vector2(270,45), 16, Color(0.82,0.9,0.98))
	safety_label = _label("🛡️ 12% безопасность", Vector2(485,45), 16, Color(0.39,0.9,0.68))
	status_label = _label("Уровень участка 1", Vector2(745,45), 15, Color(0.56,0.76,1))
	# Bottom glass-like control panel.
	var panel := Panel.new()
	panel.position = Vector2(12, 354)
	panel.size = Vector2(936, 174)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.07,0.11,0.96)
	style.border_color = Color(0.16,0.31,0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	call_title = _label("🚨 Вызов диспетчера", Vector2(30,366), 18, Color(1,0.79,0.39))
	call_desc = _label("Ожидание вызова...", Vector2(30,397), 14, Color(0.76,0.84,0.91))
	call_desc.size = Vector2(500, 35)
	call_button = _button("ОТПРАВИТЬ ПАТРУЛЬ", Vector2(600,375), Vector2(320,44), Color(0.15,0.48,0.85))
	call_button.pressed.connect(_respond_to_call)
	var upgrade1 := _button("🏢 Улучшить штаб  $900", Vector2(30,455), Vector2(270,48), Color(0.15,0.31,0.46))
	upgrade1.pressed.connect(func(): _buy_upgrade("HQ", 900))
	upgrade_buttons.append(upgrade1)
	var upgrade2 := _button("🚓 Купить патруль  $1,100", Vector2(315,455), Vector2(285,48), Color(0.15,0.31,0.46))
	upgrade2.pressed.connect(_buy_vehicle)
	upgrade_buttons.append(upgrade2)
	var upgrade3 := _button("🧪 Лаборатория  $1,200", Vector2(615,455), Vector2(305,48), Color(0.15,0.31,0.46))
	upgrade3.pressed.connect(func(): _buy_upgrade("Lab", 1200))
	upgrade_buttons.append(upgrade3)
	event_label = _label(event_text, Vector2(30,424), 12, Color(0.55,0.86,0.71))
	event_label.size = Vector2(890, 24)
	var admin_open := _button("⚙ АДМИН", Vector2(820, 8), Vector2(118, 30), Color(0.48, 0.18, 0.24))
	admin_open.add_theme_font_size_override("font_size", 12)
	admin_open.pressed.connect(_toggle_admin)
	_build_admin_panel()

func _label(text_value: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	ui.add_child(l)
	return l

func _button(text_value: String, pos: Vector2, dimensions: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = dimensions
	b.add_theme_font_size_override("font_size", 15)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.12)
	b.add_theme_stylebox_override("hover", hover)
	ui.add_child(b)
	return b

func _income_per_second() -> int:
	return 1 + officers + vehicles * 2 + station_level * 2

func _new_call() -> void:
	active_call = INCIDENTS[randi() % INCIDENTS.size()].duplicate(true)
	call_title.text = "🚨 " + active_call.title
	call_desc.text = active_call.desc + "   Награда: $" + str(active_call.reward)
	call_button.text = "ОТПРАВИТЬ ПАТРУЛЬ"

func _respond_to_call() -> void:
	if active_call.is_empty():
		_new_call()
		return
	var power: int = officers + vehicles * 2 + station_level
	var chance: int = clampi(75 + power * 2 - int(active_call.risk), 20, 97)
	if randi_range(1, 100) <= chance:
		cash += int(active_call.reward)
		safety = mini(100, safety + 3)
		event_text = "Успех! Вызов закрыт. Получено $" + str(active_call.reward)
	else:
		var loss: int = mini(cash, int(active_call.reward) / 4)
		cash -= loss
		safety = maxi(0, safety - 2)
		event_text = "Неудача: требуется усилить патруль. Потери $" + str(loss)
	calls_done += 1
	if calls_done % 4 == 0:
		station_level += 1
		cash += 500
		event_text += "  •  Повышение! Грант города +$500"
	_new_call()
	_refresh_ui()

func _buy_upgrade(kind: String, cost: int) -> void:
	if cash < cost:
		event_text = "Недостаточно средств для улучшения."
		_refresh_ui()
		return
	cash -= cost
	upgrade_level[kind] = int(upgrade_level[kind]) + 1
	station_level += 1
	safety = mini(100, safety + 2)
	event_text = "Инфраструктура улучшена: " + kind + ". Доход вырос."
	_refresh_ui()

func _buy_vehicle() -> void:
	if cash < 1100:
		event_text = "Недостаточно средств для новой патрульной машины."
		_refresh_ui()
		return
	cash -= 1100
	vehicles += 1
	officers += 1
	event_text = "Новый патруль введён в строй. Штат +1."
	_refresh_ui()

func _refresh_ui() -> void:
	if not is_instance_valid(cash_label):
		return
	cash_label.text = "Бюджет: $" + _format_number(cash)
	staff_label.text = "👮 " + str(officers) + " сотрудников"
	safety_label.text = "🛡️ " + str(safety) + "% безопасность"
	status_label.text = "Уровень участка " + str(station_level) + "  •  +$" + str(_income_per_second()) + "/сек"
	if is_instance_valid(event_label):
		event_label.text = event_text
	for b in upgrade_buttons:
		b.disabled = cash < (1100 if b.text.begins_with("🚓") else 900 if b.text.begins_with("🏢") else 1200)

func _format_number(value: int) -> String:
	var raw := str(value)
	var out := ""
	for i in range(raw.length()):
		out += raw[i]
		var left := raw.length() - i - 1
		if left > 0 and left % 3 == 0:
			out += ","
	return out

func _build_admin_panel() -> void:
	admin_panel = Panel.new()
	admin_panel.position = Vector2(185, 115)
	admin_panel.size = Vector2(590, 300)
	admin_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.085, 0.99)
	panel_style.border_color = Color(0.85, 0.24, 0.31)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	admin_panel.add_theme_stylebox_override("panel", panel_style)
	ui.add_child(admin_panel)
	var title := Label.new()
	title.text = "⚙ АДМИН-ПАНЕЛЬ"
	title.position = Vector2(22, 12)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.38, 0.42))
	admin_panel.add_child(title)
	admin_status_label = Label.new()
	admin_status_label.text = "Управление параметрами игры"
	admin_status_label.position = Vector2(22, 46)
	admin_status_label.add_theme_font_size_override("font_size", 13)
	admin_status_label.add_theme_color_override("font_color", Color(0.77, 0.85, 0.94))
	admin_panel.add_child(admin_status_label)
	_admin_button("💰 +$10,000", Vector2(22, 82), Vector2(170, 44), func(): _admin_money())
	_admin_button("👮 +10 сотрудников", Vector2(207, 82), Vector2(170, 44), func(): _admin_staff())
	_admin_button("🛡️ Безопасность 100%", Vector2(392, 82), Vector2(175, 44), func(): _admin_safety())
	_admin_button("🏢 Уровень участка +5", Vector2(22, 140), Vector2(170, 44), func(): _admin_level())
	_admin_button("🚓 +5 машин", Vector2(207, 140), Vector2(170, 44), func(): _admin_vehicles())
	_admin_button("🚨 Новый вызов", Vector2(392, 140), Vector2(175, 44), func(): _admin_new_call())
	_admin_button("🔄 Сбросить показатели", Vector2(22, 198), Vector2(270, 44), func(): _admin_reset_stats())
	_admin_button("✕ ЗАКРЫТЬ", Vector2(307, 198), Vector2(260, 44), func(): _toggle_admin())

func _admin_button(text_value: String, pos: Vector2, dimensions: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = dimensions
	b.add_theme_font_size_override("font_size", 13)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.14, 0.24, 0.36)
	st.set_corner_radius_all(9)
	b.add_theme_stylebox_override("normal", st)
	var hov := st.duplicate()
	hov.bg_color = Color(0.22, 0.36, 0.51)
	b.add_theme_stylebox_override("hover", hov)
	b.pressed.connect(action)
	admin_panel.add_child(b)

func _toggle_admin() -> void:
	admin_panel.visible = not admin_panel.visible
	if admin_panel.visible:
		admin_status_label.text = "Режим разработчика: параметры применяются сразу"

func _admin_money() -> void:
	cash += 10000
	event_text = "Админ: добавлено $10,000."
	_refresh_ui()
	admin_status_label.text = "Баланс увеличен на $10,000"

func _admin_staff() -> void:
	officers += 10
	event_text = "Админ: добавлено 10 сотрудников."
	_refresh_ui()
	admin_status_label.text = "В штат добавлено 10 сотрудников"

func _admin_safety() -> void:
	safety = 100
	event_text = "Админ: безопасность города установлена на 100%."
	_refresh_ui()
	admin_status_label.text = "Безопасность города: 100%"

func _admin_level() -> void:
	station_level += 5
	event_text = "Админ: уровень участка увеличен на 5."
	_refresh_ui()
	admin_status_label.text = "Уровень участка повышен на 5"

func _admin_vehicles() -> void:
	vehicles += 5
	for i in range(5):
		var car := Node3D.new()
		world_root.add_child(car)
		_box(car, Vector3(1.5,0.45,0.8), Vector3.ZERO, Color(0.82,0.88,0.94))
		_box(car, Vector3(0.75,0.3,0.83), Vector3(0,0.32,0), Color(0.10,0.22,0.34))
		car.position = Vector3(-8 + (car_nodes.size() % 8) * 2, 0.35, 7.1)
		car_nodes.append(car)
	event_text = "Админ: добавлено 5 машин."
	_refresh_ui()
	admin_status_label.text = "В автопарк добавлено 5 машин"

func _admin_new_call() -> void:
	_new_call()
	event_text = "Админ: вызов создан принудительно."
	_refresh_ui()
	admin_status_label.text = "Создан новый вызов диспетчера"

func _admin_reset_stats() -> void:
	calls_done = 0
	safety = 12
	station_level = 1
	event_text = "Админ: статистика сброшена. Бюджет и персонал сохранены."
	_refresh_ui()
	admin_status_label.text = "Сброшены уровень, безопасность и счётчик вызовов"
