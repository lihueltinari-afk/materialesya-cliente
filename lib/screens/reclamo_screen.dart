// Pantalla "Tuve un problema con mi pedido": disponible hasta 24hs después de la entrega.
// Las fotos se mandan como base64 (data URL) directo en el JSON del reclamo — no hay un
// servicio de almacenamiento de archivos (S3/Cloudinary/etc) conectado todavía, así que esto
// es una solución simple para el MVP. Funciona bien con pocas fotos chicas; si en el futuro se
// agrega un storage real, lo único que cambia es _elegirFotos() (subir y guardar la URL en vez
// del base64 completo).
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class ReclamoScreen extends StatefulWidget {
  final int pedidoId;
  const ReclamoScreen({super.key, required this.pedidoId});
  @override
  State<ReclamoScreen> createState() => _ReclamoScreenState();
}

class _ReclamoScreenState extends State<ReclamoScreen> {
  String _tipo = 'faltante';
  final _comentarioCtrl = TextEditingController();
  final List<String> _fotosBase64 = [];
  bool _enviando = false;
  String? _error;

  final _tipos = const [
    {'valor': 'faltante', 'label': 'Producto faltante', 'icono': Icons.remove_shopping_cart_outlined},
    {'valor': 'danado', 'label': 'Producto dañado', 'icono': Icons.broken_image_outlined},
    {'valor': 'incorrecto', 'label': 'Producto incorrecto', 'icono': Icons.swap_horiz_outlined},
    {'valor': 'cobro_incorrecto', 'label': 'Cobro incorrecto', 'icono': Icons.payments_outlined},
    {'valor': 'otro', 'label': 'Otro', 'icono': Icons.more_horiz},
  ];

  Future<void> _elegirFotos() async {
    if (_fotosBase64.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 3 fotos')));
      return;
    }
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
    if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
    final bytes = res.files.first.bytes!;
    final base64Str = base64Encode(bytes);
    setState(() => _fotosBase64.add('data:image/jpeg;base64,$base64Str'));
  }

  Future<void> _enviar() async {
    setState(() { _enviando = true; _error = null; });
    final res = await ApiService.post('/reclamos', {
      'pedido_id': widget.pedidoId,
      'tipo': _tipo,
      'comentario': _comentarioCtrl.text.trim(),
      'fotos': _fotosBase64,
    });
    if (!mounted) return;
    setState(() => _enviando = false);
    if (res['status'] == 201) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reclamo enviado. El comercio fue notificado y te vamos a avisar la resolución.'),
        backgroundColor: kSuccess,
      ));
    } else {
      setState(() => _error = res['data']?['error'] ?? 'No se pudo enviar el reclamo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(title: const Text('Reportar un problema'), backgroundColor: Colors.white, foregroundColor: kTextDark, elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('¿Qué pasó con tu pedido?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 12),
          ..._tipos.map((t) => RadioListTile<String>(
            value: t['valor'] as String,
            groupValue: _tipo,
            onChanged: (v) => setState(() => _tipo = v!),
            title: Text(t['label'] as String, style: const TextStyle(fontSize: 14)),
            secondary: Icon(t['icono'] as IconData, color: kAmber),
            activeColor: kAmber,
            contentPadding: EdgeInsets.zero,
          )),
          const SizedBox(height: 16),
          const Text('Contanos más detalles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describí qué pasó...',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Fotos (opcional, hasta 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
            const Spacer(),
            TextButton.icon(onPressed: _elegirFotos, icon: const Icon(Icons.add_a_photo_outlined, size: 16), label: const Text('Agregar')),
          ]),
          if (_fotosBase64.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fotosBase64.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(
                    base64Decode(_fotosBase64[i].split(',').last), width: 80, height: 80, fit: BoxFit.cover)),
                  Positioned(top: 2, right: 2, child: GestureDetector(
                    onTap: () => setState(() => _fotosBase64.removeAt(i)),
                    child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                  )),
                ]),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(backgroundColor: kAmber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _enviando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enviar reclamo', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
