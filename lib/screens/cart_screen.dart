import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final Map<int, Map<String, dynamic>> carrito;
  final Map<String, dynamic> comercio;
  final void Function(Map<int, Map<String, dynamic>>) onActualizar;
  const CartScreen({super.key, required this.carrito, required this.comercio, required this.onActualizar});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<int, Map<String, dynamic>> _carrito;
  final _dirCtrl = TextEditingController(text: 'Av. San Martín 1234, Mendoza');
  String _metodoPago = 'efectivo';
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carrito = Map.from(widget.carrito);
  }

  double get _subtotal => _carrito.values.fold(0, (a, b) => a + (b['precio'] as double) * (b['cantidad'] as int));
  double get _costoEnvio => double.tryParse(widget.comercio['costo_envio'].toString()) ?? 0;
  double get _total => _subtotal + _costoEnvio;

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  void _cambiarCant(int id, int delta) {
    setState(() {
      final cant = (_carrito[id]!['cantidad'] as int) + delta;
      if (cant <= 0) { _carrito.remove(id); } else { _carrito[id]!['cantidad'] = cant; }
    });
    widget.onActualizar(_carrito);
  }

  Future<void> _confirmar() async {
    if (_carrito.isEmpty) return;
    if (_dirCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá una dirección de entrega'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _enviando = true);

    final items = _carrito.entries.map((e) => {
      'comercio_producto_id': e.key,
      'cantidad': e.value['cantidad'],
    }).toList();

    final res = await ApiService.post('/pedidos', {
      'comercio_id': widget.comercio['id'],
      'items': items,
      'dir_entrega': _dirCtrl.text.trim(),
      'metodo_pago': _metodoPago,
    });

    if (!mounted) return;
    setState(() => _enviando = false);

    if (res['status'] == 201) {
      final pedidoId = res['data']['id'];
      widget.onActualizar({});
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => _ConfirmacionScreen(pedidoId: pedidoId, comercio: widget.comercio['nombre'] ?? '')),
        (route) => route.isFirst,
      );
    } else {
      final msg = res['data']?['error'] ?? 'Error al crear el pedido';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Mi carrito', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
      ),
      body: _carrito.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('Tu carrito está vacío', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Nombre del local
              Text(widget.comercio['nombre'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              // Items
              ..._carrito.entries.map((e) {
                final item = e.value;
                final id = e.key;
                final cant = item['cantidad'] as int;
                final precio = item['precio'] as double;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.construction, color: kAmber, size: 22)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('\$${_fmt(precio * cant)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAmber)),
                    ])),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: kAmber), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(onTap: () => _cambiarCant(id, -1), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Icon(Icons.remove, size: 16, color: kAmber))),
                        Text('$cant', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAmber)),
                        GestureDetector(onTap: () => _cambiarCant(id, 1), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Icon(Icons.add, size: 16, color: kAmber))),
                      ]),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 8),
              // Resumen de precios
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                child: Column(children: [
                  _linea('Subtotal', '\$${_fmt(_subtotal)}'),
                  const SizedBox(height: 6),
                  _linea('Costo de envío', _costoEnvio == 0 ? 'Gratis' : '\$${_fmt(_costoEnvio)}', colorVal: _costoEnvio == 0 ? kSuccess : null),
                  const Divider(height: 18),
                  Row(children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                    const Spacer(),
                    Text('\$${_fmt(_total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kAmber)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              // Dirección
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.location_on_outlined, color: kAmber, size: 18),
                    SizedBox(width: 6),
                    Text('Dirección de entrega', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark)),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dirCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Calle Falsa 123, Mendoza',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Método de pago
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.credit_card_outlined, color: kAmber, size: 18),
                    SizedBox(width: 6),
                    Text('Método de pago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _chipPago('efectivo', 'Efectivo', Icons.money),
                    _chipPago('transferencia', 'Transferencia', Icons.account_balance_outlined),
                    _chipPago('mercado_pago', 'Mercado Pago', Icons.payment),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando ? null : _confirmar,
                child: _enviando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirmar pedido · \$${_fmt(_total)}'),
              ),
              const SizedBox(height: 16),
            ]),
    );
  }

  Widget _linea(String label, String valor, {Color? colorVal}) {
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      const Spacer(),
      Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorVal ?? kTextDark)),
    ]);
  }

  Widget _chipPago(String value, String label, IconData icono) {
    final sel = _metodoPago == value;
    return GestureDetector(
      onTap: () => setState(() => _metodoPago = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? kAmber.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? kAmber : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 14, color: sel ? kAmber : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? kAmber : Colors.grey)),
        ]),
      ),
    );
  }
}

// ─── PANTALLA DE CONFIRMACIÓN ─────────────────────────────────────────────────
class _ConfirmacionScreen extends StatelessWidget {
  final int pedidoId;
  final String comercio;
  const _ConfirmacionScreen({required this.pedidoId, required this.comercio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: kSuccessBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: kSuccess, size: 60),
          ),
          const SizedBox(height: 24),
          const Text('¡Pedido confirmado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kTextDark)),
          const SizedBox(height: 8),
          Text('Tu pedido #$pedidoId en $comercio está siendo preparado.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Seguir comprando'),
          ),
        ]),
      )),
    );
  }
}
