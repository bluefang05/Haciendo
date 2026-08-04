# Haciendo: contexto maestro del proyecto

## Producto

**Haciendo: proceso en fotos** es una aplicación Android local para registrar el progreso visual de proyectos físicos o creativos: dibujo, pintura, cocina, manualidades, restauración, jardinería, costura, carpintería, proyectos escolares y stop motion.

La idea central es: **guardar el proceso, no solo el resultado**.

## Marca

- Desarrollador: Enmanuel Apps.
- Paquete Android: `com.enmanuelapps.haciendo`.
- Identidad: capas simples que progresan desde contorno hasta una forma completa con una H.
- Paleta: naranja, terracota, coral, durazno y crema.
- No usar verde en el icono principal.
- No usar cámara, martillo, pincel o aguja como símbolo principal.

## Compatibilidad

- Flutter para Android.
- Android minSdk 21 en adelante; compileSdk/targetSdk 36 para publicación 2026.
- API 21 es un requisito de producto, no una preferencia.
- Todo local, sin cuenta, servidor ni Firebase.

## Funciones aprobadas

- Proyectos ilimitados, limitados solo por el almacenamiento del dispositivo.
- Paginación y miniaturas.
- Estados: Idea, En proceso, Pausado, Terminado y Archivado.
- Favoritos y papelera.
- Avances con título, descripción, materiales, fecha, hito y visibilidad privada.
- Varias fotos por avance.
- Conservación del original por defecto.
- Preferencia de almacenamiento ajustable para nuevas fotos.
- Vistas cronológica y galería.
- Comparación antes/después.
- Cuatro exportaciones PDF: Historia, Tutorial, Álbum y Antes/después.
- ZIP de respaldo restaurable con `backup.json` e imágenes.
- ZIP compartible distinto del respaldo interno.
- Compartir con Android: Drive, correo, mensajería y otros destinos.
- Importar respaldos sin reemplazar silenciosamente proyectos existentes.
- Modo Secuencia para stop motion.
- Cámara con fotograma anterior transparente como guía.
- Reordenar, duplicar, eliminar y previsualizar fotogramas.
- Exportación de fotogramas numerados.
- Generación MP4 solo si puede implementarse sin romper API 21 ni inflar excesivamente el proyecto.
- Recordatorios opcionales por proyecto.
- PIN práctico opcional por proyecto.
- Tema claro, oscuro y seguir sistema.
- Idiomas: español, inglés, portugués, francés y alemán.
- Banner AdMob inferior, discreto y fácil de ignorar.

## AdMob

- App ID: `ca-app-pub-3322493998376707~6272582654`
- Banner release: `ca-app-pub-3322493998376707/2990833259`
- Banner Android de prueba: `ca-app-pub-3940256099942544/6300978111`
- Debug siempre usa prueba.
- El banner no aparece en cámara, secuencia, presentación, PIN ni exportación.

## Decisiones de datos

- SQLite guarda proyectos, avances, fotografías y ajustes.
- Las imágenes se almacenan como archivos, no blobs SQLite.
- Cada proyecto tiene carpeta propia.
- El original se guarda por defecto.
- Se generan miniaturas para listados.
- Los eliminados pasan a papelera hasta vaciado manual.

## Prioridad de implementación

1. Integridad y recuperación de datos.
2. API 21.
3. Fluidez con muchas imágenes.
4. Facilidad de registrar avances.
5. Exportación y compartir.
6. Apariencia y animación.

## No hacer

- No convertirla en gestor de tareas empresarial.
- No exigir porcentajes de progreso.
- No imponer categorías de manualidades.
- No añadir red social.
- No subir contenido automáticamente.
- No insertar anuncios dentro de proyectos o documentos exportados.
