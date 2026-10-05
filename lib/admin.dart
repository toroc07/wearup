import 'package:flutter/material.dart';

import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

const _sections = [
  ('Panel', Icons.grid_view_outlined),
  ('Productos', Icons.sell_outlined),
  ('Inventario', Icons.list_alt_outlined),
  ('Promociones', Icons.local_offer_outlined),
  ('Pedidos', Icons.inventory_2_outlined),
];

// Panel de administración: menú lateral en pantallas anchas, cajón en móviles
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _section = 1;

  void _logout() {
    app.logout();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _menu({required bool drawer}) {
    return Container(
      color: kNavy,
      width: 240,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Logo(height: 40)),
          ),
          for (var i = 0; i < _sections.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Material(
                color: i == _section ? Colors.white.withValues(alpha: .1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  dense: true,
                  leading: Icon(_sections[i].$2, color: Colors.white70),
                  title: Text(_sections[i].$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  onTap: () {
                    setState(() => _section = i);
                    if (drawer) Navigator.pop(context);
                  },
                ),
              ),
            ),
          const Spacer(),
          const Padding(padding: EdgeInsets.fromLTRB(28, 0, 16, 4), child: Text('Administrador', style: TextStyle(color: Colors.white70, fontSize: 12))),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white70)),
            onTap: _logout,
          ),
        ]),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final content = ListenableBuilder(
      listenable: app,
      builder: (context, _) => switch (_section) {
        0 => const _Dashboard(),
        1 => const _ProductsAdmin(),
        2 => const _InventoryAdmin(),
        3 => const _PromoAdmin(),
        _ => const _OrdersAdmin(),
      },
    );
    return Scaffold(
      appBar: wide ? null : AppBar(title: Text(_sections[_section].$1)),
      drawer: wide ? null : Drawer(child: _menu(drawer: true)),
      body: wide ? Row(children: [_menu(drawer: false), Expanded(child: content)]) : content,
    );
  }
}

Widget _pageHeader(String title, String subtitle, {Widget? action}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kNavy)),
            Text(subtitle, style: const TextStyle(color: kMuted)),
          ]),
        ),
        ?action,
      ]),
    );

Widget _statCard(String label, int value) => Card2(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 6),
        Text('$value', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kNavy)),
      ]),
    );

Widget _stats() {
  final low = app.products.where((p) => p.status == Stock.low).length;
  final out = app.products.where((p) => p.status == Stock.out).length;
  final pending = app.orders.where((o) => o.status != OrderStatus.delivered).length;
  return LayoutBuilder(builder: (context, c) {
    final cols = c.maxWidth >= 700 ? 4 : 2;
    final w = (c.maxWidth - 12 * (cols - 1)) / cols;
    final cards = [
      ('Productos activos', app.products.length),
      ('Últimas unidades', low),
      ('Agotados', out),
      ('Pedidos por atender', pending),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: [
      for (final s in cards) SizedBox(width: w, child: _statCard(s.$1, s.$2)),
    ]);
  });
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Panel', 'Resumen de tu tienda.'),
      _stats(),
    ]);
  }
}

// ---------------------------------------------------------------- Productos

class _ProductsAdmin extends StatefulWidget {
  const _ProductsAdmin();

  @override
  State<_ProductsAdmin> createState() => _ProductsAdminState();
}

class _ProductsAdminState extends State<_ProductsAdmin> {
  String _query = '';
  String? _category;
  Stock? _stock;

  Future<void> _edit([Product? p]) async {
    await showDialog<void>(context: context, builder: (_) => _ProductDialog(product: p));
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true) app.deleteProduct(p);
  }

  @override
  Widget build(BuildContext context) {
    // Aplica búsqueda y filtros de la tabla
    final list = app.products.where((p) {
      if (_query.isNotEmpty && !p.name.toLowerCase().contains(_query.toLowerCase())) return false;
      if (_category != null && p.category != _category) return false;
      if (_stock != null && p.status != _stock) return false;
      return true;
    }).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader(
        'Productos',
        'Gestiona el catálogo, los precios y el inventario.',
        action: FilledButton.icon(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo producto'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
        ),
      ),
      _stats(),
      const SizedBox(height: 16),
      Card2(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 280,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(hintText: 'Buscar producto', prefixIcon: Icon(Icons.search), isDense: true),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(isDense: true, hintText: 'Categoría'),
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<Stock?>(
                  isExpanded: true,
                  initialValue: _stock,
                  decoration: const InputDecoration(isDense: true),
                  hint: const Text('Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: Stock.available, child: Text('Disponible')),
                    DropdownMenuItem(value: Stock.low, child: Text('Últimas unidades')),
                    DropdownMenuItem(value: Stock.out, child: Text('Agotado')),
                  ],
                  onChanged: (v) => setState(() => _stock = v),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: kBorder),
          // Tabla con scroll horizontal para pantallas angostas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 760),
              child: DataTable(
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 1),
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('PRODUCTO')),
                  DataColumn(label: Text('CATEGORÍA')),
                  DataColumn(label: Text('PRECIO'), numeric: true),
                  DataColumn(label: Text('STOCK'), numeric: true),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: [
                  for (final p in list)
                    DataRow(cells: [
                      DataCell(Row(children: [
                        SizedBox(width: 44, height: 44, child: PhotoPlaceholder(tint: p.tint, radius: 8, iconSize: 20)),
                        const SizedBox(width: 12),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                      ])),
                      DataCell(Text(p.category)),
                      DataCell(Text(fmtPrice(p.price))),
                      DataCell(Text('${p.stock}')),
                      DataCell(StockLabel(p.status)),
                      DataCell(Row(children: [
                        TextButton(
                          onPressed: () => _edit(p),
                          child: const Text('Editar', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                        ),
                        TextButton.icon(
                          onPressed: () => _delete(p),
                          icon: const Icon(Icons.delete_outline, size: 18, color: kRed),
                          label: const Text('Eliminar', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
                        ),
                      ])),
                    ]),
                ],
              ),
            ),
          ),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Sin resultados', style: TextStyle(color: kMuted))),
        ]),
      ),
    ]);
  }
}

// Formulario para crear o editar un producto
class _ProductDialog extends StatefulWidget {
  final Product? product;
  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(text: widget.product?.price.toString());
  late final _stock = TextEditingController(text: widget.product?.stock.toString());
  late final _desc = TextEditingController(text: widget.product?.description);
  late String _category = widget.product?.category ?? kCategories.first;

  String? _number(String? v) => (v == null || int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0) ? 'Número inválido' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final p = widget.product ??
        Product(
          id: app.newProductId(),
          name: '',
          category: _category,
          price: 0,
          stock: 0,
          colors: const [ProductColor('Negro', Color(0xFF1A2433)), ProductColor('Azul', Color(0xFF3B5B8F))],
        );
    p
      ..name = _name.text.trim()
      ..category = _category
      ..price = int.parse(_price.text.trim())
      ..stock = int.parse(_stock.text.trim())
      ..description = _desc.text.trim();
    app.saveProduct(p);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              LabeledField(label: 'Nombre', hint: 'Nombre del producto', controller: _name),
              Align(alignment: Alignment.centerLeft, child: Text('Categoría', style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              LabeledField(label: 'Precio', hint: 'Ej. 149900', controller: _price, keyboard: TextInputType.number, validator: _number),
              LabeledField(label: 'Stock', hint: 'Unidades disponibles', controller: _stock, keyboard: TextInputType.number, validator: _number),
              LabeledField(label: 'Descripción', hint: 'Materiales, ajuste y cuidado', controller: _desc, optional: true),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size(100, 44)), child: const Text('Guardar')),
      ],
    );
  }
}

// ---------------------------------------------------------------- Inventario

class _InventoryAdmin extends StatelessWidget {
  const _InventoryAdmin();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Inventario', 'Ajusta las unidades disponibles de cada producto.'),
      for (final p in app.products)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card2(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              SizedBox(width: 50, height: 50, child: PhotoPlaceholder(tint: p.tint, radius: 8, iconSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                  StockLabel(p.status),
                ]),
              ),
              // Botones para subir o bajar el stock
              IconButton(onPressed: () => app.setStock(p, p.stock - 1), icon: const Icon(Icons.remove_circle_outline)),
              SizedBox(width: 36, child: Text('${p.stock}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              IconButton(onPressed: () => app.setStock(p, p.stock + 1), icon: const Icon(Icons.add_circle_outline)),
            ]),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- Promociones

class _PromoAdmin extends StatelessWidget {
  const _PromoAdmin();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Promociones', 'Controla el banner de descuento del inicio.'),
      Card2(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar promoción en el inicio', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            value: app.promoActive,
            onChanged: (v) => app.setPromo(v, app.promoPercent),
          ),
          const SizedBox(height: 8),
          Text('Descuento máximo: ${app.promoPercent} %', style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
          Slider(
            value: app.promoPercent.toDouble(),
            min: 5,
            max: 70,
            divisions: 13,
            label: '${app.promoPercent} %',
            onChanged: (v) => app.setPromo(app.promoActive, v.round()),
          ),
        ]),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- Pedidos

class _OrdersAdmin extends StatefulWidget {
  const _OrdersAdmin();

  @override
  State<_OrdersAdmin> createState() => _OrdersAdminState();
}

class _OrdersAdminState extends State<_OrdersAdmin> {
  // Filtro por estado (null = todos)
  OrderStatus? _filter;

  Future<void> _delete(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: Text('¿Eliminar el pedido #${o.number}? Si no se ha entregado, las unidades vuelven al inventario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true) app.deleteOrder(o);
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: kMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );

  // Tarjeta de un pedido con sus datos y acciones
  Widget _orderCard(Order o) {
    final next = o.status.index < OrderStatus.values.length - 1 ? OrderStatus.values[o.status.index + 1] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card2(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Row(children: [
              Expanded(child: Text('Pedido #${o.number}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy))),
              StatusChip(o.status),
            ]),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${fmtDate(o.date)} · ${o.items.length} productos · ${fmtPrice(o.total)}', style: const TextStyle(color: kMuted, fontSize: 13)),
            ),
            children: [
              const Divider(color: kBorder),
              _line('Cliente', o.customer.isEmpty ? '-' : o.customer),
              _line('Correo', o.email ?? '-'),
              _line('Teléfono', o.phone.isEmpty ? '-' : o.phone),
              _line('Dirección', o.address),
              _line('Comprobante', o.receipt ?? 'Sin comprobante'),
              const SizedBox(height: 10),
              for (final i in o.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 36, height: 36, child: PhotoPlaceholder(tint: i.product.tint, radius: 6, iconSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${i.qty} x ${i.product.name} · ${i.color.name} · ${i.size}', style: const TextStyle(color: kNavy, fontSize: 13))),
                    Text(fmtPrice(i.total), style: const TextStyle(color: kNavy, fontSize: 13)),
                  ]),
                ),
              const SizedBox(height: 12),
              // Estado del pago
              Row(children: [
                Icon(o.paid ? Icons.verified_outlined : Icons.hourglass_empty, size: 18, color: o.paid ? kGreen : kAmber),
                const SizedBox(width: 6),
                Text(o.paid ? 'Pago validado' : 'Pago por validar',
                    style: TextStyle(fontWeight: FontWeight.w700, color: o.paid ? kGreen : kAmber)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (!o.paid)
                  FilledButton.icon(
                    onPressed: () => app.validatePayment(o),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Validar pago'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: kGreen),
                  ),
                if (next != null)
                  FilledButton(
                    onPressed: () => app.setOrderStatus(o, next),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: Text('Marcar como ${next.label.toLowerCase()}'),
                  ),
                // También se puede fijar cualquier estado directamente
                DropdownButton<OrderStatus>(
                  value: o.status,
                  underline: const SizedBox.shrink(),
                  items: [for (final s in OrderStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                  onChanged: (s) => app.setOrderStatus(o, s!),
                ),
                TextButton.icon(
                  onPressed: () => _delete(o),
                  icon: const Icon(Icons.delete_outline, size: 18, color: kRed),
                  label: const Text('Eliminar', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = app.orders.where((o) => _filter == null || o.status == _filter).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Pedidos', 'Valida pagos y actualiza el estado de cada pedido.'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final s in <OrderStatus?>[null, ...OrderStatus.values])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s?.label ?? 'Todos'),
                selected: _filter == s,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = s),
                selectedColor: kBlue,
                backgroundColor: Colors.white,
                side: BorderSide(color: _filter == s ? kBlue : kBorder),
                labelStyle: TextStyle(color: _filter == s ? Colors.white : kNavy, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No hay pedidos.', style: TextStyle(color: kMuted)))),
      for (final o in list) _orderCard(o),
    ]);
  }
}
