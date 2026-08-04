# Estado de implementación

## Incluido

- Proyecto Flutter y Android con `minSdk 21`, `targetSdk 36`.
- SQLite local para proyectos, avances, fotos y ajustes.
- Proyectos ilimitados con búsqueda y paginación.
- Estados, favoritos, papelera y portada.
- Avances con varias fotos, notas, materiales, fecha, privacidad e hitos.
- Originales preservados; miniaturas y copias de visualización.
- Galería paginada, historia, presentación y comparación antes/después.
- Cuatro formatos PDF.
- ZIP de respaldo restaurable y ZIP humano para compartir.
- Importación como copia o reemplazo explícito.
- Modo Secuencia: cámara, onion skin, reordenar, duplicar, borrar, vista previa y ZIP numerado.
- PIN práctico por proyecto con bloqueo al salir de la app.
- Recordatorios opcionales.
- Temas claro, oscuro y sistema.
- Cinco idiomas con fallback español.
- Banner AdMob adaptable inferior con ID de prueba en debug.
- Canal Android nativo para rutas privadas y compartir, evitando dependencias que rompen API 21.

## No incluido todavía

- Codificación MP4 de stop motion. Los fotogramas ya pueden exportarse numerados.
- Cifrado real de archivos; el PIN es una barrera de interfaz.
- Consentimiento UMP final y política pública de privacidad.
- Pruebas de integración en un dispositivo API 21.

## Validación de esta entrega

El entorno usado para generar el ZIP no dispone del SDK Flutter. Se realizaron comprobaciones estáticas de estructura, XML, YAML, JSON, rutas y empaquetado, pero aún deben ejecutarse `flutter analyze`, `flutter test` y una compilación real.
