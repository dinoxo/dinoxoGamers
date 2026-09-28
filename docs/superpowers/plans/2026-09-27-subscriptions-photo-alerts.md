# Reparación de Plus, fotos y alertas

**Objetivo:** suscripciones USA consultadas en fuentes públicas actuales, búsqueda real tras leer una portada y avisos de precio persistentes, sin crear APK ni cambiar versión.

**Diseño:** sustituir la lista fija de Plus por catálogos oficiales con fecha y fuente; separar disponibles, altas del mes y anuncios del siguiente. Compartir la misma información con Ofertas y Buscar y evitar coincidencias entre secuelas, versiones y DLC. Revisar selección/recuperación de imágenes y puente ML Kit; mostrar errores precisos y permitir corregir el título. Guardar un importe exacto elegido por el usuario y revisar precios mediante trabajo periódico Android y consultas en primer plano.

**Tecnologías:** Flutter/Dart, HTTP/HTML públicos, ML Kit Android, SQLite, notificaciones locales y trabajo periódico gratuito Android.

## Comprobaciones y tareas

- [x] Reproducir los problemas mediante pruebas de coincidencias de suscripción, foto y guardado del importe.
- [x] Verificar las respuestas oficiales y crear parsers probados; eliminar los datos fijos y mostrar fuente, fecha, errores y estados sin anuncios.
- [x] Conectar Plus, Ofertas y Buscar al mismo servicio; mostrar nivel requerido y advertencia condicional sobre la membresía.
- [x] Corregir errores de imagen, permisos, recuperación tras el selector y lectura de URI/formato; probar búsqueda con título editado.
- [x] Reemplazar el control de importe por entrada decimal válida, persistencia y mensajes de permiso; revisar objetivos y notificar desde trabajo periódico.
- [x] Probar reinicios, umbrales exactos, desactivación y prevención de duplicados; análisis Flutter y compilación Kotlin sin APK.
- [x] Actualizar README y CHANGELOG en Sin publicar con comportamiento y límites de Android.

## Casos que requieren cuidado

Datos del siguiente mes solo si están anunciados; no confundir fecha de publicación con alta. No incluir PC como catálogo de consola Xbox. Las pruebas gratuitas o DLC no equivalen al juego completo. Una foto sin texto debe permitir introducir el título y buscar. Si se deniegan notificaciones, conservar la alerta y explicar cómo habilitarlas. Android decide cuándo ejecutar revisiones de fondo; no prometer avisos instantáneos.

## Resultado comprobado el 28 de septiembre de 2026

69 pruebas generales aprobadas (dos comprobaciones de internet opcionales omitidas en esa ejecución) y una prueba adicional contra respuestas oficiales actuales aprobada. Análisis Flutter sin incidencias y compilación Kotlin completada sin empaquetar APK.

La consulta completa mediante el mismo servicio Dart de producción verificó 711 entradas de PlayStation, 355 de Nintendo y 628 de Xbox. Altas del mes: 14, 3 y 25, respectivamente; Xbox devolvió dos anuncios fechados para el siguiente mes. Son entradas de catálogo por versión/nivel, no un recuento universal de títulos únicos.

Se reprodujeron y corrigieron también la pérdida de acceso actual por anuncios para otro plan, la selección de un nivel superior innecesario, el cambio de año y el fallo al abrir fichas sin precio. Nintendo tiene un encabezado genérico «News» antes del título del artículo; el parser lee el encabezado real del anuncio y recupera sus tres altas de septiembre.

No había un teléfono conectado. La cámara física, los permisos del selector y la recepción visible de notificaciones requieren comprobación posterior en Android. El APK existente y la versión `1.3.0+4` permanecen sin cambios.
