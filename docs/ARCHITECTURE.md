# Arquitectura

- `lib/app`: arranque, estado global y navegación.
- `lib/core`: localización, tema, utilidades y widgets comunes.
- `lib/data/models`: modelos serializables.
- `lib/data/db`: esquema SQLite y consultas.
- `lib/data/repositories`: operaciones de dominio.
- `lib/data/services`: archivos, imágenes, exportación, anuncios, PIN, recordatorios y plataforma.
- `lib/features`: pantallas por función.

## Flujo de imágenes

1. Cámara o selector devuelve un archivo temporal/original.
2. `FileStorageService` copia a la carpeta privada del proyecto.
3. `ImageProcessingService` crea una miniatura.
4. SQLite registra rutas y orden.
5. Las listas cargan miniaturas; la vista completa carga el archivo principal.

## Respaldo

`backup.json` contiene versión de esquema y proyecto. Las imágenes se guardan en `images/`. La importación genera nuevos IDs por defecto para evitar colisiones.
