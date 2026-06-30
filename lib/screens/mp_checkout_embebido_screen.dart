// Checkout de Mercado Pago embebido DENTRO de la app (no abre pestaña externa). Usa el "Wallet
// Brick" oficial de Mercado Pago: el usuario inicia sesión en Mercado Pago y paga con su saldo
// disponible o sus medios guardados, todo adentro de este iframe. La confirmación real del
// pedido sigue viniendo del backend por polling (ver pagos.js), nunca se confía en el iframe
// para eso — es solo la interfaz visual de pago.
import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../theme.dart';
import '../services/api_service.dart';
import 'pedidos_screen.dart';

class MpCheckoutEmbebidoScreen extends StatefulWidget {
  final int pedidoId;
  final String preferenceId;
  final String publicKey;
  const MpCheckoutEmbebidoScreen({super.key, required this.pedidoId, required this.preferenceId, required this.publicKey});
  @override
  State<MpCheckoutEmbebidoScreen> createState() => _MpCheckoutEmbebidoScreenState();
}

class _MpCheckoutEmbebidoScreenState extends State<MpCheckoutEmbebidoScreen> {
  Timer? _timer;
  bool _expirado = false;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'mp-brick-${widget.pedidoId}';
    final brickUrl = '${ApiService.baseUrlPublico}/pagos/mercadopago/brick.html'
        '?preference_id=${Uri.encodeComponent(widget.preferenceId)}&public_key=${Uri.encodeComponent(widget.publicKey)}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = brickUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _consultarEstado());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultarEstado() async {
    final res = await ApiService.get('/pagos/mercadopago/estado/${widget.pedidoId}');
    if (!mounted) return;
    if (res['status'] == 200) {
      final estado = res['data']?['estado'];
      if (estado != null && estado != 'reservado') {
        _timer?.cancel();
        if (estado == 'cancelado') {
          setState(() => _expirado = true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PedidosScreen()),
            (route) => route.isFirst,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(title: const Text('Pagar con Mercado Pago'), backgroundColor: Colors.white, foregroundColor: kTextDark, elevation: 0.5),
      body: _expirado
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Se venció el tiempo para pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('El pedido se canceló y el stock se liberó. Podés volver a intentarlo.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: kAmber, foregroundColor: Colors.white),
                  child: const Text('Volver al inicio'),
                ),
              ]),
            ),
          )
        : HtmlElementView(viewType: _viewType),
    );
  }
}
