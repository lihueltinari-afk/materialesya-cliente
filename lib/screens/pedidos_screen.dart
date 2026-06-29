import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../services/api_service.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<dynamic> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final pedidos = await ApiService.misPedidos();
    if (mounted) setState(() { _pedidos = pedidos; _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: const Row(children: [
            Text('Mis pedidos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark)),
          ]),
        ),
        Expanded(child: _cargando
          ? const Center(child: CircularProgressIndicator(color: kAmber))
          : _pedidos.isEmpty
            ? _Empty()
            : RefreshIndicator(
                color: kAmber,
                onRefresh: _cargar,
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _pedidos.length,
                  itemBuilder: (_, i) => _PedidoCard(
                    pedido: _pedidos[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DetallePedidoScreen(pedidoId: _pedidos[i]['id']),
                    )),
                  ),
                ),
              ),
        ),
      ])),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_rounded, size: 48, color: kAmber),
      ),
      const SizedBox(height: 16),
      const Text('Todavía no hiciste pedidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextDark)),
      const SizedBox(height: 6),
      const Text('Explorá los locales y pedí materiales', style: TextStyle(color: Colors.grey, fontSize: 13)),
    ]));
  }
}

class _PedidoCard extends StatelessWidget {
  final dynamic pedido;
  final VoidCallback onTap;
  const _PedidoCard({required this.pedido, required this.onTap});

  static const _estados = {
    'pendiente':          ['Pendiente de confirmación', Color(0xFFFFF3E0), Color(0xFFE65100), Icons.schedule],
    'confirmado':         ['Confirmado',       Color(0xFFE3F2FD), Color(0xFF1565C0), Icons.check_circle_outline],
    'preparando':         ['Preparando',       Color(0xFFE3F2FD), Color(0xFF1565C0), Icons.inventory_2_outlined],
    'listo_para_retirar': ['Listo para despacho', Color(0xFFE8F5E9), Color(0xFF2E7D32), Icons.store_mall_directory_outlined],
    'en_camino':          ['En camino 🚚',     Color(0xFFE8F5E9), Color(0xFF2E7D32), Icons.local_shipping_outlined],
    'entregado':          ['Entregado ✓',      Color(0xFFF5F5F5), Color(0xFF757575), Icons.done_all],
    'cancelado':          ['Cancelado',        Color(0xFFFFEBEE), Color(0xFFC62828), Icons.cancel_outlined],
  };

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado'] as String? ?? 'pendiente';
    final info = _estados[estado] ?? ['Desconocido', const Color(0xFFF5F5F5), Colors.grey, Icons.help_outline];
    final label = info[0] as String;
    final bgColor = info[1] as Color;
    final fgColor = info[2] as Color;
    final icono = info[3] as IconData;
    final total = double.tryParse(pedido['total'].toString()) ?? 0;
    final fmt = total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final enCamino = estado == 'en_camino';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Barra de estado coloreada arriba
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Icon(icono, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fgColor)),
              const Spacer(),
              if (enCamino) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kSuccess, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.radio_button_checked, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text('En vivo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          // Contenido
          Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(pedido['comercio_nombre'] ?? 'Local', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark))),
              Text('Pedido #${pedido['id']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            const SizedBox(height: 6),
            Text(_formatFecha(pedido['creado_en']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 18),
            Row(children: [
              const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Total', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              Text('\$$fmt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextDark)),
            ]),
            if (enCamino) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kSuccessBg, borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.location_on, color: kSuccess, size: 16),
                  SizedBox(width: 6),
                  Text('Tocá para ver el repartidor en el mapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSuccess)),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 12, color: kSuccess),
                ]),
              ),
            ],
          ])),
        ]),
      ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      final meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${meses[dt.month - 1]} · ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

// ─── DETALLE PEDIDO CON MAPA ──────────────────────────────────────────────────
class DetallePedidoScreen extends StatefulWidget {
  final int pedidoId;
  const DetallePedidoScreen({super.key, required this.pedidoId});
  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  Map<String, dynamic>? _pedido;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final res = await ApiService.get('/pedidos/${widget.pedidoId}');
    if (mounted) setState(() { _pedido = res['data']; _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextDark), onPressed: () => Navigator.pop(context)),
        title: Text('Pedido #${widget.pedidoId}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: kAmber))
        : _pedido == null
          ? const Center(child: Text('No se encontró el pedido'))
          : _buildDetalle(),
    );
  }

  Widget _buildDetalle() {
    final p = _pedido!;
    final estado = p['estado'] as String? ?? 'pendiente';
    final enCamino = estado == 'en_camino';
    final items = p['items'] as List? ?? [];
    final total = double.tryParse(p['total'].toString()) ?? 0;
    final subtotal = double.tryParse(p['subtotal'].toString()) ?? 0;
    final costoEnvio = double.tryParse(p['costo_envio'].toString()) ?? 0;
    final fmt = (double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    // Coordenadas del comercio (Mendoza centro como fallback)
    final lat = double.tryParse(p['comercio_lat']?.toString() ?? '') ?? -32.8908;
    final lng = double.tryParse(p['comercio_lng']?.toString() ?? '') ?? -68.8272;

    return ListView(padding: EdgeInsets.zero, children: [
      // ── Mapa si está en camino, o mini-mapa de la ubicación del local
      SizedBox(
        height: enCamino ? 220 : 160,
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: enCamino ? 14 : 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.materialesya.app',
              ),
              MarkerLayer(markers: [
                // Marcador del local
                Marker(
                  point: LatLng(lat, lng),
                  width: 40, height: 40,
                  child: Container(
                    decoration: const BoxDecoration(color: kAmber, shape: BoxShape.circle),
                    child: const Icon(Icons.store, color: Colors.white, size: 20),
                  ),
                ),
                // Marcador simulado del repartidor (un poco al sur si está en camino)
                if (enCamino) Marker(
                  point: LatLng(lat + 0.008, lng + 0.005),
                  width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: kSuccess.withValues(alpha: 0.4), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ],
          ),
          if (enCamino) Positioned(bottom: 10, left: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)]),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delivery_dining, color: kSuccess, size: 16),
              SizedBox(width: 6),
              Text('Repartidor en camino', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kSuccess)),
            ]),
          )),
        ]),
      ),

      // ── Timeline de estado
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: _TimelineEstado(estado: estado),
      ),
      const SizedBox(height: 8),

      // ── Detalle del local y dirección
      Container(
        color: Colors.white, margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Detalles del pedido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 12),
          _DetalleRow(icono: Icons.store_outlined, label: 'Local', valor: p['comercio_nombre'] ?? ''),
          const SizedBox(height: 10),
          _DetalleRow(icono: Icons.location_on_outlined, label: 'Entrega en', valor: p['dir_entrega'] ?? ''),
          const SizedBox(height: 10),
          _DetalleRow(icono: Icons.payment_outlined, label: 'Pago', valor: _formatPago(p['metodo_pago'])),
        ]),
      ),
      const SizedBox(height: 8),

      // ── Items del pedido
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Productos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final precioU = double.tryParse(item['precio_unitario'].toString()) ?? 0;
            final sub = double.tryParse(item['subtotal'].toString()) ?? 0;
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.construction, color: kAmber, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['producto_nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('\$${fmt(precioU)} x ${item['cantidad']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Text('\$${fmt(sub)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
            ]));
          }),
          const Divider(height: 20),
          _LineaTotal('Subtotal', '\$${fmt(subtotal)}', negrita: false),
          const SizedBox(height: 6),
          _LineaTotal('Envío', '\$${fmt(costoEnvio)}', negrita: false),
          const Divider(height: 16),
          _LineaTotal('Total', '\$${fmt(total)}', negrita: true, grande: true),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  String _formatPago(dynamic v) {
    switch (v?.toString()) {
      case 'efectivo': return 'Efectivo';
      case 'transferencia': return 'Transferencia bancaria';
      case 'mercado_pago': return 'Mercado Pago';
      default: return v?.toString() ?? '';
    }
  }
}

class _DetalleRow extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  const _DetalleRow({required this.icono, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icono, size: 18, color: kAmber),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
      ])),
    ]);
  }
}

class _LineaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrita;
  final bool grande;
  const _LineaTotal(this.label, this.valor, {this.negrita = false, this.grande = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(fontSize: grande ? 15 : 13,
        fontWeight: negrita ? FontWeight.w800 : FontWeight.w400, color: grande ? kTextDark : Colors.grey)),
      const Spacer(),
      Text(valor, style: TextStyle(fontSize: grande ? 20 : 14,
        fontWeight: FontWeight.w900, color: grande ? kAmber : kTextDark)),
    ]);
  }
}

// ─── TIMELINE DE ESTADO ───────────────────────────────────────────────────────
class _TimelineEstado extends StatelessWidget {
  final String estado;
  const _TimelineEstado({required this.estado});

  static const _pasos = [
    ['pendiente',    'Pedido recibido',    Icons.receipt_outlined],
    ['confirmado',   'Confirmado',         Icons.check_circle_outline],
    ['preparando',   'Preparando',         Icons.inventory_2_outlined],
    ['en_camino',    'En camino',          Icons.local_shipping_outlined],
    ['entregado',    'Entregado',          Icons.done_all],
  ];

  int get _indiceActual {
    for (int i = 0; i < _pasos.length; i++) {
      if (_pasos[i][0] == estado) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (estado == 'cancelado') {
      return Row(children: [
        Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
          child: const Icon(Icons.cancel, color: Color(0xFFC62828), size: 18)),
        const SizedBox(width: 10),
        const Text('Pedido cancelado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
      ]);
    }

    final actual = _indiceActual;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Estado del pedido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
      const SizedBox(height: 14),
      Row(children: List.generate(_pasos.length, (i) {
        final done = i <= actual;
        final current = i == actual;
        return Expanded(child: Row(children: [
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done ? kAmber : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: current ? Border.all(color: kAmber, width: 2) : null,
                boxShadow: current ? [BoxShadow(color: kAmber.withValues(alpha: 0.3), blurRadius: 6)] : null,
              ),
              child: Icon(_pasos[i][2] as IconData, size: 14, color: done ? Colors.white : Colors.grey.shade400),
            ),
            const SizedBox(height: 4),
            SizedBox(width: 54, child: Text(_pasos[i][1] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: current ? FontWeight.w800 : FontWeight.w400,
                color: done ? kAmber : Colors.grey.shade400))),
          ]),
          if (i < _pasos.length - 1) Expanded(child: Container(
            height: 2, margin: const EdgeInsets.only(bottom: 20),
            color: i < actual ? kAmber : Colors.grey.shade200,
          )),
        ]));
      })),
    ]);
  }
}
