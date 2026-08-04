# Instrucciones obligatorias para agentes

Lee primero `PROJECT_CONTEXT.md` y `docs/ARCHITECTURE.md`.

## Compatibilidad crítica

- Android mínimo: API 21.
- No subir `minSdk` a 22, 23, 24 ni superior.
- No aceptar automáticamente actualizaciones de paquetes.
- Antes de añadir o actualizar una dependencia, revisar su Android mínimo y sus requisitos de Flutter, Gradle, Kotlin y Java.
- Si una dependencia exige API superior, fijar una versión compatible, reemplazarla o escribir una implementación pequeña nativa.
- Probar siempre en API 21 y en una versión Android moderna.

## Alcance y privacidad

- La aplicación es local y funciona sin cuenta.
- No añadir Firebase, servidor, login ni sincronización automática.
- Google Drive se usa mediante el menú Compartir de Android.
- No añadir permisos amplios de almacenamiento.
- Los archivos originales se conservan por defecto.
- Un PIN es privacidad práctica, no cifrado criptográfico del contenido.

## Eficiencia

- Usar paginación y carga diferida.
- No cargar proyectos enteros ni todas sus imágenes en memoria.
- Usar miniaturas en cuadrículas.
- Procesar imágenes y exportaciones grandes fuera del hilo de interfaz cuando sea posible.
- Evitar paquetes pesados para tareas simples.
- Cerrar y liberar cámara, anuncios, controladores y streams.

## Consistencia

- Todos los textos visibles deben pasar por localización.
- No cambiar el paquete `com.enmanuelapp.haciendo`.
- No cambiar el nombre visible `Haciendo: proceso en fotos` sin decisión explícita.
- Mantener el banner fuera de cámara, secuencia, presentación, PIN y vistas de exportación.
- Actualizar `CHANGELOG.md`, `PENDING.md` y `docs/DECISIONS.md` con cambios relevantes.

## Entrega mínima de cambios

- `flutter analyze` sin errores.
- `flutter test` aprobado.
- Compilación debug en API 21.
- Verificación manual de creación, edición, eliminación, respaldo, importación y compartir.
