# Catálogo, fotos y estabilidad Implementation Plan

> **For agentic workers:** Usar superpowers:executing-plans para ejecutar aquí las correcciones autorizadas. No crear APK ni publicar.

**Goal:** Evitar bloqueos, mostrar suscripciones USA comprobadas y evitar imágenes/fichas de otro juego.

**Architecture:** Procesar respuestas grandes fuera del hilo de interfaz y crear tarjetas visibles bajo demanda. Mantener identidad estricta de título, edición y consola en las fuentes. Separar beneficios, altas y retiradas, con fecha y fuente pública.

**Tech Stack:** Flutter/Dart, HTTP público, Android ML Kit local, pruebas Flutter y sondeos Dart sin APK.

**Spec:** Solicitudes del usuario en este chat del 28 de septiembre de 2026.

## Global Constraints

- Nintendo, PlayStation y Xbox, exclusivamente Estados Unidos y USD.
- No compilar ninguna APK, cambiar versión, licenciar ni publicar.
- No sustituir datos inaccesibles por catálogos o imágenes ficticios.
- Mantener alertas y estado de las pantallas ya visitadas.

## Review Focus

- Catálogos de 1.700 entradas: no construir todas las tarjetas ni bloquear el hilo principal al analizar HTML.
- Feed con juegos solo PC: no mostrarlos como acceso de consola ni inventar retiradas.
- Una portada con tres líneas: mantener el título completo y permitir corregirlo.
- Una búsqueda con varias ediciones/consolas: abrir automáticamente solo una coincidencia inequívoca.
- Oferta relacionada/primer resultado de Steam ajeno: nunca heredar portada o reseña de otro título.

### 1. Estabilidad

- [x] Reproducir construcción de 1.700 tarjetas en `test/widget/plus_large_catalog_test.dart` y medir pausas con `tool/subscription_responsiveness_probe.dart`.
- [x] Modificar `SubscriptionSource.fetch(GamePlatform, DateTime)` para analizar respuestas pesadas con `Isolate.run` y mantener fixtures de HTTP inyectados.
- [x] Indexar títulos en `live_subscription_service.dart`, hacer Plus y pestañas inactivas perezosas y mostrar la primera pantalla antes de inicializaciones externas.
- [x] Ejecutar prueba grande y sondeo antes/después.

### 2. Suscripciones actuales

- [x] Reproducir retirada Xbox con fecha publicada en `test/unit/subscription_departures_test.dart`.
- [x] Crear `MembershipBenefits`/`SubscriptionCatalog` en modelo dedicado y `fetchCatalog(GamePlatform, DateTime)` en fuente.
- [x] Extraer beneficios de páginas oficiales USA; conservar catálogo si una fuente secundaria falla. Fusionar salidas con el catálogo por identidad, sin reutilizar imágenes de anuncios.
- [x] Mostrar actuales, altas del mes, próximos, mes siguiente, salidas y beneficios en `live_plus_screen.dart`; distinguir información no comprobable de ausencia de anuncios.
- [x] Probar fechas, niveles, errores parciales y consultar las tres fuentes reales.

### 3. Identidad de imágenes

- [x] Reproducir Ghost de una ficha de Zelda y relleno ajeno en `cover_identity_test.dart`/`media_identity_test.dart`.
- [x] Restringir `LiveWebScraperService.parseItem(String, Uri, DateTime)` a la identidad de la ficha.
- [x] Verificar nombre de búsqueda y detalle en `GameMediaService`, quitar imágenes de relleno y etiquetar enlaces de búsqueda de vídeo.
- [x] Probar secuelas, edición remasterizada, falta de imágenes y resultado ajeno de Steam.

### 4. Fotos

- [x] Reproducir título en tres líneas y foto sin apertura de ficha con pruebas de OCR y pantalla.
- [x] Añadir reconocimiento con candidatos y pista de consola, límite de tiempo y lectura de imagen fuera del hilo Android principal.
- [x] Buscar en la web y abrir `GameDetailsScreen` solo para coincidencia exacta única; mostrar resultados reales en casos ambiguos.
- [x] Ejecutar pruebas de galería, cámara simulada, errores y ambigüedad. Comprobar código Kotlin sin empaquetar APK si el entorno lo permite.

### 5. Verificación final

- [x] `flutter test --no-pub` y `flutter analyze --no-pub` con Docker.
- [x] Sondeos de fuentes/tiempo de respuesta, revisión de diferencias y documentación.
- [x] Confirmar APK y versión intactos; declarar prueba física pendiente si no hay teléfono conectado.

## Evidencia del 28 de septiembre de 2026

- Suite general: **96 pruebas aprobadas**, dos pruebas de red optativas omitidas en la ejecución normal. Las consultas reales se ejecutaron por separado con los servicios de producción.
- Análisis Flutter final: **No issues found**. Diferencias sin errores de espacios.
- Revisión independiente aplicada: identidad obligatoria de página, renovación de ficha con título/consola coincidentes, advertencias por errores parciales, apertura de foto solo con consulta completa, feed ilegible y secciones Xbox que no representan altas.
- Sondeo real: 716 registros PlayStation, 355 Nintendo y 634 Xbox (incluyen distintos planes y anuncios, no son recuentos de títulos únicos disponibles). Los beneficios se verificaron para tres planes PS, dos Nintendo y tres Xbox. Xbox devolvió tres incorporaciones futuras y ocho retiradas con fecha publicada; PS/Nintendo no devolvieron anuncios futuros en las fuentes consultadas.
- Ghost y Zelda: ocho y seis resultados respectivamente; **ninguna portada compartida**. Ghost en Plus conserva la imagen de su producto oficial PlayStation.
- Sondeo de procesamiento: pausa máxima del temporizador de 270,675 ms antes y 74,118 ms al final. Es una medida del proceso Dart en Docker, no una prueba de FPS o de ausencia de bloqueos en el teléfono.
- Android: `:app:compileDebugKotlin --offline --no-daemon -x :app:compileFlutterBuildDebug`, **BUILD SUCCESSFUL**, sin tareas de empaquetado APK.
- Versión conservada `1.4.0+5`; APK existente `DinoxoGamers-V1.4.apk` de 93.114.243 bytes y fecha 28/09/2026 01:54:37 intacto. Sin nuevos APK bajo `build`.
- No hay teléfono conectado: cámara, selector de galería, recepción de notificaciones y fluidez física pendientes de comprobación. Fechas de retirada PS no publicadas en las fuentes oficiales consultadas se muestran como no comprobables.
