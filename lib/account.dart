import 'package:flutter/material.dart';

import 'admin.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

// Formulario de ingreso / registro (se usa en la pestaña Cuenta y al comprar)
class AuthForm extends StatefulWidget {
  // Se llama cuando el usuario ya inició sesión
  final VoidCallback onDone;
  // Se llama si elige continuar como invitado
  final VoidCallback onGuest;
  const AuthForm({super.key, required this.onDone, required this.onGuest});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _register = false;
  bool _showPass = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Valida el formulario e inicia sesión (simulado, sin servidor)
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    app.login(_emailCtrl.text.trim());
    widget.onDone();
  }

  Widget _tab(String label, bool selected) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _register = label == 'Crear cuenta'),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? kNavy : kMuted)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      // Cabecera con el logo
      Container(
        color: const Color(0xFFE3EDF8),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Logo(height: 90),
          SizedBox(height: 12),
          Text('Ingresa para comprar y seguir tus pedidos.', style: TextStyle(color: kNavy, fontSize: 15)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Selector Ingresar / Crear cuenta
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE3EDF8), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [_tab('Ingresar', !_register), _tab('Crear cuenta', _register)]),
            ),
            const SizedBox(height: 20),
            if (_register) LabeledField(label: 'Nombre', hint: 'Tu nombre', controller: _nameCtrl),
            LabeledField(
              label: 'Correo electrónico',
              hint: 'tucorreo@ejemplo.com',
              controller: _emailCtrl,
              keyboard: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Ingresa un correo válido' : null,
            ),
            Text('Contraseña', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kNavy)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: !_showPass,
              decoration: InputDecoration(
                hintText: 'Tu contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Te enviaremos un enlace para restablecer tu contraseña')),
                  ),
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              )
            else
              const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: Text(_register ? 'Crear cuenta' : 'Ingresar')),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onGuest,
                child: const Text('Continuar como invitado', style: TextStyle(color: kNavy, fontWeight: FontWeight.w800)),
              ),
            ),
            const Center(
              child: Text('Como invitado puedes explorar el catálogo. Para comprar necesitas una cuenta.',
                  textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12)),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// Pantalla de login que se abre desde el carrito; devuelve true si inició sesión
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: AuthForm(
        onDone: () => Navigator.of(context).pop(true),
        onGuest: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

// Pestaña Cuenta: login si no hay sesión, perfil si ya la hay
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (!app.loggedIn) {
          return Scaffold(
            body: SafeArea(
              child: AuthForm(
                onDone: () {
                  // Si es administrador, entra directo al panel
                  if (app.isAdmin) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
                  }
                },
                onGuest: () => app.goTab(0),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Mi cuenta'), automaticallyImplyLeading: false, actions: const [CartButton()]),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card2(
              child: Row(children: [
                const CircleAvatar(radius: 28, backgroundColor: Color(0xFFDCEBF8), child: Icon(Icons.person, color: kBlue, size: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.userEmail!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                    Text(app.isAdmin ? 'Administrador' : 'Cliente', style: const TextStyle(color: kMuted)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (app.isAdmin) ...[
              _tile(Icons.dashboard_outlined, 'Panel de administración',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()))),
              const SizedBox(height: 8),
            ],
            _tile(Icons.inventory_2_outlined, 'Mis pedidos', () => app.goTab(2)),
            const SizedBox(height: 8),
            _tile(Icons.logout, 'Cerrar sesión', app.logout),
          ]),
        );
      },
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => Card2(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: kNavy),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy))),
          const Icon(Icons.chevron_right, color: kMuted),
        ]),
      );
}

// ---------------------------------------------------------------- Pedidos

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _filter = 'Todos';

  Widget _chip(String label) {
    final selected = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = label),
        selectedColor: kBlue,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? kBlue : kBorder),
        labelStyle: TextStyle(color: selected ? Colors.white : kNavy, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        // Sin sesión no hay pedidos que mostrar
        if (!app.loggedIn) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mis pedidos'), automaticallyImplyLeading: false),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inventory_2_outlined, size: 56, color: kMuted),
                  const SizedBox(height: 12),
                  const Text('Ingresa para ver tus pedidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: () => app.goTab(3), child: const Text('Ingresar')),
                ]),
              ),
            ),
          );
        }
        // Filtra por estado
        final list = app.myOrders.where((o) {
          if (_filter == 'En curso') return o.status != OrderStatus.delivered;
          if (_filter == 'Entregados') return o.status == OrderStatus.delivered;
          return true;
        }).toList();
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            title: const Text('Mis pedidos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            actions: const [CartButton()],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [_chip('Todos'), _chip('En curso'), _chip('Entregados')]),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No hay pedidos en esta categoría.', style: TextStyle(color: kMuted)))),
            for (final o in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card2(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrackingScreen(order: o))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Pedido #${o.number}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy)),
                      StatusChip(o.status),
                    ]),
                    const SizedBox(height: 6),
                    Text('${fmtDate(o.date)} · ${o.items.length} productos', style: const TextStyle(color: kMuted)),
                    const SizedBox(height: 10),
                    Row(children: [
                      for (final i in o.items.take(3))
                        Container(margin: const EdgeInsets.only(right: 8), width: 50, height: 50, child: PhotoPlaceholder(tint: i.product.tint, radius: 8, iconSize: 20)),
                      const Spacer(),
                      Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy)),
                      const Icon(Icons.chevron_right, color: kNavy),
                    ]),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Seguimiento

class TrackingScreen extends StatelessWidget {
  final Order order;
  const TrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final o = order;
        const names = ['Confirmado', 'En preparación', 'Enviado', 'Entregado'];
        const hints = ['Recibimos tu pago', 'Estamos alistando tu pedido', 'Tu pedido va en camino', 'Pedido entregado'];
        return Scaffold(
          appBar: AppBar(title: const Text('Seguimiento')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card2(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pedido #${o.number}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kNavy)),
                  Text('${fmtDate(o.date)} · ${o.items.length} productos', style: const TextStyle(color: kMuted)),
                ]),
                StatusChip(o.status),
              ]),
            ),
            const SizedBox(height: 12),
            // Línea de tiempo del pedido
            Card2(
              child: Column(children: [
                for (var i = 0; i < names.length; i++)
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Column(children: [
                        _dot(i, o.status.index),
                        if (i < names.length - 1) Expanded(child: Container(width: 2, color: i < o.status.index ? kTeal : kBorder)),
                      ]),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(names[i],
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: i <= o.status.index ? kNavy : kMuted)),
                            Text(i <= o.status.index ? (i == 0 ? '${fmtDate(o.date)} · ${hints[i]}' : hints[i]) : 'Pendiente',
                                style: const TextStyle(color: kMuted)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            Card2(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined, color: kNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Dirección de envío', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                    Text(o.address, style: const TextStyle(color: kMuted)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Resumen de productos
            Card2(
              child: Column(children: [
                for (final i in o.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 50, height: 50, child: PhotoPlaceholder(tint: i.product.tint, radius: 8, iconSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.product.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                          Text('${i.color.name} · Talla ${i.size}', style: const TextStyle(color: kMuted, fontSize: 12)),
                        ]),
                      ),
                      Text(fmtPrice(i.total), style: const TextStyle(color: kNavy)),
                    ]),
                  ),
                const Divider(color: kBorder),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy)),
                  Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy)),
                ]),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _dot(int i, int current) {
    if (i < current) {
      return const CircleAvatar(radius: 12, backgroundColor: kTeal, child: Icon(Icons.check, size: 14, color: kNavy));
    }
    if (i == current) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: kBlue, width: 2)),
        child: const Center(child: CircleAvatar(radius: 5, backgroundColor: kBlue)),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: kBorder, width: 2)),
    );
  }
}
