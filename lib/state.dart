import 'package:flutter/foundation.dart';

import 'backend.dart';
import 'models.dart';

export 'backend.dart';
export 'models.dart';

/// Estado global de la app: catálogo, carrito, pedidos y sesión.
/// Los datos viven en el servidor ([Backend]); aquí se guarda la copia que se muestra.
/// El carrito es local hasta que se confirma la compra.
class AppState extends ChangeNotifier {
  AppState(this.backend);

  final Backend backend;

  List<ProductCategory> categories = const [];
  List<Product> products = [];
  StoreSettings settings = const StoreSettings();
  final List<Order> orders = [];
  final List<CartItem> cart = [];
  Profile? profile;

  // Carga inicial
  bool loading = false;
  String? loadError;

  bool get loggedIn => profile != null;
  bool get isAdmin => profile?.isAdmin ?? false;
  String? get userEmail => profile?.email;

  // Pestaña activa del shell
  final ValueNotifier<int> tab = ValueNotifier(0);
  void goTab(int i) => tab.value = i;

  String categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return '';
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  String imageUrl(String path) => backend.productImageUrl(path);

  // ---------------------------------------------------------------- Carga

  Future<void> init() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      await _loadCatalog();
      profile = await backend.currentProfile();
      if (profile != null) await _loadOrders();
    } on BackendException catch (e) {
      loadError = e.message;
    }
    loading = false;
    notifyListeners();
  }

  // Recarga catálogo y pedidos (por ejemplo, al deslizar hacia abajo)
  Future<void> refresh() async {
    await _loadCatalog();
    if (loggedIn) await _loadOrders();
    notifyListeners();
  }

  Future<void> _loadCatalog() async {
    final c = await backend.loadCatalog();
    categories = c.categories;
    products = c.products;
    settings = c.settings;
    _relinkCart();
  }

  Future<void> _loadOrders() async {
    final list = await backend.loadOrders();
    orders
      ..clear()
      ..addAll(list);
  }

  // Tras recargar el catálogo, el carrito apunta a los productos nuevos;
  // lo que ya no existe se quita.
  void _relinkCart() {
    final updated = <CartItem>[];
    for (final i in cart) {
      final p = productById(i.product.id);
      if (p == null) continue;
      final v = p.variants.where((v) => v.id == i.variant.id);
      if (v.isEmpty) continue;
      updated.add(CartItem(p, v.first, i.qty));
    }
    cart
      ..clear()
      ..addAll(updated);
  }

  // ---------------------------------------------------------------- Carrito

  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  int get subtotal => cart.fold(0, (s, i) => s + i.total);
  int get shipping => cart.isEmpty ? 0 : settings.shippingCost;
  int get total => subtotal + shipping;

  int inCart(Variant v) => cart.where((i) => i.variant.id == v.id).fold(0, (s, i) => s + i.qty);

  // Unidades de una variante que todavía se pueden agregar
  int remaining(Variant v) {
    final r = v.stock - inCart(v);
    return r < 0 ? 0 : r;
  }

  // true si ninguna variante del carrito supera su stock actual
  bool get cartFitsStock => cart.every((i) => i.qty <= i.variant.stock);

  // Agrega sin pasar del stock de la variante. Devuelve cuántas unidades se agregaron.
  int addToCart(Product p, Variant v, int qty) {
    final add = qty.clamp(0, remaining(v));
    if (add == 0) return 0;
    final existing = cart.where((i) => i.variant.id == v.id);
    if (existing.isNotEmpty) {
      existing.first.qty += add;
    } else {
      cart.add(CartItem(p, v, add));
    }
    notifyListeners();
    return add;
  }

  void setQty(CartItem i, int qty) {
    final max = i.variant.stock;
    i.qty = qty.clamp(1, max < 1 ? 1 : max);
    notifyListeners();
  }

  void removeItem(CartItem i) {
    cart.remove(i);
    notifyListeners();
  }

  // ---------------------------------------------------------------- Sesión

  Future<void> signIn(String email, String password) async {
    profile = await backend.signIn(email, password);
    await _loadOrders();
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required bool dataConsent,
  }) async {
    profile = await backend.signUp(email: email, password: password, fullName: fullName, phone: phone, dataConsent: dataConsent);
    await _loadOrders();
    notifyListeners();
  }

  Future<void> signOut() async {
    await backend.signOut();
    _clearSession();
  }

  Future<void> sendPasswordReset(String email) => backend.sendPasswordReset(email);

  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) =>
      backend.confirmPasswordReset(email: email, code: code, newPassword: newPassword);

  Future<void> updateProfile({required String fullName, required String phone}) async {
    profile = await backend.updateProfile(fullName: fullName, phone: phone);
    notifyListeners();
  }

  Future<void> deleteMyAccount() async {
    await backend.deleteMyAccount();
    cart.clear();
    _clearSession();
  }

  void _clearSession() {
    profile = null;
    orders.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Pedidos

  // Pedidos del usuario actual (el administrador recibe todos, pero aquí solo ve los suyos)
  List<Order> get myOrders => orders.where((o) => o.userId != null && o.userId == profile?.id).toList();

  /// Sube el comprobante y crea el pedido en el servidor, que valida el stock
  /// y calcula los precios. Si algo falla, el carrito se conserva.
  Future<Order> placeOrder({required ShippingInfo shippingInfo, required PickedImage receipt}) async {
    if (!loggedIn) throw BackendException(serverErrors['NO_AUTENTICADO']!);
    if (cart.isEmpty) throw BackendException(serverErrors['CARRITO_VACIO']!);
    if (!cartFitsStock) throw BackendException(serverErrors['STOCK_INSUFICIENTE']!);

    final receiptPath = await backend.uploadReceipt(receipt);
    final int number;
    try {
      number = await backend.placeOrder(items: List.of(cart), shipping: shippingInfo, receiptPath: receiptPath);
    } on BackendException {
      // El stock pudo cambiar: se recarga para mostrar las unidades reales
      try {
        await _loadCatalog();
        notifyListeners();
      } on BackendException {
        // sin conexión: se mantiene lo que había
      }
      rethrow;
    }

    // Copia local por si no se puede recargar enseguida
    final local = Order(
      number: number,
      userId: profile!.id,
      date: DateTime.now(),
      items: [
        for (final i in cart)
          OrderItem(
            productName: i.product.name,
            colorName: i.variant.colorName,
            colorHex: i.variant.colorHex,
            size: i.variant.size,
            tint: i.product.tint,
            unitPrice: i.product.price,
            qty: i.qty,
          ),
      ],
      subtotal: subtotal,
      shipping: shipping,
      status: OrderStatus.confirmed,
      customerName: shippingInfo.customerName,
      customerEmail: profile!.email,
      phone: shippingInfo.phone,
      address: shippingInfo.address,
      city: shippingInfo.city,
      department: shippingInfo.department,
      notes: shippingInfo.notes,
      receiptPath: receiptPath,
    );
    cart.clear();
    try {
      await _loadCatalog();
      await _loadOrders();
    } on BackendException {
      orders.insert(0, local);
    }
    notifyListeners();
    return orders.firstWhere((o) => o.number == number, orElse: () => local);
  }

  Future<String> receiptUrl(String path) => backend.receiptUrl(path);

  // ---------------------------------------------------------------- Administración

  Future<void> saveProduct(ProductDraft draft) async {
    await backend.saveProduct(draft);
    await _loadCatalog();
    notifyListeners();
  }

  Future<void> deleteProduct(Product p) async {
    await backend.deleteProduct(p.id);
    cart.removeWhere((i) => i.product.id == p.id);
    await _loadCatalog();
    notifyListeners();
  }

  // Cambia el stock enseguida en pantalla y lo guarda; si falla, lo revierte
  Future<void> setVariantStock(Variant v, int stock) async {
    final old = v.stock;
    v.stock = stock < 0 ? 0 : stock;
    notifyListeners();
    try {
      await backend.setVariantStock(v.id, v.stock);
    } on BackendException {
      v.stock = old;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addProductImage(Product p, PickedImage image) async {
    await backend.addProductImage(p.id, image);
    await _loadCatalog();
    notifyListeners();
  }

  Future<void> deleteProductImage(Product p, String path) async {
    await backend.deleteProductImage(p.id, path);
    await _loadCatalog();
    notifyListeners();
  }

  Future<void> setOrderStatus(Order o, OrderStatus s) async {
    final old = o.status;
    o.status = s;
    notifyListeners();
    try {
      await backend.updateOrder(o.number, status: s);
    } on BackendException {
      o.status = old;
      notifyListeners();
      rethrow;
    }
  }

  // El administrador confirma que recibió la transferencia
  Future<void> validatePayment(Order o) async {
    o.paid = true;
    notifyListeners();
    try {
      await backend.updateOrder(o.number, paid: true);
    } on BackendException {
      o.paid = false;
      notifyListeners();
      rethrow;
    }
  }

  // Elimina un pedido; si no se había entregado, el servidor devuelve las unidades
  Future<void> deleteOrder(Order o) async {
    await backend.deleteOrder(o.number);
    orders.remove(o);
    await _loadCatalog();
    notifyListeners();
  }

  Future<void> setPromo(bool active, int percent) async {
    final old = settings;
    settings = settings.copyWith(promoActive: active, promoPercent: percent);
    notifyListeners();
    try {
      await backend.saveSettings(settings);
    } on BackendException {
      settings = old;
      notifyListeners();
      rethrow;
    }
  }
}

// Instancia única que usan todas las pantallas (se crea en main o en las pruebas)
late AppState app;
