import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'admin.dart';
import 'legal.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

void _openPrivacy(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));

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
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _register = false;
  bool _showPass = false;
  bool _consent = false;
  bool _consentError = false;
  bool _busy = false;
  late final _privacyTap = TapGestureRecognizer()..onTap = () => _openPrivacy(context);

  @override
  void dispose() {
    _privacyTap.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Ingresa o crea la cuenta en el servidor
  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (_register && !_consent) setState(() => _consentError = true);
    if (!valid || (_register && !_consent)) return;
    setState(() => _busy = true);
    final ok = await runAction(context, () async {
      final email = _emailCtrl.text.trim();
      if (_register) {
        await app.signUp(
          email: email,
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          dataConsent: _consent,
        );
      } else {
        await app.signIn(email, _passCtrl.text);
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onDone();
  }

  Widget _tab(String label, bool selected) => Expanded(
        child: GestureDetector(
          onTap: _busy ? null : () => setState(() => _register = label == 'Crear cuenta'),
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
            if (_register) ...[
              LabeledField(label: 'Nombre completo', hint: 'Nombre y apellido', controller: _nameCtrl),
              LabeledField(label: 'Teléfono', hint: 'Número de celular', controller: _phoneCtrl, keyboard: TextInputType.phone, validator: validatePhone),
            ],
            LabeledField(
              label: 'Correo electrónico',
              hint: 'tucorreo@ejemplo.com',
              controller: _emailCtrl,
              keyboard: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kNavy)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: !_showPass,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Tu contraseña',
                suffixIcon: IconButton(
                  tooltip: _showPass ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
              validator: validatePassword,
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => showDialog<void>(context: context, builder: (_) => _PasswordResetDialog(initialEmail: _emailCtrl.text.trim())),
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              // Autorización de tratamiento de datos (Ley 1581 de 2012)
              CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() {
                  _consent = v ?? false;
                  _consentError = false;
                }),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text.rich(TextSpan(style: const TextStyle(fontSize: 13, color: kNavy), children: [
                  const TextSpan(text: 'Autorizo el tratamiento de mis datos personales según la '),
                  TextSpan(
                    text: 'política de privacidad',
                    style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                    recognizer: _privacyTap,
                  ),
                  const TextSpan(text: '.'),
                ])),
                subtitle: _consentError
                    ? const Text('Debes aceptar para crear la cuenta', style: TextStyle(color: kRed, fontSize: 12))
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_register ? 'Crear cuenta' : 'Ingresar'),
            ),
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

// Recuperar contraseña: se envía un código al correo y con él se define una nueva
class _PasswordResetDialog extends StatefulWidget {
  final String initialEmail;
  const _PasswordResetDialog({required this.initialEmail});

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_codeSent) {
        await app.sendPasswordReset(_email.text.trim());
        if (mounted) setState(() => _codeSent = true);
      } else {
        await app.confirmPasswordReset(email: _email.text.trim(), code: _code.text.trim(), newPassword: _pass.text);
        if (!mounted) return;
        Navigator.pop(context);
        showMessage(context, 'Contraseña actualizada. Ya puedes ingresar.');
      }
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _codeSent
                    ? 'Te enviamos un código a ${_email.text.trim()}. Escríbelo junto con tu nueva contraseña.'
                    : 'Escribe el correo de tu cuenta y te enviaremos un código para crear una nueva contraseña.',
                style: const TextStyle(color: kMuted, height: 1.35),
              ),
              const SizedBox(height: 14),
              if (!_codeSent)
                LabeledField(label: 'Correo electrónico', hint: 'tucorreo@ejemplo.com', controller: _email, keyboard: TextInputType.emailAddress, validator: validateEmail)
              else ...[
                LabeledField(
                  label: 'Código',
                  hint: 'Código del correo',
                  controller: _code,
                  keyboard: TextInputType.number,
                  validator: (v) => (v == null || v.trim().length < 6) ? 'Ingresa el código del correo' : null,
                ),
                LabeledField(label: 'Nueva contraseña', hint: 'Mínimo 6 caracteres', controller: _pass, obscure: true, validator: validatePassword),
              ],
              if (_error != null) Text(_error!, style: const TextStyle(color: kRed, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _busy ? null : _go,
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          child: Text(_codeSent ? 'Cambiar contraseña' : 'Enviar código'),
        ),
      ],
    );
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
        final profile = app.profile;
        if (profile == null) {
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
                    Text(profile.fullName.isEmpty ? profile.email : profile.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                    Text(profile.email, style: const TextStyle(color: kMuted, fontSize: 13)),
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
            _tile(Icons.badge_outlined, 'Mis datos', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
            const SizedBox(height: 8),
            _tile(Icons.privacy_tip_outlined, 'Política de privacidad', () => _openPrivacy(context)),
            const SizedBox(height: 8),
            _tile(Icons.logout, 'Cerrar sesión', () => runAction(context, app.signOut)),
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

// ---------------------------------------------------------------- Mis datos

// Editar nombre y teléfono, y eliminar la cuenta (derechos del titular, Ley 1581)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: app.profile?.fullName);
  late final _phone = TextEditingController(text: app.profile?.phone);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await runAction(context, () => app.updateProfile(fullName: _name.text.trim(), phone: _phone.text.trim()), success: 'Datos actualizados');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mi cuenta'),
        content: const Text('Se borrarán tu cuenta y tus datos de perfil. Los pedidos ya realizados se conservan como soporte '
            'de la venta, sin vínculo con tu cuenta. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final done = await runAction(context, app.deleteMyAccount, success: 'Tu cuenta fue eliminada');
    if (!mounted) return;
    setState(() => _busy = false);
    if (done) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Correo: ${app.profile?.email ?? ''}', style: const TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          LabeledField(label: 'Nombre completo', hint: 'Nombre y apellido', controller: _name),
          LabeledField(label: 'Teléfono', hint: 'Número de celular', controller: _phone, keyboard: TextInputType.phone, validator: validatePhone),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Guardar cambios')),
          const SizedBox(height: 32),
          const Divider(color: kBorder),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            style: OutlinedButton.styleFrom(foregroundColor: kRed, side: const BorderSide(color: kRed)),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Eliminar mi cuenta'),
          ),
        ]),
      ),
    );
  }
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
          body: RefreshIndicator(
            onRefresh: () => runAction(context, app.refresh),
            child: ListView(padding: const EdgeInsets.all(16), children: [
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
                          Container(margin: const EdgeInsets.only(right: 8), width: 50, height: 50, child: PhotoPlaceholder(tint: i.tintColor, radius: 8, iconSize: 20)),
                        const Spacer(),
                        Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy)),
                        const Icon(Icons.chevron_right, color: kNavy),
                      ]),
                    ]),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }
}

// Abre la captura del comprobante (enlace temporal firmado)
Future<void> showReceipt(BuildContext context, String path) async {
  String? url;
  final ok = await runAction(context, () async => url = await app.receiptUrl(path));
  if (!ok || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(children: [
            const Expanded(child: Text('Comprobante de pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy))),
            IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
          ]),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.network(
                url!,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null ? child : const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                errorBuilder: (_, _, _) => const Padding(padding: EdgeInsets.all(24), child: Text('No se pudo cargar la imagen.')),
              ),
            ),
          ),
        ),
      ]),
    ),
  );
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
        // Versión más reciente del pedido tras recargar
        final o = app.orders.firstWhere((x) => x.number == order.number, orElse: () => order);
        const names = ['Confirmado', 'En preparación', 'Enviado', 'Entregado'];
        final hints = [o.paid ? 'Pago validado' : 'Estamos validando tu pago', 'Estamos alistando tu pedido', 'Tu pedido va en camino', 'Pedido entregado'];
        return Scaffold(
          appBar: AppBar(title: const Text('Seguimiento')),
          body: RefreshIndicator(
            onRefresh: () => runAction(context, app.refresh),
            child: ListView(padding: const EdgeInsets.all(16), children: [
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
                      Text(o.fullAddress, style: const TextStyle(color: kMuted)),
                      if (o.notes.isNotEmpty) Text(o.notes, style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
              if (o.receiptPath != null) ...[
                const SizedBox(height: 12),
                Card2(
                  onTap: () => showReceipt(context, o.receiptPath!),
                  child: const Row(children: [
                    Icon(Icons.receipt_long_outlined, color: kNavy),
                    SizedBox(width: 12),
                    Expanded(child: Text('Ver comprobante de pago', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy))),
                    Icon(Icons.chevron_right, color: kMuted),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              // Resumen de productos
              Card2(
                child: Column(children: [
                  for (final i in o.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        SizedBox(width: 50, height: 50, child: PhotoPlaceholder(tint: i.tintColor, radius: 8, iconSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                            Text('${i.qty} x ${i.colorName} · Talla ${i.size}', style: const TextStyle(color: kMuted, fontSize: 12)),
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
          ),
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
