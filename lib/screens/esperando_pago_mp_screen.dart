// Pantalla que se muestra mientras se espera la confirmación de un pago con Mercado Pago.
// Abre el Checkout Pro en el navegador y mientras tanto consulta cada 3 segundos si el pago
// ya se aprobó (fallback por polling — ver comentario en backend/src/routes/pagos.js sobre
// por qué no alcanza con el webhook en desarrollo local).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'pedidos_screen.dart';

class EsperandoPagoMpScreen extends StatefulWidget {
  final int pedidoId;
  final String initPoint;
  const EsperandoPagoMpScreen({super.key, required this.pedidoId, required this.initPoint});
  @override
  State<EsperandoPagoMpScreen> createState() => _EsperandoPagoMpScreenState();
}

class _EsperandoPagoMpScreenState extends State<EsperandoPagoMpScreen> {
  Timer? _timer;
  bool _abrioCheckout = false;
  bool _expirado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _abrirCheckout();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _consultarEstado());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _abrirCheckout() async {
    final uri = Uri.parse(widget.initPoint);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) setState(() => _abrioCheckout = ok);
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
      appBar: AppBar(title: const Text('Esperando el pago'), backgroundColor: Colors.white, foregroundColor: kTextDark, elevation: 0.5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_expirado) ...[
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
            ] else ...[
              const CircularProgressIndicator(color: kAmber),
              const SizedBox(height: 24),
              const Text('Completá el pago en la pestaña de Mercado Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Apenas se confirme, tu pedido va a aparecer automáticamente.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              if (_abrioCheckout) ...[
                const SizedBox(height: 24),
                TextButton(onPressed: _abrirCheckout, child: const Text('¿No se abrió? Tocá acá para reintentar', style: TextStyle(color: kAmber))),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}
