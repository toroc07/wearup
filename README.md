# WearUp — Plataforma E-Commerce de Moda

<p align="center">
  <img src="assets/logo.png" alt="WearUp Logo" width="220" />
</p>

<p align="center">
  <strong>Viste tu estilo</strong> — Aplicación móvil y de escritorio multiplataforma desarrollada en Flutter para la comercialización de moda, calzado y accesorios, con flujo guiado de compra, pagos mediante transferencia bancaria (BRE-B), seguimiento de pedidos y panel administrativo integrado.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.13%2B-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.1%2B-0175C2?logo=dart&logoColor=white" alt="Dart" />
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

La aplicación opera de manera reactiva mediante arquitectura desacoplada impulsada por [`AppState`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L171-L417), manteniendo persistencia local sincronizada para catálogos, pedidos, sesiones y promociones.

---

## Identidad Visual y Diseño

El sistema visual de WearUp está construido sobre Material 3 con especificaciones tipográficas y paletas cromáticas personalizadas en [lib/theme.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/theme.dart):

* **Tipografía:** Familia [Montserrat](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/assets/fonts/Montserrat.ttf) registrada en [pubspec.yaml](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/pubspec.yaml#L61-L66).
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
* **Pantalla de Inicio ([`HomeScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L10-L152)):**
  * Buscador rápido con redirección interactiva al catálogo.
  * Banner de portada de temporada ("Nueva Colección").
  * Carrusel de acceso directo a categorías (`Ropa`, `Jeans`, `Zapatos`, `Accesorios`).
  * Sección horizontal de productos destacados con acceso directo al detalle.
  * Banner promocional dinámico con descuento configurable por el administrador.
* **Catálogo y Filtrado Multinivel ([`CatalogScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L161-L322)):**
  * Búsqueda en vivo por texto en nombres y categorías.
  * Filtros por categoría mediante chips interactivos.
  * Menús desplegables para filtrar por **Talla**, **Color** y **Rango de Precio**.
  * Conteo dinámico de productos coincidentes y botón para limpiar filtros.
* **Detalle de Producto ([`ProductDetailScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L367-L532)):**
  * Galería de miniaturas y visualizador de imágenes.
  * Selector de variantes de color con previsualización visual de muestras.
  * Selector de tallas con modal de guía de medidas ("¿Cuál es mi talla?").
  * Selector de cantidad ([`QtyStepper`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L165-L188)) acotado al stock disponible.
  * Indicadores de disponibilidad inmediata ([`StockLabel`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L64-L81)): Disponible, Últimas unidades o Agotado.

### 2. Flujo de Compra en 5 Pasos (Checkout)
Implementado en [`CheckoutScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/checkout.dart#L13-L387), cuenta con un indicador de progreso ([`_Stepper`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/checkout.dart#L390-L432)):
1. **Carrito:** Edición de unidades, cálculo de subtotal y costo de envío fijo (`$9.900`), eliminación de ítems y validación de autenticación obligatoria para proceder.
2. **Envío:** Captura y validación de datos de entrega (Nombre, celular, dirección, ciudad, departamento y notas opcionales).
3. **Pago:** Datos de transferencia directa interbancaria mediante Llave BRE-B con botón de copiado al portapapeles.
4. **Comprobante:** Módulo de adjunto de foto/captura de la transferencia bancaria realizada.
5. **Confirmación:** Pantalla de pedido confirmado con número de orden único, desglose final y accesos a seguimiento o nuevo pedido.

### 3. Cuenta y Seguimiento de Pedidos
* **Autenticación e Ingreso ([`AuthForm`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L9-L131)):**
  * Pestañas unificadas de inicio de sesión y registro de usuario nuevo.
  * Modo de navegación como invitado para exploración del catálogo.
* **Historial de Pedidos ([`OrdersTab`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L216-L313)):**
  * Listado de pedidos filtrable por estado: *Todos*, *En curso* y *Entregados*.
* **Línea de Tiempo de Entrega ([`TrackingScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L317-L431)):**
  * Progreso visual cronológico en 4 etapas: `Confirmado` ➔ `En preparación` ➔ `Enviado` ➔ `Entregado`.
  * Consulta detallada de dirección de destino y resumen de productos adquiridos.

### 4. Panel de Administración (Backoffice)
Ubicado en [`AdminScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/admin.dart#L16-L94):
* **Panel (Dashboard):** Métricas clave en tiempo real (productos activos, productos con pocas unidades, agotados y pedidos pendientes).
* **Gestión de Productos:** Tabla con scroll horizontal, filtros por categoría y stock, modal de creación/edición ([`_ProductDialog`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/admin.dart#L301-L372)) y borrado con confirmación.
* **Control de Inventario:** Modificación rápida de existencias (+ / -) con actualización instantánea de estado.
* **Configuración de Promociones:** Activación/desactivación del banner en tiempo real y ajuste porcentual de descuento mediante slider (5% al 70%).
* **Control de Pedidos:**
  * Filtro por etapas (`OrderStatus`).
  * Desglose completo de cliente, teléfono, comprobante adjunto e ítems.
  * Validación de pagos con un clic.
  * Transición de estados de envío y restitución automática de inventario en caso de cancelación de pedidos no entregados.

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
│   └── widget_test.dart        # Pruebas integrales de flujo de compra y backoffice
├── pubspec.yaml                # Especificación de paquetes, versiones y recursos
└── README.md                   # Documentación técnica del proyecto
```

### Componentes Clave

| Archivo | Responsabilidad Principal |
| :--- | :--- |
| [lib/main.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/main.dart) | Inicialización asíncrona de datos, configuración de tema y contenedor principal [`MainShell`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/main.dart#L31-L45) con navegación inferior indexada. |
| [lib/theme.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/theme.dart) | Definición centralizada de colores corporativos y tema visual [`buildTheme()`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/theme.dart#L15-L58). |
| [lib/state.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart) | Estado reactivo [`AppState`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L171-L417), modelos [`Product`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L29-L74), [`Order`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L92-L152), [`CartItem`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L77-L89), serialización JSON y sincronización con disco. |
| [lib/widgets.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart) | UI compartida: [`Logo`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L8-L14), [`CartButton`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L42-L61), [`StockLabel`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L64-L81), [`StatusChip`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L84-L106), [`Card2`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L109-L127) y [`SummaryRows`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/widgets.dart#L191-L212). |
| [lib/shop.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart) | Pantallas de vitrina: [`HomeScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L10-L152), [`CatalogScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L161-L322) y [`ProductDetailScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/shop.dart#L367-L532). |
| [lib/checkout.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/checkout.dart) | Control del embudo transaccional ([`CheckoutScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/checkout.dart#L13-L387)), cálculo de flete y confirmación de pago. |
| [lib/account.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart) | Autenticación ([`AuthForm`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L9-L131)), panel de cuenta ([`AccountTab`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L150-L212)), pedidos personales ([`OrdersTab`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L216-L313)) y seguimiento ([`TrackingScreen`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/account.dart#L317-L431)). |
| [lib/admin.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/admin.dart) | Interfaz administrativa con panel de control, inventario, promociones y atención de pedidos. |
| [test/widget_test.dart](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/test/widget_test.dart) | Batería de pruebas de integración con simulación de fuentes y mocking de `SharedPreferences`. |

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
  * `stock > 5` ➔ [`Stock.available`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L7)
  * `1 <= stock <= 5` ➔ [`Stock.low`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L7)
  * `stock <= 0` ➔ [`Stock.out`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L7)
* **Aislamiento en Pedidos:** Cada [`CartItem`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/lib/state.dart#L77-L89) guarda una copia estática de la información del producto al momento de confirmar la compra. Si el producto se edita o elimina más adelante, el registro histórico del pedido permanece íntegro.

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
* [Flutter SDK](https://docs.flutter.dev/get-started/install) versión `^3.13.3` o superior.
* Dart SDK `^3.1.0`.
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

Para ejecutar los tests en la consola:

```bash
flutter test
```

---

## Persistencia y Datos

Los datos de la aplicación se guardan localmente bajo la clave `'wearup_data'` utilizando [`shared_preferences`](file:///c:/Users/carli/Documents/Desarrollo%20de%20Software/wearup/pubspec.yaml#L37). Al abrir la app por primera vez, se cargan productos iniciales de muestra (chaquetas denim, camisetas, jeans slim, calzado urbano y bolsos) junto con pedidos históricos de demostración. Cualquier cambio posterior (nuevos pedidos, cambios de stock o edición de productos) se preserva automáticamente entre sesiones.

---

## Repositorio y Autor

* **Repositorio oficial en GitHub:** [https://github.com/toroc07/wearup](https://github.com/toroc07/wearup)
* **Desarrollador / Propietario:** [@toroc07](https://github.com/toroc07)
* **ID de Aplicación / Namespace:** `com.wearup.wearup`