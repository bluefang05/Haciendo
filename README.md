# Haciendo: proceso en fotos

Aplicación Flutter local para documentar cómo un proyecto va tomando forma mediante fotografías, notas y secuencias visuales.

## Regla principal

**Android minSdk 21. No elevarlo.**

Antes de cambiar dependencias, lee `AGENTS.md` y `PROJECT_CONTEXT.md`.

## Preparación

1. Instala Flutter estable y Java 17.
2. Si `android/gradlew` no está presente, ejecuta en Windows `tools\prepare_android_wrapper.bat` o en macOS/Linux `tools/prepare_android_wrapper.sh`. El script obtiene el wrapper desde un proyecto Flutter temporal sin tocar el código de Haciendo.
3. Ejecuta `flutter pub get`.
4. Ejecuta `flutter analyze` y `flutter test`.
5. Conecta un dispositivo o emulador Android API 21 o superior.
6. Ejecuta `flutter run`.

## Publicidad

- Desarrollo/debug: unidad de banner de prueba de Google.
- Release: unidad real configurada en `lib/data/services/ad_service.dart`.
- App ID real ya está en `AndroidManifest.xml`.

Nunca pulses anuncios reales durante pruebas.

## Compilación

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

## Estado

Esta entrega es una base MVP amplia y documentada. Incluye almacenamiento local, proyectos, avances, fotografías, secuencia con cámara y guía transparente, exportación PDF/ZIP, importación de respaldo, PIN práctico, recordatorios y banner inferior. Revisa `PENDING.md` antes de publicar.


## Firma release

Copia `android/key.properties.example` como `android/key.properties`, crea tu keystore de subida y completa los valores. Nunca incluyas la clave real en el ZIP ni en Git.
