import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estado de disponibilidad de un producto
enum Stock { available, low, out }

enum OrderStatus { confirmed, preparing, shipped, delivered }

extension OrderStatusX on OrderStatus {
  String get label => const ['Confirmado', 'En preparación', 'Enviado', 'Entregado'][index];
}

// Un color con su nombre y su tono
class ProductColor {
  final String name;
  final Color color;
  const ProductColor(this.name, this.color);

  Map<String, dynamic> toJson() => {'n': name, 'c': color.toARGB32()};
  factory ProductColor.fromJson(Map<String, dynamic> j) => ProductColor(j['n'], Color(j['c']));
}

const kSizes = ['S', 'M', 'L', 'XL'];
const kCategories = ['Ropa', 'Jeans', 'Zapatos', 'Accesorios'];

// El molde de los datos de un producto
class Product {
  String id, name, category, description;
  int price, stock;
  List<ProductColor> colors;
  List<String> sizes;
  Color tint;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.colors,
    this.sizes = kSizes,
    this.description = '',
    this.tint = const Color(0xFFD3E2F0),
  });

  // Se calcula según las unidades disponibles
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'stock': stock,
        'colors': [for (final c in colors) c.toJson()],
        'sizes': sizes,
        'tint': tint.toARGB32(),
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        category: j['category'],
        description: j['description'],
        price: j['price'],
        stock: j['stock'],
        colors: [for (final c in j['colors']) ProductColor.fromJson(c)],
        sizes: List<String>.from(j['sizes']),
        tint: Color(j['tint']),
      );

  Stock get status => stock <= 0 ? Stock.out : (stock <= 5 ? Stock.low : Stock.available);
}

// Un producto elegido en el carrito (con color, talla y cantidad)
class CartItem {
  final Product product;
  final ProductColor color;
  final String size;
  int qty;
  CartItem(this.product, this.color, this.size, this.qty);
  int get total => product.price * qty;

  // Se guarda una copia del producto para que el pedido no cambie si luego se edita o elimina
  Map<String, dynamic> toJson() => {'p': product.toJson(), 'c': color.toJson(), 's': size, 'q': qty};
  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(Product.fromJson(j['p']), ProductColor.fromJson(j['c']), j['s'], j['q']);
}

// Un pedido ya confirmado
class Order {
  final int number;
  final DateTime date;
  final List<CartItem> items;
  final int subtotal, shipping;
  final String address, customer, phone;
  // Correo del cliente (null en los pedidos de ejemplo, que ve cualquier cliente)
  final String? email;
  // Nombre del archivo del comprobante y si el administrador ya validó el pago
  final String? receipt;
  bool paid;
  OrderStatus status;

  Order({
    required this.number,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.address,
    required this.status,
    this.customer = '',
    this.phone = '',
    this.email,
    this.receipt,
    this.paid = false,
  });

  int get total => subtotal + shipping;
  int get units => items.fold(0, (s, i) => s + i.qty);

  Map<String, dynamic> toJson() => {
        'number': number,
        'date': date.toIso8601String(),
        'items': [for (final i in items) i.toJson()],
        'subtotal': subtotal,
        'shipping': shipping,
        'address': address,
        'customer': customer,
        'phone': phone,
        'email': email,
        'receipt': receipt,
        'paid': paid,
        'status': status.index,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        number: j['number'],
        date: DateTime.parse(j['date']),
        items: [for (final i in j['items']) CartItem.fromJson(i)],
        subtotal: j['subtotal'],
        shipping: j['shipping'],
        address: j['address'],
        customer: j['customer'],
        phone: j['phone'],
        email: j['email'],
        receipt: j['receipt'],
        paid: j['paid'],
        status: OrderStatus.values[j['status']],
      );
}

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

// Da formato al precio: 149900 -> \$149.900
String fmtPrice(int v) {
  final s = v.toString();
  final buf = StringBuffer('\$');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

const kShipping = 9900;

// Estado global de la app: productos, carrito, pedidos y sesión
class AppState extends ChangeNotifier {
  final List<Product> products = [
    Product(
      id: 'p1', name: 'Chaqueta denim', category: 'Ropa', price: 149900, stock: 24,
      colors: const [ProductColor('Azul', Color(0xFF3B5B8F)), ProductColor('Negro', Color(0xFF1A2433))],
      description: 'Chaqueta de denim con corte clásico. Algodón de 12 oz, ajuste regular. Lavar a máquina en frío.',
      tint: const Color(0xFFD3E2F0),
    ),
    Product(
      id: 'p2', name: 'Camiseta básica', category: 'Ropa', price: 59900, stock: 63,
      colors: const [
        ProductColor('Blanco', Color(0xFFF2F2F2)), ProductColor('Negro', Color(0xFF1A2433)),
        ProductColor('Azul', Color(0xFF3B5B8F)), ProductColor('Verde', Color(0xFF4F8F6B)), ProductColor('Gris', Color(0xFF9AA5B1)),
      ],
      description: '100 % algodón peinado, cuello redondo y tejido suave. Ideal para el día a día.',
      tint: const Color(0xFFE3EAF4),
    ),
    Product(
      id: 'p3', name: 'Jeans slim', category: 'Jeans', price: 119900, stock: 3,
      colors: const [ProductColor('Negro', Color(0xFF1A2433)), ProductColor('Azul', Color(0xFF3B5B8F)), ProductColor('Gris', Color(0xFF9AA5B1))],
      sizes: const ['28', '30', '32', '34'],
      description: 'Jeans de corte slim con elastano para mayor comodidad. Tiro medio.',
      tint: const Color(0xFFD9E7F2),
    ),
    Product(
      id: 'p4', name: 'Tenis urbanos', category: 'Zapatos', price: 189900, stock: 18,
      colors: const [ProductColor('Blanco', Color(0xFFF2F2F2)), ProductColor('Negro', Color(0xFF1A2433))],
      sizes: const ['38', '39', '40', '41', '42'],
      description: 'Tenis de suela ligera y plantilla acolchada para uso diario.',
      tint: const Color(0xFFDDEBEA),
    ),
    Product(
      id: 'p5', name: 'Bolso de mano', category: 'Accesorios', price: 99900, stock: 0,
      colors: const [
        ProductColor('Negro', Color(0xFF1A2433)), ProductColor('Café', Color(0xFF8B5E3C)),
        ProductColor('Beige', Color(0xFFD9C7A8)), ProductColor('Azul', Color(0xFF3B5B8F)),
      ],
      sizes: const ['Único'],
      description: 'Bolso de mano en cuero sintético con cierre y bolsillo interior.',
      tint: const Color(0xFFD5EBF1),
    ),
  ];

  // Carrito y pedidos
  final List<CartItem> cart = [];
  final List<Order> orders = [];
  int _nextOrder = 1032;

  // Sesión
  String? userEmail;
  bool isAdmin = false;
  bool get loggedIn => userEmail != null;

  // Promoción
  bool promoActive = true;
  int promoPercent = 30;

  // Pestaña activa del shell
  final ValueNotifier<int> tab = ValueNotifier(0);
  void goTab(int i) => tab.value = i;

  AppState() {
    _seed();
  }

  // Datos de ejemplo del prototipo (pedidos anteriores)
  void _seed() {
    final dim = products;
    orders.addAll([
      Order(
        number: 1024, date: DateTime(2026, 9, 18), items: [CartItem(dim[1], dim[1].colors[0], 'M', 1)], subtotal: 59900, shipping: 0,
        address: 'Calle 45 # 12-30, Bogotá', status: OrderStatus.shipped, customer: 'Cliente de ejemplo', paid: true,
      ),
      Order(
        number: 1009, date: DateTime(2026, 9, 2), items: [CartItem(dim[0], dim[0].colors[0], 'M', 1), CartItem(dim[2], dim[2].colors[0], '32', 1)],
        subtotal: 259800, shipping: 0, address: 'Calle 45 # 12-30, Bogotá', status: OrderStatus.delivered, customer: 'Cliente de ejemplo', paid: true,
      ),
    ]);
  }

  // --- Guardado local ---
  // Se guarda todo en el dispositivo (SharedPreferences) cada vez que algo cambia
  static const _key = 'wearup_data';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final loadedProducts = [for (final p in j['products']) Product.fromJson(p)];
      final loadedOrders = [for (final o in j['orders']) Order.fromJson(o)];
      products
        ..clear()
        ..addAll(loadedProducts);
      orders
        ..clear()
        ..addAll(loadedOrders);
      _nextOrder = j['nextOrder'];
      promoActive = j['promoActive'];
      promoPercent = j['promoPercent'];
      userEmail = j['userEmail'];
      isAdmin = userEmail?.toLowerCase().startsWith('admin') ?? false;
    } catch (_) {
      // Si los datos guardados están dañados se usan los de ejemplo
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'products': [for (final p in products) p.toJson()],
          'orders': [for (final o in orders) o.toJson()],
          'nextOrder': _nextOrder,
          'promoActive': promoActive,
          'promoPercent': promoPercent,
          'userEmail': userEmail,
        }),
      );
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _save();
  }

  // Pedidos que ve el cliente actual
  List<Order> get myOrders => orders.where((o) => o.email == null || o.email == userEmail).toList();

  // --- Carrito ---
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  int get subtotal => cart.fold(0, (s, i) => s + i.total);
  int get shipping => cart.isEmpty ? 0 : kShipping;
  int get total => subtotal + shipping;

  // Agrega al carrito; si ya existe, suma la cantidad
  void addToCart(Product p, ProductColor c, String size, int qty) {
    final existing = cart.where((i) => i.product == p && i.color == c && i.size == size);
    if (existing.isNotEmpty) {
      existing.first.qty = (existing.first.qty + qty).clamp(1, p.stock);
    } else {
      cart.add(CartItem(p, c, size, qty));
    }
    notifyListeners();
  }

  void setQty(CartItem i, int qty) {
    i.qty = qty.clamp(1, i.product.stock < 1 ? 1 : i.product.stock);
    notifyListeners();
  }

  void removeItem(CartItem i) {
    cart.remove(i);
    notifyListeners();
  }

  // Crea el pedido, descuenta el stock y vacía el carrito
  Order placeOrder({required String address, required String customer, required String phone, required String receipt}) {
    final order = Order(
      number: _nextOrder++,
      date: DateTime.now(),
      items: List.of(cart),
      subtotal: subtotal,
      shipping: shipping,
      address: address,
      status: OrderStatus.confirmed,
      customer: customer,
      phone: phone,
      email: userEmail,
      receipt: receipt,
    );
    for (final i in cart) {
      i.product.stock = (i.product.stock - i.qty).clamp(0, 1 << 30);
    }
    orders.insert(0, order);
    cart.clear();
    notifyListeners();
    return order;
  }

  // --- Sesión ---
  // Inicio de sesión simulado: un correo que empieza por "admin" es administrador
  void login(String email) {
    userEmail = email;
    isAdmin = email.toLowerCase().startsWith('admin');
    notifyListeners();
  }

  void logout() {
    userEmail = null;
    isAdmin = false;
    notifyListeners();
  }

  // --- Administración ---
  void saveProduct(Product p) {
    if (!products.contains(p)) products.add(p);
    notifyListeners();
  }

  void deleteProduct(Product p) {
    products.remove(p);
    cart.removeWhere((i) => i.product == p);
    notifyListeners();
  }

  void setStock(Product p, int stock) {
    p.stock = stock < 0 ? 0 : stock;
    notifyListeners();
  }

  void setOrderStatus(Order o, OrderStatus s) {
    o.status = s;
    notifyListeners();
  }

  // El administrador confirma que recibió la transferencia
  void validatePayment(Order o) {
    o.paid = true;
    notifyListeners();
  }

  // Elimina un pedido y devuelve las unidades al inventario si aún no se entregó
  void deleteOrder(Order o) {
    if (o.status != OrderStatus.delivered) {
      for (final i in o.items) {
        final live = products.where((p) => p.id == i.product.id);
        if (live.isNotEmpty) live.first.stock += i.qty;
      }
    }
    orders.remove(o);
    notifyListeners();
  }

  void setPromo(bool active, int percent) {
    promoActive = active;
    promoPercent = percent;
    notifyListeners();
  }

  String newProductId() => 'p${DateTime.now().microsecondsSinceEpoch}';
}

// Instancia única que usan todas las pantallas
final app = AppState();
