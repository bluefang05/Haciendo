# Changelog

## Cambios locales pendientes

- Version actualizada a `0.1.5+6` para publicar un AAB nuevo con Android `minSdk 21` fijado explicitamente.
- Version actualizada a `0.1.4+5` para publicar un AAB nuevo con visor full screen de fotos en los pasos.
- Las fotos de cada paso ahora se abren en pantalla completa al tocarlas; editar queda en el menu de tres puntos.
- Paquete Android alineado con Google Play: `com.enmanuelapps.haciendo`; los respaldos antiguos con el identificador previo siguen siendo aceptados al importar.
- Version actualizada a `0.1.3+4` para publicar un AAB nuevo tras corregir el paquete.
- Version actualizada a `0.1.2+3` y AAB configurado con clave local de subida para Google Play.
- Version actualizada a `0.1.1+2` para que Google Play acepte un bundle nuevo con versionCode superior.
- AÃ±adido `docs/REFINEMENT_PLAYBOOK.md`, una lista reutilizable de oportunidades de mejora aplicables a Haciendo y a otros proyectos similares.
- Compartir proceso ahora abre mucho mas rapido con pocas fotos: reutiliza las imagenes ya preparadas por la app en vez de recomprimirlas otra vez, y Android recibe permisos de lectura mas compatibles para multiples archivos.
- Compartir proceso ahora pregunta si se quieren enviar fotos en tamano original o comprimidas, explicando que original es mas rapido y comprimido tarda mas pero pesa menos.
- Multilenguaje reforzado: el idioma por defecto sigue el sistema, se agrego resolucion segura de locales, textos pendientes de Ajustes, recursos Android por idioma y una prueba basica de traducciones.
- El release local usa firma debug si no existe una clave release privada, permitiendo instalar `flutter run --release` en dispositivos de prueba.
- El banner inferior ahora usa el espacio inferior del `Scaffold` para evitar que el boton de agregar se superponga a la publicidad.
- El detalle del proyecto ahora permite **Compartir proceso**: envía las fotos públicas en orden mediante el menú nativo de Android, sin APIs de redes sociales.
- Los avances sin título real ahora se muestran como `Paso 1`, `Paso 2`, etc.; si cambia el orden, el nombre automático se reajusta sin tocar títulos escritos por el usuario.
- Los campos de texto ahora tienen límites razonables: 80 caracteres para títulos, 1000 para descripciones y 500 para materiales.
- Las pantallas de guardar avance, editar proyecto y PIN ahora respetan el área segura inferior de Android para no quedar debajo de los botones de navegación del sistema.
- Añadido flujo rápido para gente que no quiere escribir: foto rápida desde el proyecto y desde Añadir avance, guardando el paso con título automático.

- El guardado de pasos nuevos con fotos ahora limpia archivos importados si algo falla antes de registrar el avance.
- La foto rÃ¡pida desde el proyecto ahora ofrece tomar otra foto inmediatamente despuÃ©s de guardar.
- Los avances se pueden eliminar desde su tarjeta y recuperar al momento con Deshacer.
- Compartir proceso usa copias temporales numeradas para ayudar a conservar el orden en el menÃº nativo de Android sin tocar los originales.

- La foto rapida del proyecto ahora funciona como una sesion continua: muestra cuantas fotos se guardaron y permite tomar otra o terminar claramente.
- Compartir proceso ahora genera copias temporales redimensionadas para redes y mensajeria, preservando los originales y reduciendo riesgo de fallos por archivos pesados.
- La importacion de respaldos ahora valida el ZIP antes de extraerlo y reemplaza proyectos usando una carpeta temporal para no borrar el proyecto anterior antes de completar la restauracion.
- La busqueda del inicio ahora espera brevemente al escribir y siempre aplica la ultima consulta, aunque una carga anterior siga en curso.
- El dialogo de importacion de respaldo ahora usa textos localizados.
- La papelera ahora carga proyectos por paginas y el borrado definitivo prepara primero la carpeta de fotos para poder recuperarla si falla la eliminacion en la base de datos.
- El inicio reutiliza la consulta de portada de cada proyecto durante la carga actual, reduciendo trabajo repetido al redibujar tarjetas.
- Android `minSdk` queda fijado explicitamente en 21 para evitar cambios accidentales por futuras versiones de Flutter.
- Los textos visibles pendientes de la papelera pasaron por localizacion.
- El detalle del proyecto ahora carga las fotos de cada pagina de avances en una sola consulta agrupada.
- Presentacion carga fotos publicas por paginas y sigue cargando al avanzar, evitando traer todo el proyecto al abrir.
- Galeria permite seguir cargando fotos al navegar en el visor y localiza su estado vacio.
- Antes/despues, secuencia, editor de proyecto, avisos y exportaciones usan mas textos localizados.
- Las exportaciones PDF preparan copias reducidas de las imagenes antes de insertarlas para bajar memoria y tamano del archivo sin modificar originales.

## 0.1.0 - 2026-08-02

- Base Flutter Android API 21.
- Proyectos y avances locales con SQLite.
- Fotografías múltiples y miniaturas.
- Estados, favoritos, papelera y privacidad por avance.
- PIN práctico por proyecto.
- Exportaciones PDF y respaldo ZIP.
- Importación de respaldo.
- Modo Secuencia con cámara, guía transparente y vista previa.
- Recordatorios locales opcionales.
- Banner AdMob adaptable inferior.
- Temas claro/oscuro/sistema.
- Localización inicial en cinco idiomas.
- Dependencias de cámara y selección de imágenes fijadas a versiones compatibles con Android API 21.
- Corregido el orden del bloque de plugins de Gradle para permitir compilaciones release.
