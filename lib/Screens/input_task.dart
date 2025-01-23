import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:todo_tugas/Screens/home.dart';
import '../url.dart';

class InputTask extends StatefulWidget {
  const InputTask({super.key});

  @override
  State<InputTask> createState() => _InputTaskState();
}

class _InputTaskState extends State<InputTask> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/todo'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'nama_tugas': _nameController.text,
          'deskripsi': _descriptionController.text,
          'deadline': _deadlineController.text,
        }),
      );

      if (response.statusCode == 201) {
        ElegantNotification.success(
          title: const Text('Success'),
          description: const Text('Task created successfully.'),
        ).show(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Home(),
          ),
        );
      } else {
        ElegantNotification.error(
          title: const Text('Error'),
          description: Text('Error: ${response.reasonPhrase}'),
        ).show(context);
      }
    } catch (e) {
      ElegantNotification.error(
        title: const Text('Error'),
        description: Text('Error: $e'),
      ).show(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _deadlineController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Input Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Home(),
              ),
            );
          },
        ),
        backgroundColor: secondaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tugas',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deadlineController,
                    decoration: const InputDecoration(
                      labelText: 'Deadline',
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      await _selectDate(context);
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
