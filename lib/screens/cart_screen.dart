import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/api_service.dart';
import 'pedidos_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<int, Map<String, dynamic>> carrito;
  final Map<String, dynamic> comercio;
  final void Function(Map<int, Map<String, dynamic>>) onActualizar;
  final VoidCallback? onVerPedidos;
  const CartScreen({super.key, required this.carrito, required this.comercio, required this.onActualizar, this.onVerPedidos});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<int, Map<String, dynamic>> _carrito;
  int _paso = 0; // 0=carrito 1=dirección 2=pago 3=confirmar
  final _dirCtrl = TextEditingController();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresá una dirección de entrega'), backgroundColor: kWarning));
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
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => _ConfirmacionScreen(
          pedidoId: pedidoId,
          comercio: widget.comercio['nombre'] ?? '',
          total: _total,
          metodoPago: _metodoPago,
          dirEntrega: _dirCtrl.text.trim(),
          onVerPedidos: widget.onVerPedidos,
        )),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextDark),
          onPressed: () {
            if (_paso > 0) setState(() => _paso--);
            else Navigator.pop(context);
          },
        ),
        title: Text(_tituloPaso(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _BarraProgreso(paso: _paso, total: 4),
        ),
      ),
      body: _carrito.isEmpty && _paso == 0
        ? _CarritoVacio()
        : _buildPaso(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _tituloPaso() {
    switch (_paso) {
      case 0: return 'Mi carrito';
      case 1: return 'Dirección de entrega';
      case 2: return 'Método de pago';
      case 3: return 'Confirmar pedido';
      default: return '';
    }
  }

  Widget _buildPaso() {
    switch (_paso) {
      case 0: return _PasoCarrito(carrito: _carrito, comercio: widget.comercio, fmt: _fmt, onCambiar: _cambiarCant);
      case 1: return _PasoDireccion(ctrl: _dirCtrl);
      case 2: return _PasoPago(metodo: _metodoPago, onCambiar: (m) => setState(() => _metodoPago = m));
      case 3: return _PasoConfirmar(
          carrito: _carrito, comercio: widget.comercio,
          dir: _dirCtrl.text, metodo: _metodoPago,
          subtotal: _subtotal, costoEnvio: _costoEnvio, total: _total, fmt: _fmt);
      default: return const SizedBox();
    }
  }

  Widget _buildBottomBar() {
    if (_carrito.isEmpty && _paso == 0) return const SizedBox(height: 0);

    final esUltimo = _paso == 3;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Total del pedido', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const Spacer(),
            Text('\$${_fmt(_total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextDark)),
          ]),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: esUltimo ? (_enviando ? null : _confirmar) : () => setState(() => _paso++),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAmber,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _enviando
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    esUltimo ? 'Confirmar y pagar' : 'Continuar',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Icon(esUltimo ? Icons.lock_outline : Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ─── BARRA DE PROGRESO ────────────────────────────────────────────────────────
class _BarraProgreso extends StatelessWidget {
  final int paso;
  final int total;
  const _BarraProgreso({required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(total, (i) => Expanded(child: Container(
      height: 3,
      margin: EdgeInsets.only(left: i > 0 ? 2 : 0),
      color: i <= paso ? kAmber : const Color(0xFFEEEEEE),
    ))));
  }
}

// ─── PASO 0: CARRITO ─────────────────────────────────────────────────────────
class _PasoCarrito extends StatelessWidget {
  final Map<int, Map<String, dynamic>> carrito;
  final Map<String, dynamic> comercio;
  final String Function(double) fmt;
  final void Function(int, int) onCambiar;
  const _PasoCarrito({required this.carrito, required this.comercio, required this.fmt, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    final subtotal = carrito.values.fold<double>(0, (a, b) => a + (b['precio'] as double) * (b['cantidad'] as int));
    final costoEnvio = double.tryParse(comercio['costo_envio'].toString()) ?? 0;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Icon(Icons.store_outlined, size: 16, color: kAmber),
        const SizedBox(width: 6),
        Text(comercio['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
      ]),
      const SizedBox(height: 12),
      ...carrito.entries.map((e) {
        final item = e.value;
        final id = e.key;
        final cant = item['cantidad'] as int;
        final precio = item['precio'] as double;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.construction, color: kAmber, size: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('\$${fmt(precio)} c/u', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            Container(
              decoration: BoxDecoration(border: Border.all(color: kAmber), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: () => onCambiar(id, -1), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Icon(Icons.remove, size: 16, color: kAmber))),
                SizedBox(width: 28, child: Center(child: Text('$cant', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kAmber)))),
                GestureDetector(onTap: () => onCambiar(id, 1), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Icon(Icons.add, size: 16, color: kAmber))),
              ]),
            ),
          ]),
        );
      }),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
        child: Column(children: [
          _Linea('Subtotal', '\$${fmt(subtotal)}'),
          const SizedBox(height: 6),
          _Linea('Costo de envío', costoEnvio == 0 ? 'Gratis' : '\$${fmt(costoEnvio)}',
            colorVal: costoEnvio == 0 ? kSuccess : null),
        ]),
      ),
    ]);
  }
}

// ─── PASO 1: DIRECCIÓN ────────────────────────────────────────────────────────
class _PasoDireccion extends StatefulWidget {
  final TextEditingController ctrl;
  const _PasoDireccion({required this.ctrl});
  @override
  State<_PasoDireccion> createState() => _PasoDireccionState();
}

class _PasoDireccionState extends State<_PasoDireccion> {
  List<String> _direcciones = [];
  final _mapCtrl = MapController();
  LatLng _centro = const LatLng(-32.8908, -68.8272); // Mendoza
  LatLng? _pin;
  bool _geocodificando = false;
  bool _buscandoUbicacion = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarDirecciones() async {
    final prefs = await SharedPreferences.getInstance();
    final dirs = prefs.getStringList('direcciones') ?? [];
    if (mounted) setState(() => _direcciones = dirs);
    if (widget.ctrl.text.trim().isEmpty && dirs.isNotEmpty) {
      widget.ctrl.text = dirs.first;
      _geocodificar(dirs.first);
    }
  }

  void _onCambioTexto(String texto) {
    setState(() {});
    _debounce?.cancel();
    if (texto.trim().length < 5) return;
    _debounce = Timer(const Duration(milliseconds: 1200), () => _geocodificar(texto));
  }

  Future<void> _geocodificar(String direccion) async {
    if (direccion.trim().isEmpty) return;
    setState(() => _geocodificando = true);
    try {
      final query = Uri.encodeComponent('$direccion, Mendoza, Argentina');
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&countrycodes=ar'),
        headers: {'User-Agent': 'MaterialesYaApp/1.0 (materialesya@gmail.com)'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty && mounted) {
          final lat = double.parse(data[0]['lat'].toString());
          final lon = double.parse(data[0]['lon'].toString());
          setState(() { _pin = LatLng(lat, lon); _centro = _pin!; });
          _mapCtrl.move(_pin!, 15);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocodificando = false);
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _buscandoUbicacion = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activá el GPS para usar tu ubicación'), backgroundColor: kWarning));
        setState(() => _buscandoUbicacion = false);
        return;
      }
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          setState(() => _buscandoUbicacion = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() { _pin = LatLng(pos.latitude, pos.longitude); _centro = _pin!; });
      _mapCtrl.move(_pin!, 16);
      // Reverse geocode para completar el campo de texto
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json'),
        headers: {'User-Agent': 'MaterialesYaApp/1.0'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final address = data['address'];
        final calle = address['road'] ?? '';
        final numero = address['house_number'] ?? '';
        final dir = '$calle${numero.isNotEmpty ? ' $numero' : ''}, Mendoza'.trim();
        widget.ctrl.text = dir;
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu ubicación'), backgroundColor: kError));
    }
    if (mounted) setState(() => _buscandoUbicacion = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Direcciones guardadas
      if (_direcciones.isNotEmpty) ...[
        const Text('Mis direcciones guardadas',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextGrey)),
        const SizedBox(height: 8),
        ..._direcciones.map((dir) {
          final sel = widget.ctrl.text.trim() == dir.trim();
          return GestureDetector(
            onTap: () {
              setState(() => widget.ctrl.text = dir);
              _geocodificar(dir);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? kAmber.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? kAmber : Colors.grey.shade200, width: sel ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(Icons.location_on_rounded, color: sel ? kAmber : Colors.grey, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(dir,
                  style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? kAmber : kTextDark))),
                if (sel) const Icon(Icons.check_circle_rounded, color: kAmber, size: 18),
              ]),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('o ingresá otra dirección', style: TextStyle(fontSize: 11, color: Colors.grey))),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
      ],

      // Campo manual
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.location_on, color: kAmber, size: 20),
            SizedBox(width: 8),
            Text('¿Dónde entregamos?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          ]),
          const SizedBox(height: 4),
          const Text('Incluí piso o departamento si aplica.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.ctrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
            onChanged: _onCambioTexto,
            decoration: InputDecoration(
              hintText: 'Ej: Av. San Martín 1234, Mendoza',
              prefixIcon: const Icon(Icons.home_outlined, color: kAmber),
              filled: true, fillColor: kBgPage,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAmber)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: _geocodificando
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kAmber)))
                : null,
            ),
          ),
          const SizedBox(height: 10),
          // Botón usar ubicación actual
          OutlinedButton.icon(
            onPressed: _buscandoUbicacion ? null : _usarMiUbicacion,
            icon: _buscandoUbicacion
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kAmber))
              : const Icon(Icons.my_location_rounded, color: kAmber, size: 16),
            label: Text(_buscandoUbicacion ? 'Obteniendo ubicación...' : 'Usar mi ubicación actual',
              style: const TextStyle(color: kAmber, fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kAmber),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 16),

      // Mapa con OpenStreetMap
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 200,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _centro,
                initialZoom: 13,
                onTap: (tapPos, point) {
                  setState(() => _pin = point);
                  // Reverse geocode al tocar el mapa
                  _reverseGeocode(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.materialesya.app',
                ),
                if (_pin != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _pin!,
                      width: 40, height: 40,
                      child: const Icon(Icons.location_on, color: kAmber, size: 40),
                    ),
                  ]),
              ],
            ),
            // Overlay: instrucción
            Positioned(
              top: 8, left: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: kAmber),
                  SizedBox(width: 6),
                  Text('Tocá el mapa para ajustar la ubicación exacta',
                    style: TextStyle(fontSize: 11, color: kTextGrey)),
                ]),
              ),
            ),
          ]),
        ),
      ),

      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: kAmber, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
            'El repartidor te contactará si necesita indicaciones adicionales.',
            style: TextStyle(fontSize: 11, color: kAmber, height: 1.4),
          )),
        ]),
      ),
    ]);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json'),
        headers: {'User-Agent': 'MaterialesYaApp/1.0'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final address = data['address'];
        final calle = address?['road'] ?? '';
        final numero = address?['house_number'] ?? '';
        final dir = '$calle${numero.isNotEmpty ? ' $numero' : ''}, Mendoza'.trim();
        if (dir.trim().isNotEmpty && dir.trim() != ', Mendoza') {
          widget.ctrl.text = dir;
          setState(() {});
        }
      }
    } catch (_) {}
  }
}

// ─── PASO 2: PAGO ─────────────────────────────────────────────────────────────
class _PasoPago extends StatelessWidget {
  final String metodo;
  final void Function(String) onCambiar;
  const _PasoPago({required this.metodo, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {'id': 'efectivo', 'label': 'Efectivo', 'desc': 'Pagás al repartidor al recibir', 'icono': Icons.money, 'disponible': true},
      {'id': 'transferencia', 'label': 'Transferencia bancaria', 'desc': 'Te enviamos el alias por WhatsApp', 'icono': Icons.account_balance_outlined, 'disponible': true},
      {'id': 'mercado_pago', 'label': 'Mercado Pago', 'desc': 'Pagá online con tarjeta o saldo', 'icono': Icons.payment_outlined, 'disponible': false},
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('¿Cómo querés pagar?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextDark)),
      const SizedBox(height: 4),
      const Text('Seleccioná un método de pago para tu pedido',
        style: TextStyle(fontSize: 13, color: Colors.grey)),
      const SizedBox(height: 16),
      ...opciones.map((op) {
        final sel = metodo == op['id'];
        final disponible = op['disponible'] as bool;
        return GestureDetector(
          onTap: disponible ? () => onCambiar(op['id'] as String) : null,
          child: Opacity(
            opacity: disponible ? 1 : 0.5,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? kAmber : Colors.grey.shade200, width: sel ? 2 : 1),
                boxShadow: sel ? [BoxShadow(color: kAmber.withValues(alpha: 0.1), blurRadius: 8)] : null,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel ? kAmber.withValues(alpha: 0.1) : kBgPage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(op['icono'] as IconData, color: sel ? kAmber : Colors.grey, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(op['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: sel ? kAmber : kTextDark)),
                    if (!disponible) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Pronto', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(op['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                if (sel) const Icon(Icons.check_circle, color: kAmber, size: 22)
                else const Icon(Icons.circle_outlined, color: Color(0xFFDDDDDD), size: 22),
              ]),
            ),
          ),
        );
      }),
    ]);
  }
}

// ─── PASO 3: CONFIRMAR ────────────────────────────────────────────────────────
class _PasoConfirmar extends StatelessWidget {
  final Map<int, Map<String, dynamic>> carrito;
  final Map<String, dynamic> comercio;
  final String dir;
  final String metodo;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final String Function(double) fmt;
  const _PasoConfirmar({required this.carrito, required this.comercio, required this.dir,
    required this.metodo, required this.subtotal, required this.costoEnvio, required this.total, required this.fmt});

  String _nombreMetodo(String m) {
    switch (m) {
      case 'efectivo': return 'Efectivo';
      case 'transferencia': return 'Transferencia bancaria';
      case 'mercado_pago': return 'Mercado Pago';
      default: return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resumen del pedido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 14),
          ...carrito.entries.map((e) {
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.construction, color: kAmber, size: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('x${item['cantidad']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                Text('\$${fmt((item['precio'] as double) * (item['cantidad'] as int))}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
              ]),
            );
          }),
          const Divider(height: 20),
          _Linea('Subtotal', '\$${fmt(subtotal)}'),
          const SizedBox(height: 6),
          _Linea('Costo de envío', costoEnvio == 0 ? 'Gratis' : '\$${fmt(costoEnvio)}',
            colorVal: costoEnvio == 0 ? kSuccess : null),
          const Divider(height: 16),
          Row(children: [
            const Text('Total a pagar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
            const Spacer(),
            Text('\$${fmt(total)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kAmber)),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      _TarjetaInfo(icono: Icons.location_on_outlined, titulo: 'Entrega en', contenido: dir),
      const SizedBox(height: 10),
      _TarjetaInfo(icono: Icons.payment_outlined, titulo: 'Método de pago', contenido: _nombreMetodo(metodo)),
      const SizedBox(height: 10),
      _TarjetaInfo(icono: Icons.store_outlined, titulo: 'Comercio', contenido: comercio['nombre'] ?? ''),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Al confirmar, el comercio recibirá tu pedido y comenzará a prepararlo.',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
          )),
        ]),
      ),
    ]);
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────────
class _TarjetaInfo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String contenido;
  const _TarjetaInfo({required this.icono, required this.titulo, required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: kAmber, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(contenido, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark)),
        ])),
      ]),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
      SizedBox(height: 12),
      Text('Tu carrito está vacío', style: TextStyle(fontSize: 16, color: Colors.grey)),
    ]));
  }
}

Widget _Linea(String label, String valor, {Color? colorVal}) => Row(children: [
  Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
  const Spacer(),
  Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorVal ?? kTextDark)),
]);

// ─── PANTALLA DE CONFIRMACIÓN FINAL ──────────────────────────────────────────
class _ConfirmacionScreen extends StatelessWidget {
  final int pedidoId;
  final String comercio;
  final double total;
  final String metodoPago;
  final String dirEntrega;
  final VoidCallback? onVerPedidos;
  const _ConfirmacionScreen({
    required this.pedidoId, required this.comercio,
    required this.total, required this.metodoPago, required this.dirEntrega,
    this.onVerPedidos});

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 110, height: 110,
              decoration: const BoxDecoration(color: kSuccessBg, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: kSuccess, size: 66),
            ),
          ),
          const SizedBox(height: 28),
          const Text('¡Pedido confirmado!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kTextDark)),
          const SizedBox(height: 10),
          Text('Tu pedido #$pedidoId en $comercio\nestá siendo preparado.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgPage, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              _RowInfo('Pedido', '#$pedidoId'),
              const Divider(height: 16),
              _RowInfo('Total', '\$${_fmt(total)}', bold: true),
              const Divider(height: 16),
              _RowInfo('Pago', _fmtMetodo(metodoPago)),
              const Divider(height: 16),
              _RowInfo('Entrega en', dirEntrega),
            ]),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              onVerPedidos?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAmber,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Ver estado del pedido',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Seguir comprando', style: TextStyle(color: kAmber, fontWeight: FontWeight.w700)),
          ),
        ]),
      )),
    );
  }

  String _fmtMetodo(String m) {
    switch (m) {
      case 'efectivo': return 'Efectivo';
      case 'transferencia': return 'Transferencia bancaria';
      case 'mercado_pago': return 'Mercado Pago';
      default: return m;
    }
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String valor;
  final bool bold;
  const _RowInfo(this.label, this.valor, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    const Spacer(),
    Flexible(child: Text(valor, textAlign: TextAlign.right,
      style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        color: bold ? kAmber : kTextDark))),
  ]);
}
