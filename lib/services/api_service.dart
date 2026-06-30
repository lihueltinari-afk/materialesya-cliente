import 'dart:convert';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: volver a _prod antes de compilar para producción.
  static const String _prod = 'https://materialesya-backend-production.up.railway.app/api';
  static String get _base => const String.fromEnvironment('API_URL', defaultValue: '') != '' ? const String.fromEnvironment('API_URL') : 'http://localhost:3000/api';
  static String get baseUrlPublico => _base;

    // Callback que se dispara cuando cualquier endpoint devuelve 401
  static VoidCallback? onSesionExpirada;
  static bool _sesionExpirandose = false;

  static Future<void> _manejarUnauthorized() async {
    if (_sesionExpirandose) return;
    _sesionExpirandose = true;
    await cerrarSesion();
    onSesionExpirada?.call();
    // Resetear después de un momento para no disparar múltiples veces
    Future.delayed(const Duration(seconds: 3), () => _sesionExpirandose = false);
  }

  // ── Token JWT ─────────────────────────────────────────────────────────────
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await obtenerToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: await _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await guardarToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(data['usuario']));
      }
      return {'status': res.statusCode, 'data': data};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registro(String nombre, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/registro'),
        headers: await _headers(),
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password, 'rol': 'cliente'}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        await guardarToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(data['usuario']));
      }
      return {'status': res.statusCode, 'data': data};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> usuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('usuario');
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<Map<String, dynamic>> verificarEmail(String email, String codigo) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/verificar-email'),
        headers: await _headers(),
        body: jsonEncode({'email': email, 'codigo': codigo}),
      ).timeout(const Duration(seconds: 10));
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> reenviarVerificacion(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/reenviar-verificacion'),
        headers: await _headers(),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  // ── PRODUCTOS ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> obtenerProductos({int? categoriaId, String? busqueda, int limit = 30, int offset = 0}) async {
    String url = '$_base/productos?limit=$limit&offset=$offset';
    if (categoriaId != null) url += '&categoria_id=$categoriaId';
    if (busqueda != null && busqueda.isNotEmpty) url += '&busqueda=${Uri.encodeComponent(busqueda)}';
    try {
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> obtenerCategorias() async {
    try {
      final res = await http.get(Uri.parse('$_base/productos/categorias'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> misPedidos() async {
    try {
      final res = await http.get(Uri.parse('$_base/pedidos/mis-pedidos'), headers: await _headers(auth: true));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return []; }
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> obtenerProducto(int id) async {
    try {
      final res = await http.get(Uri.parse('$_base/productos/$id'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // ── GET genérico ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) {
        await _manejarUnauthorized();
        return {'status': 401, 'data': null};
      }
      final decoded = jsonDecode(res.body);
      return {'status': res.statusCode, 'data': decoded};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  // ── POST genérico ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) {
        await _manejarUnauthorized();
        return {'status': 401, 'data': null};
      }
      final decoded = jsonDecode(res.body);
      return {'status': res.statusCode, 'data': decoded};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  // ── PATCH genérico ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) {
        await _manejarUnauthorized();
        return {'status': 401, 'data': null};
      }
      final decoded = jsonDecode(res.body);
      return {'status': res.statusCode, 'data': decoded};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }
}
