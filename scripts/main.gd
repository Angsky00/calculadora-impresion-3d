extends Control
## UI responsiva construida por código. Guarda en user://config.cfg.

const RUTA := "user://config.cfg"
var datos: Dictionary
var campos := {}
var sel_material: OptionButton
var campo_precio_kg: SpinBox
var salida: RichTextLabel
var cargando := false

const CAMPOS := [
	["gramos", "Gramos de filamento (por pieza)", 0.0, 100000.0, 0.1],
	["horas", "Horas de impresión (por pieza)", 0.0, 10000.0, 0.1],
	["tarifa_kwh", "Tarifa de luz ($/kWh)", 0.0, 1000.0, 0.01],
	["kwh_hora", "Consumo de la impresora (kWh/hora)", 0.0, 100.0, 0.01],
	["desgaste_hora", "Desgaste ($/hora)", 0.0, 10000.0, 0.1],
	["horas_diseno", "Horas de diseño y personalización (lote)", 0.0, 10000.0, 0.25],
	["tarifa_diseno", "Tarifa de diseño ($/hora)", 0.0, 100000.0, 1.0],
	["cantidad", "Cantidad de piezas", 1.0, 100000.0, 1.0],
	["empaque", "Empaque ($ por pieza)", 0.0, 100000.0, 0.5],
	["comision", "Comisión de la plataforma (%)", 0.0, 99.0, 0.5],
	["margen", "Margen de ganancia sobre costo (%)", 0.0, 10000.0, 1.0],
]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	datos = cargar()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	scroll.add_child(margen)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	margen.add_child(col)
	var titulo := Label.new()
	titulo.text = "Calculadora de impresión 3D"
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(titulo)
	var grid := GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(grid)
	sel_material = OptionButton.new()
	for m in Calculo.MATERIALES:
		sel_material.add_item(m)
	sel_material.select(Calculo.MATERIALES.find(datos.material))
	sel_material.item_selected.connect(_on_material)
	_fila(grid, "Material", sel_material)
	campo_precio_kg = _spin(0.0, 100000.0, 1.0)
	campo_precio_kg.value = datos.precio_kg[datos.material]
	campo_precio_kg.value_changed.connect(func(v): if not cargando: datos.precio_kg[datos.material] = v; _actualizar())
	_fila(grid, "Precio del kilo ($/kg)", campo_precio_kg)
	for c in CAMPOS:
		var s := _spin(c[2], c[3], c[4])
		s.value = datos[c[0]]
		var clave: String = c[0]
		s.value_changed.connect(func(v): datos[clave] = int(v) if clave == "cantidad" else v; _actualizar())
		campos[clave] = s
		_fila(grid, c[1], s)
	var reset := Button.new()
	reset.text = "Restaurar valores iniciales"
	reset.pressed.connect(_restaurar)
	col.add_child(reset)
	salida = RichTextLabel.new()
	salida.bbcode_enabled = true
	salida.fit_content = true
	salida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salida.add_theme_font_size_override("normal_font_size", 18)
	salida.add_theme_font_size_override("bold_font_size", 18)
	col.add_child(salida)
	resized.connect(func(): grid.columns = 2 if size.x >= 700 else 1)
	grid.columns = 2 if get_viewport_rect().size.x >= 700 else 1
	_actualizar()

func _spin(mn: float, mx: float, paso: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = mn; s.max_value = mx; s.step = paso
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 44
	s.select_all_on_focus = true
	return s

func _fila(grid: GridContainer, texto: String, ctrl: Control) -> void:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)
	ctrl.custom_minimum_size.y = 44
	grid.add_child(ctrl)

func _on_material(i: int) -> void:
	datos.material = Calculo.MATERIALES[i]
	cargando = true
	campo_precio_kg.value = datos.precio_kg[datos.material]
	cargando = false
	_actualizar()

func _restaurar() -> void:
	datos = Calculo.defaults()
	cargando = true
	sel_material.select(0)
	campo_precio_kg.value = datos.precio_kg.PLA
	for k in campos:
		campos[k].set_value_no_signal(datos[k])
	cargando = false
	_actualizar()

static func _m(v: float) -> String:
	return "$%s" % String.num(v, 2)

func _actualizar() -> void:
	guardar(datos)
	var r := Calculo.calcular(datos)
	var t := "[b]Costo por pieza[/b]\n"
	t += "Filamento: %s\nLuz: %s\nDesgaste: %s\nDiseño y personalización: %s\nEmpaque: %s\n" % [_m(r.filamento), _m(r.luz), _m(r.desgaste), _m(r.diseno), _m(r.empaque)]
	t += "[b]Costo total: %s[/b] (lote: %s)\n\n" % [_m(r.costo), _m(r.costo_lote)]
	if r.valido:
		t += "[b]Precio de venta sugerido: %s[/b] (lote: %s)\n" % [_m(r.precio), _m(r.precio_lote)]
		t += "Comisión de plataforma: %s por pieza\n" % _m(r.comision_monto)
		t += "[b]Ganancia por pieza: %s[/b]\n[b]Ganancia por lote: %s[/b]" % [_m(r.ganancia), _m(r.ganancia_lote)]
	else:
		t += "[color=red]La comisión debe ser menor a 100 %.[/color]"
	salida.text = t

static func cargar() -> Dictionary:
	var d := Calculo.defaults()
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return d
	for k in d:
		d[k] = cfg.get_value("datos", k, d[k])
	if not d.material in Calculo.MATERIALES:
		d.material = "PLA"
	return d

static func guardar(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in d:
		cfg.set_value("datos", k, d[k])
	cfg.save(RUTA)
