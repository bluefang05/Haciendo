# Dependencias y compatibilidad

Fecha de revisión: 2026-08-02.

- `google_mobile_ads 9.0.0`: mínimo Android API 21.
- `flutter_local_notifications 19.5.0`: se fija porque 21.0.0 elevó Android mínimo a API 24.
- `file_picker 8.3.7`: mínimo API 21.
- `image_picker`: implementación Android API 21+.
- `camera`: usado para la guía transparente del modo Secuencia.
- `sqflite`: metadatos locales.
- `archive`: ZIP restaurable y ZIP compartible.
- `pdf`: generación local de cuatro presentaciones.
- `image`: miniaturas y copias optimizadas.
- `crypto`: hash del PIN práctico.

## Dependencias omitidas intencionalmente

- `share_plus`: versiones recientes ya no preservan Android 21.
- `path_provider`: versión reciente declara Android 24+.

Estas funciones se resuelven mediante un canal Android nativo pequeño.
