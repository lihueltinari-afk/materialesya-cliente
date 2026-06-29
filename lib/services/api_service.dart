import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _prod = 'https://materialesya-backend-production.up.railway.app/api';
  static String get _base => kIsWeb ? _prod : (const String.fromEnvironment('API_URL', defaultValue: '') != '' ? const String.fromEnvironment('API_URL') : 'http://10.0.2.2:3000/api');

  // Guarda y recupera el token JWT
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

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await guardarToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario', jsonEncode(data['usuario']));
    }
    return {'status': res.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> registro(String nombre, String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/registro'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'email': email, 'password': password, 'rol': 'cliente'}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await guardarToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario', jsonEncode(data['usuario']));
    }
    return {'status': res.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>?> usuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('usuario');
    if (str == null) return null;
    return jsonDecode(str);
  }

  // PRODUCTOS
  static Future<List<dynamic>> obtenerProductos({int? categoriaId, String? busqueda, int limit = 30, int offset = 0}) async {
    String url = '$_base/productos?limit=$limit&offset=$offset';
    if (categoriaId != null) url += '&categoria_id=$categoriaId';
    if (busqueda != null && busqueda.isNotEmpty) url += '&busqueda=${Uri.encodeComponent(busqueda)}';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> obtenerCategorias() async {
    final res = await http.get(Uri.parse('$_base/productos/categorias'), headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> misPedidos() async {
    final res = await http.get(Uri.parse('$_base/pedidos/mis-pedidos'), headers: await _headers(auth: true));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> obtenerProducto(int id) async {
    final res = await http.get(Uri.parse('$_base/productos/$id'), headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // GET genérico — retorna { status, data }
  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(Uri.parse('$_base$path'), headers: await _headers(auth: true));
      final decoded = jsonDecode(res.body);
      return {'status': res.statusCode, 'data': decoded};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }

  // POST genérico — retorna { status, data }
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body);
      return {'status': res.statusCode, 'data': decoded};
    } catch (e) {
      return {'status': 0, 'data': null, 'error': e.toString()};
    }
  }
}
