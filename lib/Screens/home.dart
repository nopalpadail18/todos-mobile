import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_tugas/Screens/input_task.dart';
import 'package:todo_tugas/auth/login.dart';
import 'package:radial_button/widget/circle_floating_button.dart';
import '../url.dart';
import '../models/todos.dart';
import 'task_detail.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  Future<void> _fetchTodos() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final todos = await fetchTodos(token);
        setState(() {
          _todos = todos;
        });
      } else {
        throw Exception('Token not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      setState(
        () {
          _isLoading = false;
        },
      );
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );
      }
      await prefs.remove('token');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
        ElegantNotification.success(
          title: const Text('Logout Berhasil'),
          description: const Text('Anda telah berhasil keluar.'),
        ).show(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _navigateToTaskDetail(Todo todo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetail(todo: todo),
      ),
    );

    if (result == true) {
      _fetchTodos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Tasks',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'List',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Task Categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('Semua Tugas', '65', true),
                          _buildCategoryChip('Belum Selesai', '12', false),
                          _buildCategoryChip('Selesai', '', false),
                          _buildCategoryChip('Chat AI', '', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Task List
                    Expanded(
                      child: _todos.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada tugas tersedia',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _todos.length,
                              itemBuilder: (context, index) {
                                final todo = _todos[index];
                                return GestureDetector(
                                  onTap: () => _navigateToTaskDetail(todo),
                                  child: _buildTaskCard(
                                    title: todo.namaTugas.length > 25
                                        ? '${todo.namaTugas.substring(0, 25)}...'
                                        : todo.namaTugas,
                                    color: Colors.lightBlue.shade50,
                                    progress: todo.selesai == true ? 1.0 : 0.0,
                                    priority: todo.selesai == true
                                        ? 'Selesai'
                                        : 'Belum Selesai',
                                    priorityColor: todo.selesai == true
                                        ? Colors.green
                                        : Colors.pink.shade100,
                                    deadline: todo.deadline,
                                    deskripsi: todo.deskripsi.length > 50
                                        ? '${todo.deskripsi.substring(0, 50)}...'
                                        : todo.deskripsi,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: CircleFloatingButton.floatingActionButton(
              items: [
                FloatingActionButton(
                  heroTag: 'add_task_1',
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InputTask(),
                        ));
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'chat_ai_1',
                  onPressed: () {
                    // Aksi lain
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.rocket, color: Colors.white),
                ),
              ],
              color: Colors.blue,
              icon: Icons.menu,
              duration: const Duration(milliseconds: 500),
              curveAnim: Curves.bounceInOut,
              useOpacity: true,
            ),
          );
  }

  Widget _buildCategoryChip(String label, String count, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (count.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                count,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isSelected ? Colors.black : Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String deskripsi,
    required Color color,
    required double progress,
    required String priority,
    required Color priorityColor,
    required String deadline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deskripsi,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    Text(priority, style: const TextStyle(color: Colors.white)),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(deadline),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.shade200,
            ),
          ),
        ],
      ),
    );
  }
}
