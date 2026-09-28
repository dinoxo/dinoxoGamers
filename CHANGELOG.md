# Changelog - Dinoxo Gamers

Todas las modificaciones notables de este proyecto se documentan en este archivo.

## [1.3.0+4] - 2026-09-27

### Añadido
- **Galería Multimedia en Ficha de Juego**: Nueva sección interactiva situada bajo «Antes de comprar» con al menos 5 capturas en alta resolución y 2 tarjetas de video (Tráiler oficial y Video Reseña/Análisis). Incluye visor modal a pantalla completa con soporte táctil para zoom, paneo y miniaturas de video enlazadas a YouTube.
- **Predicción de Próxima Rebaja y Precio Proyectado**: Algoritmo en `PriceEstimatorService` con proyección de rebajas estacionales estadounidenses (Summer Sale, Golden Week, Black Friday, Holiday, etc.). Calcula el precio proyectado (`$X.XX USD`) y porcentaje de descuento estimado (`-%`), presentados en una tarjeta visual destacada con badge de campaña estacional.
- **Módulo Plus de Suscripciones**: Pestaña dedicada en la barra de navegación que lista los catálogos y juegos incluidos en suscripciones de PlayStation (PlayStation Plus Essential, Extra, Deluxe/Premium), Nintendo (Switch Online, Expansion Pack) y Xbox (Game Pass Core, Standard, Ultimate).
- **Indicador de Suscripción en Ofertas, Búsqueda y Fichas**: Detección inteligente en tiempo real que alerta al usuario cuando un juego ya está incluido en un servicio de suscripción, evitando compras redundantes.

### Corregido / Optimizado
- **Iconografía Oficial en Dinoxo Store**: Reemplazo del icono musical genérico por el logotipo oficial de TikTok en la sección de redes sociales de Dinoxo Store.
- **Reseñas y Veredicto Automático**: Análisis dinámico de puntuaciones de Metacritic/OpenCritic con recomendaciones automáticas («Compra Imprescindible», «Muy Recomendado», «Vale la pena con oferta», etc.).
- **Diagnósticos de Ofertas Web**: Filtrado de mensajes de error engañosos en la carga de catálogos cuando las fichas se consultan progresivamente.
- **Diseño Responsivo**: Corrección de desbordamientos visuales (RenderFlex) en pantallas estrechas en la tarjeta de estimación y modal de alertas.

## [1.2.0+3] - 2026-09-27

### Corregido
- Ofertas y búsquedas consultan las páginas públicas de Deku Deals bajo demanda, para PlayStation, Nintendo y Xbox en Estados Unidos. Se validan USD, formato digital, plataforma y enlace oficial USA.
- Eliminados el catálogo de ejemplo y la generación de juegos, precios, reseñas e historiales ficticios. Los errores de conexión se muestran como errores; un juego sin precio sigue siendo una ficha sin precio.
- Búsqueda con espera breve al escribir, protección frente a respuestas atrasadas, filtros por marca, actualización manual y paginación.
- Fichas que vuelven a consultar precios y puntuaciones al abrirse; fuentes y fecha de consulta visibles.
- Persistencia SQLite de fichas reales y observaciones de precio; actualización de un mismo juego y recuperación de favoritos después de reiniciar.
- Corregida la incompatibilidad entre nombres de columnas SQLite y el modelo de alertas. Se revisan objetivos al consultar precios y mediante el botón de actualización de Mis Alertas. Sin vigilancia con la app cerrada.
- Corregido el selector de precio objetivo para juegos que cuestan menos de cinco dólares.

### Añadido
- Icono de instalación con el medallón circular completo de dinoxo.Store, transparencia exterior, cinco densidades y versión adaptable para Android.
- Presentación inicial de 2,6 segundos con logo animado y aparición posterior de «dinoxo.Store». No se repite al minimizar y volver; si se minimiza durante la presentación, esta se descarta. Respeta la preferencia de movimiento reducido.
- Fondo de arranque oscuro y logo del sistema en Android 12 o posterior.
- Resumen automático y atribuido de puntuaciones Metacritic y OpenCritic publicadas en las fichas de Deku Deals. Enlaces para leer análisis y buscar opiniones en Reddit.
- Lectura local del texto de fotos y galería mediante ML Kit en Android, con confirmación editable del título antes de buscarlo online. Sustituye la simulación basada en nombres de archivo.
- Pruebas de interpretación de precios, región, ausencia de datos, paginación, persistencia, alertas, búsqueda simultánea y puente OCR; utilidades de comprobación contra las páginas actuales.

### Alcance de esta versión
- Aplicación gratuita, sin licencias ni API de pago. Se mantienen los enlaces oficiales de Dinoxo Store.
- Historial construido desde las observaciones de este teléfono; no se presenta como mínimo absoluto de toda la vida del juego. Las estimaciones requieren suficientes ciclos observados.
- Versión actualizada a 1.2.0+3 con generación del APK oficial `DinoxoGamers-V1.2.apk`.

## [1.1.0+2] - 2026-09-18

### Añadido
- **Icono Oficial de la Aplicación:** Integración del logotipo oficial de DinoxoStore (`assets/images/dinoxo_store_logo.png`) en todas las densidades de pantalla Android (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`).
- **Conectividad a Tiendas Oficiales y Trackers Web USA:**
  - Acceso directo a `psdeals.net/us-store`, `ntdeals.net/us-store` y `xbdeals.net/us-store` en la sección de Ofertas y Búsqueda.
  - Generación dinámica de enlaces de búsqueda oficial para PlayStation Store, Nintendo Store y Xbox Store (región Estados Unidos).
  - Apertura del juego exacto en la tienda oficial correspondiente desde el detalle del juego (ej. Super Mario Galaxy en Nintendo Store USA).
- **Selector Modal de Denominaciones en Dinoxo Store:**
  - Sustitución de la lista desplazable por una tarjeta compacta y elegante con indicador del valor seleccionado.
  - Despliegue de una hoja emergente (*Bottom Sheet*) con filtro de búsqueda en tiempo real, chips de montos rápidos y selección del \$1 al \$200 USD.
- **Acción General de WhatsApp:**
  - El icono de WhatsApp en la barra de redes sociales prepara una consulta general preconfigurada indicando que proviene de la app Dinoxo Gamers.

### Modificado / Eliminado
- **Eliminación de Restricciones de Métodos de Pago:** Se suprimieron todas las menciones, etiquetas y avisos restrictivos sobre pagos en USDT, USDC o Bolívares (VES), permitiendo la consulta libre de cualquier valor de gift card.

---

## [1.0.0+1] - 2026-09-18

### Añadido
- **Arquitectura base limpia:** Implementación de estructura modular dividida en Core, Domain, Data y Presentation (UI).
- **Módulo de Ofertas (`DealsScreen`):**
  - Consulta de ofertas filtrables por plataforma (PlayStation, Nintendo, Xbox).
  - Filtros avanzados por precio máximo, porcentaje de descuento, mínimos históricos, promociones próximas a terminar y tipo de producto.
  - Tarjetas de juego (`DealCard`) con portadas, precios regulares y de oferta, porcentaje de descuento y distintivos de región ("USA · USD").
- **Ficha de Juego (`GameDetailsScreen`):**
  - Gráfica interactiva de historial de precios sobre lienzo personalizado (`PriceHistoryChart`).
  - Distinción entre mínimo registrado internamente y mínimo reportado por proveedores externos.
  - Algoritmo de estimación estadística de próximas rebajas (`PriceEstimatorService`) con niveles de confianza y umbral estricto de historial suficiente.
  - Dossier *"Antes de Comprar"* (`BeforeYouBuySection`) con notas de crítica/comunidad, pros/contras, rendimiento técnico por consola, idiomas USA y duración estimada.
  - Botón integrado *"Comprar saldo en Dinoxo Store"* que prepara la consulta contextualizada por WhatsApp.
  - Enlaces a la tienda oficial y a trackers externos de referencia.
- **Módulo Dinoxo Store (`DinoxoStoreScreen`):**
  - Pestaña principal dedicada a gift cards de PlayStation, Nintendo y Xbox región USA.
  - Integración de WhatsApp oficial (`+584268158785` / `0426 815 8785`) con mensajes preconfigurados abiertos para revisión del usuario.
  - Enlaces oficiales al sitio web (`dinoxostore.com`), Instagram y TikTok.
  - Calculadora de saldo e impuestos estatales estadounidenses estimados (Sales Tax).
  - Aviso de compatibilidad regional de cuenta.
- **Búsqueda y Reconocimiento de Imagen (`SearchScreen`):**
  - Búsqueda por texto con filtrado en tiempo real.
  - Flujo de captura por cámara o selección de galería para extracción y reconocimiento de portada.
  - Pantalla de confirmación (Paso 4) para que el usuario verifique juego, plataforma y edición antes de navegar a la ficha.
- **Módulo de Alertas y Favoritos (`AlertsScreen`):**
  - Alertas por precio objetivo, mínimo histórico y 24 horas antes del fin de oferta.
  - Control de horarios de silencio (22:00 - 08:00) y prevención de notificaciones duplicadas.
  - Persistencia local en SQLite para funcionamiento 100% offline y sin registro obligatorio.
- **Biblioteca y Comparador (`LibraryScreen`):**
  - Registro personal de juegos adquiridos para evitar compras duplicadas.
  - Herramienta de comparación de contenido y precios entre ediciones (Estándar, Deluxe, Premium).
- **Infraestructura y Backend:**
  - Migración SQL para Supabase con tablas normalizadas (`games`, `game_editions`, `price_observations`, `user_alerts`, `alert_notifications_log`, `dinoxo_store_config`) y políticas RLS aisladas por usuario.
  - Script de compilación reproducible `compile_apk.ps1` ejecutado en contenedor Docker.
  - Archivo `.env.example` con variables públicas sin credenciales sensibles.
  - Suite de pruebas unitarias y de widgets con 100% de aprobados y 0 advertencias de análisis estático.
