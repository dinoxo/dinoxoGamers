# Preventas, foto y alertas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar lanzamientos USA verificados, abrir fichas desde Plus, reconocer fotos sin confirmación y avisar precios/lanzamientos en Android aun con la app cerrada.

**Architecture:** Las fuentes públicas aportan identidad, consola, fecha y precio sin inventar datos. La foto se lee localmente gratis; Gemini usa únicamente la clave que el usuario guarde de forma segura. Precio y lanzamiento son tipos de alerta diferentes persistidos en SQLite; WorkManager y notificaciones Android los comprueban en segundo plano.

**Tech Stack:** Flutter/Dart, Kotlin Android, ML Kit, HTTP, SQLite, WorkManager, flutter_local_notifications.

**Spec:** Solicitud del usuario del 30 de septiembre de 2026 en esta conversación.

## Global Constraints

- Solo tiendas y fechas de Estados Unidos; USD cuando existe precio.
- Nintendo, PlayStation y Xbox; nunca atribuir portada o precio de otro juego.
- No compilar APK, no cambiar versión ni incrustar claves privadas.
- No mostrar preventa activa si la fuente solo anuncia un juego.
- La notificación de precio exige precio digital verificado y permiso Android; el sistema puede retrasar WorkManager.

## Review Focus

- Imagen HEIF/JPEG de cámara o galería: nunca clasificar error de ML Kit como error de formato.
- Foto con logos/edición/rating: abrir solo ficha de coincidencia verificable o mostrar resultados para elegir.
- Búsqueda tras cambiar consola: descartar respuestas antiguas sin perder el texto.
- Fecha de salida sin día preciso: no programar aviso de un día antes.
- Clave Gemini: solo almacenamiento cifrado del dispositivo, sin logs ni respaldo inseguro.

---

### Task 1: Catálogo y UI Preventas

**Files:** Crear `lib/data/datasources/preorder_source.dart`, `lib/ui/features/preorders/preorders_screen.dart`, pruebas respectivas; modificar `lib/ui/navigation/main_shell.dart` al integrar.

- [ ] Escribir pruebas de listado anunciado/preventa, plataforma USA, fecha verificable, búsqueda y autocompletado restringidos a próximos juegos.
- [ ] Ejecutar pruebas y comprobar que fallan antes de implementar.
- [ ] Implementar consulta dinámica, paginación, estados sin precio inventado, días restantes y ficha.
- [ ] Integrar entre Plus y Mis Alertas; comprobar pruebas y análisis estático.

### Task 2: Foto y búsqueda real

**Files:** Modificar `PhotoTextReader.kt`, `ocr_service.dart`, `search_screen.dart`, `deals_screen.dart`, `web_scraper_service.dart`, `game_repository.dart`; crear pruebas correspondientes.

- [ ] Probar el endpoint `/autocomplete?term=` real y resultados estructurados.
- [ ] Escribir pruebas de decodificación/error diferenciado, sugerencias remotas, respuesta tardía y foto sin diálogo.
- [ ] Corregir decoder, validación de títulos y navegación automática a coincidencia única; si hay varias, mostrar fichas para elegir.
- [ ] Añadir reconocimiento opcional Gemini con clave personal cifrada, imagen acotada, salida JSON validada y verificación posterior en catálogo.
- [ ] Ejecutar pruebas, análisis, y verificación en dispositivo si hay uno conectado.

### Task 3: Fichas Plus y alertas de lanzamiento

**Files:** Modificar `live_plus_screen.dart`, `user_alert.dart`, `local_database_service.dart`, `game_repository.dart`, `notification_service.dart`, `price_alert_scheduler.dart`, `alerts_screen.dart`, manifiesto y pruebas.

- [ ] Escribir pruebas de botón Ver detalles, migración de alertas existentes, alerta de un día/salida y precio con app cerrada.
- [ ] Abrir ficha del juego desde Plus mediante identidad de título y compañía verificada.
- [ ] Persistir tipo y fecha de alerta; mostrar cuenta regresiva en Mis Alertas sin precio objetivo para lanzamientos.
- [ ] Notificar lanzamiento un día antes y día de salida con deduplicación; mantener comprobación de precios por WorkManager.
- [ ] Verificar reinicio, permiso, desactivación y borrado; ejecutar pruebas/analizador sin compilar APK.
