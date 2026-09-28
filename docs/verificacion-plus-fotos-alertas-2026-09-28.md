# Correcciones de Plus, fotos y alertas

Cambios en desarrollo sobre `1.5.0+6`, sin empaquetar APK, instalar ni publicar.

## Causas y cambios

- Plus todavía descargaba/decodificaba respuestas y recorría JSON grandes en el hilo de Flutter. Ahora la consulta completa vive en un trabajador con plazo de 40 segundos y terminación; las compañías se actualizan progresivamente. Se preserva la consulta anterior durante la sesión si falla una fuente y se retira el consejo de compra no verificado.
- Los botones de las suscripciones abrían páginas externas. Ahora abren pantallas internas con beneficios y juegos por plan, búsqueda y filtro por consola. Nintendo combina las bibliotecas de clásicos con los juegos gratuitos publicados en su página de membresía USA; el plan de expansión muestra también los beneficios básicos.
- El lector de fotos podía decodificar imágenes originales enormes. Ahora lee dimensiones primero, limita la muestra a 2048 por lado y 3 millones de píxeles, aplica orientación EXIF y reconoce texto fuera del hilo Android. Impide lecturas simultáneas y controla cancelación, tiempo de espera y retornos después de cerrar la pantalla.
- Mis Alertas muestra la portada de su ficha guardada y conserva la edición al abrir y actualizar el juego. Las tarjetas, búsqueda por marca y fichas adoptan los colores solicitados. Se corrigieron desbordamientos en una anchura de 390 píxeles lógicos.

## Evidencia

- Flutter: **112 pruebas aprobadas**, dos pruebas de red optativas omitidas. Incluye catálogos parciales, conservación tras errores, trabajador ocupado/cancelado, cámara/galería simuladas, ficha correcta y edición, portada de alerta y navegación en pantalla estrecha.
- El código nativo Android se comprobó con `:app:compileDebugKotlin`, excluyendo la tarea de compilación Flutter. Resultado correcto; no empaqueta APK.
- Android JVM: **3 pruebas aprobadas** del cálculo de muestras para fotos de 12/50/200 MP, panorámicas, dimensiones extremas e inválidas. `:app:testDebugUnitTest` terminó correctamente sin empaquetar APK. Estas pruebas no sustituyen capturar fotos reales.
- Consulta real con el mismo `SubscriptionSource.fetchCatalog`: **716 entradas PlayStation, 358 Nintendo y 634 Xbox**, con `gamesVerified=true` y 3/2/3 planes respectivamente. Son entradas de catálogo/anuncios, no necesariamente títulos únicos.
- Nintendo devolvió NES, Super NES, Game Boy, Game Boy Advance, Nintendo 64, GameCube, Virtual Boy, SEGA Genesis y Nintendo Switch, incluidos F-ZERO 99 y Tetris 99 en las tarjetas de juegos para miembros.
- La consulta secuencial tardó 15,54 segundos; un temporizador de control siguió activo (967 pulsos, intervalo máximo 83,1 ms) mientras se descargaban y procesaban las fuentes. Es una comprobación del proceso Dart en Docker, no una medición de fotogramas en un teléfono.
- La fuente PlayStation advierte que las retiradas sin fecha pública en su blog requieren comprobar «Última oportunidad para jugar» en consola. No se inventan fechas ni juegos futuros.

## Pendiente físico

El usuario tiene un Samsung S24 Ultra y cree utilizar Android 16. No hay teléfono conectado para comprobar captura real, selector de galería, permisos, orientación y retorno tras una interrupción del sistema. Las fotos se leen por el texto del título; una imagen sin texto legible permite introducirlo manualmente.

El APK existente `DinoxoGamers-V1.5.apk` se conserva sin cambios (93.294.495 bytes, 28/09/2026 11:35:15 hora local). Estas correcciones todavía no están instaladas en el teléfono.
