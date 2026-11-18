// Prueba contra el proyecto Supabase real (no se ejecuta con `flutter test` normal).
//
//   flutter test test/live --dart-define=LIVE=true
//
// Crea una cuenta de prueba, sube un comprobante de 1 píxel, comprueba que el
// servidor rechaza un pedido sin stock y que un cliente no puede tocar el
// inventario, y al final elimina la cuenta. No crea pedidos ni cambia el stock.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wearup/config.dart';
import 'package:wearup/state.dart';
import 'package:wearup/supabase_backend.dart';

import '../fake_backend.dart' show fakeReceipt;

const live = bool.fromEnvironment('LIVE');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!live) return;
    // flutter_test bloquea la red por defecto; esta prueba sí necesita internet
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  });

  test('backend real: catálogo, registro, comprobante, permisos y borrado de cuenta', () async {
    final b = SupabaseBackend();

    // Catálogo público
    final catalog = await b.loadCatalog();
    expect(catalog.categories.map((c) => c.name), ['Ropa', 'Jeans', 'Zapatos', 'Accesorios']);
    expect(catalog.products.first.name, 'Chaqueta denim');
    expect(catalog.products.fold<int>(0, (s, p) => s + p.variants.length), greaterThanOrEqualTo(54));
    expect(catalog.settings.breBKey, isNotEmpty);
    final jacket = catalog.products.first;
    expect(jacket.sizes, ['S', 'M', 'L', 'XL']);

    // Invitado: la base le niega los pedidos
    await expectLater(b.loadOrders(), throwsA(isA<BackendException>()));

    // Registro
    final email = 'prueba.${DateTime.now().millisecondsSinceEpoch}@wearup-pruebas.com';
    final profile = await b.signUp(email: email, password: 'clave-prueba-123', fullName: 'Prueba Automática', phone: '3000000000', dataConsent: true);
    expect(profile.fullName, 'Prueba Automática');
    expect(profile.isAdmin, isFalse);
    expect((await b.currentProfile())!.email, email);

    try {
      // Cliente nuevo: sin pedidos, y no ve los de ejemplo
      expect(await b.loadOrders(), isEmpty);

      // Comprobante en su carpeta privada
      final receipt = await b.uploadReceipt(fakeReceipt());
      expect(receipt, startsWith('${profile.id}/'));
      expect(await b.receiptUrl(receipt), contains('token='));

      // El servidor rechaza pedir más que el stock (no se crea pedido)
      final v = jacket.variants.first;
      await expectLater(
        b.placeOrder(
          items: [CartItem(jacket, v, v.stock + 1)],
          shipping: const ShippingInfo(customerName: 'Prueba', phone: '3000000000', address: 'Calle 1', city: 'Bogotá', department: 'Cundinamarca'),
          receiptPath: receipt,
        ),
        throwsA(isA<BackendException>().having((e) => e.message, 'mensaje', serverErrors['STOCK_INSUFICIENTE'])),
      );
      expect(await b.loadOrders(), isEmpty);

      // Un cliente no puede cambiar inventario ni configuración
      await expectLater(b.setVariantStock(v.id, 999), throwsA(isA<BackendException>()));
      await expectLater(b.saveSettings(catalog.settings.copyWith(promoPercent: 50)), throwsA(isA<BackendException>()));
      final again = await b.loadCatalog();
      expect(again.products.first.variants.first.stock, v.stock);
      expect(again.settings.promoPercent, catalog.settings.promoPercent);

      // Editar su perfil
      final updated = await b.updateProfile(fullName: 'Prueba Editada', phone: '3111111111');
      expect(updated.fullName, 'Prueba Editada');
    } finally {
      // Limpieza: elimina la cuenta de prueba
      await b.deleteMyAccount();
    }
    expect(await b.currentProfile(), isNull);
  }, skip: live ? false : 'Prueba en vivo: usa --dart-define=LIVE=true', timeout: const Timeout(Duration(minutes: 2)));
}
