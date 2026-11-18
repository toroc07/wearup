import 'package:flutter/material.dart';

// Disponibilidad calculada a partir de las unidades
enum Stock { available, low, out }

Stock stockStatus(int units) => units <= 0 ? Stock.out : (units <= 5 ? Stock.low : Stock.available);

// Estados de un pedido (mismos nombres que el tipo order_status de la base)
enum OrderStatus { confirmed, preparing, shipped, delivered }

extension OrderStatusX on OrderStatus {
  String get label => const ['Confirmado', 'En preparación', 'Enviado', 'Entregado'][index];
}

// --- Colores en formato #RRGGBB ---
Color colorFromHex(String hex) => Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
String colorToHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

// Un color de producto: nombre y tono
class ProductColor {
  final String name;
  final String hex;
  const ProductColor(this.name, this.hex);
  Color get color => colorFromHex(hex);

  @override
  bool operator ==(Object other) => other is ProductColor && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

class ProductCategory {
  final int id;
  final String name;
  const ProductCategory(this.id, this.name);

  factory ProductCategory.fromJson(Map<String, dynamic> j) => ProductCategory(j['id'] as int, j['name'] as String);
}

// Variante = talla + color de un producto, con su SKU y su stock
class Variant {
  final String id;
  final String sku;
  final String colorName;
  final String colorHex;
  final String size;
  final int colorOrder;
  final int sizeOrder;
  int stock;

  Variant({
    required this.id,
    required this.sku,
    required this.colorName,
    required this.colorHex,
    required this.size,
    this.colorOrder = 0,
    this.sizeOrder = 0,
    this.stock = 0,
  });

  ProductColor get color => ProductColor(colorName, colorHex);
  Stock get status => stockStatus(stock);

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: j['id'] as String,
        sku: j['sku'] as String,
        colorName: j['color_name'] as String,
        colorHex: j['color_hex'] as String,
        size: j['size'] as String,
        colorOrder: (j['color_order'] as num?)?.toInt() ?? 0,
        sizeOrder: (j['size_order'] as num?)?.toInt() ?? 0,
        stock: (j['stock'] as num).toInt(),
      );
}

class Product {
  final String id;
  String name;
  int categoryId;
  String description;
  int price;
  String tint;
  List<Variant> variants;
  // Rutas de las fotos dentro del bucket público "product-images"
  List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.description = '',
    this.tint = '#D3E2F0',
    List<Variant>? variants,
    List<String>? images,
  })  : variants = variants ?? [],
        images = images ?? [];

  Color get tintColor => colorFromHex(tint);

  // Unidades totales (suma de todas las variantes)
  int get stock => variants.fold(0, (s, v) => s + v.stock);
  Stock get status => stockStatus(stock);

  // Colores y tallas en el orden definido por el administrador
  List<ProductColor> get colors {
    final sorted = [...variants]..sort((a, b) => a.colorOrder.compareTo(b.colorOrder));
    return {for (final v in sorted) v.color}.toList();
  }

  List<String> get sizes {
    final sorted = [...variants]..sort((a, b) => a.sizeOrder.compareTo(b.sizeOrder));
    return {for (final v in sorted) v.size}.toList();
  }

  Variant? variant(String colorName, String size) {
    for (final v in variants) {
      if (v.colorName == colorName && v.size == size) return v;
    }
    return null;
  }

  int stockOf(String colorName, String size) => variant(colorName, size)?.stock ?? 0;
  int stockOfColor(String colorName) => variants.where((v) => v.colorName == colorName).fold(0, (s, v) => s + v.stock);
  int stockOfSize(String size) => variants.where((v) => v.size == size).fold(0, (s, v) => s + v.stock);

  factory Product.fromJson(Map<String, dynamic> j) {
    final variants = [for (final v in (j['product_variants'] as List? ?? const [])) Variant.fromJson(v as Map<String, dynamic>)]
      ..sort((a, b) => a.colorOrder != b.colorOrder ? a.colorOrder.compareTo(b.colorOrder) : a.sizeOrder.compareTo(b.sizeOrder));
    final images = [for (final i in (j['product_images'] as List? ?? const [])) i as Map<String, dynamic>]
      ..sort((a, b) => ((a['position'] as num?) ?? 0).compareTo((b['position'] as num?) ?? 0));
    return Product(
      id: j['id'] as String,
      name: j['name'] as String,
      categoryId: (j['category_id'] as num).toInt(),
      description: (j['description'] as String?) ?? '',
      price: (j['price'] as num).toInt(),
      tint: (j['tint'] as String?) ?? '#D3E2F0',
      variants: variants,
      images: [for (final i in images) i['path'] as String],
    );
  }
}

// Un producto en el carrito: variante elegida y cantidad
class CartItem {
  final Product product;
  final Variant variant;
  int qty;
  CartItem(this.product, this.variant, this.qty);

  int get total => product.price * qty;
}

// Un ítem de un pedido ya hecho: copia del producto al momento de comprar
class OrderItem {
  final String productName, colorName, colorHex, size, tint;
  final int unitPrice, qty;

  const OrderItem({
    required this.productName,
    required this.colorName,
    required this.colorHex,
    required this.size,
    required this.tint,
    required this.unitPrice,
    required this.qty,
  });

  int get total => unitPrice * qty;
  Color get tintColor => colorFromHex(tint);

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productName: j['product_name'] as String,
        colorName: j['color_name'] as String,
        colorHex: j['color_hex'] as String,
        size: j['size'] as String,
        tint: (j['tint'] as String?) ?? '#D3E2F0',
        unitPrice: (j['unit_price'] as num).toInt(),
        qty: (j['quantity'] as num).toInt(),
      );
}

class Order {
  final int number;
  final String? userId;
  final DateTime date;
  final List<OrderItem> items;
  final int subtotal, shipping;
  final String customerName, customerEmail, phone, address, city, department, notes;
  // Ruta de la captura del comprobante en el bucket privado "receipts"
  final String? receiptPath;
  bool paid;
  OrderStatus status;

  Order({
    required this.number,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.status,
    this.userId,
    this.customerName = '',
    this.customerEmail = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.department = '',
    this.notes = '',
    this.receiptPath,
    this.paid = false,
  });

  int get total => subtotal + shipping;
  int get units => items.fold(0, (s, i) => s + i.qty);
  String get fullAddress => [address, city, department].where((s) => s.trim().isNotEmpty).join(', ');

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        number: (j['id'] as num).toInt(),
        userId: j['user_id'] as String?,
        date: DateTime.parse(j['created_at'] as String).toLocal(),
        items: [for (final i in (j['order_items'] as List? ?? const [])) OrderItem.fromJson(i as Map<String, dynamic>)],
        subtotal: (j['subtotal'] as num).toInt(),
        shipping: (j['shipping'] as num).toInt(),
        status: OrderStatus.values.byName(j['status'] as String),
        customerName: (j['customer_name'] as String?) ?? '',
        customerEmail: (j['customer_email'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        address: (j['address'] as String?) ?? '',
        city: (j['city'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
        receiptPath: j['receipt_path'] as String?,
        paid: (j['paid'] as bool?) ?? false,
      );
}

class Profile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final bool isAdmin;

  const Profile({required this.id, required this.email, this.fullName = '', this.phone = '', this.isAdmin = false});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        email: (j['email'] as String?) ?? '',
        fullName: (j['full_name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        isAdmin: j['role'] == 'admin',
      );
}

// Configuración de la tienda (promoción, envío y llave BRE-B)
class StoreSettings {
  final bool promoActive;
  final int promoPercent;
  final int shippingCost;
  final String breBKey;
  final String breBHolder;

  const StoreSettings({
    this.promoActive = false,
    this.promoPercent = 30,
    this.shippingCost = 9900,
    this.breBKey = '',
    this.breBHolder = '',
  });

  StoreSettings copyWith({bool? promoActive, int? promoPercent}) => StoreSettings(
        promoActive: promoActive ?? this.promoActive,
        promoPercent: promoPercent ?? this.promoPercent,
        shippingCost: shippingCost,
        breBKey: breBKey,
        breBHolder: breBHolder,
      );

  factory StoreSettings.fromJson(Map<String, dynamic> j) => StoreSettings(
        promoActive: j['promo_active'] as bool,
        promoPercent: (j['promo_percent'] as num).toInt(),
        shippingCost: (j['shipping_cost'] as num).toInt(),
        breBKey: j['bre_b_key'] as String,
        breBHolder: j['bre_b_holder'] as String,
      );
}

// --- Formatos ---
const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

// Da formato al precio: 149900 -> $149.900
String fmtPrice(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer(v < 0 ? '-\$' : '\$');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
