import 'package:http/http.dart' as http;
import 'dart:convert';
import '../url.dart';

class Todo {
  final String namaTugas;
  final String deskripsi;
  final String deadline;
  bool selesai; 
  final int id;

  Todo({
    required this.namaTugas,
    required this.deskripsi,
    required this.deadline,
    required this.selesai,
    required this.id,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      namaTugas: json['nama_tugas'],
      deskripsi: json['deskripsi'],
      deadline: json['deadline'],
      selesai: json['selesai'] == 1, // Convert int to bool
      id: json['id'],
    );
  }
}

Future<List<Todo>> fetchTodos(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/todos'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> body = jsonDecode(response.body);
    return body.map<Todo>((dynamic item) => Todo.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load todos');
  }
}
