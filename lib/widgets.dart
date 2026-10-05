import 'package:flutter/material.dart';

import 'checkout.dart';
import 'state.dart';
import 'theme.dart';

// Logo de WearUp (imagen en assets/logo.png)
class Logo extends StatelessWidget {
  final double height;
  const Logo({super.key, this.height = 44});

  @override
  Widget build(BuildContext context) => Image.asset('assets/logo.png', height: height, fit: BoxFit.contain);
}

// Recuadro que reemplaza las fotos mientras no hay imágenes
class PhotoPlaceholder extends StatelessWidget {
  final String? label;
  final Color tint;
  final double radius;
  final double iconSize;
  const PhotoPlaceholder({super.key, this.label, this.tint = const Color(0xFFD3E2F0), this.radius = 12, this.iconSize = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_outlined, size: iconSize, color: kNavy.withValues(alpha: .6)),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: kNavy.withValues(alpha: .6))),
        ],
      ]),
    );
  }
}

/// Icono del carrito con insignia de cantidad.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => IconButton(
        tooltip: 'Carrito',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
        icon: Badge(
          isLabelVisible: app.cartCount > 0,
          label: Text('${app.cartCount}'),
          backgroundColor: kBlue,
          child: const Icon(Icons.shopping_bag_outlined, size: 26),
        ),
      ),
    );
  }
}

// Texto con icono según la disponibilidad
class StockLabel extends StatelessWidget {
  final Stock status;
  const StockLabel(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (status) {
      Stock.available => (Icons.check, 'Disponible', kGreen),
      Stock.low => (Icons.warning_amber_rounded, 'Últimas unidades', kAmber),
      Stock.out => (Icons.remove_circle_outline, 'Agotado', kMuted),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}

// Etiqueta con el estado de un pedido
class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg, border) = switch (status) {
      OrderStatus.confirmed => (Icons.check, Colors.white, kNavy, kBorder),
      OrderStatus.preparing => (Icons.schedule, const Color(0xFFDCEBF8), kBlue, const Color(0xFFDCEBF8)),
      OrderStatus.shipped => (Icons.local_shipping_outlined, kBlue, Colors.white, kBlue),
      OrderStatus.delivered => (Icons.check, const Color(0xFFD7F0E0), kGreen, const Color(0xFFD7F0E0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        Text(status.label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// Tarjeta blanca con borde, reutilizada en toda la app
class Card2 extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Card2({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// Campo de texto con su etiqueta y validación
class LabeledField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final bool obscure, optional;
  final String? Function(String?)? validator;
  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboard,
    this.obscure = false,
    this.optional = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kNavy)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint),
        validator: validator ?? (optional ? null : (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null),
      ),
      const SizedBox(height: 14),
    ]);
  }
}

// Selector de cantidad con botones - y +
class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;
  const QtyStepper({super.key, required this.value, required this.onChanged, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final h = compact ? 44.0 : 50.0;
    Widget btn(IconData i, VoidCallback f) => InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: h, height: h, child: Icon(i, size: 20, color: kNavy)),
        );
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove, () => onChanged(value - 1)),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        btn(Icons.add, () => onChanged(value + 1)),
      ]),
    );
  }
}

// Subtotal, envío y total del carrito
class SummaryRows extends StatelessWidget {
  const SummaryRows({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l, style: TextStyle(color: bold ? kNavy : kMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 18 : 14)),
            Text(v, style: TextStyle(color: kNavy, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 14)),
          ]),
        );
    return Card2(
      child: Column(children: [
        row('Subtotal (${app.cart.length} productos)', fmtPrice(app.subtotal)),
        row('Envío', fmtPrice(app.shipping)),
        const Divider(color: kBorder),
        row('Total', fmtPrice(app.total), bold: true),
      ]),
    );
  }
}

/// Barra inferior fija con contenido y botón principal.
class BottomBar extends StatelessWidget {
  final Widget child;
  const BottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kBorder))),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}
