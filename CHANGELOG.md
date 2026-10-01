# Changelog - Dinoxo Gamers

Todas las modificaciones notables de este proyecto se documentan en este archivo.

## [1.8.0+9] - 2026-10-01

### Añadido
- **Módulo de Preventas USA:** Catálogo de próximos lanzamientos y preventas para PlayStation, Nintendo y Xbox con fechas anunciadas oficiales, búsqueda y autocompletado en tiempo real acotados a este catálogo, y acceso directo a la ficha del juego.
- **Alertas de Lanzamiento:** Mis Alertas ahora diferencia entre objetivos de precio y recordatorios de fecha de lanzamiento. Android programa avisos un día antes y el día anunciado de salida, restableciéndolos automáticamente tras reiniciar el teléfono.
- **Sugerencias y Reconocimiento de Foto:** El buscador predice títulos desde el endpoint web oficial y abre automáticamente la ficha cuando una foto identifica un juego único. Incluye lector local gratuito optimizado y soporte opcional de IA Gemini con clave personal almacenada de forma segura en el dispositivo.
- **Detalles desde Plus:** Se habilitó el acceso a la ficha completa de un juego directamente desde la sección "Ver detalles" en Plus.

### Corregido
- Corregido el motor de decodificación de fotos para evitar fallos de formato en imágenes de alta resolución o formatos recientes de Android (HEIC/JPEG).
- Ofertas y consultas en vivo ahora manejan títulos y descuentos actualizados dinámicamente sin bloqueos de memoria.

### Alcance
- Empaquetado en APK Release único universal `DinoxoGamers-V1.8.apk`, versión `1.8.0+9`.

### Verificación
- Pruebas Flutter y nativas Android aprobadas, consulta real de próximos lanzamientos USA verificada y empaquetado reproducible en contenedor.

## [1.7.0+8] - 2026-09-28

### Corregido
- Corregido el error IMAGE_INVALID que ocurría al analizar fotos tomadas o de la galería. Se cambió el acceso a los archivos para utilizar flujos directos en lugar de intentar forzar URLs de sistema, permitiendo que la foto se lea perfectamente.
- Reducción extrema de la presión de memoria y picos de recolección de basura (Garbage Collection) durante la consulta de juegos del catálogo de Nintendo Switch (Plus). Se reemplazaron algoritmos de parseo web pesados por expresiones regulares ligeras, solucionando problemas de "app congelada" o retardos de varios segundos en esa sección.
- El análisis de la cámara ahora omite la pantalla intermedia ("Confirma el título") y salta directamente a la búsqueda en la web si el escáner (OCR) detectó el nombre del juego con éxito y certeza. La pantalla de corrección manual solo aparecerá como respaldo si la foto es muy borrosa o ilegible.

### Añadido
- **Autocompletado predictivo en buscador:** La barra de "Escribe Tu Juego" ahora sugiere juegos instantáneamente (como Mario Kart, Super Mario Galaxy) al escribir 2 o más letras, gracias a una conexión nativa con la API en vivo.
- **Buscador en Ofertas:** Se agregó una barra inteligente de búsqueda ("Busca Tu oferta") sobre los filtros de plataformas. Este buscador filtra y localiza en tiempo real únicamente los títulos que estén descontados dentro de esa categoría.
## [1.6.0+7] - 2026-09-28

### Corregido
- Plus procesa cada consulta completa (descarga, decodificación y catálogo) fuera del hilo de la interfaz, con un límite que termina la tarea bloqueada. Las compañías se actualizan de forma progresiva y se evitan reintentos automáticos continuos.
- Los fallos parciales conservan las listas y planes comprobados. Si falla una actualización completa, se mantiene la consulta anterior durante la sesión, marcada pendiente; no genera consejos de compra como si estuviera recién verificada.
- Las membresías se abren dentro de la app. Nintendo muestra beneficios, DLC, bibliotecas por consola y juegos para miembros obtenidos de su web USA, con búsqueda por plan. No abre el navegador al consultar estas tarjetas.
- Fotos: decodificación con límite de 3 millones de píxeles y lado máximo de 2048, orientación EXIF, una lectura simultánea, cancelación y recuperación segura al volver del selector. No se carga primero la foto completa para reducirla.
- PlayStation azul, Nintendo rojo y Xbox verde en tarjetas, búsqueda por marca y fichas. Portadas con tamaño de decodificación limitado.
- Mis Alertas muestra la portada guardada y abre la ficha conservando la edición de la alerta, también después de actualizar el precio. Ajustes de texto en pantallas estrechas.

### Alcance
- Empaquetado en APK Release único universal `DinoxoGamers-V1.6.apk`, versión `1.6.0+7`.

### Verificación
- 112 pruebas automáticas de Flutter aprobadas y análisis de código con 0 advertencias ni errores.
- 3 pruebas unitarias de Kotlin/JVM aprobadas para límites y muestreo de imágenes de alta resolución (12 MP, 50 MP, 200 MP).

## [1.5.0+6] - 2026-09-28

### Corregido
- Portadas y reseñas vinculadas al título de la ficha: se rechazan ofertas relacionadas y respuestas sin identidad comprobable. Actualizar una ficha antigua no permite sustituirla por otro juego de la misma compañía.
- Las imágenes y reseñas guardadas con el método anterior se ocultan hasta verificar su fuente; se conservan favoritos, alertas e historial.
- Galería sin imágenes de relleno: coincidencia exacta de título y edición en Steam, procedencia visible y enlaces de vídeo etiquetados como búsquedas.
- Inicio y Plus: análisis de HTML/JSON en un hilo separado, índice de títulos, construcción de tarjetas visibles y carga de pestañas bajo demanda. Notificaciones y consultas externas comienzan después de mostrar la primera pantalla.
- Plus: próximos ingresos, mes siguiente, retiradas con fecha publicada y beneficios por plan de las tres compañías, exclusivamente USA. Nintendo separa DLC y mejoras del juego base; Xbox excluye actualizaciones, pruebas y beneficios de las altas de juegos completos.
- Una fuente de anuncios ilegible muestra un aviso y conserva los juegos actuales. El fallo de una página de beneficios Nintendo conserva el otro plan verificado. Las retiradas PlayStation sin fecha pública confirmada no se inventan.
- Cámara y galería: lectura de imagen fuera del hilo principal Android, títulos repartidos entre líneas, pista de consola y límite de tiempo. La ficha automática requiere una coincidencia exacta única y una consulta completa; los errores parciales y las distintas ediciones quedan visibles para elegir.

### Alcance
- Empaquetado en APK Release único universal `DinoxoGamers-V1.5.apk`, versión `1.5.0+6`.

### Verificación
- 96 pruebas aprobadas y análisis Flutter sin incidencias. Comprobación Kotlin y compilación APK Release exitosa.
- Consultas reales con los servicios de la app: catálogos y beneficios de las tres compañías, portadas distintas para Ghost y Zelda, próximas incorporaciones y retiradas Xbox fechadas. Revisión independiente y pruebas de errores parciales.

## [1.4.0+5] - 2026-09-28

### Corregido
- Plus sustituye las listas fijas por consultas oficiales de suscripciones USA para PlayStation, Xbox de consola y Nintendo, incluido SEGA Genesis. Se muestran disponibilidad actual, altas del mes y anuncios fechados para el siguiente, con fuentes, nivel requerido y errores visibles.
- Ofertas, Buscar y fichas consultan la misma información de membresías. Coincidencias estrictas evitan confundir secuelas, DLC, ediciones y remakes de Nintendo; el consejo de compra depende de que el usuario tenga la membresía correspondiente.
- El consejo selecciona el nivel mínimo verificado. Un alta futura en otro plan conserva el acceso disponible hoy; se respetan los anuncios que pasan de diciembre a enero.
- Cámara/galería: lectura de rutas y URI, combinación del título en varias líneas, errores diferenciados de permisos, recuperación de fotos al recrear la actividad y búsqueda web tras confirmar o corregir el texto. Una foto ilegible permite introducir el título.
- Alertas con importe decimal exacto en USD, persistencia por edición, actualización inmediata de Mis Alertas y botón de actualización en su barra superior.
- Revisión de precios en segundo plano mediante WorkManager, además de las consultas en primer plano. Avisos al alcanzar o bajar del objetivo, comparación en centavos, silencio nocturno y prevención de duplicados persistente entre comprobaciones concurrentes.
- Denegar notificaciones conserva la alerta y permite habilitarlas después. Android puede retrasar los intervalos solicitados de 15 minutos.
- Las fichas de resultados sin precio publicado se abren sin acceder a una edición inexistente.

### Verificación
- Pruebas de fuentes, fechas y coincidencias de membresías, búsquedas desde fotos y errores OCR, importes exactos, persistencia y notificaciones duplicadas.
- Comprobación de consultas reales oficiales y compilación del código Kotlin de Android sin empaquetar APK. Versión conservada en `1.3.0+4`.
- 69 pruebas generales aprobadas y una comprobación adicional con respuestas oficiales reales; análisis Flutter sin incidencias. Cámara y recepción de notificaciones pendientes de prueba física en un teléfono.

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

