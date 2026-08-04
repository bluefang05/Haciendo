# Codex: empieza aquí

Lee en este orden y no reconstruyas el producto desde conversaciones anteriores:

1. `project_context.json` — resumen legible por máquina.
2. `PROJECT_CONTEXT.md` — alcance funcional completo.
3. `AGENTS.md` — reglas obligatorias de implementación.
4. `docs/ARCHITECTURE.md` — mapa del código.
5. `PENDING.md` — tareas realmente pendientes.

## Mandato crítico

- Paquete: `com.enmanuelapp.haciendo`.
- Marca: Enmanuel Apps.
- Android: **minSdk 21**. Nunca elevarlo silenciosamente.
- `compileSdk` y `targetSdk`: 36.
- App local; no añadir Firebase, cuenta, servidor ni sincronización.
- No actualizar dependencias sin volver a verificar API 21.
- No usar `share_plus` ni `path_provider` sin comprobar una versión compatible.
- Los IDs reales de AdMob solo se usan en release; debug usa el banner oficial de prueba.

## Antes de modificar

Busca primero la función existente. No dupliques pantallas, servicios o modelos. Mantén la documentación actualizada y ejecuta análisis, pruebas y compilación en API 21.
