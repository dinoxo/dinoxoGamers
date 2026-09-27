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

La cámara y galería usan el selector existente de imágenes. Un puente Android invoca **ML Kit Text Recognition** con el modelo latino incluido (`com.google.mlkit:text-recognition:16.0.1`). Lee texto de la imagen localmente. El usuario selecciona/corrige el título reconocido y ese texto se busca en la web. No se envía la foto a un servidor de reconocimiento. Android mínimo: el mayor entre 23 y el mínimo de Flutter.

Las alertas guardan el precio objetivo en SQLite. Se evalúan al consultar una ficha, cargar resultados que contienen el juego o pulsar actualizar en Mis Alertas. Requieren permiso para notificar, respetan el silencio de 22:00 a 08:00 y guardan la última notificación para evitar repeticiones. **No hay vigilancia en segundo plano con la app cerrada.** Los avisos por mínimo absoluto o 24 horas antes de finalizar necesitan datos adicionales; no se ofrecen como una función activa.

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
```

También se pueden obtener respuestas actuales y comprobar el parser contra ellas:

```sh
node --use-system-ca tool/probe_live_catalog.mjs
flutter test test/live/catalog_network_test.dart --dart-define=LIVE_CATALOG_PROBE=true
```

Las respuestas de comprobación se guardan en `build/live-probe`, excluido del código de producción. Las pruebas normales usan respuestas sintéticas aisladas en `test/fixtures` y no requieren internet. Si el contenedor Linux necesita las autoridades certificadoras del anfitrión, `tool/export_probe_certificates.mjs` exporta exclusivamente certificados públicos para la utilidad de comprobación; no cambia la validación TLS de la app.

Desde `android`, `bash gradlew :app:compileDebugKotlin` verifica código Android sin empaquetar un APK. Cámara y notificaciones necesitan además una prueba posterior en un dispositivo Android.

No se ha generado un APK en esta revisión. La versión del proyecto se conserva en `1.1.0+2`.
