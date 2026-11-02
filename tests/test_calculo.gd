extends SceneTree
## godot --headless -s res://tests/test_calculo.gd  (sale con código 1 si falla)

var fallos := 0

func ok(nombre: String, real: float, esperado: float) -> void:
	if abs(real - esperado) > 0.001:
		fallos += 1
		printerr("FALLA %s: %s != %s" % [nombre, real, esperado])
	else:
		print("ok   %s = %s" % [nombre, real])

func _init() -> void:
	# Caso 1: valores por defecto (PLA 400/kg, 50 g, 3 h, 0.15 kWh/h, $3/kWh, $2/h, margen 50 %)
	var r := Calculo.calcular(Calculo.defaults())
	ok("filamento", r.filamento, 20.0)
	ok("luz", r.luz, 1.35)
	ok("desgaste", r.desgaste, 6.0)
	ok("costo", r.costo, 27.35)
	ok("precio sin comisión", r.precio, 41.025)
	ok("ganancia", r.ganancia, 13.675)
	# Caso 2: PETG, diseño de lote, empaque, comisión 20 %, 10 piezas
	var d := Calculo.defaults()
	d.material = "PETG"; d.precio_kg.PETG = 500.0
	d.gramos = 100.0; d.horas = 5.0; d.horas_diseno = 2.0; d.tarifa_diseno = 100.0
	d.cantidad = 10; d.empaque = 5.0; d.comision = 20.0; d.margen = 30.0
	r = Calculo.calcular(d)
	ok("filamento2", r.filamento, 50.0)
	ok("luz2", r.luz, 2.25)
	ok("desgaste2", r.desgaste, 10.0)
	ok("diseño2 repartido", r.diseno, 20.0)
	ok("costo2", r.costo, 87.25)
	ok("costo lote2", r.costo_lote, 872.5)
	ok("precio2", r.precio, 87.25 * 1.3 / 0.8)
	ok("comisión2", r.comision_monto, 87.25 * 1.3 / 0.8 * 0.2)
	ok("ganancia2 = margen sobre costo", r.ganancia, 87.25 * 0.3)
	ok("ganancia lote2", r.ganancia_lote, 261.75)
	# Caso 3: comisión 100 % es inválida
	d.comision = 100.0
	r = Calculo.calcular(d)
	ok("comisión 100 inválida", 1.0 if not r.valido else 0.0, 1.0)
	ok("precio centinela", r.precio, -1.0)
	ok("comisión centinela", r.comision_monto, -1.0)
	ok("ganancia 0 si inválido", r.ganancia, 0.0)
	ok("precio finito", 1.0 if is_finite(r.precio) else 0.0, 1.0)
	d.comision = 150.0
	r = Calculo.calcular(d)
	ok("comisión 150 inválida", 1.0 if not r.valido else 0.0, 1.0)
	# Caso 4: persistencia
	var main_script = load("res://scripts/main.gd")
	var g := Calculo.defaults(); g.gramos = 123.0; g.precio_kg.TPU = 777.0
	# Ruta temporal por pid: no toca user://config.cfg real.
	var tmp := "user://test_config_%d.cfg" % OS.get_process_id()
	var real_antes := FileAccess.get_file_as_bytes("user://config.cfg") if FileAccess.file_exists("user://config.cfg") else PackedByteArray()
	main_script.guardar(g, tmp)
	var c: Dictionary = main_script.cargar(tmp)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	ok("tmp borrado", 0.0 if FileAccess.file_exists(tmp) else 1.0, 1.0)
	var real_despues := FileAccess.get_file_as_bytes("user://config.cfg") if FileAccess.file_exists("user://config.cfg") else PackedByteArray()
	ok("config real intacto", 1.0 if real_antes == real_despues else 0.0, 1.0)
	ok("guardado gramos", c.gramos, 123.0)
	ok("guardado TPU", c.precio_kg.TPU, 777.0)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
