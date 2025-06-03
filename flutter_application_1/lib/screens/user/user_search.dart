import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/http_service.dart';
import 'package:flutter_application_1/config/api_constants.dart';
import 'dart:convert';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/models/user.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _searchUsers(String query) async {
  query = query.trim();
  if (query.isEmpty) {
    setState(() {
      _users = [];
      _error = null;
    });
    return;
  }
  setState(() {
    _isLoading = true;
    _error = null;
  });
  try {
    final userService = Provider.of<UserService>(context, listen: false);
    final users = await userService.searchUsersByUsername(query);
    setState(() {
      _users = users;
    });
  } catch (e) {
    setState(() {
      _error = 'Error: $e';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search users',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: _searchUsers,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_isLoading && _users.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(user.username ?? 'No username'),
                      subtitle: Text(user.email ?? ''),
                    );
                  },
                ),
              ),
            if (!_isLoading && _users.isEmpty && _controller.text.isNotEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No users found.'),
              ),
          ],
        ),
      ),
    );
  }
}