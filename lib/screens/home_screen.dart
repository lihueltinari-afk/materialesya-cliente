import 'package:flutter/material.dart';
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
  int get _totalCarrito =>
      _carrito.values.fold(0, (a, b) => a + (b['cantidad'] as int));

  void _agregarAlCarrito(Map<String, dynamic> item) {
    setState(() {
      final id = item['id'] as int;
      if (_carrito.containsKey(id)) {
        _carrito[id]!['cantidad'] = (_carrito[id]!['cantidad'] as int) + 1;
      } else {
        _carrito[id] = {...item, 'cantidad': 1};
      }
    });
  }

  void _irAlCarrito() {
    if (_carrito.isEmpty) return;
    final primer = _carrito.values.first;
    final comercio = {
      'id': primer['comercio_id'],
      'nombre': primer['comercio_nombre'] ?? '',
      'costo_envio': primer['costo_envio'] ?? 0,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          carrito: _carrito,
          comercio: comercio,
          onActualizar: (n) =>
              setState(() { _carrito.clear(); _carrito.addAll(n); }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _InicioTab(
        carritoCount: _totalCarrito,
        onVerComercio: (c) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ComercioScreen(comercio: c, onAgregar: _agregarAlCarrito),
          ),
        ),
        onCarritoTap: _irAlCarrito,
      ),
      _BuscarTab(
        onVerComercio: (c) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ComercioScreen(comercio: c, onAgregar: _agregarAlCarrito),
          ),
        ),
      ),
      const PedidosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: kBgPage,
      body: IndexedStack(index: _navIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
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
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Inicio'},
      {'icon': Icons.search_rounded, 'label': 'Buscar'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Pedidos'},
      {'icon': Icons.person_rounded, 'label': 'Mi perfil'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i]['icon'] as IconData,
                          size: 24,
                          color: sel ? kAmber : const Color(0xFFBBBBBB)),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? kAmber : const Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── CATEGORÍAS ───────────────────────────────────────────────────────────────
const _kCategorias = [
  {'label': 'Todo',         'emoji': '🏗️', 'id': null},
  {'label': 'Materiales',   'emoji': '🧱', 'id': 1},
  {'label': 'Insumos',      'emoji': '🎨', 'id': 2},
  {'label': 'Herramientas', 'emoji': '🔧', 'id': 3},
  {'label': 'Maquinaria',   'emoji': '⚙️', 'id': 4},
];

// ─── TAB INICIO ───────────────────────────────────────────────────────────────
class _InicioTab extends StatefulWidget {
  final int carritoCount;
  final void Function(Map<String, dynamic>) onVerComercio;
  final VoidCallback onCarritoTap;
  const _InicioTab({
    required this.carritoCount,
    required this.onVerComercio,
    required this.onCarritoTap,
  });
  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  List<dynamic> _comercios = [];
  bool _cargando = true;
  int _catSeleccionada = 0; // índice en _kCategorias

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({int? categoriaId}) async {
    setState(() => _cargando = true);
    final path = categoriaId != null
        ? '/comercio/lista?categoria_id=$categoriaId'
        : '/comercio/lista';
    final res = await ApiService.get(path);
    if (mounted) {
      setState(() {
        _comercios = res['data'] is List ? res['data'] : [];
        _cargando = false;
      });
    }
  }

  void _seleccionarCategoria(int idx) {
    setState(() => _catSeleccionada = idx);
    final cat = _kCategorias[idx];
    _cargar(categoriaId: cat['id'] as int?);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── AppBar naranja con título y carrito
        SliverAppBar(
          pinned: true,
          backgroundColor: kAmber,
          elevation: 0,
          expandedHeight: 110,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              color: kAmber,
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: título centrado + carrito
                  Row(children: [
                    const SizedBox(width: 32),
                    const Expanded(
                      child: Text(
                        'MaterialesYa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCarritoTap,
                      child: Stack(children: [
                        const Icon(Icons.shopping_cart_outlined,
                            color: Colors.white, size: 26),
                        if (widget.carritoCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${widget.carritoCount}',
                                    style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: kAmber)),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Barra de búsqueda
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      SizedBox(width: 12),
                      Icon(Icons.search_rounded,
                          color: Color(0xFFBBBBBB), size: 20),
                      SizedBox(width: 8),
                      Text('Buscar locales o materiales...',
                          style: TextStyle(
                              color: Color(0xFFBBBBBB), fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          // Título colapsado
          title: const Text('MaterialesYa',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: widget.onCarritoTap,
                child: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 24),
              ),
            ),
          ],
        ),

        // ── Categorías
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: List.generate(_kCategorias.length, (i) {
                  final cat = _kCategorias[i];
                  final sel = i == _catSeleccionada;
                  return GestureDetector(
                    onTap: () => _seleccionarCategoria(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kAmber : const Color(0xFFF5F5F3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: sel ? kAmber : Colors.transparent,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cat['emoji'] as String,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                sel ? Colors.white : const Color(0xFF444444),
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // ── Banner promo
        const SliverToBoxAdapter(child: _BannerPromo()),

        // ── Título sección locales
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            child: Row(children: [
              Text(
                _catSeleccionada == 0
                    ? 'Todos los locales'
                    : _kCategorias[_catSeleccionada]['label'] as String,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kTextDark),
              ),
              const Spacer(),
              if (!_cargando)
                Text(
                  '${_comercios.length} ${_comercios.length == 1 ? 'local' : 'locales'}',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ]),
          ),
        ),

        // ── Lista de locales o loading
        if (_cargando)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: kAmber)))
        else if (_comercios.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No hay locales con\n${(_kCategorias[_catSeleccionada]['label'] as String).toLowerCase()}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _LocalCard(
                comercio: _comercios[i],
                onTap: () => widget.onVerComercio(_comercios[i]),
              ),
              childCount: _comercios.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ─── BANNER PROMO ─────────────────────────────────────────────────────────────
class _BannerPromo extends StatelessWidget {
  const _BannerPromo();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Primer pedido con envío gratis',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kAmber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SOLO PARA NUEVOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        const Text('🚚', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
      ]),
    );
  }
}

// ─── TARJETA LOCAL (horizontal, estilo PedidosYa) ─────────────────────────────
class _LocalCard extends StatelessWidget {
  final dynamic comercio;
  final VoidCallback onTap;
  const _LocalCard({required this.comercio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final abierto = comercio['abierto'] == true;
    final cal =
        double.tryParse(comercio['calificacion_promedio'].toString()) ?? 0;
    final envio =
        double.tryParse(comercio['costo_envio'].toString()) ?? 0;
    final tiempo = comercio['tiempo_entrega_estimado'] ?? 30;

    return GestureDetector(
      onTap: abierto ? onTap : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: kAmber.withValues(alpha: 0.08),
              child: Image.network(
                comercio['logo_url'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.store_rounded,
                    color: kAmber,
                    size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      comercio['nombre'] ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kTextDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  Text(cal.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kTextDark)),
                ]),
                const SizedBox(height: 3),
                Text(
                  comercio['descripcion'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('$tiempo min',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 12),
                  const Icon(Icons.delivery_dining_rounded,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(
                    envio == 0
                        ? 'Envío gratis'
                        : '\$${envio.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: envio == 0 ? kSuccess : Colors.grey,
                        fontWeight: envio == 0
                            ? FontWeight.w700
                            : FontWeight.w400),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: abierto
                          ? kSuccessBg
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      abierto ? 'Abierto' : 'Cerrado',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: abierto ? kSuccess : Colors.grey),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
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
  List<dynamic> _comercios = [];
  List<dynamic> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final res = await ApiService.get('/comercio/lista');
    if (mounted) {
      setState(() {
        _comercios = res['data'] is List ? res['data'] : [];
        _filtrados = _comercios;
        _cargando = false;
      });
    }
  }

  void _filtrar(String q) {
    setState(() {
      if (q.isEmpty) { _filtrados = _comercios; return; }
      final lower = q.toLowerCase();
      _filtrados = _comercios.where((c) =>
        (c['nombre'] ?? '').toString().toLowerCase().contains(lower) ||
        (c['descripcion'] ?? '').toString().toLowerCase().contains(lower)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Buscar',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kTextDark)),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Locales, materiales...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kAmber),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          _filtrar('');
                        })
                    : null,
                filled: true,
                fillColor: kBgPage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ]),
        ),
        if (_cargando)
          const Expanded(
              child: Center(child: CircularProgressIndicator(color: kAmber)))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _filtrados.length,
              itemBuilder: (_, i) => _LocalCard(
                comercio: _filtrados[i],
                onTap: () => widget.onVerComercio(_filtrados[i]),
              ),
            ),
          ),
      ]),
    );
  }
}
