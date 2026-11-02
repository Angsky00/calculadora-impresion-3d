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

## APK liberado (release)
`export_presets.cfg` usa el preset **"Android"** con `package/signed=true` y deja vacíos los datos del keystore (no se suben al repo); Godot los toma de variables de entorno.

1. Genera tu keystore propio (una sola vez; guárdalo fuera del repo, `*.keystore` está en `.gitignore`, y respáldalo: sin él no podrás publicar actualizaciones):
   ```
   keytool -genkeypair -v -keystore ~/claves/calculadora3d-release.keystore \
     -alias calculadora3d -keyalg RSA -keysize 2048 -validity 10000
   ```
   `keytool` pide la contraseña y los datos (nombre, organización…). Usa la misma contraseña para el almacén y la clave.
2. Configura las variables (o llena `keystore/release`, `keystore/release_user` y `keystore/release_password` en Proyecto > Exportar > Android, sin commitear ese cambio):
   ```
   export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/claves/calculadora3d-release.keystore
   export GODOT_ANDROID_KEYSTORE_RELEASE_USER=calculadora3d
   export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='tu-contraseña'
   ```
3. Sube `version/code` (entero, +1 en cada versión) y `version/name` en `export_presets.cfg`.
4. Exporta:
   ```
   mkdir -p build
   godot --headless --path . --export-release "Android" build/calculadora-3d-release.apk
   ```
   Requiere las mismas plantillas 4.7, JDK 17 y Android SDK con build-tools que el APK debug.

**Firmar y alinear:** con `package/signed=true` Godot alinea (zipalign) y firma con `apksigner` del build-tools del SDK durante el export; no hace falta hacerlo a mano. Para verificar:
```
$ANDROID_SDK_ROOT/build-tools/<versión>/zipalign -c -v 4 build/calculadora-3d-release.apk
$ANDROID_SDK_ROOT/build-tools/<versión>/apksigner verify --verbose build/calculadora-3d-release.apk
```
Si exportas sin firmar (`package/signed=false`), alinea primero y firma después: `zipalign -p -f 4 entrada.apk alineado.apk` y luego `apksigner sign --ks <keystore> --ks-key-alias calculadora3d alineado.apk`. Para Google Play se usa AAB (`gradle_build/use_gradle_build=true`, `gradle_build/export_format=1`), que este preset no tiene activado.
