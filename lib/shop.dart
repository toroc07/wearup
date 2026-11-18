import 'package:flutter/material.dart';

import 'legal.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- Inicio

// Pantalla de inicio: portada, categorías, destacados y promoción
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCatalog(BuildContext context, {int? category, String? query}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CatalogScreen(showBack: true, initialCategory: category, initialQuery: query),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final featured = app.products.take(4).toList();
        const catTints = [Color(0xFFE6ECF6), Color(0xFFD9E7F2), Color(0xFFDDEFEA), Color(0xFFD5EBF1)];
        final cats = app.categories;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            title: const Logo(),
            actions: [
              IconButton(tooltip: 'Cuenta', onPressed: () => app.goTab(3), icon: const Icon(Icons.person_outline, size: 26)),
              const CartButton(),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => runAction(context, app.refresh),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) => _openCatalog(context, query: q),
                  decoration: const InputDecoration(hintText: 'Buscar ropa, jeans, zapatos...', prefixIcon: Icon(Icons.search, color: kNavy)),
                ),
                const SizedBox(height: 16),
                // Portada
                Container(
                  height: 300,
                  decoration: BoxDecoration(color: const Color(0xFFD3E2F0), borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    const Expanded(child: Center(child: PhotoPlaceholder(label: 'Foto de moda · portada', tint: Colors.transparent))),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('NUEVA COLECCIÓN', style: TextStyle(fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: kMuted)),
                        const SizedBox(height: 4),
                        const Text('VISTE TU ESTILO', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kNavy)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: () => _openCatalog(context), child: const Text('Descubrir colección')),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                // Categorías (abren el catálogo filtrado)
                const Text('Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
                const SizedBox(height: 12),
                Row(children: [
                  for (var i = 0; i < cats.length; i++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openCatalog(context, category: cats[i].id),
                        child: Padding(
                          padding: EdgeInsets.only(right: i == cats.length - 1 ? 0 : 8),
                          child: Column(children: [
                            AspectRatio(aspectRatio: 1, child: PhotoPlaceholder(tint: catTints[i % catTints.length], radius: 14, iconSize: 24)),
                            const SizedBox(height: 8),
                            FittedBox(fit: BoxFit.scaleDown, child: Text(cats[i].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kNavy))),
                          ]),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Productos destacados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
                  TextButton(
                    onPressed: () => _openCatalog(context),
                    child: const Text('Ver todo', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ),
                ]),
                // Lista horizontal de productos destacados
                SizedBox(
                  height: 290,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final p = featured[i];
                      return SizedBox(
                        width: 162,
                        child: InkWell(
                          onTap: () => openProduct(context, p),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(height: 198, child: ProductPhoto.of(p, label: 'Foto producto', radius: 16, iconSize: 32)),
                            const SizedBox(height: 8),
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
                            const SizedBox(height: 4),
                            Text(fmtPrice(p.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                // Banner de promoción (lo controla el administrador)
                if (app.settings.promoActive) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [Color(0xFF1F4E8C), Color(0xFF2A8AA6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('PROMOCIÓN', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Hasta ${app.settings.promoPercent} % en productos seleccionados',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kNavy),
                        onPressed: () => _openCatalog(context),
                        child: const Text('Ver colección'),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Contacto · Envíos y devoluciones · ', style: TextStyle(color: kMuted, fontSize: 12)),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Privacidad', style: TextStyle(color: kMuted, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ),
                ]),
                const Center(child: Text('© WearUp', style: TextStyle(color: kMuted, fontSize: 12))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Abre el detalle de un producto
void openProduct(BuildContext context, Product p) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));

// Agrega al carrito y avisa cuántas unidades entraron según el stock de la variante
void addAndNotify(BuildContext context, Product p, Variant v, int qty) {
  final added = app.addToCart(p, v, qty);
  final what = '${p.name} (${v.colorName} · ${v.size})';
  final msg = added == 0
      ? 'Ya tienes en el carrito todas las unidades disponibles de $what'
      : added < qty
          ? 'Solo quedaban $added unidades de $what: se agregaron al carrito'
          : '$what agregado al carrito';
  showMessage(context, msg);
}

// Primera variante con stock (para la selección inicial)
Variant? _firstAvailable(Product p, {String? color}) {
  for (final v in p.variants) {
    if ((color == null || v.colorName == color) && v.stock > 0) return v;
  }
  return null;
}

// ---------------------------------------------------------------- Selector de variante

/// Colores y tallas de un producto. Solo deja elegir combinaciones con stock (RF-004).
class VariantPicker extends StatelessWidget {
  final Product product;
  final String color;
  final String? size;
  final ValueChanged<String> onColor;
  final ValueChanged<String> onSize;
  final VoidCallback? onSizeGuide;

  const VariantPicker({
    super.key,
    required this.product,
    required this.color,
    required this.size,
    required this.onColor,
    required this.onSize,
    this.onSizeGuide,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(children: [
        const TextSpan(text: 'Color: ', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
        TextSpan(text: color, style: const TextStyle(color: kMuted)),
      ])),
      const SizedBox(height: 10),
      Wrap(spacing: 12, runSpacing: 8, children: [
        for (final c in p.colors)
          Tooltip(
            message: p.stockOfColor(c.name) > 0 ? c.name : '${c.name} (agotado)',
            child: GestureDetector(
              onTap: () => onColor(c.name),
              child: Opacity(
                opacity: p.stockOfColor(c.name) > 0 ? 1 : .35,
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color == c.name ? kBlue : kBorder, width: 2),
                  ),
                  child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c.color, border: Border.all(color: kBorder))),
                ),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Talla: ', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
          TextSpan(text: size ?? 'Sin tallas disponibles en este color', style: const TextStyle(color: kMuted)),
        ])),
        if (onSizeGuide != null)
          InkWell(
            onTap: onSizeGuide,
            child: const Text('¿Cuál es mi talla?', style: TextStyle(fontWeight: FontWeight.w700, color: kNavy, decoration: TextDecoration.underline)),
          ),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in p.sizes)
          Builder(builder: (context) {
            final available = p.stockOf(color, s) > 0;
            final selected = size == s;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: available ? () => onSize(s) : null,
              child: Container(
                constraints: const BoxConstraints(minWidth: 56),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? kBlue : (available ? Colors.white : const Color(0xFFF0F3F7)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? kBlue : kBorder),
                ),
                child: Text(s,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : (available ? kNavy : kMuted),
                      decoration: available ? null : TextDecoration.lineThrough,
                    )),
              ),
            );
          }),
      ]),
    ]);
  }
}

// Hoja rápida para elegir talla y color desde la cuadrícula del catálogo
Future<void> showQuickAdd(BuildContext context, Product p) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _QuickAddSheet(product: p, parentContext: context),
  );
}

class _QuickAddSheet extends StatefulWidget {
  final Product product;
  final BuildContext parentContext;
  const _QuickAddSheet({required this.product, required this.parentContext});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late String _color = (_firstAvailable(widget.product) ?? widget.product.variants.first).colorName;
  late String? _size = _firstAvailable(widget.product, color: _color)?.size;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final v = _size == null ? null : p.variant(_color, _size!);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kNavy)),
          Text(fmtPrice(p.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 16),
          VariantPicker(
            product: p,
            color: _color,
            size: _size,
            onColor: (c) => setState(() {
              _color = c;
              if (_size == null || p.stockOf(c, _size!) == 0) _size = _firstAvailable(p, color: c)?.size;
            }),
            onSize: (s) => setState(() => _size = s),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: v == null || v.stock == 0
                ? null
                : () {
                    Navigator.pop(context);
                    addAndNotify(widget.parentContext, p, v, 1);
                  },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Agregar al carrito'),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Catálogo

// Catálogo con búsqueda y filtros por categoría, talla, color, precio y disponibilidad (RF-003)
class CatalogScreen extends StatefulWidget {
  final bool showBack;
  final int? initialCategory;
  final String? initialQuery;
  const CatalogScreen({super.key, this.showBack = false, this.initialCategory, this.initialQuery});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _search = TextEditingController(text: widget.initialQuery ?? '');
  late int? _category = widget.initialCategory;
  String? _size, _color, _price, _availability;

  static const _prices = {
    'Hasta \$100.000': (0, 100000),
    '\$100.000 - \$150.000': (100000, 150000),
    'Más de \$150.000': (150000, 1 << 30),
  };
  static const _inStock = 'En stock';
  static const _outOfStock = 'Agotados';

  bool get _hasFilters => _size != null || _color != null || _price != null || _availability != null;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Unidades del producto que cumplen la talla y el color filtrados
  int _matchingStock(Product p) => p.variants
      .where((v) => (_size == null || v.size == _size) && (_color == null || v.colorName == _color))
      .fold(0, (s, v) => s + v.stock);

  // Aplica la búsqueda y los filtros activos
  List<Product> _filtered() {
    final q = _search.text.trim().toLowerCase();
    return app.products.where((p) {
      if (_category != null && p.categoryId != _category) return false;
      if (q.isNotEmpty && !('${p.name} ${app.categoryName(p.categoryId)}'.toLowerCase().contains(q))) return false;
      if (_size != null && !p.sizes.contains(_size)) return false;
      if (_color != null && !p.colors.any((c) => c.name == _color)) return false;
      if (_price != null) {
        final (lo, hi) = _prices[_price]!;
        if (p.price < lo || p.price > hi) return false;
      }
      if (_availability == _inStock && _matchingStock(p) == 0) return false;
      if (_availability == _outOfStock && _matchingStock(p) > 0) return false;
      return true;
    }).toList();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: kBlue,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? kBlue : kBorder),
          labelStyle: TextStyle(color: selected ? Colors.white : kNavy, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      );

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String?>(
        tooltip: label,
        onSelected: onChanged,
        itemBuilder: (_) => [
          const PopupMenuItem(value: null, child: Text('Todos')),
          for (final o in options) PopupMenuItem(value: o, child: Text(o)),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: value != null ? kBlue : kBorder, width: value != null ? 2 : 1),
          ),
          child: Row(children: [
            Text(value ?? label, style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: kNavy),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final items = _filtered();
        final allSizes = {for (final p in app.products) ...p.sizes}.toList();
        final allColors = {for (final p in app.products) for (final c in p.colors) c.name}.toList();
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.showBack ? const BackButton() : null,
            title: const Text('Catálogo'),
            actions: const [CartButton()],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Buscar ropa, jeans, zapatos...', prefixIcon: Icon(Icons.search, color: kNavy)),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                _chip('Todo', _category == null, () => setState(() => _category = null)),
                for (final c in app.categories) _chip(c.name, _category == c.id, () => setState(() => _category = c.id)),
              ]),
            ),
            SizedBox(
              height: 52,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 6, 16, 0), children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: _hasFilters ? () => setState(() => _size = _color = _price = _availability = null) : null,
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(_hasFilters ? 'Limpiar' : 'Filtros'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: kNavy,
                      side: const BorderSide(color: kBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                _dropdown('Talla', _size, allSizes, (v) => setState(() => _size = v)),
                _dropdown('Color', _color, allColors, (v) => setState(() => _color = v)),
                _dropdown('Precio', _price, _prices.keys.toList(), (v) => setState(() => _price = v)),
                _dropdown('Disponibilidad', _availability, const [_inStock, _outOfStock], (v) => setState(() => _availability = v)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_category == null ? 'Todos los productos' : app.categoryName(_category!),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy)),
                Text('${items.length} productos', style: const TextStyle(color: kMuted, fontSize: 13)),
              ]),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => runAction(context, app.refresh),
                child: items.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No encontramos productos con esos filtros.', style: TextStyle(color: kMuted))),
                      ])
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 345,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => ProductCard(product: items[i]),
                      ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// Tarjeta de producto de la cuadrícula
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Card2(
      padding: const EdgeInsets.all(8),
      onTap: () => openProduct(context, p),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SizedBox(width: double.infinity, child: ProductPhoto.of(p, label: 'Foto producto'))),
        const SizedBox(height: 8),
        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(fmtPrice(p.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
          Text('${p.colors.length} colores', style: const TextStyle(color: kMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        StockLabel(p.status),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44), textStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700)),
          // Primero se elige talla y color (RF-004)
          onPressed: p.status == Stock.out ? null : () => showQuickAdd(context, p),
          child: Text(p.status == Stock.out ? 'No disponible' : 'Agregar al carrito'),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Detalle

// Detalle: fotos, color, talla, cantidad y botón de agregar
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _color;
  String? _size;
  int _qty = 1;
  int _photo = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final first = _firstAvailable(p) ?? (p.variants.isEmpty ? null : p.variants.first);
    _color = first?.colorName ?? '';
    _size = _firstAvailable(p, color: _color)?.size;
  }

  void _sizeGuide() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cuál es mi talla?'),
        content: const Text('Mide tu contorno de pecho, cintura y cadera y compáralo con la tabla de la prenda. '
            'Si estás entre dos tallas, elige la mayor para un ajuste más cómodo.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        // Tras recargar el catálogo se usa la versión más reciente del producto
        final p = app.productById(widget.product.id) ?? widget.product;
        if (_size != null && p.stockOf(_color, _size!) == 0) _size = _firstAvailable(p, color: _color)?.size;
        final v = _size == null ? null : p.variant(_color, _size!);
        final left = v == null ? 0 : app.remaining(v);
        final photos = p.images;
        final photoIndex = _photo < photos.length ? _photo : 0;
        return Scaffold(
          appBar: AppBar(title: const Text('Detalle'), actions: const [CartButton()]),
          body: ListView(children: [
            SizedBox(height: 330, child: ProductPhoto.of(p, index: photoIndex, label: 'Foto principal', radius: 0, iconSize: 40)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (photos.length > 1) ...[
                  Row(children: [
                    for (var i = 0; i < photos.length && i < 4; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _photo = i),
                          child: Container(
                            height: 70,
                            margin: EdgeInsets.only(right: i == 3 ? 0 : 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: photoIndex == i ? kBlue : Colors.transparent, width: 2),
                            ),
                            child: ProductPhoto(path: photos[i], tint: p.tintColor, radius: 10, iconSize: 20),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),
                ],
                Text(p.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kNavy)),
                const SizedBox(height: 4),
                Text(fmtPrice(p.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kNavy)),
                const SizedBox(height: 6),
                StockLabel(v?.status ?? p.status),
                const SizedBox(height: 20),
                if (p.variants.isNotEmpty)
                  VariantPicker(
                    product: p,
                    color: _color,
                    size: _size,
                    onSizeGuide: _sizeGuide,
                    onColor: (c) => setState(() {
                      _color = c;
                      if (_size == null || p.stockOf(c, _size!) == 0) _size = _firstAvailable(p, color: c)?.size;
                      _qty = 1;
                    }),
                    onSize: (s) => setState(() {
                      _size = s;
                      _qty = 1;
                    }),
                  ),
                const SizedBox(height: 20),
                const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                const SizedBox(height: 8),
                Row(children: [
                  QtyStepper(value: _qty, onChanged: (n) => setState(() => _qty = n.clamp(1, left < 1 ? 1 : left))),
                  const SizedBox(width: 12),
                  if (v != null && v.stock <= 5 && v.stock > 0)
                    Text('Quedan ${v.stock} unidades', style: const TextStyle(color: kAmber, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                const Card2(
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.local_shipping_outlined, size: 22, color: kNavy),
                      SizedBox(width: 12),
                      Expanded(child: Text('Envío: el costo se calcula en el checkout')),
                    ]),
                    SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.lock_outline, size: 22, color: kNavy),
                      SizedBox(width: 12),
                      Expanded(child: Text('Pago por transferencia BRE-B con comprobante')),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
                const SizedBox(height: 6),
                Text(p.description, style: const TextStyle(color: kMuted, height: 1.4)),
              ]),
            ),
          ]),
          bottomNavigationBar: BottomBar(
            child: FilledButton.icon(
              onPressed: v == null || v.stock == 0 ? null : () => addAndNotify(context, p, v, _qty),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(v == null || v.stock == 0 ? 'No disponible' : 'Agregar al carrito'),
            ),
          ),
        );
      },
    );
  }
}
