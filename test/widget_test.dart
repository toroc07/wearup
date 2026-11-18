import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wearup/main.dart';
import 'package:wearup/state.dart';
import 'package:wearup/widgets.dart' as widgets;

import 'fake_backend.dart';

void main() {
  late FakeBackend server;

  // Carga la fuente real para que las medidas del test sean las de la app
  setUpAll(() async {
    final loader = FontLoader('Montserrat')..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
    await loader.load();
  });

  setUp(() async {
    server = FakeBackend();
    app = AppState(server);
    await app.init();
    // En lugar de abrir la galería, se adjunta una imagen fija
    widgets.pickImage = (_) async => fakeReceipt();
  });

  Future<void> start(WidgetTester tester, {double width = 1000}) async {
    tester.view.physicalSize = Size(width, 2000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const WearUpApp());
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
  }

  testWidgets('Compra completa: talla y color, envío, comprobante y seguimiento', (tester) async {
    server.addUser('cliente@correo.com', 'clave123', fullName: 'Ana Pérez', phone: '3001234567');
    await start(tester);
    expect(find.text('VISTE TU ESTILO'), findsOneWidget);

    // Catálogo -> "Agregar al carrito" pide elegir talla y color (RF-004)
    await tester.tap(find.text('Catálogo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar al carrito').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar al carrito').last);
    await tester.pumpAndSettle();
    expect(app.cartCount, 1);
    expect(app.cart.single.variant.size, 'L');

    // Carrito -> pide iniciar sesión
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await login(tester, 'cliente@correo.com');

    // Envío: nombre y teléfono vienen del perfil
    final fields = find.byType(TextFormField);
    expect(find.text('Ana Pérez'), findsOneWidget);
    await tester.enterText(fields.at(2), 'Calle 1 # 2-3');
    await tester.enterText(fields.at(3), 'Cartagena');
    await tester.enterText(fields.at(4), 'Bolívar');
    await tester.tap(find.text('Continuar al pago'));
    await tester.pumpAndSettle();
    expect(find.text('300 123 4567'), findsOneWidget);
    await tester.tap(find.text('Ya transferí, continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sube una foto del comprobante'));
    await tester.pumpAndSettle();
    expect(find.text('Comprobante adjunto'), findsOneWidget);
    await tester.tap(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();

    expect(find.text('Compra confirmada'), findsOneWidget);
    expect(server.orders.single['customer_name'], 'Ana Pérez');
    expect(server.orders.single['paid'], false);
    expect(server.variantRow('p1-Azul-L')['stock'], 2);

    // El cliente ve el pedido y su seguimiento
    await tester.tap(find.text('Ver mis pedidos'));
    await tester.pumpAndSettle();
    expect(find.text('Pedido #1032'), findsOneWidget);
    await tester.tap(find.text('Pedido #1032'));
    await tester.pumpAndSettle();
    expect(find.text('Seguimiento'), findsOneWidget);
    expect(find.textContaining('Estamos validando tu pago'), findsOneWidget);
  });

  testWidgets('El registro exige autorizar el tratamiento de datos', (tester) async {
    await start(tester);
    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta').first);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Luis Gómez');
    await tester.enterText(fields.at(1), '3109876543');
    await tester.enterText(fields.at(2), 'luis@correo.com');
    await tester.enterText(fields.at(3), 'clave123');
    final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Debes aceptar para crear la cuenta'), findsOneWidget);
    expect(app.loggedIn, isFalse);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(app.loggedIn, isTrue);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('El catálogo filtra por disponibilidad', (tester) async {
    // Pantalla ancha para que se vean todos los filtros sin desplazar
    await start(tester, width: 3000);
    await tester.tap(find.text('Catálogo'));
    await tester.pumpAndSettle();
    expect(find.text('3 productos'), findsOneWidget);
    await tester.tap(find.text('Disponibilidad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agotados').last);
    await tester.pumpAndSettle();
    expect(find.text('1 productos'), findsOneWidget);
    expect(find.text('Bolso de mano'), findsOneWidget);
  });

  testWidgets('El administrador valida el pago y cambia el estado desde el panel', (tester) async {
    // Pedido de un cliente con su comprobante
    server.addUser('ana@correo.com', 'clave123');
    await app.signIn('ana@correo.com', 'clave123');
    app.addToCart(app.productById('p1')!, app.productById('p1')!.variant('Azul', 'M')!, 1);
    final order = await app.placeOrder(
      shippingInfo: const ShippingInfo(customerName: 'Ana', phone: '3001234567', address: 'Calle 1', city: 'Cali', department: 'Valle'),
      receipt: fakeReceipt(),
    );
    await app.signOut();

    await start(tester);
    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    await login(tester, 'admin@wearup.com');
    expect(find.text('Productos'), findsWidgets);

    // Abre el menú y entra a Pedidos
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedidos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedido #${order.number}'));
    await tester.pumpAndSettle();
    expect(find.text('Ver comprobante'), findsOneWidget);
    await tester.tap(find.text('Validar pago'));
    await tester.pumpAndSettle();
    expect(server.orders.single['paid'], true);
    await tester.tap(find.text('Marcar como en preparación'));
    await tester.pumpAndSettle();
    expect(server.orders.single['status'], 'preparing');
  });
}
