# Interfaz gamer y menú Más

> Ejecución en esta sesión sobre el proyecto existente. Solicitud del usuario: adaptar toda la interfaz a su referencia visual, conservar los colores por compañía y reunir los módulos restantes en Más.

**Objetivo:** Cabeceras con el logo Dinoxo, superficies azul oscuro, búsqueda luminosa, fichas horizontales y navegación con seis destinos.

**Arquitectura:** Componentes Flutter compartidos para cabecera, filtros por compañía y contenedor de tarjetas. Se conservan repositorios, lectores de fotos, suscripciones, alertas y carga diferida. Más abre los módulos existentes mediante rutas internas.

**Restricciones:** USA/USD; PlayStation azul, Nintendo rojo, Xbox verde. Versión 1.8.0+9 conservada. Sin APK, publicación ni nuevas dependencias. Portadas y datos continúan viniendo de sus fuentes actuales.

- [x] Navegación: Ofertas, Buscar, Plus, Preventas, Mis Alertas y Más. Más da acceso a Noticias, Dinoxo Store, Biblioteca/Comparador e información de la app. Prueba de acceso y regreso sin perder pestaña.
- [x] Tema y componentes: cabecera adaptable, filtros de compañía, tarjetas con portada al borde izquierdo y acciones accesibles. Precios reales y sin precio disponible. Prueba de tarjetas en pantalla estrecha y texto ampliado.
- [x] Aplicar estilo en Ofertas, Buscar, Plus, Preventas, Alertas, Noticias, Biblioteca, Store y fichas. No perder acciones de cámara, galería, permisos, favoritos ni avisos. Mantener listas perezosas.
- [x] Verificar navegación, autocompletado, fotos, fichas, catálogos y alertas; análisis estático y revisión visual con captura de widgets. Documentar en Sin publicar.

**Revisión:** títulos largos, importes de tres cifras, fuente grande, teclado abierto, portadas no disponibles y navegación de regreso desde Más.

**Validación final:** `flutter analyze --no-pub` sin incidencias; `flutter test --no-pub --reporter expanded`: 142 pruebas aprobadas y 4 omitidas (tres consultas de red opcionales y captura visual opcional). Captura visual ejecutada por separado y revisada en `build/ui-preview/ofertas.png` y `build/ui-preview/mas.png`, con entradas reales archivadas para comprobar el diseño, sin afirmar precios vigentes. Revisión independiente de código sin hallazgos pendientes. No se generó APK ni se verificó en un teléfono físico.
