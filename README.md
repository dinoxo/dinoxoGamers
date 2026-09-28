# Dinoxo Gamers

App Flutter para Android, gratuita y sin activación de licencias. Consulta juegos digitales de PlayStation, Nintendo y Xbox en **Estados Unidos / USD**. Interfaz en español.

## Datos de ofertas y búsquedas

`LiveWebScraperService` consulta bajo demanda páginas públicas de **Deku Deals**. Configura las consolas mediante el formulario público de preferencias anónimas del sitio y solicita la región `country=us`. No necesita cuentas, claves ni una API de pago.

- Buscar consulta la web al escribir un título; no filtra un catálogo fijo. Incluye paginación y selección de marca.
- Ofertas consulta caídas de precio y muestra únicamente descuentos digitales publicados para la tienda oficial de cada marca en USA.
- Cada ficha valida la moneda, el formato digital, la plataforma y el dominio/región del enlace oficial. Los importes publicados en centavos se convierten a USD.
- Una ficha sin precio permanece sin precio. No se crean juegos, rebajas, fechas ni valoraciones como alternativa a una consulta fallida.
- La app muestra la fuente y cuándo hizo la consulta. Deku Deals es un agregador: sus datos pueden tener demora respecto de la tienda. El importe final se confirma en el comercio.
- Errores HTTP, problemas de conexión y fichas parcialmente disponibles son estados visibles. No se evita el bloqueo de una fuente.

PSDeals, NTDeals y XBDeals se conservan como enlaces externos de referencia. Las peticiones directas comprobadas a esos sitios fueron bloqueadas; no se usan para rellenar las ofertas de la app. La implementación actual está destinada a Android, no a un cliente Flutter Web sujeto a CORS.

## Fichas, reseñas e historial

Al abrir una ficha se vuelven a consultar sus datos. Las puntuaciones de Metacritic y OpenCritic que publica Deku Deals se resumen automáticamente, con fuente, fecha y enlaces a los análisis. Las puntuaciones pueden corresponder a otra versión y no incluyen necesariamente el número de reseñas. No se inventan pros, contras, FPS, idiomas ni testimonios. Reddit se ofrece como búsqueda externa de opiniones.

SQLite conserva las fichas consultadas, favoritos, biblioteca y observaciones reales de precio. La gráfica comienza con lo observado en este teléfono, no con una curva ficticia del pasado. No se declara un mínimo histórico absoluto basándose únicamente en el precio actual. El estimador requiere al menos tres ciclos de rebajas observados y presenta una estimación, no una fecha garantizada.

Las fechas de fin de oferta se muestran tal como las publica la fuente cuando están disponibles. No se deduce una fecha absoluta a partir de un texto que no especifica año o zona horaria.

## Inicio, fotos y alertas

El icono de instalación usa el medallón circular de dinoxo.Store, completo y con transparencia exterior. Al iniciar una sesión nueva, una presentación de 2,6 segundos muestra primero el logo y luego «dinoxo.Store». La app carga sus datos durante la presentación. Esta no se repite al volver de minimizar y se descarta si se minimiza mientras se reproduce. Con movimiento reducido habilitado, muestra una entrada breve sin los efectos de escala o desplazamiento.

La cámara y galería usan el selector de imágenes de Android. El permiso de cámara se solicita al usarla; el selector de fotos de Android 13 o posterior no requiere acceso a toda la galería. Un puente Android invoca **ML Kit Text Recognition** con el modelo latino incluido (`com.google.mlkit:text-recognition:16.0.1`), admite rutas locales y URI y lee el texto en el teléfono. Combina títulos repartidos entre líneas y descarta texto habitual del embalaje. El usuario confirma o corrige el título y se ejecuta la búsqueda web. Si no se lee texto, se puede escribir el título; un permiso denegado tiene su propio mensaje. Se recupera la selección cuando Android interrumpe la actividad durante el selector. No se envía la foto a un servidor de reconocimiento. Android mínimo: el mayor entre 23 y el mínimo de Flutter.

Las alertas permiten escribir un importe exacto en USD con hasta dos decimales y lo guardan en SQLite para la edición elegida. Mis Alertas se actualiza al guardar, permite activar/desactivar y tiene actualización manual. Se compara el precio real consultado con el objetivo en centavos: se avisa si es igual o inferior. El permiso denegado conserva la alerta y explica cómo habilitarlo.

WorkManager revisa las alertas activas en segundo plano con conexión a internet, con un intervalo solicitado de 15 minutos. Android puede retrasarlo por ahorro de batería; forzar la detención impide estos trabajos hasta abrir de nuevo la app. También se revisan al consultar precios en primer plano. Los avisos respetan el silencio de 22:00 a 08:00 y una espera de 24 horas por alerta; la prevención de duplicados persiste y coordina las comprobaciones de primer y segundo plano. No se prometen avisos instantáneos. Los avisos por mínimo absoluto o 24 horas antes de finalizar necesitan datos adicionales y no se ofrecen como una función activa.

## Plus y membresías USA

Plus consulta los catálogos públicos oficiales de PlayStation Plus, Xbox Game Pass para consola y Nintendo Switch Online de Estados Unidos. Combina las listas actuales con anuncios oficiales de altas y sus fechas; Nintendo incluye también el catálogo de SEGA Genesis. No necesita cuentas ni claves de pago.

Los filtros separan los juegos disponibles ahora, las altas del mes en curso y los anuncios fechados para el mes siguiente. Si todavía no hay anuncios, se indica sin inventar juegos ni fechas. Se muestra el nivel requerido, consola, fuente y momento de la consulta. Un error al verificar una compañía aparece en pantalla y retira sus coincidencias anteriores. El catálogo se vuelve a consultar al abrir Plus o actualizarlo; se reutiliza durante 30 minutos.

Ofertas, Buscar y las fichas comparten este catálogo y sugieren revisar la membresía antes de comprar. La coincidencia exige el mismo título y marca, conserva números de secuela, ediciones y complementos y descarta verificaciones de más de 24 horas. Los originales emulados de Nintendo no se usan para afirmar que un remake vendido para Switch está incluido. La app no conoce la suscripción del usuario ni los juegos mensuales que haya reclamado antes.

## Dinoxo Store

- Web: [dinoxostore.com](https://dinoxostore.com/)
- Instagram: [@dinoxo.store](https://www.instagram.com/dinoxo.store/)
- TikTok: [@dinoxo.store](https://www.tiktok.com/@dinoxo.store)
- WhatsApp: [0426 815 8785](https://wa.me/584268158785)

Los botones preparan consultas sobre saldo y gift cards USA para que el usuario las revise y envíe. Los montos del selector son denominaciones solicitadas, no cotizaciones de venta en tiempo real.

## Verificación sin APK

Con Flutter disponible:

```sh
flutter pub get
flutter analyze
flutter test
```

Prueba de consultas reales utilizando el mismo servicio Dart de la app:

```sh
dart run tool/live_client_probe.dart
dart run tool/live_subscription_probe.dart
```

También se pueden obtener respuestas actuales y comprobar el parser contra ellas:

```sh
node --use-system-ca tool/probe_live_catalog.mjs
flutter test test/live/catalog_network_test.dart --dart-define=LIVE_CATALOG_PROBE=true
node --use-system-ca tool/probe_subscriptions.mjs
flutter test test/live/subscription_network_test.dart --dart-define=LIVE_SUBSCRIPTION_PROBE=true
```

Las respuestas de comprobación se guardan en `build/live-probe` y `build/subscription-probe`, excluidos del código de producción. Las pruebas normales usan respuestas sintéticas aisladas en `test/fixtures` y no requieren internet. Si el contenedor Linux necesita las autoridades certificadoras del anfitrión, `tool/export_probe_certificates.mjs` exporta exclusivamente certificados públicos para la utilidad de comprobación; no cambia la validación TLS de la app.

Desde `android`, `bash gradlew :app:compileDebugKotlin` verifica código Android sin empaquetar un APK. Cámara y notificaciones necesitan además una prueba posterior en un dispositivo Android.

No se ha generado un APK en esta revisión. La versión del proyecto se conserva en `1.3.0+4`.
