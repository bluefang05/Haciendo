# Decisiones técnicas

## ADR-016: Paquete Android para Google Play

La ficha de Google Play de Haciendo exige el paquete `com.enmanuelapps.haciendo`. El proyecto se alinea con ese identificador para que los AAB sean aceptados por la consola.

Los respaldos nuevos usan el formato `com.enmanuelapps.haciendo.backup`, pero la importacion conserva compatibilidad con respaldos previos `com.enmanuelapp.haciendo.backup`.

## ADR-009: Firma release local

Si `android/key.properties` existe, la compilación release usa la clave privada configurada fuera del repositorio. Si no existe, el build release usa la firma debug para permitir instalación local con `flutter run --release`.

Esta firma de respaldo es solo para pruebas en dispositivo. La publicación en Play Store sigue requiriendo una clave release privada no versionada.

## ADR-001: Android API 21

Se mantiene minSdk 21. Dependencias recientes que lo rompan no se actualizan automáticamente.

## ADR-002: Sin share_plus

Las versiones recientes elevaron el mínimo Android. Compartir se implementa con un `MethodChannel` y `FileProvider` nativos.

## ADR-003: Sin path_provider

La versión reciente ya no garantiza API 21. Las rutas de `filesDir` y `cacheDir` se obtienen mediante código Android nativo.

## ADR-004: Imágenes fuera de SQLite

SQLite contiene metadatos y rutas. Los binarios permanecen en carpetas del proyecto.

## ADR-005: PIN práctico

El PIN bloquea la interfaz del proyecto. No cifra archivos. Debe comunicarse con honestidad.

## ADR-006: Respaldo y paquete compartible separados

El respaldo preserva estructura restaurable. El paquete compartible prioriza legibilidad humana.

## ADR-010: Compartir proceso sin APIs sociales

La opción Compartir proceso usa el menú nativo de Android con `ACTION_SEND_MULTIPLE` para enviar las fotos públicas del proyecto en orden. No se integran APIs de redes sociales, cuentas ni publicación automática.

La app de destino decide si acepta varias imágenes. Para destinos que no lo soporten, las alternativas futuras son una composición de imágenes o un PDF.

## ADR-011: Capturar primero, describir después

El registro de avances debe funcionar sin texto obligatorio. Si una persona solo toma fotos, la app crea el avance con fecha actual y título automático por posición.

Los campos de título, descripción, materiales, privacidad e hito son opcionales y se pueden completar después. El flujo rápido no reemplaza el editor detallado; convive con él para usuarios que sí quieren documentar cada paso.

## ADR-012: Guardado rapido consistente

Los pasos nuevos con fotos se registran solo despues de importar correctamente sus archivos. Si una importacion falla antes de guardar la base de datos, se borran las copias creadas por la app y no queda un avance vacio accidental.

Compartir proceso puede crear copias temporales numeradas para que las apps de destino tengan una senal clara del orden cronologico. Las fotografias originales del proyecto no se modifican.

Las copias temporales para compartir se redimensionan a un tamano razonable para mensajeria y redes. Esto reduce memoria, tiempo de envio y rechazos de apps destino sin cambiar los archivos guardados del proyecto.

La captura rapida desde el proyecto se trata como una sesion: cada foto crea un paso nuevo sin pedir texto, se muestra el contador de fotos guardadas y la persona decide entre tomar otra o terminar.

## ADR-013: Restauracion segura de respaldos

La importacion valida el ZIP antes de extraer imagenes: formato, manifiesto, rutas relativas, cantidad de archivos y tamano total. Los archivos inesperados o rutas fuera del respaldo se rechazan.

Cuando se reemplaza un proyecto existente, las fotos nuevas se preparan en una carpeta temporal. Solo despues de importar todo se mueve la carpeta vieja a un respaldo temporal, se coloca la nueva carpeta en la ruta definitiva y se reemplazan los registros en una transaccion SQLite. Si falla el cambio final, se intenta restaurar la carpeta anterior.

## ADR-014: Borrado definitivo recuperable

Al vaciar un proyecto de la papelera, la carpeta de fotos se mueve primero a una ruta temporal dentro del almacenamiento privado de la app. Luego se elimina el registro del proyecto en SQLite, aprovechando las cascadas para avances y fotos.

Si falla la eliminacion en SQLite, la carpeta temporal se restaura a su ubicacion original. Si SQLite ya confirmo la eliminacion y falla el borrado fisico final, no se recrea el proyecto automaticamente; queda un resto de archivos que puede limpiarse despues sin dejar una ficha rota apuntando a fotos inexistentes.

## ADR-015: Exportaciones ligeras para uso real

Las exportaciones PDF usan copias preparadas en memoria con un lado maximo razonable antes de insertarlas en el documento. Los originales se conservan intactos en la carpeta del proyecto.

Las vistas de consulta intensiva deben cargar por paginas o por demanda. En detalle se cargan las fotos de cada pagina de avances con una consulta agrupada; en presentacion se cargan paginas de fotos publicas conforme se avanza.

## ADR-007: Stop motion incremental

La primera prioridad es captura estable, guía transparente, orden, vista previa y exportación de fotogramas. MP4 es ampliación condicionada a compatibilidad y tamaño.

## ADR-008: Plugins multimedia fijados para API 21

Se fijan `camera` 0.11.2+1 y `camera_android_camerax` 0.6.20+3. Esta es la última línea verificada cuya implementación Android declara `minSdkVersion 21`; versiones posteriores de CameraX exigen API 23 o superior.

También se fijan `image_picker` 1.2.0 e `image_picker_android` 0.8.13+1. La siguiente revisión de su implementación Android eleva el mínimo a API 24.

Se fija `flutter_plugin_android_lifecycle` 2.0.33 porque la versión 2.0.34 eleva el mínimo Android de API 21 a API 24.

Se fija `google_mobile_ads` 5.3.1, última versión verificada del plugin que declara Android API 21. La versión 6.0.0 requiere API 23 y las líneas posteriores requieren API 24.

La dependencia Android de WebView usada por AdMob se fija en `webview_flutter_android` 4.10.1; desde 4.10.2 exige API 24.
