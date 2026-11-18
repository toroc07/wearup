import 'package:flutter_test/flutter_test.dart';
import 'package:wearup/state.dart';

import 'fake_backend.dart';

void main() {
  late FakeBackend server;
  late AppState s;

  setUp(() async {
    server = FakeBackend();
    s = AppState(server);
    await s.init();
  });

  Product product(String id) => s.productById(id)!;
  Variant variant(String productId, String color, String size) => product(productId).variant(color, size)!;
  const shipping = ShippingInfo(customerName: 'Ana Pérez', phone: '3001234567', address: 'Calle 1 # 2-3', city: 'Cartagena', department: 'Bolívar');

  Future<void> loginCustomer() async {
    server.addUser('ana@correo.com', 'clave123', fullName: 'Ana Pérez', phone: '3001234567');
    await s.signIn('ana@correo.com', 'clave123');
  }

  group('Catálogo', () {
    test('carga productos con stock por variante', () {
      expect(s.loadError, isNull);
      expect(s.products.map((p) => p.name), ['Chaqueta denim', 'Jeans slim', 'Bolso de mano']);
      final jacket = product('p1');
      expect(jacket.variants.length, 8);
      expect(jacket.stock, 24);
      expect(jacket.colors.map((c) => c.name), ['Azul', 'Negro']);
      expect(jacket.sizes, ['S', 'M', 'L', 'XL']);
      expect(product('p3').status, Stock.low);
      expect(product('p5').status, Stock.out);
    });

    test('si no hay conexión muestra un error y se puede reintentar', () async {
      server.offline = true;
      await s.init();
      expect(s.loadError, contains('conexión'));
      await s.init();
      expect(s.loadError, isNull);
    });
  });

  group('Carrito (stock por variante)', () {
    test('no se agregan más unidades que el stock de la talla y color', () {
      final azulM = variant('p1', 'Azul', 'M'); // 3 unidades
      expect(s.addToCart(product('p1'), azulM, 2), 2);
      expect(s.addToCart(product('p1'), azulM, 5), 1);
      expect(s.addToCart(product('p1'), azulM, 1), 0);
      // Otra variante del mismo producto tiene su propio stock
      expect(s.addToCart(product('p1'), variant('p1', 'Negro', 'M'), 3), 3);
      expect(s.cartCount, 6);
    });

    test('la cantidad en el carrito no supera el stock de la variante', () {
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 1);
      s.setQty(s.cart.first, 10);
      expect(s.cart.first.qty, 3);
    });

    test('una variante agotada no se agrega', () {
      expect(s.addToCart(product('p3'), variant('p3', 'Negro', '28'), 1), 0);
      expect(s.cart, isEmpty);
    });
  });

  group('Pedidos', () {
    test('comprar exige sesión', () async {
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 1);
      await expectLater(s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt()), throwsA(isA<BackendException>()));
    });

    test('el pedido se crea en el servidor, descuenta stock y vacía el carrito', () async {
      await loginCustomer();
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 2);
      s.addToCart(product('p1'), variant('p1', 'Negro', 'L'), 1);
      final order = await s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt());

      expect(order.number, 1032);
      expect(order.subtotal, 149900 * 3);
      expect(order.shipping, 9900);
      expect(order.paid, isFalse);
      expect(order.receiptPath, isNotNull);
      expect(s.cart, isEmpty);
      expect(server.variantRow('p1-Azul-M')['stock'], 1);
      expect(variant('p1', 'Azul', 'M').stock, 1); // el catálogo se recargó
      expect(s.myOrders.map((o) => o.number), [1032]);
    });

    test('editar el producto después no cambia el pedido', () async {
      await loginCustomer();
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 1);
      final order = await s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt());
      server.products.first['price'] = 1;
      server.products.first['name'] = 'Otro nombre';
      await s.refresh();

      final again = s.orders.firstWhere((o) => o.number == order.number);
      expect(again.items.single.productName, 'Chaqueta denim');
      expect(again.items.single.total, 149900);
      expect(again.subtotal, 149900);
    });

    test('si el stock bajó en el servidor, no se crea el pedido y el carrito se conserva', () async {
      await loginCustomer();
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 3);
      server.variantRow('p1-Azul-M')['stock'] = 1; // otro cliente compró antes

      await expectLater(s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt()),
          throwsA(isA<BackendException>().having((e) => e.message, 'mensaje', contains('suficientes unidades'))));
      expect(server.orders, isEmpty);
      expect(s.cart.single.qty, 3);
      expect(s.cartFitsStock, isFalse); // el catálogo se recargó con el stock real
    });

    test('cada cliente ve solo sus pedidos; el administrador ve todos', () async {
      await loginCustomer();
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 1);
      await s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt());

      await s.signOut();
      server.addUser('luis@correo.com', 'clave123');
      await s.signIn('luis@correo.com', 'clave123');
      expect(s.orders, isEmpty);

      await s.signOut();
      await s.signIn('admin@wearup.com', 'clave123');
      expect(s.isAdmin, isTrue);
      expect(s.orders.length, 1);
      expect(s.myOrders, isEmpty); // no son pedidos del administrador
    });
  });

  group('Sesión', () {
    test('el registro guarda nombre, teléfono y la autorización de datos', () async {
      await s.signUp(email: 'nuevo@correo.com', password: 'clave123', fullName: 'Nuevo Cliente', phone: '3110000000', dataConsent: true);
      expect(s.profile!.fullName, 'Nuevo Cliente');
      expect(s.profile!.phone, '3110000000');
      expect(server.users['nuevo@correo.com']!.$2['data_consent_at'], isNotNull);
      expect(s.isAdmin, isFalse);
    });

    test('contraseña incorrecta', () async {
      await expectLater(s.signIn('admin@wearup.com', 'mala'), throwsA(isA<BackendException>()));
      expect(s.loggedIn, isFalse);
    });

    test('recuperar contraseña con el código del correo', () async {
      await s.sendPasswordReset('admin@wearup.com');
      await expectLater(s.confirmPasswordReset(email: 'admin@wearup.com', code: '000000', newPassword: 'nueva123'), throwsA(isA<BackendException>()));
      await s.confirmPasswordReset(email: 'admin@wearup.com', code: '123456', newPassword: 'nueva123');
      await s.signIn('admin@wearup.com', 'nueva123');
      expect(s.loggedIn, isTrue);
    });

    test('editar datos y eliminar la cuenta', () async {
      await loginCustomer();
      await s.updateProfile(fullName: 'Ana María', phone: '3200000000');
      expect(s.profile!.fullName, 'Ana María');
      await s.deleteMyAccount();
      expect(s.loggedIn, isFalse);
      expect(server.users.containsKey('ana@correo.com'), isFalse);
    });
  });

  group('Administración', () {
    setUp(() => s.signIn('admin@wearup.com', 'clave123'));

    test('valida el pago, cambia el estado y al borrar devuelve el stock', () async {
      await s.signOut();
      await loginCustomer();
      s.addToCart(product('p1'), variant('p1', 'Azul', 'M'), 2);
      await s.placeOrder(shippingInfo: shipping, receipt: fakeReceipt());
      await s.signOut();
      await s.signIn('admin@wearup.com', 'clave123');

      final order = s.orders.single;
      await s.validatePayment(order);
      await s.setOrderStatus(order, OrderStatus.preparing);
      expect(server.orders.single['paid'], isTrue);
      expect(server.orders.single['status'], 'preparing');

      await s.deleteOrder(order);
      expect(server.orders, isEmpty);
      expect(variant('p1', 'Azul', 'M').stock, 3);
    });

    test('crear producto genera una variante por color y talla', () async {
      await s.saveProduct(const ProductDraft(
        name: 'Gorra',
        categoryId: 4,
        description: '',
        price: 39900,
        tint: '#D3E2F0',
        colors: [ProductColor('Negro', '#1A2433'), ProductColor('Rojo', '#B23A3A')],
        sizes: ['Único'],
      ));
      final cap = s.products.firstWhere((p) => p.name == 'Gorra');
      expect(cap.variants.length, 2);
      expect(cap.stock, 0);
    });

    test('quitar una talla borra solo esas variantes y conserva el stock de las demás', () async {
      final jacket = product('p1');
      await s.setVariantStock(variant('p1', 'Azul', 'M'), 10);
      await s.saveProduct(ProductDraft(
        id: jacket.id,
        name: jacket.name,
        categoryId: jacket.categoryId,
        description: jacket.description,
        price: 159900,
        tint: jacket.tint,
        colors: jacket.colors,
        sizes: const ['S', 'M', 'L'],
      ));
      expect(product('p1').sizes, ['S', 'M', 'L']);
      expect(product('p1').price, 159900);
      expect(variant('p1', 'Azul', 'M').stock, 10);
    });

    test('si el servidor rechaza un cambio de stock, se revierte en pantalla', () async {
      final v = variant('p1', 'Azul', 'M');
      server.offline = true;
      await expectLater(s.setVariantStock(v, 50), throwsA(isA<BackendException>()));
      expect(v.stock, 3);
    });

    test('un cliente no puede hacer cambios de administrador', () async {
      await s.signOut();
      await loginCustomer();
      await expectLater(s.setVariantStock(variant('p1', 'Azul', 'M'), 99), throwsA(isA<BackendException>()));
      expect(server.variantRow('p1-Azul-M')['stock'], 3);
    });
  });
}
