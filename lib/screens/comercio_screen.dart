import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'producto_detalle_screen.dart';

class ComercioScreen extends StatefulWidget {
  final Map<String, dynamic> comercio;
  final void Function(Map<String, dynamic>) onAgregar;
  final Map<int, Map<String, dynamic>> carritoInicial;
  final VoidCallback? onVerPedidos;
  const ComercioScreen({
    super.key,
    required this.comercio,
    required this.onAgregar,
    this.carritoInicial = const {},
    this.onVerPedidos,
  });
  @override
  State<ComercioScreen> createState() => _ComercioScreenState();
}

class _ComercioScreenState extends State<ComercioScreen> {
  List<dynamic> _productos = [];
  bool _cargando = true;
  String _busqueda = '';
  late Map<int, Map<String, dynamic>> _carrito;
  final Set<String> _colapsadas = {};

  int get _totalItems => _carrito.values.fold(0, (a, b) => a + (b['cantidad'] as int));

  @override
  void initState() {
    super.initState();
    _carrito = Map.from(widget.carritoInicial);
    _cargar();
  }

  Future<void> _cargar() async {
    final id = widget.comercio['id'];
    final res = await ApiService.get('/comercio/$id/productos');
    if (mounted) {
      final lista = res['data'] is List ? res['data'] : [];
      setState(() { _productos = lista; _cargando = false; });
    }
  }

  List<dynamic> get _filtrados {
    if (_busqueda.isEmpty) return _productos;
    final lower = _busqueda.toLowerCase();
    return _productos.where((p) =>
      (p['nombre'] ?? '').toString().toLowerCase().contains(lower) ||
      (p['subcategoria'] ?? '').toString().toLowerCase().contains(lower) ||
      (p['marca'] ?? '').toString().toLowerCase().contains(lower)
    ).toList();
  }

  // Agrupa la lista filtrada por subcategoría
  Map<String, List<dynamic>> get _agrupados {
    final map = <String, List<dynamic>>{};
    for (final p in _filtrados) {
      final sub = (p['subcategoria'] as String?) ?? 'Otros';
      map.putIfAbsent(sub, () => []).add(p);
    }
    return map;
  }

  void _agregar(Map<String, dynamic> producto) {
    final id = producto['id'] as int;
    setState(() {
      if (_carrito.containsKey(id)) {
        _carrito[id]!['cantidad'] = (_carrito[id]!['cantidad'] as int) + 1;
      } else {
        _carrito[id] = {
          'id': id,
          'nombre': producto['nombre'],
          'precio': double.tryParse(producto['precio'].toString()) ?? 0.0,
          'unidad': producto['unidad'] ?? '',
          'comercio_id': widget.comercio['id'],
          'comercio_nombre': widget.comercio['nombre'],
          'costo_envio': widget.comercio['costo_envio'] ?? 0,
          'cantidad': 1,
        };
      }
      widget.onAgregar(_carrito[id]!);
    });
  }

  void _quitar(int id) {
    setState(() {
      if (!_carrito.containsKey(id)) return;
      final cant = (_carrito[id]!['cantidad'] as int) - 1;
      if (cant <= 0) { _carrito.remove(id); } else { _carrito[id]!['cantidad'] = cant; }
    });
  }

  void _irAlCarrito() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CartScreen(
        carrito: Map.from(_carrito),
        comercio: widget.comercio,
        onActualizar: (nuevo) => setState(() { _carrito.clear(); _carrito.addAll(nuevo); }),
        onVerPedidos: widget.onVerPedidos,
      ),
    ));
  }

  IconData _iconoSubcat(String sub) {
    switch (sub.toLowerCase()) {
      case 'áridos y granulados':      return Icons.terrain_outlined;
      case 'cementos y mezclas':       return Icons.science_outlined;
      case 'mampostería':              return Icons.foundation_outlined;
      case 'estructura metálica':      return Icons.architecture_outlined;
      case 'pintura y revestimientos': return Icons.format_paint_outlined;
      case 'impermeabilización':       return Icons.water_drop_outlined;
      case 'fijaciones':               return Icons.hardware_outlined;
      case 'selladores':               return Icons.vaccines_outlined;
      case 'abrasivos':                return Icons.rotate_right_outlined;
      case 'herramientas eléctricas':  return Icons.electrical_services_outlined;
      case 'herramientas neumáticas':  return Icons.air_outlined;
      case 'medición y trazado':       return Icons.straighten_outlined;
      case 'maquinaria de obra':       return Icons.agriculture_outlined;
      case 'andamiaje y seguridad':    return Icons.safety_check_outlined;
      case 'electricidad y energía':   return Icons.bolt_outlined;
      default:                         return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agrupados = _agrupados;
    final subcats = agrupados.keys.toList();

    return Scaffold(
      backgroundColor: kBgPage,
      body: CustomScrollView(slivers: [
        // ── Header del comercio
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: kAmber.withValues(alpha: 0.07),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]),
                  child: const Icon(Icons.store_rounded, color: kAmber, size: 28),
                ),
                const SizedBox(height: 8),
                Text(widget.comercio['nombre'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
                Text(widget.comercio['direccion'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          ),
        ),

        // ── Info del local (tiempo, envío, calificación)
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(children: [
            _chip(Icons.access_time_outlined,
              '${widget.comercio['tiempo_entrega_estimado'] ?? 30} min'),
            const SizedBox(width: 12),
            _chip(Icons.delivery_dining_outlined, () {
              final e = double.tryParse(widget.comercio['costo_envio'].toString()) ?? 0;
              return e == 0 ? 'Envío gratis' : '\$${e.toStringAsFixed(0)}';
            }()),
            const SizedBox(width: 12),
            _chip(Icons.star_rounded,
              '${double.tryParse(widget.comercio['calificacion_promedio'].toString())?.toStringAsFixed(1) ?? '0.0'}'),
          ]),
        )),

        // ── Buscador
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (q) => setState(() => _busqueda = q),
            decoration: InputDecoration(
              hintText: 'Buscar en ${widget.comercio['nombre']}...',
              prefixIcon: const Icon(Icons.search, color: kAmber, size: 20),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
        )),

        // ── Productos agrupados por subcategoría
        if (_cargando)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kAmber)))
        else if (_filtrados.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_busqueda.isEmpty ? 'No hay productos' : 'Sin resultados para "$_busqueda"',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ])))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) {
              final sub = subcats[i];
              final prods = agrupados[sub]!;
              final colapsada = _colapsadas.contains(sub);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Cabecera de subcategoría (tappable para colapsar)
                GestureDetector(
                  onTap: () => setState(() {
                    if (colapsada) _colapsadas.remove(sub);
                    else _colapsadas.add(sub);
                  }),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(_iconoSubcat(sub), size: 16, color: kAmber),
                      const SizedBox(width: 8),
                      Text(sub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kAmber)),
                      const Spacer(),
                      Text('${prods.length} ${prods.length == 1 ? 'producto' : 'productos'}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Icon(colapsada ? Icons.expand_more : Icons.expand_less,
                        size: 18, color: kAmber),
                    ]),
                  ),
                ),
                // ── Productos de esa subcategoría
                if (!colapsada)
                  ...prods.map((p) {
                    final id = p['id'] as int;
                    final cant = _carrito[id]?['cantidad'] as int? ?? 0;
                    final precio = double.tryParse(p['precio'].toString()) ?? 0.0;
                    return _ProductoTile(
                      producto: p, precio: precio, cantidad: cant,
                      onAgregar: () => _agregar(p),
                      onQuitar: () => _quitar(id),
                    );
                  }),
              ]);
            },
            childCount: subcats.length,
          )),

        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ]),
      bottomNavigationBar: _totalItems > 0 ? _barraCarrito() : null,
    );
  }

  Widget _chip(IconData icono, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icono, size: 13, color: Colors.grey),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ]);

  Widget _barraCarrito() {
    final total = _carrito.values.fold<double>(0, (a, b) => a + (b['precio'] as double) * (b['cantidad'] as int));
    final fmt = total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ElevatedButton(
          onPressed: _irAlCarrito,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAmber,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('$_totalItems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Ver carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            Text('\$$fmt', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _ProductoTile extends StatelessWidget {
  final dynamic producto;
  final double precio;
  final int cantidad;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;
  const _ProductoTile({required this.producto, required this.precio, required this.cantidad, required this.onAgregar, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    final stock = producto['stock'] as int? ?? 0;
    final sinStock = stock == 0;
    final fmt = precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(
          producto: Map<String, dynamic>.from(producto as Map),
          cantidadActual: cantidad,
          onAgregar: onAgregar,
          onQuitar: onQuitar,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.construction, color: kAmber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(producto['nombre'] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            if ((producto['marca'] ?? '').isNotEmpty)
              Text(producto['marca'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text('${producto['unidad'] ?? ''} · ${sinStock ? 'Sin stock' : '$stock en stock'}',
              style: TextStyle(fontSize: 10, color: sinStock ? Colors.red : Colors.grey)),
            const SizedBox(height: 3),
            Text('\$$fmt', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          ])),
          if (sinStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text('Sin stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
            )
          else if (cantidad == 0)
            GestureDetector(
              onTap: onAgregar,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            )
          else
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: kAmber), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(onTap: onQuitar, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.remove, size: 16, color: kAmber))),
                  SizedBox(width: 24, child: Center(child: Text('$cantidad', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAmber)))),
                  GestureDetector(onTap: onAgregar, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.add, size: 16, color: kAmber))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
