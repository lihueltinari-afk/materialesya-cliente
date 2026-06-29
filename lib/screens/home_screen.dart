import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'comercio_screen.dart';
import 'cart_screen.dart';
import 'pedidos_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final Map<int, Map<String, dynamic>> _carrito = {};

  int get _totalCarrito => _carrito.values.fold(0, (a, b) => a + (b['cantidad'] as int));

  @override
  void initState() {
    super.initState();
    _cargarCarritoGuardado();
  }

  Future<void> _cargarCarritoGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('carrito');
    if (json != null) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      setState(() {
        _carrito.clear();
        map.forEach((k, v) => _carrito[int.parse(k)] = Map<String, dynamic>.from(v));
      });
    }
  }

  Future<void> _guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final e in _carrito.entries) e.key.toString(): e.value};
    await prefs.setString('carrito', jsonEncode(map));
  }

  Map<int, Map<String, dynamic>> _carritoDeComercio(int comercioId) =>
      Map.fromEntries(_carrito.entries.where((e) => e.value['comercio_id'] == comercioId));

  void _agregarAlCarrito(Map<String, dynamic> item) {
    setState(() {
      final id = item['id'] as int;
      if (_carrito.containsKey(id)) {
        _carrito[id]!['cantidad'] = (_carrito[id]!['cantidad'] as int) + 1;
      } else {
        _carrito[id] = {...item, 'cantidad': 1};
      }
    });
    _guardarCarrito();
  }

  void _irAlCarrito() {
    if (_carrito.isEmpty) return;
    final primer = _carrito.values.first;
    final comercio = {
      'id': primer['comercio_id'],
      'nombre': primer['comercio_nombre'] ?? '',
      'costo_envio': primer['costo_envio'] ?? 0,
    };
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CartScreen(
        carrito: _carrito,
        comercio: comercio,
        onActualizar: (n) { setState(() { _carrito.clear(); _carrito.addAll(n); }); _guardarCarrito(); },
        onVerPedidos: () => setState(() => _navIndex = 2),
      ),
    ));
  }

  void _abrirComercio(Map<String, dynamic> c) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ComercioScreen(
        comercio: c,
        onAgregar: _agregarAlCarrito,
        carritoInicial: _carritoDeComercio(c['id'] as int),
        onVerPedidos: () => setState(() => _navIndex = 2),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _InicioTab(
        carritoCount: _totalCarrito,
        onVerComercio: _abrirComercio,
        onCarritoTap: _irAlCarrito,
        onBuscarTap: () => setState(() => _navIndex = 1),
      ),
      _BuscarTab(onVerComercio: _abrirComercio),
      const PedidosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: kBgPage,
      body: IndexedStack(index: _navIndex, children: screens),
      bottomNavigationBar: _BottomNav(index: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final void Function(int) onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, 'Inicio'),
      (Icons.search_rounded, Icons.search_outlined, 'Buscar'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Pedidos'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Mi perfil'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(top: false, child: SizedBox(
        height: 60,
        child: Row(children: List.generate(items.length, (i) {
          final sel = i == index;
          return Expanded(child: GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(sel ? items[i].$1 : items[i].$2, size: 24, color: sel ? kAmber : const Color(0xFFBBBBBB)),
              const SizedBox(height: 2),
              Text(items[i].$3, style: TextStyle(fontSize: 10,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? kAmber : const Color(0xFFBBBBBB))),
            ]),
          ));
        })),
      )),
    );
  }
}

// ─── MAPA EMOJIS PARA LAS 8 CATEGORÍAS ───────────────────────────────────────
String _emojiCategoria(String nombre) {
  switch (nombre.toLowerCase()) {
    case 'materiales de construcción': return '🧱';
    case 'pinturas y revestimientos':  return '🎨';
    case 'herramientas':               return '🔧';
    case 'electricidad':               return '⚡';
    case 'plomería y sanitarios':      return '🚿';
    case 'maquinaria y equipos':       return '⚙️';
    case 'tornillería y fijaciones':   return '🔩';
    case 'seguridad personal':         return '🦺';
    default:                           return '🏗️';
  }
}

// ─── TAB INICIO ───────────────────────────────────────────────────────────────
class _InicioTab extends StatefulWidget {
  final int carritoCount;
  final void Function(Map<String, dynamic>) onVerComercio;
  final VoidCallback onCarritoTap;
  final VoidCallback onBuscarTap;
  const _InicioTab({required this.carritoCount, required this.onVerComercio, required this.onCarritoTap, required this.onBuscarTap});
  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  List<dynamic> _comercios = [];
  List<Map<String, dynamic>> _categorias = [];
  List<dynamic> _pedidosRecientes = [];
  bool _cargando = true;
  int _catSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    final results = await Future.wait([
      ApiService.get('/comercio/categorias'),
      ApiService.get('/comercio/lista'),
      ApiService.get('/pedidos/mis-pedidos'),
    ]);
    if (!mounted) return;
    setState(() {
      _categorias = results[0]['data'] is List
          ? List<Map<String, dynamic>>.from(results[0]['data'])
          : [];
      _comercios = results[1]['data'] is List ? results[1]['data'] : [];
      final pedidos = results[2]['data'] is List ? results[2]['data'] as List : [];
      _pedidosRecientes = pedidos.take(2).toList();
      _cargando = false;
    });
  }

  Future<void> _cargar({int? categoriaId}) async {
    setState(() => _cargando = true);
    final path = categoriaId != null ? '/comercio/lista?categoria_id=$categoriaId' : '/comercio/lista';
    final res = await ApiService.get(path);
    if (mounted) setState(() { _comercios = res['data'] is List ? res['data'] : []; _cargando = false; });
  }

  void _seleccionarCategoria(int idx) {
    setState(() => _catSeleccionada = idx);
    if (idx == 0) { _cargar(); }
    else { _cargar(categoriaId: _categorias[idx - 1]['id'] as int); }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kAmber,
      onRefresh: _cargarTodo,
      child: CustomScrollView(slivers: [
        // ── AppBar
        SliverAppBar(
          pinned: true,
          backgroundColor: kAmber,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 110,
          flexibleSpace: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                const Text('Mendoza, Argentina', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCarritoTap,
                  child: Stack(children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
                    if (widget.carritoCount > 0)
                      Positioned(right: 0, top: 0, child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(child: Text('${widget.carritoCount}',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kAmber))),
                      )),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: widget.onBuscarTap,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 20),
                    SizedBox(width: 8),
                    Text('Buscar locales o materiales...', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          )),
        ),

        // ── Categorías
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              _CategoriaChip(emoji: '🏗️', label: 'Todos', seleccionado: _catSeleccionada == 0,
                onTap: () => _seleccionarCategoria(0)),
              ..._categorias.asMap().entries.map((e) => _CategoriaChip(
                emoji: _emojiCategoria(e.value['nombre'] as String),
                label: e.value['nombre'] as String,
                seleccionado: _catSeleccionada == e.key + 1,
                onTap: () => _seleccionarCategoria(e.key + 1),
              )),
            ]),
          ),
        )),

        // ── Banners carrusel
        const SliverToBoxAdapter(child: _BannerCarrusel()),

        // ── Volver a pedir (si hay pedidos anteriores)
        if (_pedidosRecientes.isNotEmpty && _catSeleccionada == 0) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Row(children: [
              const Text('Volver a pedir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kTextDark)),
              const SizedBox(width: 6),
              const Text('🔄', style: TextStyle(fontSize: 14)),
            ]),
          )),
          SliverToBoxAdapter(child: SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _pedidosRecientes.length,
              itemBuilder: (_, i) {
                final p = _pedidosRecientes[i];
                return GestureDetector(
                  onTap: () {}, // TODO: navegar a detalle del pedido
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.store_rounded, color: kAmber, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(p['comercio_nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('\$${_fmt(double.tryParse(p['total'].toString()) ?? 0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ])),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ]),
                  ),
                );
              },
            ),
          )),
        ],

        // ── Título locales
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          child: Row(children: [
            Text(_catSeleccionada == 0 ? 'Locales cercanos' : _categorias[_catSeleccionada - 1]['nombre'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kTextDark)),
            const Spacer(),
            if (!_cargando)
              Text('${_comercios.length} ${_comercios.length == 1 ? 'local' : 'locales'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        )),

        // ── Lista locales
        if (_cargando)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kAmber)))
        else if (_comercios.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.store_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No hay locales en esta categoría', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ])))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _LocalCard(comercio: _comercios[i], onTap: () => widget.onVerComercio(_comercios[i])),
            childCount: _comercios.length,
          )),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ]),
    );
  }
}

// ─── CHIPS DE CATEGORÍA ───────────────────────────────────────────────────────
class _CategoriaChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;
  const _CategoriaChip({required this.emoji, required this.label, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? kAmber : kBgPage,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: seleccionado ? Colors.white : const Color(0xFF444444))),
        ]),
      ),
    );
  }
}

// ─── BANNERS CARRUSEL ─────────────────────────────────────────────────────────
class _BannerCarrusel extends StatefulWidget {
  const _BannerCarrusel();
  @override
  State<_BannerCarrusel> createState() => _BannerCarruselState();
}

class _BannerCarruselState extends State<_BannerCarrusel> {
  int _pagina = 0;
  final _ctrl = PageController();

  static const _banners = [
    { 'titulo': 'Primer pedido con envío gratis', 'sub': 'Solo para nuevos usuarios', 'emoji': '🚚', 'color': Color(0xFF1E3A5F) },
    { 'titulo': 'Entrega el mismo día', 'sub': 'Pedidos antes de las 14 hs', 'emoji': '⚡', 'color': Color(0xFFB45309) },
    { 'titulo': 'Los mejores corralones', 'sub': 'Materiales de primera calidad', 'emoji': '🏗️', 'color': Color(0xFF2E7D32) },
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 100,
        child: PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _pagina = i),
          itemCount: _banners.length,
          itemBuilder: (_, i) {
            final b = _banners[i];
            return Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: b['color'] as Color, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b['titulo'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(b['sub'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ])),
                Text(b['emoji'] as String, style: const TextStyle(fontSize: 40)),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length, (i) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _pagina == i ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _pagina == i ? kAmber : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      )),
    ]);
  }
}

// ─── TARJETA LOCAL ────────────────────────────────────────────────────────────
class _LocalCard extends StatelessWidget {
  final dynamic comercio;
  final VoidCallback onTap;
  const _LocalCard({required this.comercio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final abierto = comercio['abierto'] == true;
    final cal = double.tryParse(comercio['calificacion_promedio'].toString()) ?? 0;
    final envio = double.tryParse(comercio['costo_envio'].toString()) ?? 0;
    final tiempo = comercio['tiempo_entrega_estimado'] ?? 30;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Banner del local (placeholder coloreado)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              height: 90,
              color: kAmber.withValues(alpha: 0.08),
              child: comercio['banner_url'] != null
                ? Image.network(comercio['banner_url'], fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => _bannerPlaceholder(comercio['nombre']))
                : _bannerPlaceholder(comercio['nombre']),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                ),
                child: comercio['logo_url'] != null
                  ? ClipOval(child: Image.network(comercio['logo_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, color: kAmber, size: 24)))
                  : const Icon(Icons.store_rounded, color: kAmber, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(comercio['nombre'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  Text(cal.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextDark)),
                ]),
                const SizedBox(height: 3),
                Text(comercio['descripcion'] ?? '', style: const TextStyle(fontSize: 11, color: kTextGrey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('$tiempo min', style: const TextStyle(fontSize: 11, color: kTextGrey)),
                  const SizedBox(width: 10),
                  const Icon(Icons.delivery_dining_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(envio == 0 ? 'Envío gratis' : '\$${_fmt(envio)}',
                    style: TextStyle(fontSize: 11, color: envio == 0 ? kSuccess : kTextGrey,
                      fontWeight: envio == 0 ? FontWeight.w700 : FontWeight.w400)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: abierto ? kSuccessBg : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(abierto ? 'Abierto' : 'Cerrado',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: abierto ? kSuccess : Colors.grey)),
                  ),
                ]),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bannerPlaceholder(String? nombre) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.store_rounded, color: kAmber, size: 28),
      if (nombre != null) Text(nombre, style: const TextStyle(color: kAmber, fontSize: 11, fontWeight: FontWeight.w700)),
    ]));
  }
}

// ─── TAB BUSCAR ───────────────────────────────────────────────────────────────
class _BuscarTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onVerComercio;
  const _BuscarTab({required this.onVerComercio});
  @override
  State<_BuscarTab> createState() => _BuscarTabState();
}

class _BuscarTabState extends State<_BuscarTab> {
  final _ctrl = TextEditingController();
  List<dynamic> _resultados = [];
  List<String> _recientes = [];
  bool _cargando = false;
  bool _buscado = false;
  String _sortBy = 'calificacion'; // calificacion | tiempo | envio

  @override
  void initState() {
    super.initState();
    _cargarRecientes();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _cargarRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('busquedas_recientes') ?? [];
    setState(() => _recientes = lista);
  }

  Future<void> _guardarReciente(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = [q, ..._recientes.where((r) => r != q)].take(5).toList();
    await prefs.setStringList('busquedas_recientes', lista);
    setState(() => _recientes = lista);
  }

  Future<void> _buscar(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _resultados = []; _buscado = false; });
      return;
    }
    setState(() => _cargando = true);
    final res = await ApiService.get('/comercio/lista?busqueda=${Uri.encodeComponent(q.trim())}');
    if (!mounted) return;
    List<dynamic> lista = res['data'] is List ? res['data'] : [];
    lista = _aplicarSort(lista);
    setState(() { _resultados = lista; _cargando = false; _buscado = true; });
    await _guardarReciente(q.trim());
  }

  List<dynamic> _aplicarSort(List<dynamic> lista) {
    final copia = List<dynamic>.from(lista);
    switch (_sortBy) {
      case 'tiempo':
        copia.sort((a, b) => (a['tiempo_entrega_estimado'] ?? 99).compareTo(b['tiempo_entrega_estimado'] ?? 99));
      case 'envio':
        copia.sort((a, b) => (double.tryParse(a['costo_envio'].toString()) ?? 0).compareTo(double.tryParse(b['costo_envio'].toString()) ?? 0));
      default: // calificacion
        copia.sort((a, b) => (double.tryParse(b['calificacion_promedio'].toString()) ?? 0).compareTo(double.tryParse(a['calificacion_promedio'].toString()) ?? 0));
    }
    return copia;
  }

  void _cambiarSort(String v) {
    setState(() { _sortBy = v; _resultados = _aplicarSort(_resultados); });
  }

  Future<void> _borrarRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('busquedas_recientes');
    setState(() => _recientes = []);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buscar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            onChanged: _buscar,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onSubmitted: _buscar,
            decoration: InputDecoration(
              hintText: 'Ej: cemento, pintura, taladro...',
              prefixIcon: const Icon(Icons.search_rounded, color: kAmber),
              suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _ctrl.clear(); _buscar(''); })
                : null,
              filled: true, fillColor: kBgPage,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAmber)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_buscado && _resultados.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                const Text('Ordenar:', style: TextStyle(fontSize: 12, color: kTextGrey)),
                const SizedBox(width: 8),
                _FiltroChip('⭐ Calificación', _sortBy == 'calificacion', () => _cambiarSort('calificacion')),
                const SizedBox(width: 6),
                _FiltroChip('⏱ Más rápido', _sortBy == 'tiempo', () => _cambiarSort('tiempo')),
                const SizedBox(width: 6),
                _FiltroChip('🚚 Menor envío', _sortBy == 'envio', () => _cambiarSort('envio')),
              ]),
            ),
          ],
        ]),
      ),
      Expanded(child: _buildContenido()),
    ]));
  }

  Widget _buildContenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: kAmber));

    if (!_buscado) return _buildSugerencias();

    if (_resultados.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No encontramos "${_ctrl.text}"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
      const SizedBox(height: 6),
      const Text('Intentá con otro término', style: TextStyle(fontSize: 13, color: kTextGrey)),
    ]));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Text('${_resultados.length} ${_resultados.length == 1 ? 'local encontrado' : 'locales encontrados'}',
          style: const TextStyle(fontSize: 13, color: kTextGrey, fontWeight: FontWeight.w600)),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        itemCount: _resultados.length,
        itemBuilder: (_, i) => _LocalCard(comercio: _resultados[i], onTap: () => widget.onVerComercio(_resultados[i])),
      )),
    ]);
  }

  Widget _buildSugerencias() {
    const sugerencias = [
      {'label': 'Cemento', 'emoji': '🧱'},
      {'label': 'Pintura', 'emoji': '🎨'},
      {'label': 'Taladro', 'emoji': '🔧'},
      {'label': 'Arena', 'emoji': '⛏️'},
      {'label': 'Caños', 'emoji': '🚿'},
      {'label': 'Cable eléctrico', 'emoji': '⚡'},
      {'label': 'Casco', 'emoji': '🦺'},
      {'label': 'Tornillos', 'emoji': '🔩'},
    ];

    void tap(String s) { _ctrl.text = s; _buscar(s); }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_recientes.isNotEmpty) ...[
          Row(children: [
            const Text('Búsquedas recientes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
            const Spacer(),
            GestureDetector(onTap: _borrarRecientes,
              child: const Text('Borrar', style: TextStyle(fontSize: 12, color: kAmber, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 10),
          ..._recientes.map((r) => ListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: Colors.grey, size: 18),
            title: Text(r, style: const TextStyle(fontSize: 14, color: kTextDark)),
            onTap: () { _ctrl.text = r; _buscar(r); },
          )),
          const SizedBox(height: 16),
        ],
        const Text('Búsquedas frecuentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: sugerencias.map((s) =>
          GestureDetector(
            onTap: () => tap(s['label']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s['emoji']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(s['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
              ]),
            ),
          ),
        ).toList()),
      ]),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool sel;
  final VoidCallback onTap;
  const _FiltroChip(this.label, this.sel, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? kAmber : kBgPage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : kTextGrey)),
      ),
    );
  }
}

String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
