# Informe de validación de la entrega

Fecha: 2026-08-02

## Comprobaciones realizadas

- Estructura de 38 archivos Dart revisada mediante análisis estático básico de delimitadores.
- Todos los XML Android se parsean correctamente.
- `pubspec.yaml` y `analysis_options.yaml` se parsean correctamente.
- `project_context.json` es JSON válido.
- Todos los recursos PNG incluidos son legibles y tienen dimensiones válidas.
- Todos los identificadores de localización usados existen en español.
- Los cinco idiomas contienen el mismo conjunto completo de claves.
- `minSdk = 21`, `targetSdk = 36` y paquete `com.enmanuelapp.haciendo` están presentes.
- El App ID y el banner release de AdMob están configurados; debug usa el banner de prueba.
- El ZIP final fue verificado con prueba de integridad.

## Comprobaciones pendientes en una máquina con Flutter

Este entorno no dispone del SDK Flutter ni de Dart CLI. Por tanto, antes de publicar deben ejecutarse:

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

También debe probarse en un dispositivo o emulador API 21 y en un Android moderno. Esto está documentado, no escondido debajo de la alfombra.
