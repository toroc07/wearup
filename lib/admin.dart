import 'package:flutter/material.dart';

import 'account.dart';
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

// Panel de administración: menú lateral en pantallas anchas, cajón en móviles.
// Los permisos reales los aplica la base de datos: solo un perfil con rol admin puede escribir.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _section = 1;

  Future<void> _logout() async {
    final ok = await runAction(context, app.signOut);
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
      builder: (context, _) {
        // Si la sesión se cerró o ya no es administrador, no se muestra nada del panel
        if (!app.isAdmin) return const Center(child: Text('Necesitas una cuenta de administrador.', style: TextStyle(color: kMuted)));
        return RefreshIndicator(
          onRefresh: () => runAction(context, app.refresh),
          child: switch (_section) {
            0 => const _Dashboard(),
            1 => const _ProductsAdmin(),
            2 => const _InventoryAdmin(),
            3 => const _PromoAdmin(),
            _ => const _OrdersAdmin(),
          },
        );
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
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kNavy)),
            Text(subtitle, style: const TextStyle(color: kMuted)),
          ]),
          ?action,
        ],
      ),
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
  final unpaid = app.orders.where((o) => !o.paid).length;
  return LayoutBuilder(builder: (context, c) {
    final cols = c.maxWidth >= 900 ? 5 : 2;
    final w = (c.maxWidth - 12 * (cols - 1)) / cols;
    final cards = [
      ('Productos activos', app.products.length),
      ('Últimas unidades', low),
      ('Agotados', out),
      ('Pedidos por atender', pending),
      ('Pagos por validar', unpaid),
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
  int? _category;
  Stock? _stock;

  Future<void> _edit([Product? p]) async {
    await showDialog<void>(context: context, builder: (_) => _ProductDialog(product: p));
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p.name}"? Se borran sus variantes, su stock y sus fotos. '
            'Los pedidos ya hechos conservan su copia del producto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true && mounted) await runAction(context, () => app.deleteProduct(p), success: 'Producto eliminado');
  }

  @override
  Widget build(BuildContext context) {
    // Aplica búsqueda y filtros de la tabla
    final list = app.products.where((p) {
      if (_query.isNotEmpty && !p.name.toLowerCase().contains(_query.toLowerCase())) return false;
      if (_category != null && p.categoryId != _category) return false;
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
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(isDense: true),
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final c in app.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
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
                        SizedBox(width: 44, height: 44, child: ProductPhoto.of(p, radius: 8, iconSize: 20)),
                        const SizedBox(width: 12),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                      ])),
                      DataCell(Text(app.categoryName(p.categoryId))),
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

// Colores que el administrador puede elegir para las variantes
const _palette = [
  ProductColor('Negro', '#1A2433'),
  ProductColor('Blanco', '#F2F2F2'),
  ProductColor('Gris', '#9AA5B1'),
  ProductColor('Azul', '#3B5B8F'),
  ProductColor('Azul claro', '#8FB3DE'),
  ProductColor('Verde', '#4F8F6B'),
  ProductColor('Rojo', '#B23A3A'),
  ProductColor('Rosado', '#E3A1B5'),
  ProductColor('Amarillo', '#E8C547'),
  ProductColor('Café', '#8B5E3C'),
  ProductColor('Beige', '#D9C7A8'),
  ProductColor('Morado', '#6E4C9A'),
];

// Tallas sugeridas por tipo de producto
const _sizePresets = {
  'Ropa (S-XL)': ['S', 'M', 'L', 'XL'],
  'Jeans (28-34)': ['28', '30', '32', '34'],
  'Calzado (38-42)': ['38', '39', '40', '41', '42'],
  'Talla única': ['Único'],
};

// Formulario para crear o editar un producto: datos, colores, tallas y fotos.
// Cada combinación color x talla es una variante con su propio stock (se ajusta en Inventario).
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
  late final _desc = TextEditingController(text: widget.product?.description);
  final _newSize = TextEditingController();
  late int _category = widget.product?.categoryId ?? (app.categories.isEmpty ? 1 : app.categories.first.id);
  late final List<ProductColor> _colors = [...?widget.product?.colors];
  late final List<String> _sizes = [...?widget.product?.sizes];
  String? _variantError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    _newSize.dispose();
    super.dispose();
  }

  String? _number(String? v) => (v == null || int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0) ? 'Número inválido' : null;

  void _addSize(String s) {
    final size = s.trim();
    if (size.isEmpty || _sizes.any((x) => x.toLowerCase() == size.toLowerCase())) return;
    setState(() {
      _sizes.add(size);
      _variantError = null;
    });
    _newSize.clear();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_colors.isEmpty || _sizes.isEmpty) setState(() => _variantError = 'Agrega al menos un color y una talla');
    if (!valid || _colors.isEmpty || _sizes.isEmpty) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => app.saveProduct(ProductDraft(
        id: widget.product?.id,
        name: _name.text.trim(),
        categoryId: _category,
        description: _desc.text.trim(),
        price: int.parse(_price.text.trim()),
        tint: widget.product?.tint ?? '#D3E2F0',
        colors: _colors,
        sizes: _sizes,
      )),
      success: widget.product == null ? 'Producto creado. Ajusta su stock en Inventario.' : 'Producto actualizado',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _addPhoto(Product p) async {
    final image = await pickImage(context);
    if (image == null || !mounted) return;
    setState(() => _busy = true);
    await runAction(context, () => app.addProductImage(p, image), success: 'Foto agregada');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _deletePhoto(Product p, String path) async {
    setState(() => _busy = true);
    await runAction(context, () => app.deleteProductImage(p, path));
    if (mounted) setState(() => _busy = false);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
      );

  @override
  Widget build(BuildContext context) {
    final existing = widget.product == null ? null : app.productById(widget.product!.id);
    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              LabeledField(label: 'Nombre', hint: 'Nombre del producto', controller: _name),
              _label('Categoría'),
              DropdownButtonFormField<int>(
                initialValue: _category,
                items: [for (final c in app.categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              LabeledField(label: 'Precio', hint: 'Ej. 149900', controller: _price, keyboard: TextInputType.number, validator: _number),
              LabeledField(label: 'Descripción', hint: 'Materiales, ajuste y cuidado', controller: _desc, optional: true),

              // Colores
              _label('Colores'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in _colors)
                  InputChip(
                    avatar: CircleAvatar(backgroundColor: c.color),
                    label: Text(c.name),
                    onDeleted: () => setState(() => _colors.remove(c)),
                  ),
                PopupMenuButton<ProductColor>(
                  tooltip: 'Agregar color',
                  onSelected: (c) => setState(() {
                    _colors.add(c);
                    _variantError = null;
                  }),
                  itemBuilder: (_) => [
                    for (final c in _palette.where((c) => !_colors.contains(c)))
                      PopupMenuItem(
                        value: c,
                        child: Row(children: [CircleAvatar(radius: 10, backgroundColor: c.color), const SizedBox(width: 10), Text(c.name)]),
                      ),
                  ],
                  child: const Chip(avatar: Icon(Icons.add, size: 18), label: Text('Agregar color')),
                ),
              ]),
              const SizedBox(height: 14),

              // Tallas
              _label('Tallas'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _sizes) InputChip(label: Text(s), onDeleted: () => setState(() => _sizes.remove(s))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _newSize,
                    decoration: const InputDecoration(hintText: 'Nueva talla (ej. M, 32, 40)', isDense: true),
                    onSubmitted: _addSize,
                  ),
                ),
                IconButton(tooltip: 'Agregar talla', onPressed: () => _addSize(_newSize.text), icon: const Icon(Icons.add_circle_outline)),
              ]),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final e in _sizePresets.entries)
                  ActionChip(
                    label: Text(e.key, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      for (final s in e.value) {
                        _addSize(s);
                      }
                    },
                  ),
              ]),
              if (_variantError != null) ...[
                const SizedBox(height: 8),
                Text(_variantError!, style: const TextStyle(color: kRed, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Text(
                'Cada color con cada talla es una variante con su propio stock. '
                '${widget.product == null ? 'Empiezan en 0 unidades: ajústalas en Inventario.' : 'Si quitas un color o una talla, se borran esas variantes con su stock.'}',
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),

              // Fotos (solo al editar, porque necesitan el producto guardado)
              const SizedBox(height: 16),
              _label('Fotos'),
              if (existing == null)
                const Text('Guarda el producto para poder agregarle fotos.', style: TextStyle(color: kMuted, fontSize: 12))
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final path in existing.images)
                    Stack(children: [
                      SizedBox(width: 72, height: 72, child: ProductPhoto(path: path, tint: existing.tintColor, radius: 8, iconSize: 18)),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Quitar foto',
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            onPressed: _busy ? null : () => _deletePhoto(existing, path),
                            icon: const Icon(Icons.close, color: kRed),
                          ),
                        ),
                      ),
                    ]),
                  InkWell(
                    onTap: _busy ? null : () => _addPhoto(existing),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_a_photo_outlined, color: kBlue),
                    ),
                  ),
                ]),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Inventario

// Stock por variante (talla + color) de cada producto
class _InventoryAdmin extends StatelessWidget {
  const _InventoryAdmin();

  Future<void> _typeStock(BuildContext context, Variant v) async {
    final ctrl = TextEditingController(text: '${v.stock}');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stock de ${v.colorName} · ${v.size}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Unidades disponibles'),
          onSubmitted: (s) => Navigator.pop(ctx, int.tryParse(s.trim())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value != null && value >= 0 && context.mounted) await runAction(context, () => app.setVariantStock(v, value));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Inventario', 'Ajusta las unidades de cada talla y color.'),
      for (final p in app.products)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card2(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                leading: SizedBox(width: 50, height: 50, child: ProductPhoto.of(p, radius: 8, iconSize: 20)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                subtitle: Row(children: [StockLabel(p.status), const SizedBox(width: 8), Text('${p.stock} unidades', style: const TextStyle(color: kMuted, fontSize: 12))]),
                children: [
                  for (final v in p.variants)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        CircleAvatar(radius: 9, backgroundColor: v.color.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${v.colorName} · ${v.size}', style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
                            Text(v.sku, style: const TextStyle(color: kMuted, fontSize: 11)),
                          ]),
                        ),
                        IconButton(
                          tooltip: 'Quitar una unidad',
                          onPressed: v.stock == 0 ? null : () => runAction(context, () => app.setVariantStock(v, v.stock - 1)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        InkWell(
                          onTap: () => _typeStock(context, v),
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 36,
                            child: Center(
                              child: Text('${v.stock}',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: v.stock == 0 ? kRed : kNavy)),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Agregar una unidad',
                          onPressed: () => runAction(context, () => app.setVariantStock(v, v.stock + 1)),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ]),
                    ),
                  if (p.variants.isEmpty) const Text('Sin variantes: agrega colores y tallas en Productos.', style: TextStyle(color: kMuted)),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- Promociones

class _PromoAdmin extends StatefulWidget {
  const _PromoAdmin();

  @override
  State<_PromoAdmin> createState() => _PromoAdminState();
}

class _PromoAdminState extends State<_PromoAdmin> {
  // Valor mientras se arrastra el control; se guarda al soltarlo
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final s = app.settings;
    final percent = (_dragging ?? s.promoPercent.toDouble()).round();
    return ListView(padding: const EdgeInsets.all(20), children: [
      _pageHeader('Promociones', 'Controla el banner de descuento del inicio.'),
      Card2(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar promoción en el inicio', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
            value: s.promoActive,
            onChanged: (v) => runAction(context, () => app.setPromo(v, s.promoPercent)),
          ),
          const SizedBox(height: 8),
          Text('Descuento anunciado: $percent %', style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
          Slider(
            value: percent.toDouble(),
            min: 5,
            max: 70,
            divisions: 13,
            label: '$percent %',
            onChanged: (v) => setState(() => _dragging = v),
            onChangeEnd: (v) async {
              await runAction(context, () => app.setPromo(s.promoActive, v.round()));
              if (mounted) setState(() => _dragging = null);
            },
          ),
          const Text('El porcentaje solo se muestra en el banner; no cambia los precios.', style: TextStyle(color: kMuted, fontSize: 12)),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: Text('¿Eliminar el pedido #${o.number}? Si no se ha entregado, las unidades vuelven al inventario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true && mounted) await runAction(context, () => app.deleteOrder(o), success: 'Pedido eliminado');
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
              child: Text('${fmtDate(o.date)} · ${o.items.length} productos · ${fmtPrice(o.total)}${o.paid ? '' : ' · pago por validar'}',
                  style: TextStyle(color: o.paid ? kMuted : kAmber, fontSize: 13)),
            ),
            children: [
              const Divider(color: kBorder),
              _line('Cliente', o.customerName.isEmpty ? '-' : o.customerName),
              _line('Correo', o.customerEmail.isEmpty ? '-' : o.customerEmail),
              _line('Teléfono', o.phone.isEmpty ? '-' : o.phone),
              _line('Dirección', o.fullAddress),
              if (o.notes.isNotEmpty) _line('Indicaciones', o.notes),
              const SizedBox(height: 10),
              for (final i in o.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 36, height: 36, child: PhotoPlaceholder(tint: i.tintColor, radius: 6, iconSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${i.qty} x ${i.productName} · ${i.colorName} · ${i.size}', style: const TextStyle(color: kNavy, fontSize: 13))),
                    Text(fmtPrice(i.total), style: const TextStyle(color: kNavy, fontSize: 13)),
                  ]),
                ),
              const SizedBox(height: 12),
              // Estado del pago
              Row(children: [
                Icon(o.paid ? Icons.verified_outlined : Icons.hourglass_empty, size: 18, color: o.paid ? kGreen : kAmber),
                const SizedBox(width: 6),
                Text(o.paid ? 'Pago validado' : 'Pago por validar', style: TextStyle(fontWeight: FontWeight.w700, color: o.paid ? kGreen : kAmber)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (o.receiptPath != null)
                  OutlinedButton.icon(
                    onPressed: () => showReceipt(context, o.receiptPath!),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Ver comprobante'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  ),
                if (!o.paid)
                  FilledButton.icon(
                    onPressed: () => runAction(context, () => app.validatePayment(o), success: 'Pago validado'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Validar pago'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: kGreen),
                  ),
                if (next != null)
                  FilledButton(
                    onPressed: () => runAction(context, () => app.setOrderStatus(o, next)),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: Text('Marcar como ${next.label.toLowerCase()}'),
                  ),
                // También se puede fijar cualquier estado directamente
                DropdownButton<OrderStatus>(
                  value: o.status,
                  underline: const SizedBox.shrink(),
                  items: [for (final s in OrderStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                  onChanged: (s) => runAction(context, () => app.setOrderStatus(o, s!)),
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
