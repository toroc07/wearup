import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearup/main.dart';
import 'package:wearup/state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Carga la fuente real para que las medidas del test sean las de la app
  setUpAll(() async {
    final loader = FontLoader('Montserrat')..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await loader.load();
  });

  testWidgets('Compra completa y gestión del pedido como administrador', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const WearUpApp());
    expect(find.text('VISTE TU ESTILO'), findsOneWidget);

    // Catálogo -> agregar chaqueta
    await tester.tap(find.text('Catálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar al carrito').first);
    await tester.pump();
    expect(app.cartCount, 1);

    // Carrito -> pide iniciar sesión
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'cliente@correo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    // Envío
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana Pérez');
    await tester.enterText(fields.at(1), '3001234567');
    await tester.enterText(fields.at(2), 'Calle 1 # 2-3');
    await tester.enterText(fields.at(3), 'Cartagena');
    await tester.enterText(fields.at(4), 'Bolívar');
    await tester.tap(find.text('Continuar al pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya transferí, continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sube una foto del comprobante'));
    await tester.pump();
    await tester.tap(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();
    expect(find.text('Compra confirmada'), findsOneWidget);
    expect(app.orders.first.customer, 'Ana Pérez');
    expect(app.orders.first.paid, false);

    // El administrador valida el pago y avanza el estado
    final order = app.orders.first;
    app.validatePayment(order);
    app.setOrderStatus(order, OrderStatus.shipped);
    expect(order.paid, true);
    expect(order.status, OrderStatus.shipped);

    // El cliente lo ve en Mis pedidos
    await tester.tap(find.text('Ver mis pedidos'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido #${order.number}'), findsOneWidget);
    expect(find.text('Enviado'), findsWidgets);
  });

  testWidgets('El administrador valida el pago y cambia el estado desde el panel', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    // El estado es global: se limpia la sesión del test anterior
    app.logout();
    app.goTab(0);
    final order = Order(
      number: 2000, date: DateTime(2026, 10, 1), items: [CartItem(app.products[0], app.products[0].colors[0], 'M', 1)],
      subtotal: 149900, shipping: 9900, address: 'Calle 1', status: OrderStatus.confirmed, customer: 'Ana', email: 'ana@correo.com', receipt: 'foto.jpg',
    );
    app.orders.insert(0, order);

    await tester.pumpWidget(const WearUpApp());
    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@wearup.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Productos'), findsWidgets);

    // Abre el menú y entra a Pedidos
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedidos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedido #2000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validar pago'));
    await tester.pumpAndSettle();
    expect(order.paid, true);
    await tester.tap(find.text('Marcar como en preparación'));
    await tester.pumpAndSettle();
    expect(order.status, OrderStatus.preparing);
  });
}
