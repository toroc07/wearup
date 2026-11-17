import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearup/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState s;
  late Product jacket; // stock 24

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    s = AppState();
    jacket = s.products.firstWhere((p) => p.id == 'p1');
  });

  Order placeDefault() => s.placeOrder(address: 'Calle 1', customer: 'Ana', phone: '3001234567', receipt: 'r.jpg')!;

  group('Aislamiento de pedidos', () {
    test('editar un producto no cambia los pedidos ya hechos', () {
      s.addToCart(jacket, jacket.colors[0], 'M', 2);
      final order = placeDefault();

      jacket
        ..name = 'Otro nombre'
        ..price = 1;
      s.saveProduct(jacket);

      expect(order.items.first.product.name, 'Chaqueta denim');
      expect(order.items.first.total, 149900 * 2);
      expect(order.items.fold<int>(0, (t, i) => t + i.total), order.subtotal);
    });

    test('los pedidos de ejemplo tampoco cambian al editar el catálogo', () {
      final seeded = s.orders.firstWhere((o) => o.number == 1024);
      s.products[1].price = 1;
      expect(seeded.items.first.total, 59900);
    });

    test('el pedido descuenta el stock del catálogo', () {
      s.addToCart(jacket, jacket.colors[0], 'M', 3);
      placeDefault();
      expect(jacket.stock, 21);
    });
  });

  group('Límite de stock', () {
    test('no se agregan más unidades que el stock, sumando todas las variantes', () {
      s.setStock(jacket, 5);
      expect(s.addToCart(jacket, jacket.colors[0], 'M', 3), 3);
      expect(s.addToCart(jacket, jacket.colors[1], 'L', 4), 2);
      expect(s.addToCart(jacket, jacket.colors[1], 'S', 1), 0);
      expect(s.inCart(jacket), 5);
    });

    test('al subir la cantidad en el carrito se respeta el stock restante', () {
      s.setStock(jacket, 5);
      s.addToCart(jacket, jacket.colors[0], 'M', 3);
      s.addToCart(jacket, jacket.colors[1], 'L', 1);
      s.setQty(s.cart.last, 10);
      expect(s.cart.last.qty, 2);
    });

    test('no se confirma un pedido si el stock bajó después de agregar al carrito', () {
      s.addToCart(jacket, jacket.colors[0], 'M', 4);
      s.setStock(jacket, 2);
      final before = s.orders.length;

      expect(s.cartFitsStock, isFalse);
      expect(s.placeOrder(address: 'a', customer: 'b', phone: '1234567', receipt: 'r'), isNull);
      expect(s.orders.length, before);
      expect(jacket.stock, 2);
      expect(s.cart, isNotEmpty);
    });

    test('un producto agotado no se puede agregar', () {
      final bag = s.products.firstWhere((p) => p.id == 'p5'); // stock 0
      expect(s.addToCart(bag, bag.colors[0], 'Único', 1), 0);
      expect(s.cart, isEmpty);
    });
  });
}
