import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class ComercioScreen extends StatefulWidget {
  final Map<String, dynamic> comercio;
  final void Function(Map<String, dynamic>) onAgregar;
  const ComercioScreen({super.key, required this.comercio, required this.onAgregar});
  @override
  State<ComercioScreen> createState() => _ComercioScreenState();
}

class _ComercioScreenState extends State<ComercioScreen> {
  List<dynamic> _productos = [];
  List<dynamic> _filtrados = [];
  bool _cargando = true;
  String _busqueda = '';
  final Map<int, Map<String, dynamic>> _carrito = {};

  int get _totalItems => _carrito.values.fold(0, (a, b) => a + (b['cantidad'] as int));

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = widget.comercio['id'];
    final res = await ApiService.get('/comercio/$id/productos');
    if (mounted) {
      final lista = res['data'] is List ? res['data'] : [];
      setState(() { _productos = lista; _filtrados = lista; _cargando = false; });
    }
  }

  void _filtrar(String q) {
    setState(() {
      _busqueda = q;
      if (q.isEmpty) { _filtrados = _productos; return; }
      final lower = q.toLowerCase();
      _filtrados = _productos.where((p) =>
        (p['nombre'] ?? '').toString().toLowerCase().contains(lower) ||
        (p['categoria_nombre'] ?? '').toString().toLowerCase().contains(lower) ||
        (p['marca'] ?? '').toString().toLowerCase().contains(lower)
      ).toList();
    });
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
          'cantidad': 1,
        };
      }
      // También notifica al padre para el badge global
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
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: kAmber.withValues(alpha: 0.08),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Image.network(
                  widget.comercio['logo_url'] ?? '',
                  width: 56, height: 56,
                  errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 48, color: kAmber),
                ),
                const SizedBox(height: 6),
                Text(widget.comercio['nombre'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                Text(widget.comercio['direccion'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _chip(Icons.access_time_outlined, '${widget.comercio['tiempo_entrega_estimado'] ?? 30} min'),
            const SizedBox(width: 8),
            _chip(Icons.delivery_dining_outlined, () {
              final e = double.tryParse(widget.comercio['costo_envio'].toString()) ?? 0;
              return e == 0 ? 'Envío gratis' : '\$${e.toStringAsFixed(0)}';
            }()),
            const SizedBox(width: 8),
            _chip(Icons.star, '${double.tryParse(widget.comercio['calificacion_promedio'].toString())?.toStringAsFixed(1) ?? ''}'),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: _filtrar,
            decoration: InputDecoration(
              hintText: 'Buscar en ${widget.comercio['nombre']}...',
              prefixIcon: const Icon(Icons.search, color: kAmber, size: 20),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
        )),
        if (_cargando)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kAmber)))
        else if (_filtrados.isEmpty)
          SliverFillRemaining(child: Center(child: Text(_busqueda.isEmpty ? 'Este local no tiene productos' : 'Sin resultados para "$_busqueda"', style: const TextStyle(color: Colors.grey))))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) {
              final p = _filtrados[i];
              final id = p['id'] as int;
              final cant = _carrito[id]?['cantidad'] as int? ?? 0;
              final precio = double.tryParse(p['precio'].toString()) ?? 0.0;
              return _ProductoTile(producto: p, precio: precio, cantidad: cant, onAgregar: () => _agregar(p), onQuitar: () => _quitar(id));
            },
            childCount: _filtrados.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ]),
      bottomNavigationBar: _totalItems > 0 ? _barraCarrito() : null,
    );
  }

  Widget _chip(IconData icono, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icono, size: 13, color: Colors.grey),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _barraCarrito() {
    final total = _carrito.values.fold<double>(0, (a, b) => a + (b['precio'] as double) * (b['cantidad'] as int));
    final fmt = total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ElevatedButton(
          onPressed: _irAlCarrito,
          style: ElevatedButton.styleFrom(backgroundColor: kAmber, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.construction, color: kAmber, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          if ((producto['marca'] ?? '').isNotEmpty)
            Text(producto['marca'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('${producto['unidad'] ?? ''} · ${sinStock ? 'Sin stock' : '$stock en stock'}', style: TextStyle(fontSize: 10, color: sinStock ? Colors.red : Colors.grey)),
          const SizedBox(height: 4),
          Text('\$$fmt', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
        ])),
        if (sinStock)
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('Sin stock', style: TextStyle(fontSize: 11, color: Colors.grey)))
        else if (cantidad == 0)
          GestureDetector(
            onTap: onAgregar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(border: Border.all(color: kAmber), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(onTap: onQuitar, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.remove, size: 16, color: kAmber))),
              Text('$cantidad', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAmber)),
              GestureDetector(onTap: onAgregar, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.add, size: 16, color: kAmber))),
            ]),
          ),
      ]),
    );
  }
}
