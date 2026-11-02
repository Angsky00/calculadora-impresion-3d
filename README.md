# Calculadora de impresión 3D

App sencilla (Godot 4.7, GDScript) para calcular costo y precio de venta de una impresión 3D. Interfaz en español, responsiva (1 columna en móvil, 2 en pantallas ≥ 700 px). Todos los valores se guardan solos en `user://config.cfg` (ConfigFile).

## Fórmulas (`scripts/calculo.gd`)
Gramos, horas de impresión y empaque son **por pieza**; las horas de diseño son **por lote** y se reparten entre la cantidad.

| Concepto | Fórmula (por pieza) |
|---|---|
| Filamento | gramos / 1000 × precio del kg del material |
| Luz | horas × consumo kWh/h × tarifa $/kWh |
| Desgaste | horas × desgaste $/h |
| Diseño y personalización | horas de diseño × tarifa $/h / cantidad |
| Empaque | costo de empaque |
| **Costo total** | suma de lo anterior (lote = costo × cantidad) |
| **Precio sugerido (bruto)** | costo × (1 + margen) / (1 − comisión) |
| Comisión | precio × comisión |
| **Ganancia por pieza** | precio − comisión − costo = costo × margen |
| Ganancia por lote | ganancia × cantidad |

El margen es **sobre el costo** y la comisión se calcula sobre el precio bruto: el precio se sube lo necesario para que, después de que la plataforma cobre su %, quede exactamente costo + margen. Ej.: costo $100, margen 30 %, comisión 20 % → precio $162.50; comisión $32.50; te quedan $130 = $100 + $30. Una comisión ≥ 100 % se marca como inválida.

## Valores iniciales
PLA $400/kg · PETG $450/kg · ABS $420/kg · TPU $600/kg (PETG/ABS/TPU son estimados, editables) · 50 g · 3 h · luz $3/kWh · consumo 0.15 kWh/h · desgaste $2/h · diseño 0 h a $150/h · 1 pieza · empaque $0 · comisión 0 % · margen 50 %. El botón «Restaurar valores iniciales» los recupera.

## Pruebas
```
godot --headless --path . --import
godot --headless --path . -s res://tests/test_calculo.gd   # código 0 = todo bien
```

## Generar el APK
La CI (`.github/workflows/ci.yml`) corre las pruebas y exporta un **APK debug** que queda como artefacto `calculadora-3d-debug-apk` en cada ejecución (pestaña Actions).

Localmente se necesita: Godot 4.7, plantillas de export 4.7 en `~/.local/share/godot/export_templates/4.7.stable/`, JDK 17, Android SDK (platform-tools, build-tools) y un keystore debug:
```
keytool -genkeypair -keystore debug.keystore -storepass android -keypass android \
  -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
# En Editor > Ajustes del editor > Export > Android: ruta del Android SDK y del JDK
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$PWD/debug.keystore
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
godot --headless --path . --export-debug "Android" build/calculadora-3d-debug.apk
```
Para instalar: `adb install build/calculadora-3d-debug.apk` o copiar el APK al teléfono y permitir «orígenes desconocidos». Para escritorio basta abrir el proyecto en Godot y ejecutar.
