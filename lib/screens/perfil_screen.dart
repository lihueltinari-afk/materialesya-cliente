import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../soporte.dart';
import '../legal_texts.dart';
import 'login_screen.dart';
import 'legal_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _usuario;
  List<String> _direcciones = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final u = await ApiService.usuarioActual();
    final prefs = await SharedPreferences.getInstance();
    final dirs = prefs.getStringList('direcciones') ?? [];
    if (mounted) setState(() { _usuario = u; _direcciones = dirs; });
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('¿Querés salir de tu cuenta?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true) return;
    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _editarDatos() {
    final nombreCtrl = TextEditingController(text: _usuario?['nombre'] ?? '');
    final telCtrl = TextEditingController(text: _usuario?['telefono'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Editar datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextDark)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: telCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Guardar en backend
                final res = await ApiService.patch('/auth/perfil', {
                  'nombre': nombreCtrl.text.trim(),
                  'telefono': telCtrl.text.trim(),
                });
                if (!mounted) return;
                if (res['status'] == 200) {
                  final u = Map<String, dynamic>.from(_usuario ?? {});
                  u['nombre'] = nombreCtrl.text.trim();
                  u['telefono'] = telCtrl.text.trim();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('usuario', jsonEncode(u));
                  if (!mounted) return;
                  setState(() => _usuario = u);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos actualizados ✓'), backgroundColor: kSuccess));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['data']?['error'] ?? 'Error al guardar'), backgroundColor: kError));
                }
              },
              child: const Text('Guardar cambios'),
            ),
          ]),
        ),
      ),
    );
  }

  void _agregarDireccion() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Nueva dirección', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextDark)),
            const SizedBox(height: 8),
            const Text('Mendoza, Argentina', style: TextStyle(fontSize: 12, color: kTextGrey)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, autofocus: true,
              decoration: const InputDecoration(labelText: 'Calle y número', prefixIcon: Icon(Icons.location_on_outlined, color: kAmber))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                final prefs = await SharedPreferences.getInstance();
                final nueva = List<String>.from(_direcciones)..add(ctrl.text.trim());
                await prefs.setStringList('direcciones', nueva);
                if (!mounted) return;
                setState(() => _direcciones = nueva);
                Navigator.pop(context);
              },
              child: const Text('Agregar dirección'),
            ),
          ]),
        ),
      ),
    );
  }

  void _eliminarDireccion(int i) async {
    final prefs = await SharedPreferences.getInstance();
    final nueva = List<String>.from(_direcciones)..removeAt(i);
    await prefs.setStringList('direcciones', nueva);
    setState(() => _direcciones = nueva);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _usuario?['nombre'] ?? 'Usuario';
    final email = _usuario?['email'] ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: kBgPage,
      body: SafeArea(child: ListView(children: [
        // Header del perfil
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Row(children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: kAmber, shape: BoxShape.circle),
              child: Center(child: Text(inicial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(fontSize: 12, color: kTextGrey)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _editarDatos,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Editar perfil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kAmber)),
                ),
              ),
            ])),
          ]),
        ),

        const SizedBox(height: 12),

        // Mis direcciones
        _Seccion(
          titulo: 'Mis direcciones',
          icono: Icons.location_on_outlined,
          children: [
            if (_direcciones.isEmpty)
              _ItemInfo('Agregá una dirección de entrega')
            else
              ..._direcciones.asMap().entries.map((e) => _ItemDireccion(
                dir: e.value,
                onEliminar: () => _eliminarDireccion(e.key),
              )),
            _Item(Icons.add_location_alt_outlined, 'Agregar dirección', onTap: _agregarDireccion, color: kAmber),
          ],
        ),

        const SizedBox(height: 8),

        // Métodos de pago
        _Seccion(
          titulo: 'Métodos de pago',
          icono: Icons.payment_outlined,
          children: [
            _ItemInfo('Podés pagar en efectivo, transferencia o Mercado Pago al hacer tu pedido'),
          ],
        ),

        const SizedBox(height: 8),

        // Configuración
        _Seccion(
          titulo: 'Configuración',
          icono: Icons.settings_outlined,
          children: [
            _Item(Icons.notifications_outlined, 'Notificaciones', onTap: () {}),
            _Item(Icons.support_agent_outlined, 'Ayuda / Soporte', onTap: () => abrirSoporteWhatsApp()),
            _Item(Icons.description_outlined, 'Términos y condiciones', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Términos y condiciones', texto: terminosCliente)));
            }),
            _Item(Icons.privacy_tip_outlined, 'Política de privacidad', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Política de privacidad', texto: politicaPrivacidad)));
            }),
            _Item(Icons.info_outline_rounded, 'Acerca de MaterialesYa', onTap: () {
              showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('MaterialesYa', style: TextStyle(fontWeight: FontWeight.w800)),
                content: const Text('v1.0.0\nDelivery de materiales de construcción en Mendoza, Argentina.\n\n© 2026 MaterialesYa'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
              ));
            }),
          ],
        ),

        const SizedBox(height: 8),

        // Cerrar sesión
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Center(child: Text('MaterialesYa v1.0 · Mendoza', style: TextStyle(fontSize: 11, color: Colors.grey))),
        const SizedBox(height: 24),
      ])),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  const _Seccion({required this.titulo, required this.icono, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icono, size: 15, color: kTextGrey),
          const SizedBox(width: 6),
          Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextGrey, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)]),
          child: Column(children: List.generate(children.length, (i) => Column(children: [
            children[i],
            if (i < children.length - 1) Divider(height: 1, indent: 16, color: Colors.grey.shade100),
          ]))),
        ),
      ]),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const _Item(this.icono, this.label, {this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icono, color: color ?? kTextDark, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? kTextDark)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}

class _ItemInfo extends StatelessWidget {
  final String texto;
  const _ItemInfo(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Text(texto, style: const TextStyle(fontSize: 13, color: kTextGrey)),
  );
}

class _ItemDireccion extends StatelessWidget {
  final String dir;
  final VoidCallback onEliminar;
  const _ItemDireccion({required this.dir, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_on_rounded, color: kAmber, size: 20),
      title: Text(dir, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
      subtitle: const Text('Mendoza, Argentina', style: TextStyle(fontSize: 11, color: kTextGrey)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
        onPressed: onEliminar,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
