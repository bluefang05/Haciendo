# Lista reutilizable de oportunidades de mejora

Este documento recoge aprendizajes detectados durante el refinamiento de **Haciendo**. La intención es que pueda leerse desde otro proyecto y sirva como lista de revisión para aplicaciones móviles locales, visuales, de registro, creación, organización, exportación o captura rápida.

La regla central es: **reducir fricción, proteger datos y hacer que la app funcione bien incluso cuando la persona no quiere pensar**.

## 1. Flujo simple para personas con poca paciencia

- Permitir completar la acción principal sin escribir texto obligatorio.
- Crear valores por defecto útiles: `Paso 1`, `Paso 2`, fecha actual, estado inicial, visibilidad normal.
- Hacer que los valores automáticos se reajusten cuando cambia el orden, pero sin tocar títulos reales escritos por la persona.
- Separar el flujo rápido del flujo detallado: quien quiere solo tirar fotos puede hacerlo; quien quiere describir todo también.
- Después de guardar una acción repetible, ofrecer repetir inmediatamente la misma acción.
- Mostrar una salida clara del modo rápido o continuo para que la persona no se sienta atrapada.
- Evitar formularios largos antes de la primera captura o primer guardado.
- Poner la acción primaria donde el pulgar la espera, pero sin tapar anuncios ni controles del sistema.
- Usar textos de ayuda cortos que expliquen el beneficio, no instrucciones pesadas.
- No pedir decisiones irreversibles al principio si pueden decidirse después.

## 2. Estados vacíos que empujan a empezar

- Cada pantalla vacía debe responder: qué es esto, por qué sirve y cuál es el primer botón.
- El primer botón debe ser concreto: “Crear primer perfil”, “Añadir primera foto”, “Guardar primer paso”.
- Evitar pantallas vacías que parezcan error.
- Si hay varias opciones, destacar la más probable y esconder lo avanzado.
- Usar ejemplos humanos: perros/gatos, dibujo/cocina/restauración, antes/después, proceso/resultado.
- Mostrar una promesa de valor antes de pedir trabajo.

## 3. Títulos, textos y límites razonables

- Limitar títulos a un tamaño humano, por ejemplo 60–100 caracteres.
- Limitar descripciones largas sin impedir que alguien documente bien; 800–1500 caracteres suele ser razonable.
- Limitar campos secundarios como materiales, notas o etiquetas.
- Mostrar contador o ayuda cuando la persona se acerque al límite.
- Validar longitud antes de guardar, no solo visualmente.
- Probar tarjetas, diálogos, PDF, vista grande y presentación con textos extremos.
- Diferenciar texto vacío de texto escrito: un título automático no debe guardarse como si fuera título real si la app necesita recalcularlo.
- Evitar que un texto largo rompa botones, barras inferiores, exportaciones o listados.

## 4. Áreas seguras en móviles reales

- Revisar pantallas con navegación clásica de Android: triángulo, círculo y cuadrado.
- Revisar también navegación por gestos, pantallas pequeñas y letra grande.
- Proteger botones inferiores con área segura real, no solo con margen fijo.
- Evitar que banners de publicidad ocupen el mismo espacio que botones flotantes o acciones primarias.
- No poner acciones críticas debajo del teclado.
- Comprobar formularios con teclado abierto, orientación vertical y pantallas de baja altura.
- Mantener fuera la publicidad en pantallas inmersivas: cámara, PIN, presentación, exportación o captura guiada.
- Si hay barra inferior, confirmar que la última tarjeta o campo puede desplazarse por encima de ella.

## 5. Captura, cámara y fotos

- Mantener la cámara lo más directa posible: abrir, capturar, guardar, repetir.
- Cerrar cámara, streams y controladores al salir.
- No cargar todas las fotos originales en memoria para listados.
- Usar miniaturas para cuadrículas y tarjetas.
- Conservar originales por defecto.
- Generar copias reducidas solo para compartir, PDF o previsualización.
- Si una captura se cancela, no crear registros vacíos.
- Si una importación de foto falla, limpiar las copias parciales.
- En modos de secuencia, mostrar claramente el fotograma anterior o guía.
- Numerar archivos compartidos o exportados para preservar orden.

## 6. Guardado e integridad de datos

- Guardar datos y archivos como una operación coherente: si falla una parte, no dejar fichas rotas.
- Al crear algo con archivos, importar archivos primero y registrar en base de datos después.
- Si se crean archivos temporales y falla el guardado, limpiarlos.
- Al borrar, preferir papelera o deshacer antes del borrado definitivo.
- Para borrados definitivos, mover archivos a una zona temporal antes de confirmar la base de datos.
- Si falla la base de datos, restaurar los archivos movidos.
- Evitar archivos huérfanos al borrar elementos hijos: fotos, fotogramas, avances, adjuntos.
- Validar respaldos antes de extraer: formato, rutas relativas, tamaños, cantidad de archivos y manifiesto.
- Nunca reemplazar silenciosamente un proyecto existente durante una importación.
- Preparar migraciones seguras para cambios futuros de base de datos.

## 7. Papelera, deshacer y recuperación

- Las eliminaciones normales deben ser recuperables.
- Mostrar “Deshacer” inmediatamente después de borrar algo importante.
- La papelera debe cargar por páginas si puede crecer mucho.
- Vaciar papelera debe tratarse como acción de más riesgo que borrar normal.
- Explicar cuándo algo ya no será recuperable.
- Si un borrado físico falla después de borrar la base de datos, registrar o aislar el resto para limpieza futura.
- Evitar que una restauración rompa el orden, nombres, fotos o privacidad del contenido.

## 8. Rendimiento con muchos elementos

- Cargar listas por páginas.
- Cargar imágenes por demanda.
- Agrupar consultas: pedir fotos de varios elementos en una sola consulta en vez de una consulta por tarjeta.
- Evitar recalcular portadas o miniaturas en cada reconstrucción visual.
- Usar caché de resultados pequeños durante una carga.
- No abrir un proyecto completo si la pantalla solo necesita una página.
- En visores, cargar más contenido cuando la persona se acerca al final.
- Mantener exportaciones pesadas fuera del hilo de interfaz cuando sea posible.
- Reducir imágenes antes de insertarlas en PDF o paquetes compartibles.
- Probar proyectos grandes, no solo ejemplos pequeños.

## 9. Compartir sin APIs externas

- Usar el menú nativo de Android para compartir con Drive, correo, mensajería y redes cuando sea suficiente.
- No integrar APIs de redes sociales si solo se necesita enviar archivos.
- Separar “compartir proceso” de “crear respaldo”.
- El respaldo debe ser restaurable; el paquete compartible debe ser legible para humanos.
- Compartir fotos públicas en orden cronológico.
- Crear copias temporales numeradas para ayudar a que otras apps conserven el orden.
- Reducir copias compartidas para evitar rechazos por tamaño.
- Avisar que la app destino decide si acepta varias imágenes.
- Ofrecer alternativas cuando el destino no acepte varias imágenes: PDF, collage, composición o ZIP.
- No compartir contenido privado por accidente.

## 10. Exportaciones útiles

- Ofrecer formatos según intención: historia, tutorial, álbum, antes/después, respaldo.
- No insertar publicidad en documentos exportados.
- No modificar originales para exportar.
- Localizar títulos, etiquetas y estados dentro del documento.
- Controlar tamaño de PDF cuando hay muchas fotos.
- Preparar imágenes reducidas con tamaño máximo razonable.
- Mantener orden cronológico y títulos automáticos consistentes.
- Incluir metadatos suficientes para entender el proceso fuera de la app.
- Permitir exportar algo simple aunque falten descripciones.
- Probar exportación con fotos pesadas y proyectos largos.

## 11. Localización y textos visibles

- Todo texto visible debe pasar por localización.
- Incluir textos de errores, avisos, estados vacíos, botones, exportaciones y etiquetas.
- Evitar textos duros en código que luego aparecen mezclados en otros idiomas.
- Pensar en plurales, género y textos más largos en otros idiomas.
- Probar idiomas con palabras largas, como alemán.
- Mantener nombres de marca consistentes.
- No traducir identificadores técnicos que deban quedarse estables.

## 12. Accesibilidad y comodidad visual

- Revisar tamaño grande de letra del sistema.
- Asegurar contraste suficiente en tema claro y oscuro.
- Agregar descripciones a iconos que ejecutan acciones.
- No depender solo del color para comunicar estado.
- Hacer botones táctiles suficientemente grandes.
- Evitar textos cortados en navegación inferior.
- Revisar pantallas pequeñas y densidad alta.
- Confirmar que lectores de pantalla tengan nombres comprensibles.
- No poner acciones destructivas demasiado cerca de acciones frecuentes.

## 13. Privacidad práctica

- Si la app es local, mantenerla realmente local: sin cuenta, servidor ni sincronización automática.
- Explicar con honestidad qué protege un PIN y qué no protege.
- No prometer cifrado si no existe.
- Evitar permisos amplios de almacenamiento.
- Usar carpetas privadas de la app cuando sea posible.
- Compartir solo cuando la persona lo inicia.
- Separar elementos privados de públicos en vistas y exportaciones.
- No subir contenido automáticamente.
- Evitar analytics o servicios externos si no son necesarios.

## 14. Publicidad sin estorbar

- El anuncio no debe tapar la acción principal.
- El anuncio no debe aparecer en pantallas donde rompe concentración o privacidad.
- Reservar espacio real para el banner.
- Probar con banner cargado y sin cargar.
- No poner publicidad dentro del contenido creado por la persona.
- Revisar consentimiento publicitario cuando aplique.
- En modo debug, usar anuncios de prueba.

## 15. Compatibilidad Android y dependencias

- Fijar explícitamente el `minSdk` si es requisito de producto.
- Antes de actualizar dependencias, revisar Android mínimo, Gradle, Kotlin, Java y Flutter requeridos.
- No aceptar actualizaciones automáticas que rompan dispositivos antiguos.
- Mantener notas de decisiones para versiones fijadas.
- Probar en Android antiguo y moderno.
- Tener cuidado con plugins que elevan el mínimo sin parecerlo.
- Preferir implementaciones nativas pequeñas cuando una dependencia pesada rompe compatibilidad.
- Revisar avisos de build aunque todavía no fallen.

## 16. Formularios y edición

- Permitir guardar con mínimos datos.
- Mantener campos avanzados opcionales.
- Dar defaults humanos.
- No perder datos si la persona vuelve atrás accidentalmente.
- Evitar que el teclado tape el botón de guardar.
- Confirmar antes de descartar cambios reales.
- No confirmar si no hay cambios.
- Mantener el botón principal visible y seguro.
- Mostrar errores cerca del campo afectado.

## 17. Orden, reordenamiento y nombres automáticos

- El orden visual debe coincidir con exportaciones, compartir y presentación.
- Los nombres automáticos deben derivarse del orden actual.
- Los nombres escritos por usuarios no deben cambiarse al reordenar.
- Si se borra un elemento intermedio sin título real, los automáticos deben cerrar huecos.
- Si se comparte una serie, numerar copias o páginas.
- Si se exporta un tutorial, mantener pasos consistentes.
- El orden debe conservarse al restaurar respaldos.

## 18. Búsqueda y listas

- La búsqueda debe esperar brevemente mientras la persona escribe.
- Si hay varias cargas en paralelo, aplicar siempre la última consulta.
- No borrar resultados útiles por una respuesta vieja.
- Mostrar estado vacío específico para búsqueda sin resultados.
- Paginación y búsqueda deben convivir.
- Favoritos, archivados y papelera deben respetar filtros claros.

## 19. Pruebas que suelen revelar fallos reales

- Crear primer elemento sin escribir nada.
- Crear muchos elementos con muchas fotos.
- Borrar elemento del medio y revisar nombres automáticos.
- Usar textos muy largos.
- Abrir con letra grande del sistema.
- Usar navegación clásica de Android.
- Usar teclado abierto cerca del botón inferior.
- Compartir muchas imágenes a apps distintas.
- Exportar PDF con fotos pesadas.
- Importar respaldo válido, respaldo corrupto y respaldo de proyecto ya existente.
- Cancelar cámara o selector de imagen.
- Cortar espacio disponible o simular fallo de archivo.
- Revisar app en Android viejo y moderno.

## 20. Documentación que ayuda a no perder decisiones

- Mantener un changelog local de cambios pendientes.
- Mantener una lista de pendientes priorizada.
- Registrar decisiones técnicas con el motivo, no solo el resultado.
- Documentar restricciones no negociables: privacidad, compatibilidad, nombre de paquete, minSdk.
- Anotar por qué se evita una dependencia o servicio.
- Dejar claro qué es respaldo interno y qué es paquete compartible.
- Documentar pruebas mínimas antes de publicar.

## 21. Señales de que una app está más refinada

- La primera acción se entiende sin tutorial.
- Se puede usar con prisa.
- Se puede usar sin escribir.
- Los textos largos no rompen pantallas.
- Los botones no quedan debajo de Android.
- La publicidad no compite con el contenido.
- Las fotos pesadas no congelan la app.
- El contenido se puede recuperar si alguien se equivoca.
- Exportar y compartir no destruyen originales.
- La app funciona igual de bien en un proyecto pequeño y en uno grande.
- Las decisiones difíciles están documentadas.

## 22. Lista corta para aplicar en otro proyecto

Cuando se revise otro proyecto, empezar por estas preguntas:

1. ¿Cuál es la acción principal y puede hacerse sin pensar?
2. ¿Qué pasa si la persona no escribe nada?
3. ¿Qué pasa si escribe demasiado?
4. ¿Qué pasa si borra algo por error?
5. ¿Qué pasa si hay cientos o miles de elementos?
6. ¿Qué pasa si una foto, archivo o guardado falla a mitad?
7. ¿Qué pasa si el móvil usa botones clásicos de Android?
8. ¿Qué pasa si el teclado está abierto?
9. ¿Qué pasa si la persona comparte a una app que no soporta todo?
10. ¿Qué contenido debe quedarse privado?
11. ¿Qué se carga completo y qué debería cargar por páginas?
12. ¿Qué textos visibles siguen sin localizar?
13. ¿Qué dependencias pueden romper compatibilidad?
14. ¿Qué decisiones hay que escribir para no repetir errores?

