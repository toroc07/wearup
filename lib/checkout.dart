import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

const _steps = ['Carrito', 'Envío', 'Pago', 'Comprobante', 'Confirmación'];
const _breKey = '300 123 4567';

/// Flujo de compra de 5 pasos: carrito, envío, pago, comprobante y confirmación.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Paso actual (0 a 4) y controladores del formulario de envío
  int _step = 0;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _dept = TextEditingController();
  final _notes = TextEditingController();
  String? _receipt;
  Order? _order;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _city, _dept, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _title => const ['Carrito', 'Envío', 'Pago', 'Comprobante', ''][_step];

  void _back() {
    if (_step == 0 || _step == 4) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  // Para comprar hay que haber iniciado sesión
  Future<void> _continueFromCart() async {
    if (!app.loggedIn) {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true || !mounted) return;
    }
    setState(() => _step = 1);
  }

  // Valida el formulario de envío antes de pasar al pago
  void _continueFromShipping() {
    if (_form.currentState!.validate()) setState(() => _step = 2);
  }

  // Crea el pedido y pasa a la confirmación
  void _sendReceipt() {
    final address = '${_address.text.trim()}, ${_city.text.trim()}, ${_dept.text.trim()}';
    setState(() {
      _order = app.placeOrder(address: address, customer: _name.text.trim(), phone: _phone.text.trim(), receipt: _receipt!);
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 || _step == 4,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: _back),
            title: _step == 4 ? const Logo() : Text(_title),
          ),
          body: Column(children: [
            Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(8, 10, 8, 12), child: _Stepper(current: _step)),
            const Divider(height: 1, color: kBorder),
            Expanded(child: _body()),
          ]),
          bottomNavigationBar: _bottom(),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _cartStep();
      case 1:
        return _shippingStep();
      case 2:
        return _paymentStep();
      case 3:
        return _receiptStep();
      default:
        return _confirmStep();
    }
  }

  Widget? _bottom() {
    switch (_step) {
      case 0:
        if (app.cart.isEmpty) return null;
        return BottomBar(child: FilledButton(onPressed: _continueFromCart, child: const Text('Continuar')));
      case 1:
        return BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _totalRow(),
            const SizedBox(height: 10),
            FilledButton(onPressed: _continueFromShipping, child: const Text('Continuar al pago')),
          ]),
        );
      case 2:
        return BottomBar(child: FilledButton(onPressed: () => setState(() => _step = 3), child: const Text('Ya transferí, continuar')));
      case 3:
        return BottomBar(child: FilledButton(onPressed: _receipt == null ? null : _sendReceipt, child: const Text('Enviar comprobante')));
      default:
        return BottomBar(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton(
              onPressed: () {
                app.goTab(2);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Ver mis pedidos'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                app.goTab(1);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Seguir comprando'),
            ),
          ]),
        );
    }
  }

  Widget _totalRow() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total', style: TextStyle(color: kMuted)),
        Text(fmtPrice(app.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
      ]);

  // Paso 1
  Widget _cartStep() {
    if (app.cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_bag_outlined, size: 56, color: kMuted),
            const SizedBox(height: 12),
            const Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                app.goTab(1);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Ir al catálogo'),
            ),
          ]),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final i in List.of(app.cart))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card2(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 88, height: 112, child: PhotoPlaceholder(tint: i.product.tint, iconSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(i.product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy))),
                    InkWell(onTap: () => app.removeItem(i), child: const Icon(Icons.delete_outline, color: kRed)),
                  ]),
                  Text('${i.color.name} · Talla ${i.size}', style: const TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    QtyStepper(value: i.qty, compact: true, onChanged: (v) => app.setQty(i, v)),
                    Text(fmtPrice(i.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      const SummaryRows(),
    ]);
  }

  // Paso 2
  Widget _shippingStep() {
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Dirección de envío', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 14),
        LabeledField(label: 'Nombre completo', hint: 'Nombre y apellido', controller: _name),
        LabeledField(
          label: 'Teléfono de contacto',
          hint: 'Número de celular',
          controller: _phone,
          keyboard: TextInputType.phone,
          validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 7) ? 'Ingresa un teléfono válido' : null,
        ),
        LabeledField(label: 'Dirección de entrega', hint: 'Calle, número y complemento', controller: _address, validator: req),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: LabeledField(label: 'Ciudad', hint: 'Ciudad', controller: _city)),
          const SizedBox(width: 12),
          Expanded(child: LabeledField(label: 'Departamento', hint: 'Departamento', controller: _dept)),
        ]),
        LabeledField(label: 'Indicaciones adicionales (opcional)', hint: 'Torre, apartamento, referencias', controller: _notes, optional: true),
      ]),
    );
  }

  // Paso 3
  Widget _paymentStep() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Método de pago', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kNavy)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBlue, width: 2)),
        child: const Row(children: [
          CircleAvatar(backgroundColor: Color(0xFFEAF2FB), child: Icon(Icons.vpn_key_outlined, color: kBlue)),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pagar por llave (BRE-B)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
              Text('Transferencia inmediata entre bancos', style: TextStyle(color: kMuted, fontSize: 13)),
            ]),
          ),
          Icon(Icons.check_circle, color: kBlue, size: 26),
        ]),
      ),
      const SizedBox(height: 10),
      Card2(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Llave BRE-B', style: TextStyle(color: kMuted)),
          Row(children: [
            const Text(_breKey, style: TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 16)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '3001234567'));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Llave copiada')));
              },
              child: const Icon(Icons.copy, size: 18, color: kBlue),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      const Card2(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline, color: kNavy),
          SizedBox(width: 12),
          Expanded(
            child: Text('Transfiere el total a la llave BRE-B de WearUp desde tu app bancaria. Luego sube el comprobante para validar tu pago.',
                style: TextStyle(height: 1.35)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      const SummaryRows(),
    ]);
  }

  // Paso 4: subir el comprobante
  Widget _receiptStep() {
    Widget row(String l, String v, {bool big = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l, style: const TextStyle(color: kMuted)),
            Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: big ? 20 : 16)),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Sube tu comprobante', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kNavy)),
      const SizedBox(height: 6),
      const Text('Transfiere el total a la llave BRE-B y adjunta una foto o captura del comprobante para validar tu pago.',
          style: TextStyle(color: kMuted, height: 1.35)),
      const SizedBox(height: 14),
      Card2(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          row('Llave BRE-B', _breKey),
          const Divider(height: 1, color: kBorder),
          row('Beneficiario', 'WearUp SAS'),
          const Divider(height: 1, color: kBorder),
          row('Monto a transferir', fmtPrice(app.total), big: true),
        ]),
      ),
      const SizedBox(height: 16),
      InkWell(
        borderRadius: BorderRadius.circular(16),
        // Simulación del selector de archivos de galería/cámara.
        onTap: () => setState(() => _receipt = 'comprobante_${DateTime.now().millisecondsSinceEpoch % 100000}.jpg'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _receipt == null ? kBlue.withValues(alpha: .6) : kGreen, width: 1.5),
          ),
          child: Column(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _receipt == null ? const Color(0xFFEAF2FB) : const Color(0xFFD7F0E0),
              child: Icon(_receipt == null ? Icons.cloud_upload_outlined : Icons.check, color: _receipt == null ? kBlue : kGreen, size: 28),
            ),
            const SizedBox(height: 12),
            Text(_receipt == null ? 'Sube una foto del comprobante' : 'Comprobante adjunto',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 4),
            Text(_receipt ?? 'Toca para elegir desde tu galería o tomar una foto',
                textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 13)),
            if (_receipt != null) ...[
              const SizedBox(height: 4),
              const Text('Toca para cambiarlo', style: TextStyle(color: kBlue, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: Text('Formatos JPG o PNG · Máx. 10 MB', style: TextStyle(color: kMuted, fontSize: 12))),
    ]);
  }

  // Paso 5
  Widget _confirmStep() {
    final o = _order!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 16),
      const Center(child: CircleAvatar(radius: 45, backgroundColor: kTeal, child: Icon(Icons.check, color: kNavy, size: 48))),
      const SizedBox(height: 20),
      const Center(child: Text('Compra confirmada', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kNavy))),
      const SizedBox(height: 8),
      const Text('Te avisaremos en la app cada vez que cambie el estado de tu pedido.',
          textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 15, height: 1.35)),
      const SizedBox(height: 20),
      Card2(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pedido', style: TextStyle(color: kMuted)),
            Text('#${o.number}', style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total pagado', style: TextStyle(color: kMuted)),
            Text(fmtPrice(o.total), style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Estado', style: TextStyle(color: kMuted)),
            StatusChip(o.status),
          ]),
        ]),
      ),
    ]);
  }
}

// Indicador de los 5 pasos de la compra
class _Stepper extends StatelessWidget {
  final int current;
  const _Stepper({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _steps.length; i++)
        Expanded(
          child: Column(children: [
            Row(children: [
              Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= current ? kTeal : kBorder))),
              _dot(i),
              Expanded(child: Container(height: 2, color: i == _steps.length - 1 ? Colors.transparent : (i < current ? kTeal : kBorder))),
            ]),
            const SizedBox(height: 4),
            Text(_steps[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: i == current ? FontWeight.w800 : FontWeight.w500, color: i == current ? kNavy : kMuted)),
          ]),
        ),
    ]);
  }

  Widget _dot(int i) {
    final done = i < current || current == _steps.length - 1;
    final active = i == current && !done;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? kTeal : Colors.white,
        border: Border.all(color: done ? kTeal : (active ? kBlue : kBorder), width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: kNavy)
          : Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? kBlue : kMuted)),
    );
  }
}
