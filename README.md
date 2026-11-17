# WearUp — Plataforma E-Commerce de Moda

<p align="center">
  <img src="assets/logo.png" alt="WearUp Logo" width="220" />
</p>

<p align="center">
  <strong>Viste tu estilo</strong> — Aplicación móvil y de escritorio multiplataforma desarrollada en Flutter para la comercialización de moda, calzado y accesorios, con flujo guiado de compra, pagos mediante transferencia bancaria (BRE-B), seguimiento de pedidos y panel administrativo integrado.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47%2B-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-blue" alt="Plataformas" />
  <a href="https://github.com/toroc07/wearup"><img src="https://img.shields.io/badge/GitHub-toroc07%2Fwearup-181717?logo=github&logoColor=white" alt="GitHub Repo" /></a>
  <img src="https://img.shields.io/badge/Versi%C3%B3n-1.0.0%2B1-success" alt="Versión" />
</p>

---

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Identidad Visual y Diseño](#identidad-visual-y-diseño)
3. [Características Principales](#características-principales)
   - [Módulo de Clientes (Tienda)](#1-módulo-de-clientes-tienda)
   - [Flujo de Compra en 5 Pasos (Checkout)](#2-flujo-de-compra-en-5-pasos-checkout)
   - [Cuenta y Seguimiento de Pedidos](#3-cuenta-y-seguimiento-de-pedidos)
   - [Panel de Administración (Backoffice)](#4-panel-de-administración-backoffice)
4. [Estructura del Proyecto y Enlaces de Código](#estructura-del-proyecto-y-enlaces-de-código)
5. [Modelo de Datos y Gestión del Estado](#modelo-de-datos-y-gestión-del-estado)
6. [Roles y Acceso al Sistema](#roles-y-acceso-al-sistema)
7. [Requisitos Previos e Instalación](#requisitos-previos-e-instalación)
8. [Ejecución de Pruebas](#ejecución-de-pruebas)
9. [Persistencia y Datos](#persistencia-y-datos)
10. [Repositorio y Autor](#repositorio-y-autor)

---

## Descripción General

**WearUp** es una solución de comercio electrónico diseñada para brindar una experiencia de usuario fluida, moderna y atractiva en el sector textil y de accesorios. Integra una interfaz intuitiva para compradores junto con un módulo de gestión comercial completo para administradores de tienda.

La aplicación opera de manera reactiva mediante arquitectura desacoplada impulsada por [`AppState`](lib/state.dart), manteniendo persistencia local sincronizada para catálogos, pedidos, sesiones y promociones.

---

## Identidad Visual y Diseño

El sistema visual de WearUp está construido sobre Material 3 con especificaciones tipográficas y paletas cromáticas personalizadas en [lib/theme.dart](lib/theme.dart):

* **Tipografía:** Familia [Montserrat](assets/fonts/Montserrat.ttf) registrada en [pubspec.yaml](pubspec.yaml).
* **Paleta de Colores:**
  * Primario / Énfasis: `#1F6BB5` (`kBlue`)
  * Tono Oscuro / Textos y Cabeceras: `#12203A` (`kNavy`)
  * Fondo General: `#F5F8FC` (`kBg`)
  * Bordes y Divisores: `#D5DEEA` (`kBorder`)
  * Textos Secundarios: `#5B6B80` (`kMuted`)
  * Éxito / Entregado / Validación: `#0F7B3F` (`kGreen`)
  * Alerta / Stock Bajo / Pendiente: `#B45309` (`kAmber`)
  * Peligro / Cancelaciones / Eliminar: `#C62828` (`kRed`)
  * Acento Secundario / Pasos Completados: `#4FB0CC` (`kTeal`)
* **Diseño Adaptativo (Responsive):** Experiencia optimizada tanto para dispositivos móviles como para pantallas anchas de escritorio (≥ 800 px) con menú lateral persistente en el panel administrativo.

---

## Características Principales

### 1. Módulo de Clientes (Tienda)
* **Pantalla de Inicio ([`HomeScreen`](lib/shop.dart)):**
  * Buscador rápido con redirección interactiva al catálogo.
  * Banner de portada de temporada ("Nueva Colección").
  * Carrusel de acceso directo a categorías (`Ropa`, `Jeans`, `Zapatos`, `Accesorios`).
  * Sección horizontal de productos destacados con acceso directo al detalle.
  * Banner promocional dinámico con descuento configurable por el administrador.
* **Catálogo y Filtrado Multinivel ([`CatalogScreen`](lib/shop.dart)):**
  * Búsqueda en vivo por texto en nombres y categorías.
  * Filtros por categoría mediante chips interactivos.
  * Menús desplegables para filtrar por **Talla**, **Color** y **Rango de Precio**.
  * Conteo dinámico de productos coincidentes y botón para limpiar filtros.
* **Detalle de Producto ([`ProductDetailScreen`](lib/shop.dart)):**
  * Galería de miniaturas y visualizador de imágenes.
  * Selector de variantes de color con previsualización visual de muestras.
  * Selector de tallas con modal de guía de medidas ("¿Cuál es mi talla?").
  * Selector de cantidad ([`QtyStepper`](lib/widgets.dart)) acotado al stock disponible.
  * Indicadores de disponibilidad inmediata ([`StockLabel`](lib/widgets.dart)): Disponible, Últimas unidades o Agotado.

### 2. Flujo de Compra en 5 Pasos (Checkout)
Implementado en [`CheckoutScreen`](lib/checkout.dart), cuenta con un indicador de progreso ([`_Stepper`](lib/checkout.dart)):
1. **Carrito:** Edición de unidades (limitadas al stock disponible), cálculo de subtotal y costo de envío fijo (`$9.900`), eliminación de ítems y validación de autenticación obligatoria para proceder. Si el stock baja mientras el producto está en el carrito, se avisa y no se deja continuar hasta ajustarlo.
2. **Envío:** Captura y validación de datos de entrega (Nombre, celular, dirección, ciudad, departamento y notas opcionales).
3. **Pago:** Datos de transferencia directa interbancaria mediante Llave BRE-B con botón de copiado al portapapeles.
4. **Comprobante:** Paso para adjuntar la foto/captura de la transferencia. *En el prototipo la selección es simulada: se registra un nombre de archivo, no se sube ninguna imagen.*
5. **Confirmación:** Pantalla de pedido confirmado con número de orden único, desglose final y accesos a seguimiento o nuevo pedido.

### 3. Cuenta y Seguimiento de Pedidos
* **Autenticación e Ingreso ([`AuthForm`](lib/account.dart)):**
  * Pestañas unificadas de inicio de sesión y registro de usuario nuevo.
  * Modo de navegación como invitado para exploración del catálogo.
* **Historial de Pedidos ([`OrdersTab`](lib/account.dart)):**
  * Listado de pedidos filtrable por estado: *Todos*, *En curso* y *Entregados*.
* **Línea de Tiempo de Entrega ([`TrackingScreen`](lib/account.dart)):**
  * Progreso visual cronológico en 4 etapas: `Confirmado` ➔ `En preparación` ➔ `Enviado` ➔ `Entregado`.
  * Indica si el pago ya fue validado por el administrador o sigue en validación.
  * Consulta detallada de dirección de destino y resumen de productos adquiridos.

### 4. Panel de Administración (Backoffice)
Ubicado en [`AdminScreen`](lib/admin.dart):
* **Panel (Dashboard):** Métricas clave en tiempo real (productos activos, productos con pocas unidades, agotados y pedidos pendientes).
* **Gestión de Productos:** Tabla con scroll horizontal, filtros por categoría y stock, modal de creación/edición ([`_ProductDialog`](lib/admin.dart)) y borrado con confirmación.
* **Control de Inventario:** Modificación rápida de existencias (+ / -) con actualización instantánea de estado.
* **Configuración de Promociones:** Activación/desactivación del banner en tiempo real y ajuste del porcentaje anunciado mediante slider (5% al 70%). *El porcentaje solo se muestra en el banner del inicio; no modifica los precios.*
* **Control de Pedidos:**
  * Filtro por etapas (`OrderStatus`).
  * Desglose completo de cliente, teléfono, comprobante adjunto e ítems.
  * Validación de pagos con un clic.
  * Transición de estados de envío.
  * Eliminación de pedidos con confirmación; si el pedido no se había entregado, sus unidades vuelven al inventario.

---

## Estructura del Proyecto y Enlaces de Código

```
wearup/
├── assets/
│   ├── fonts/
│   │   └── Montserrat.ttf      # Tipografía corporativa
│   └── logo.png                # Isotipo y logotipo de la marca
├── lib/
│   ├── account.dart            # Módulos de autenticación, perfil, historial y seguimiento
│   ├── admin.dart              # Panel de administración, métricas, CRUD e inventario
│   ├── checkout.dart           # Stepper y proceso de compra en 5 fases con llave BRE-B
│   ├── main.dart               # Punto de entrada de la aplicación y navegación por pestañas
│   ├── shop.dart               # Pantalla de inicio, catálogo filtrable y vista de detalle
│   ├── state.dart              # Gestión del estado global, modelos de datos y persistencia
│   ├── theme.dart              # Configuración de colores, fuentes y estilos de Material 3
│   └── widgets.dart            # Componentes reutilizables (tarjetas, botones, etiquetas)
├── test/
│   ├── state_test.dart         # Pruebas de la lógica de stock y aislamiento de pedidos
│   └── widget_test.dart        # Pruebas integrales de flujo de compra y backoffice
├── pubspec.yaml                # Especificación de paquetes, versiones y recursos
└── README.md                   # Documentación técnica del proyecto
```

### Componentes Clave

| Archivo | Responsabilidad Principal |
| :--- | :--- |
| [lib/main.dart](lib/main.dart) | Inicialización asíncrona de datos, configuración de tema y contenedor principal [`MainShell`](lib/main.dart) con navegación inferior indexada. |
| [lib/theme.dart](lib/theme.dart) | Definición centralizada de colores corporativos y tema visual [`buildTheme()`](lib/theme.dart). |
| [lib/state.dart](lib/state.dart) | Estado reactivo [`AppState`](lib/state.dart), modelos [`Product`](lib/state.dart), [`Order`](lib/state.dart), [`CartItem`](lib/state.dart), serialización JSON y sincronización con disco. |
| [lib/widgets.dart](lib/widgets.dart) | UI compartida: [`Logo`](lib/widgets.dart), [`CartButton`](lib/widgets.dart), [`StockLabel`](lib/widgets.dart), [`StatusChip`](lib/widgets.dart), [`Card2`](lib/widgets.dart) y [`SummaryRows`](lib/widgets.dart). |
| [lib/shop.dart](lib/shop.dart) | Pantallas de vitrina: [`HomeScreen`](lib/shop.dart), [`CatalogScreen`](lib/shop.dart) y [`ProductDetailScreen`](lib/shop.dart). |
| [lib/checkout.dart](lib/checkout.dart) | Control del embudo transaccional ([`CheckoutScreen`](lib/checkout.dart)), cálculo de flete y confirmación de pago. |
| [lib/account.dart](lib/account.dart) | Autenticación ([`AuthForm`](lib/account.dart)), panel de cuenta ([`AccountTab`](lib/account.dart)), pedidos personales ([`OrdersTab`](lib/account.dart)) y seguimiento ([`TrackingScreen`](lib/account.dart)). |
| [lib/admin.dart](lib/admin.dart) | Interfaz administrativa con panel de control, inventario, promociones y atención de pedidos. |
| [test/state_test.dart](test/state_test.dart) | Pruebas unitarias de `AppState`: límite de stock en el carrito y pedidos que no cambian al editar el catálogo. |
| [test/widget_test.dart](test/widget_test.dart) | Batería de pruebas de integración con simulación de fuentes y mocking de `SharedPreferences`. |

---

## Modelo de Datos y Gestión del Estado

La gestión de estado se centraliza a través del patrón **ChangeNotifier / Listenable** con una instancia única accesible globalmente (`app`):

```mermaid
graph TD
    AppState["AppState (singleton)"]
    Products["List<Product>"]
    Cart["List<CartItem>"]
    Orders["List<Order>"]
    Storage[("SharedPreferences ('wearup_data')")]

    AppState --> Products
    AppState --> Cart
    AppState --> Orders
    AppState -.->|Auto-guardado en notifyListeners()| Storage
```

* **Stock Automático:** El estado de disponibilidad se computa dinámicamente según el inventario numérico:
  * `stock > 5` ➔ [`Stock.available`](lib/state.dart)
  * `1 <= stock <= 5` ➔ [`Stock.low`](lib/state.dart)
  * `stock <= 0` ➔ [`Stock.out`](lib/state.dart)
* **Stock por Producto:** El inventario se lleva por producto, no por color o talla. El carrito no permite sumar, entre todas las variantes de un producto, más unidades de las disponibles, y un pedido no se confirma si el stock bajó después de agregarlo al carrito.
* **Aislamiento en Pedidos:** Al confirmar la compra, cada ítem del pedido guarda una copia del producto (nombre, precio, color, etc.). Si el producto se edita o elimina más adelante, el pedido conserva los datos y el total con los que se compró.

---

## Roles y Acceso al Sistema

La autenticación simula roles en tiempo de ejecución sin dependencias externas:

* **Cliente Convencional:**
  * Inicie sesión con cualquier correo electrónico estándar (ejemplo: `cliente@correo.com`).
  * Acceso completo a explorar el catálogo, agregar al carrito, completar compras, consultar su historial y rastrear sus órdenes.
* **Administrador de Tienda:**
  * Inicie sesión con cualquier correo electrónico que inicie por el prefijo **`admin`** (ejemplo: `admin@wearup.com`, `admin@tienda.com`).
  * Habilita el acceso directo al **Panel de Administración** desde la pestaña de Cuenta, visualización de métricas, edición del catálogo de productos, control de stock, gestión del banner promocional y validación de transferencias de pago.

---

## Requisitos Previos e Instalación

### Requisitos del Sistema
* [Flutter SDK](https://docs.flutter.dev/get-started/install) `3.47` o superior.
* Dart SDK `3.13.3` o superior (restricción `sdk: ^3.13.3` en `pubspec.yaml`; incluido con Flutter).
* Dispositivo físico, emulador de Android / simulador de iOS, o navegador web compatible con soporte para CanvasKit / HTML.

### Pasos de Instalación

1. **Clonar o descargar el repositorio:**
   ```bash
   git clone https://github.com/toroc07/wearup.git
   cd wearup
   ```

2. **Instalar dependencias del proyecto:**
   ```bash
   flutter pub get
   ```

3. **Verificar el entorno de desarrollo:**
   ```bash
   flutter doctor
   ```

4. **Compilar y ejecutar la aplicación:**
   ```bash
   # En el dispositivo o emulador por defecto
   flutter run

   # O especificando una plataforma concreta:
   flutter run -d chrome      # Web
   flutter run -d windows     # Escritorio Windows
   flutter run -d android     # Dispositivo Android
   ```

---

## Ejecución de Pruebas

El proyecto cuenta con pruebas de integración y widgets automatizadas que validan:
* La navegación por el catálogo y adición de productos.
* El flujo completo de checkout con validación de formularios y subida de comprobante.
* El acceso administrativo, validación de pagos y avance de estados de entrega.
* El límite de stock en el carrito y que los pedidos no cambien al editar el catálogo.

Para ejecutar los tests en la consola:

```bash
flutter test
```

---

## Persistencia y Datos

Los datos de la aplicación se guardan localmente bajo la clave `'wearup_data'` utilizando [`shared_preferences`](pubspec.yaml). Al abrir la app por primera vez, se cargan productos iniciales de muestra (chaquetas denim, camisetas, jeans slim, calzado urbano y bolsos) junto con pedidos históricos de demostración. Cualquier cambio posterior (nuevos pedidos, cambios de stock o edición de productos) se preserva automáticamente entre sesiones.

---

## Repositorio y Autor

* **Repositorio oficial en GitHub:** [https://github.com/toroc07/wearup](https://github.com/toroc07/wearup)
* **Desarrollador / Propietario:** [@toroc07](https://github.com/toroc07)
* **ID de Aplicación / Namespace:** `com.wearup.wearup`