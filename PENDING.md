# Pendientes antes de publicación

## Mejoras priorizadas de integridad y rendimiento

- Hecho: restauracion segura con reemplazo, validacion previa del ZIP y busqueda rapida sin descartar la ultima consulta.
- Hecho: guardar avances nuevos con fotos como operación completa y limpiar archivos importados si algo falla antes de registrar el avance.
- Hecho: reducir consultas repetidas de portadas en Inicio durante reconstrucciones de tarjetas.
- Hecho: reducir consultas repetidas de fotografías en el detalle del proyecto cargando fotos por pagina de avances.
- Hecho: procesar imágenes reducidas para exportaciones PDF, conservando originales.
- Hecho: el borrado definitivo de proyectos desde papelera prepara la carpeta de fotos y la restaura si falla la eliminación en la base de datos.
- Evitar archivos huérfanos al borrar avances, secuencias o fotogramas.
- Recuperarse de valores de configuración dañados y preparar migraciones seguras de la base de datos.
- Hecho: localizar textos visibles pendientes de la papelera.
- Hecho: localizar textos visibles pendientes en galería, antes/después, presentación, secuencia, editor de proyecto y exportaciones.
- Revisar accesibilidad, tamaños grandes de letra y descripciones de iconos.
- Ampliar pruebas para respaldo, restauración, falta de espacio, cancelación de cámara, eliminación y proyectos grandes.
- Hecho: fijar explícitamente Android `minSdk 21` para impedir que una futura versión de Flutter lo cambie accidentalmente.

Orden recomendado: restauración segura, guardado completo, validación de respaldos, búsqueda y rendimiento.

## Compartir el proceso en redes y mensajería

- Hecho: añadir una opción visible **Compartir proceso** distinta de compartir el respaldo o el ZIP.
- Hecho: compartir las fotos públicas juntas mediante el menú nativo de Android, sin integrar APIs ni cuentas de redes sociales.
- Pendiente: permitir seleccionar varias fotos o avances y conservar su orden cronológico, desde el inicio hasta el resultado.
- Hecho: ajustar copias para compartir a un tamaño razonable sin modificar ni borrar las fotografías originales.
- Mostrar una vista previa y permitir reordenar o excluir imágenes antes de abrir el menú Compartir.
- Tener en cuenta que la aplicación de destino decide si admite varias imágenes; ofrecer como alternativa una composición o PDF cuando no las acepte.

## Títulos automáticos de avances

- Hecho: mostrar `Paso 1`, `Paso 2`, etc. cuando un avance no tiene título escrito por el usuario.
- Hecho: conservar intactos los títulos reales escritos por el usuario.
- Pendiente: aplicar la misma regla cuando se añada eliminación/reordenamiento visual de avances.

## Límites de texto

- Hecho: limitar títulos de proyecto y avance a 80 caracteres.
- Hecho: limitar descripciones a 1000 caracteres y materiales a 500 caracteres.
- Pendiente: revisar visualmente textos largos en tarjetas, PDF y presentación con tamaño de letra grande del sistema.

## Áreas seguras del sistema

- Hecho: proteger botones inferiores de guardar avance, editar proyecto y PIN contra la barra de navegación clásica de Android.
- Pendiente: revisar manualmente el resto de pantallas en móviles con botones de navegación y con gestos.

## Flujo rápido sin pensar

- Hecho: añadir foto rápida desde el detalle del proyecto para crear y guardar un paso sin escribir.
- Hecho: añadir acciones rápidas en Añadir avance para tomar o elegir fotos y guardar como siguiente paso.
- Hecho: permitir repetir captura rápida desde el aviso de avance guardado sin buscar otra vez el botón.
- Pendiente: evaluar un ajuste opcional para abrir cámara directamente al tocar Añadir avance.
- Hecho: convertir la captura rápida repetida en modo continuo con contador y salida clara.

- Validar compilación física en Android API 21; este entorno no incluye Flutter.
- Revisar permisos y comportamiento de notificaciones en Android 13–16.
- Añadir pruebas de integración para importación de respaldos grandes.
- Añadir selección visual avanzada de páginas PDF.
- Mejorar comparación con deslizador.
- Evaluar exportación MP4 sin elevar minSdk ni aumentar demasiado el AAB.
- Añadir consentimiento UMP donde sea obligatorio antes de publicar anuncios personalizados.
- Sustituir iconos Android generados por la versión final aprobada si cambia.
- Crear política de privacidad pública y ficha de Play Store.
- Configurar firma release privada fuera del repositorio antes de publicar en Play Store.
