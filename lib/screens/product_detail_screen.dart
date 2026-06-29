import 'package:flutter/material.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map producto;
  final VoidCallback onAgregar;
  const ProductDetailScreen({super.key, required this.producto, required this.onAgregar});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final precio = (p['precio'] as double);
    final total = precio * _cantidad;
    String fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      backgroundColor: kBgPage,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: kTextDark)),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: kBgPage,
              child: Center(child: Icon(p['icono'] as IconData, size: 90, color: Colors.grey.shade300)),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kSuccessBg, borderRadius: BorderRadius.circular(20)), child: const Text('En stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSuccess))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: Text('Entrega: ${p['vehiculo']}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
            ]),
            const SizedBox(height: 10),
            Text(p['marca'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kAmber, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(p['nombre'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark, height: 1.2)),
            const SizedBox(height: 4),
            Text(p['unidad'] as String, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Text('\$${fmt(precio)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
            const SizedBox(height: 4),
            Text('por ${p['unidad']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        )),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Descripción', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 8),
            Text(p['desc'] as String, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
          ]),
        )),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Detalles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 12),
            _detalle('Peso', p['peso'] as String, Icons.scale_outlined),
            _detalle('Stock disponible', '${p['stock']} unidades', Icons.inventory_outlined),
            _detalle('Vehículo mínimo', p['vehiculo'] as String, Icons.local_shipping_outlined),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Cantidad:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () { if (_cantidad > 1) setState(() => _cantidad--); }),
                Text('$_cantidad', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.add, size: 18, color: kAmber), onPressed: () => setState(() => _cantidad++)),
              ]),
            ),
            const SizedBox(width: 12),
            Text('\$${fmt(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () { for (var i = 0; i < _cantidad; i++) { widget.onAgregar(); } Navigator.pop(context); },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('Agregar al carrito · \$${fmt(total)}'),
          ),
        ]),
      ),
    );
  }

  Widget _detalle(String label, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icono, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
      ]),
    );
  }
}
