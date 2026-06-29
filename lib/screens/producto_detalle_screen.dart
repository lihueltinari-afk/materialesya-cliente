import 'package:flutter/material.dart';
import '../theme.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> producto;
  final int cantidadActual;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  const ProductoDetalleScreen({
    super.key,
    required this.producto,
    required this.cantidadActual,
    required this.onAgregar,
    required this.onQuitar,
  });

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late int _cantidad;

  @override
  void initState() {
    super.initState();
    _cantidad = widget.cantidadActual;
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  String _vehiculo(String? v) {
    switch (v) {
      case 'bicicleta': return 'Bicicleta';
      case 'moto': return 'Moto';
      case 'auto': return 'Auto';
      case 'camioneta': return 'Camioneta';
      case 'camion': return 'Camión';
      default: return 'Cualquier vehículo';
    }
  }

  IconData _vehiculoIcono(String? v) {
    switch (v) {
      case 'bicicleta': return Icons.pedal_bike_outlined;
      case 'moto': return Icons.two_wheeler_outlined;
      case 'camion': return Icons.local_shipping_outlined;
      default: return Icons.delivery_dining_outlined;
    }
  }

  void _agregar() {
    widget.onAgregar();
    setState(() => _cantidad++);
  }

  void _quitar() {
    if (_cantidad == 0) return;
    widget.onQuitar();
    setState(() => _cantidad--);
  }

  @override
  Widget build(BuildContext context) {
    final precio = double.tryParse(widget.producto['precio'].toString()) ?? 0.0;
    final stock = widget.producto['stock'] as int? ?? 0;
    final sinStock = stock == 0;
    final pesoKg = double.tryParse(widget.producto['peso_kg']?.toString() ?? '') ?? 0;
    final volumenM3 = double.tryParse(widget.producto['volumen_m3']?.toString() ?? '') ?? 0;
    final vehiculo = widget.producto['vehiculo_minimo'] as String?;

    return Scaffold(
      backgroundColor: kBgPage,
      body: CustomScrollView(slivers: [
        // ── AppBar con imagen del producto
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          expandedHeight: 200,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: kTextDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: kAmber.withValues(alpha: 0.06),
              child: Center(child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.construction, size: 70, color: kAmber),
              ])),
            ),
          ),
        ),

        // ── Nombre, precio, stock
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Categoría tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.producto['categoria_nombre'] ?? '',
                style: const TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            // Nombre
            Text(widget.producto['nombre'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark, height: 1.2)),
            if ((widget.producto['marca'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(widget.producto['marca'],
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            // Precio
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${_fmt(precio)}',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kTextDark, height: 1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('por ${widget.producto['unidad'] ?? 'unidad'}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            ]),
            const SizedBox(height: 10),
            // Badge stock
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sinStock ? const Color(0xFFFFEBEE) : kSuccessBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(sinStock ? Icons.remove_shopping_cart : Icons.check_circle_outline,
                    size: 12, color: sinStock ? const Color(0xFFC62828) : kSuccess),
                  const SizedBox(width: 4),
                  Text(sinStock ? 'Sin stock' : '$stock disponibles',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: sinStock ? const Color(0xFFC62828) : kSuccess)),
                ]),
              ),
            ]),
          ]),
        )),

        // ── Descripción
        if ((widget.producto['descripcion'] ?? '').isNotEmpty)
          SliverToBoxAdapter(child: Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Descripción',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
              const SizedBox(height: 8),
              Text(widget.producto['descripcion'],
                style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
            ]),
          )),

        // ── Especificaciones técnicas
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Especificaciones técnicas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
            const SizedBox(height: 4),
            const Text('Datos importantes para la entrega',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 14),
            _EspecRow(icono: Icons.inventory_2_outlined, label: 'Unidad de venta',
              valor: widget.producto['unidad'] ?? '-'),
            _EspecRow(icono: Icons.scale_outlined, label: 'Peso por unidad',
              valor: pesoKg > 0 ? '${pesoKg.toStringAsFixed(pesoKg < 1 ? 2 : 1)} kg' : 'No especificado'),
            _EspecRow(icono: Icons.view_in_ar_outlined, label: 'Volumen por unidad',
              valor: volumenM3 > 0 ? '${(volumenM3 * 1000).toStringAsFixed(1)} L' : 'No especificado'),
            _EspecRow(icono: _vehiculoIcono(vehiculo), label: 'Vehículo requerido',
              valor: _vehiculo(vehiculo), last: true),
          ]),
        )),

        // ── Info de entrega
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline, color: kAmber, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text(
              'El vehículo de entrega se asignará según el peso total de tu pedido.',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            )),
          ]),
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ]),

      // ── Bottom bar: agregar/quitar
      bottomNavigationBar: sinStock
        ? _BarraSinStock()
        : _BarraAgregar(cantidad: _cantidad, precio: precio, onAgregar: _agregar, onQuitar: _quitar),
    );
  }
}

class _BarraSinStock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Container(
      margin: const EdgeInsets.all(16),
      height: 54,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Text('Sin stock disponible',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 15))),
    ));
  }
}

class _BarraAgregar extends StatelessWidget {
  final int cantidad;
  final double precio;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;
  const _BarraAgregar({required this.cantidad, required this.precio, required this.onAgregar, required this.onQuitar});

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    if (cantidad == 0) {
      return SafeArea(child: Container(
        margin: const EdgeInsets.all(16),
        height: 54,
        child: ElevatedButton(
          onPressed: onAgregar,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAmber,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Agregar · \$${_fmt(precio)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ));
    }

    return SafeArea(child: Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAmber, width: 1.5),
        boxShadow: [BoxShadow(color: kAmber.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        // Quitar
        Expanded(child: GestureDetector(
          onTap: onQuitar,
          behavior: HitTestBehavior.opaque,
          child: const Center(child: Icon(Icons.remove, color: kAmber, size: 24)),
        )),
        // Cantidad + precio
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$cantidad',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kAmber)),
            Text('\$${_fmt(precio * cantidad)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
        // Agregar
        Expanded(child: GestureDetector(
          onTap: onAgregar,
          behavior: HitTestBehavior.opaque,
          child: const Center(child: Icon(Icons.add, color: kAmber, size: 24)),
        )),
      ]),
    ));
  }
}

class _EspecRow extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final bool last;
  const _EspecRow({required this.icono, required this.label, required this.valor, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(8)),
            child: Icon(icono, size: 18, color: kAmber),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
        ]),
      ),
      if (!last) const Divider(height: 1, color: Color(0xFFF0F0F0)),
    ]);
  }
}
