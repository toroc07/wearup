import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account.dart';
import 'config.dart';
import 'shop.dart';
import 'state.dart';
import 'supabase_backend.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  app = AppState(SupabaseBackend());
  runApp(const WearUpApp());
  // Carga catálogo, sesión y pedidos; mientras tanto se muestra un indicador
  app.init();
}

// App principal: tema y pantalla de inicio
class WearUpApp extends StatelessWidget {
  const WearUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WearUp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainShell(),
    );
  }
}

// Contenedor con la barra de navegación inferior (Inicio, Catálogo, Pedidos, Cuenta)
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (app.products.isEmpty && (app.loading || app.loadError != null)) return const _StartupScreen();
        return ValueListenableBuilder<int>(
          valueListenable: app.tab,
          builder: (context, index, _) => Scaffold(
            // IndexedStack conserva el estado de cada pestaña
            body: IndexedStack(index: index, children: const [HomeScreen(), CatalogScreen(), OrdersTab(), AccountTab()]),
            bottomNavigationBar: _BottomNav(index: index),
          ),
        );
      },
    );
  }
}

// Pantalla de carga o de error de conexión al abrir la app
class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    final error = app.loadError;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/logo.png', height: 90),
            const SizedBox(height: 24),
            if (error == null)
              const CircularProgressIndicator()
            else ...[
              const Icon(Icons.wifi_off_rounded, size: 40, color: kMuted),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: kNavy, fontSize: 15)),
              const SizedBox(height: 20),
              FilledButton(onPressed: app.init, child: const Text('Reintentar')),
            ],
          ]),
        ),
      ),
    );
  }
}

// Barra inferior: la pestaña activa lleva una línea azul arriba
class _BottomNav extends StatelessWidget {
  final int index;
  const _BottomNav({required this.index});

  static const _items = [
    ('Inicio', Icons.home_outlined, Icons.home_filled),
    ('Catálogo', Icons.grid_view_outlined, Icons.grid_view_rounded),
    ('Pedidos', Icons.inventory_2_outlined, Icons.inventory_2),
    ('Cuenta', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kBorder))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => app.goTab(i),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(height: 3, color: i == index ? kBlue : Colors.transparent),
                  const SizedBox(height: 9),
                  Icon(i == index ? _items[i].$3 : _items[i].$2, color: i == index ? kBlue : kMuted, size: 26),
                  const SizedBox(height: 3),
                  Text(_items[i].$1,
                      style: TextStyle(fontSize: 12, fontWeight: i == index ? FontWeight.w800 : FontWeight.w500, color: i == index ? kBlue : kMuted)),
                  const SizedBox(height: 9),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
