import 'dart:typed_data';

import 'models.dart';

// Error con un mensaje listo para mostrar al usuario
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);
  @override
  String toString() => message;
}

class CatalogData {
  final List<ProductCategory> categories;
  final List<Product> products;
  final StoreSettings settings;
  const CatalogData(this.categories, this.products, this.settings);
}

// Datos de un producto que el administrador crea o edita.
// Las variantes resultan de combinar colores x tallas (las nuevas empiezan con stock 0).
class ProductDraft {
  final String? id;
  final String name;
  final int categoryId;
  final String description;
  final int price;
  final String tint;
  final List<ProductColor> colors;
  final List<String> sizes;

  const ProductDraft({
    this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.tint,
    required this.colors,
    required this.sizes,
  });
}

// Datos de envío del checkout
class ShippingInfo {
  final String customerName, phone, address, city, department, notes;
  const ShippingInfo({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.department,
    this.notes = '',
  });
}

// Imagen elegida por el usuario (comprobante o foto de producto)
class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage(this.bytes, this.name);

  String get extension {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? 'jpg' : name.substring(dot + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  String get contentType => extension == 'png' ? 'image/png' : (extension == 'webp' ? 'image/webp' : 'image/jpeg');
}

/// Operaciones contra el servidor. La implementación real es [SupabaseBackend];
/// las pruebas usan una versión en memoria con las mismas reglas.
abstract class Backend {
  // Catálogo
  Future<CatalogData> loadCatalog();
  String productImageUrl(String path);

  // Sesión
  Future<Profile?> currentProfile();
  Future<Profile> signIn(String email, String password);
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required bool dataConsent,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword});
  Future<Profile> updateProfile({required String fullName, required String phone});
  Future<void> deleteMyAccount();

  // Pedidos
  Future<List<Order>> loadOrders();
  Future<String> uploadReceipt(PickedImage image);
  Future<int> placeOrder({required List<CartItem> items, required ShippingInfo shipping, required String receiptPath});
  Future<String> receiptUrl(String path);

  // Administración
  Future<String> saveProduct(ProductDraft draft);
  Future<void> deleteProduct(String productId);
  Future<void> setVariantStock(String variantId, int stock);
  Future<void> addProductImage(String productId, PickedImage image);
  Future<void> deleteProductImage(String productId, String path);
  Future<void> updateOrder(int orderId, {OrderStatus? status, bool? paid});
  Future<void> deleteOrder(int orderId);
  Future<void> saveSettings(StoreSettings settings);
}

// Mensajes para los códigos de error que devuelven las funciones de la base
const serverErrors = {
  'NO_AUTENTICADO': 'Tu sesión terminó. Vuelve a ingresar.',
  'CARRITO_VACIO': 'Tu carrito está vacío.',
  'DATOS_ENVIO_INCOMPLETOS': 'Completa los datos de envío.',
  'TELEFONO_INVALIDO': 'Ingresa un teléfono válido.',
  'COMPROBANTE_INVALIDO': 'No pudimos leer el comprobante. Vuelve a subirlo.',
  'CANTIDAD_INVALIDA': 'Revisa las cantidades del carrito.',
  'PRODUCTO_NO_DISPONIBLE': 'Un producto de tu carrito ya no está disponible.',
  'STOCK_INSUFICIENTE': 'Algunos productos ya no tienen suficientes unidades. Ajusta tu carrito.',
  'SOLO_ADMIN': 'Solo el administrador puede hacer esto.',
  'PEDIDO_NO_EXISTE': 'El pedido ya no existe.',
};
