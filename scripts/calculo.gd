class_name Calculo
extends RefCounted
## Fórmulas puras (sin UI) para poder probarlas.

const MATERIALES := ["PLA", "PETG", "ABS", "TPU"]

static func defaults() -> Dictionary:
	return {
		"material": "PLA",
		"precio_kg": {"PLA": 400.0, "PETG": 450.0, "ABS": 420.0, "TPU": 600.0},
		"gramos": 50.0, "horas": 3.0,
		"tarifa_kwh": 3.0, "kwh_hora": 0.15, "desgaste_hora": 2.0,
		"horas_diseno": 0.0, "tarifa_diseno": 150.0,
		"cantidad": 1, "empaque": 0.0, "comision": 0.0, "margen": 50.0,
	}

## d: diccionario con las claves de defaults(). Gramos, horas y empaque son POR PIEZA;
## las horas de diseño son por LOTE y se reparten entre la cantidad.
static func calcular(d: Dictionary) -> Dictionary:
	var cant: int = max(1, int(d.cantidad))
	var precio_kg: float = d.precio_kg[d.material]
	var filamento: float = d.gramos / 1000.0 * precio_kg
	var luz: float = d.horas * d.kwh_hora * d.tarifa_kwh
	var desgaste: float = d.horas * d.desgaste_hora
	var diseno: float = d.horas_diseno * d.tarifa_diseno / cant
	var empaque: float = d.empaque
	var costo := filamento + luz + desgaste + diseno + empaque
	var c: float = d.comision / 100.0
	var m: float = d.margen / 100.0
	var valido := c < 1.0
	# Con comisión >= 100 % no existe precio: precio y comisión valen -1.0 (centinela) y valido = false.
	# Precio bruto P tal que lo que queda tras la comisión cubre costo + margen:
	# P * (1 - c) = costo * (1 + m)  =>  P = costo * (1 + m) / (1 - c)
	var precio := costo * (1.0 + m) / (1.0 - c) if valido else -1.0
	var comision_monto := precio * c if valido else -1.0
	var ganancia := precio - comision_monto - costo if valido else 0.0
	return {
		"filamento": filamento, "luz": luz, "desgaste": desgaste,
		"diseno": diseno, "empaque": empaque, "costo": costo,
		"costo_lote": costo * cant, "precio": precio,
		"comision_monto": comision_monto,
		"ganancia": ganancia, "ganancia_lote": ganancia * cant,
		"precio_lote": precio * cant, "valido": valido,
	}
