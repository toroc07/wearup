import 'dart:convert';
import 'dart:typed_data';

import 'package:wearup/state.dart';

/// Backend en memoria para las pruebas. Guarda filas como la base de datos real
/// (mapas JSON) y aplica las mismas reglas que database/02_seguridad.sql:
/// stock por variante, precios calculados en el "servidor", permisos de administrador.
/// Devuelve copias nuevas en cada lectura, como haría la red.
class FakeBackend implements Backend {
  FakeBackend() {
    _seed();
  }

  // Imagen PNG de 1x1 para comprobantes de prueba
  static final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

  final categories = <Map<String, dynamic>>[];
  final products = <Map<String, dynamic>>[];
  final variants = <Map<String, dynamic>>[];
  final images = <Map<String, dynamic>>[];
  final orders = <Map<String, dynamic>>[];
  final items = <Map<String, dynamic>>[];
  final receipts = <String>{};
  Map<String, dynamic> settings = {
    'id': 1, 'promo_active': true, 'promo_percent': 30, 'shipping_cost': 9900,
    'bre_b_key': '300 123 4567', 'bre_b_holder': 'WearUp SAS',
  };

  // Usuarios: correo -> (contraseña, perfil)
  final users = <String, (String, Map<String, dynamic>)>{};
  Map<String, dynamic>? _session;

  int _nextOrder = 1032;
  int _seq = 0;
  String _id() => 'id-${++_seq}';

  // Si es true, la siguiente llamada falla como si no hubiera conexión
  bool offline = false;

  void _seed() {
    categories.addAll([
      {'id': 1, 'name': 'Ropa', 'position': 1},
      {'id': 2, 'name': 'Jeans', 'position': 2},
      {'id': 3, 'name': 'Zapatos', 'position': 3},
      {'id': 4, 'name': 'Accesorios', 'position': 4},
    ]);
    _addProduct('p1', 1, 'Chaqueta denim', 149900, [('Azul', '#3B5B8F'), ('Negro', '#1A2433')], ['S', 'M', 'L', 'XL'], (c, s) => 3);
    _addProduct('p3', 2, 'Jeans slim', 119900, [('Negro', '#1A2433'), ('Azul', '#3B5B8F')], ['28', '30', '32', '34'],
        (c, s) => c == 'Negro' && s != '28' ? 1 : 0);
    _addProduct('p5', 4, 'Bolso de mano', 99900, [('Negro', '#1A2433')], ['Único'], (c, s) => 0);
    addUser('admin@wearup.com', 'clave123', fullName: 'Admin', admin: true);
  }

  void _addProduct(String id, int cat, String name, int price, List<(String, String)> colors, List<String> sizes, int Function(String, String) stock) {
    products.add({'id': id, 'category_id': cat, 'name': name, 'description': 'Descripción de $name', 'price': price, 'tint': '#D3E2F0'});
    for (var ci = 0; ci < colors.length; ci++) {
      for (var si = 0; si < sizes.length; si++) {
        final (cn, hex) = colors[ci];
        variants.add({
          'id': '$id-$cn-${sizes[si]}', 'product_id': id, 'sku': 'WU-$id-$cn-${sizes[si]}', 'color_name': cn, 'color_hex': hex,
          'size': sizes[si], 'color_order': ci + 1, 'size_order': si + 1, 'stock': stock(cn, sizes[si]),
        });
      }
    }
  }

  Map<String, dynamic> addUser(String email, String password, {String fullName = '', String phone = '', bool admin = false, bool consent = true}) {
    final profile = {
      'id': 'user-${users.length + 1}', 'email': email, 'full_name': fullName, 'phone': phone,
      'role': admin ? 'admin' : 'customer', 'data_consent_at': consent ? DateTime.now().toIso8601String() : null,
    };
    users[email] = (password, profile);
    return profile;
  }

  Map<String, dynamic> variantRow(String id) => variants.firstWhere((v) => v['id'] == id);

  // --- Ayudantes ---
  Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  Future<void> _net() async {
    if (offline) {
      offline = false;
      throw const BackendException('No se pudo conectar con el servidor. Revisa tu conexión a internet.');
    }
  }

  Map<String, dynamic> _requireUser() {
    final s = _session;
    if (s == null) throw BackendException(serverErrors['NO_AUTENTICADO']!);
    return s;
  }

  void _requireAdmin() {
    if (_session?['role'] != 'admin') throw const BackendException('No tienes permiso para hacer esto.');
  }

  // ---------------------------------------------------------------- Catálogo

  @override
  Future<CatalogData> loadCatalog() async {
    await _net();
    final cats = [for (final c in categories) ProductCategory.fromJson(_copy(c))];
    final prods = [
      for (final p in products)
        Product.fromJson({
          ..._copy(p),
          'product_variants': [for (final v in variants.where((v) => v['product_id'] == p['id'])) _copy(v)],
          'product_images': [for (final i in images.where((i) => i['product_id'] == p['id'])) _copy(i)],
        }),
    ];
    return CatalogData(cats, prods, StoreSettings.fromJson(_copy(settings)));
  }

  @override
  String productImageUrl(String path) => 'https://fake.storage/$path';

  // ---------------------------------------------------------------- Sesión

  @override
  Future<Profile?> currentProfile() async {
    await _net();
    return _session == null ? null : Profile.fromJson(_copy(_session!));
  }

  @override
  Future<Profile> signIn(String email, String password) async {
    await _net();
    final u = users[email];
    if (u == null || u.$1 != password) throw const BackendException('Correo o contraseña incorrectos.');
    _session = u.$2;
    return Profile.fromJson(_copy(u.$2));
  }

  @override
  Future<Profile> signUp({required String email, required String password, required String fullName, required String phone, required bool dataConsent}) async {
    await _net();
    if (users.containsKey(email)) throw const BackendException('Ya existe una cuenta con ese correo.');
    _session = addUser(email, password, fullName: fullName, phone: phone, consent: dataConsent);
    return Profile.fromJson(_copy(_session!));
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  final resetCodes = <String, String>{};

  @override
  Future<void> sendPasswordReset(String email) async {
    await _net();
    if (users.containsKey(email)) resetCodes[email] = '123456';
  }

  @override
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) async {
    await _net();
    if (resetCodes[email] != code) throw const BackendException('El código no es válido o ya venció.');
    users[email] = (newPassword, users[email]!.$2);
    resetCodes.remove(email);
  }

  @override
  Future<Profile> updateProfile({required String fullName, required String phone}) async {
    await _net();
    final u = _requireUser();
    u['full_name'] = fullName;
    u['phone'] = phone;
    return Profile.fromJson(_copy(u));
  }

  @override
  Future<void> deleteMyAccount() async {
    await _net();
    final u = _requireUser();
    users.remove(u['email']);
    for (final o in orders.where((o) => o['user_id'] == u['id'])) {
      o['user_id'] = null;
    }
    _session = null;
  }

  // ---------------------------------------------------------------- Pedidos

  Map<String, dynamic> _orderJson(Map<String, dynamic> o) => {
        ..._copy(o),
        'order_items': [for (final i in items.where((i) => i['order_id'] == o['id'])) _copy(i)],
      };

  @override
  Future<List<Order>> loadOrders() async {
    await _net();
    final u = _requireUser();
    final visible = orders.where((o) => u['role'] == 'admin' || o['user_id'] == u['id']).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return [for (final o in visible) Order.fromJson(_orderJson(o))];
  }

  @override
  Future<String> uploadReceipt(PickedImage image) async {
    await _net();
    final u = _requireUser();
    final path = '${u['id']}/${receipts.length + 1}.${image.extension}';
    receipts.add(path);
    return path;
  }

  // Mismas validaciones que place_order() en la base de datos
  @override
  Future<int> placeOrder({required List<CartItem> items, required ShippingInfo shipping, required String receiptPath}) async {
    await _net();
    final u = _requireUser();
    if (items.isEmpty) throw BackendException(serverErrors['CARRITO_VACIO']!);
    if (!receiptPath.startsWith('${u['id']}/') || !receipts.contains(receiptPath)) {
      throw BackendException(serverErrors['COMPROBANTE_INVALIDO']!);
    }
    final qty = <String, int>{};
    for (final i in items) {
      qty[i.variant.id] = (qty[i.variant.id] ?? 0) + i.qty;
    }
    var subtotal = 0;
    for (final e in qty.entries) {
      if (e.value <= 0) throw BackendException(serverErrors['CANTIDAD_INVALIDA']!);
      final v = variants.where((v) => v['id'] == e.key);
      if (v.isEmpty) throw BackendException(serverErrors['PRODUCTO_NO_DISPONIBLE']!);
      if ((v.first['stock'] as int) < e.value) throw BackendException(serverErrors['STOCK_INSUFICIENTE']!);
      final p = products.firstWhere((p) => p['id'] == v.first['product_id']);
      subtotal += (p['price'] as int) * e.value;
    }
    final id = _nextOrder++;
    orders.add({
      'id': id, 'user_id': u['id'], 'customer_name': shipping.customerName, 'customer_email': u['email'],
      'phone': shipping.phone, 'address': shipping.address, 'city': shipping.city, 'department': shipping.department,
      'notes': shipping.notes, 'subtotal': subtotal, 'shipping': settings['shipping_cost'], 'status': 'confirmed',
      'receipt_path': receiptPath, 'paid': false, 'created_at': DateTime.now().add(Duration(seconds: id)).toIso8601String(),
    });
    for (final e in qty.entries) {
      final v = variantRow(e.key);
      final p = products.firstWhere((p) => p['id'] == v['product_id']);
      this.items.add({
        'order_id': id, 'product_name': p['name'], 'color_name': v['color_name'], 'color_hex': v['color_hex'],
        'size': v['size'], 'tint': p['tint'], 'unit_price': p['price'], 'quantity': e.value, 'variant_id': v['id'],
      });
      v['stock'] = (v['stock'] as int) - e.value;
    }
    return id;
  }

  @override
  Future<String> receiptUrl(String path) async {
    await _net();
    return 'https://fake.storage/receipts/$path';
  }

  // ---------------------------------------------------------------- Administración

  @override
  Future<String> saveProduct(ProductDraft d) async {
    await _net();
    _requireAdmin();
    final id = d.id ?? _id();
    final row = {'id': id, 'category_id': d.categoryId, 'name': d.name, 'description': d.description, 'price': d.price, 'tint': d.tint};
    final existing = products.indexWhere((p) => p['id'] == id);
    if (existing >= 0) {
      products[existing] = row;
    } else {
      products.add(row);
    }
    final keep = <String>{};
    for (var ci = 0; ci < d.colors.length; ci++) {
      for (var si = 0; si < d.sizes.length; si++) {
        final c = d.colors[ci], s = d.sizes[si];
        final match = variants.where((v) => v['product_id'] == id && v['color_name'] == c.name && v['size'] == s);
        if (match.isNotEmpty) {
          match.first
            ..['color_hex'] = c.hex
            ..['color_order'] = ci + 1
            ..['size_order'] = si + 1;
          keep.add(match.first['id'] as String);
        } else {
          final vid = _id();
          keep.add(vid);
          variants.add({
            'id': vid, 'product_id': id, 'sku': 'WU-$id-${c.name}-$s', 'color_name': c.name, 'color_hex': c.hex,
            'size': s, 'color_order': ci + 1, 'size_order': si + 1, 'stock': 0,
          });
        }
      }
    }
    variants.removeWhere((v) => v['product_id'] == id && !keep.contains(v['id']));
    return id;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _net();
    _requireAdmin();
    products.removeWhere((p) => p['id'] == productId);
    variants.removeWhere((v) => v['product_id'] == productId);
    images.removeWhere((i) => i['product_id'] == productId);
  }

  @override
  Future<void> setVariantStock(String variantId, int stock) async {
    await _net();
    _requireAdmin();
    if (stock < 0) throw const BackendException('Hay un valor fuera del rango permitido.');
    variantRow(variantId)['stock'] = stock;
  }

  @override
  Future<void> addProductImage(String productId, PickedImage image) async {
    await _net();
    _requireAdmin();
    final n = images.where((i) => i['product_id'] == productId).length;
    images.add({'product_id': productId, 'path': '$productId/$n.${image.extension}', 'position': n});
  }

  @override
  Future<void> deleteProductImage(String productId, String path) async {
    await _net();
    _requireAdmin();
    images.removeWhere((i) => i['product_id'] == productId && i['path'] == path);
  }

  @override
  Future<void> updateOrder(int orderId, {OrderStatus? status, bool? paid}) async {
    await _net();
    _requireAdmin();
    final o = orders.firstWhere((o) => o['id'] == orderId);
    if (status != null) o['status'] = status.name;
    if (paid != null) o['paid'] = paid;
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    await _net();
    _requireAdmin();
    final o = orders.firstWhere((o) => o['id'] == orderId);
    if (o['status'] != 'delivered') {
      for (final i in items.where((i) => i['order_id'] == orderId)) {
        final v = variants.where((v) => v['id'] == i['variant_id']);
        if (v.isNotEmpty) v.first['stock'] = (v.first['stock'] as int) + (i['quantity'] as int);
      }
    }
    orders.remove(o);
    items.removeWhere((i) => i['order_id'] == orderId);
  }

  @override
  Future<void> saveSettings(StoreSettings s) async {
    await _net();
    _requireAdmin();
    if (s.promoPercent < 5 || s.promoPercent > 70) throw const BackendException('Hay un valor fuera del rango permitido.');
    settings['promo_active'] = s.promoActive;
    settings['promo_percent'] = s.promoPercent;
  }
}

PickedImage fakeReceipt() => PickedImage(Uint8List.fromList(FakeBackend.png), 'comprobante.png');
