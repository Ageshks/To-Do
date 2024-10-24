import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TaskerMaster());
}

class TaskerMaster extends StatelessWidget {
  const TaskerMaster({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasker Master',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
      ),
      home: TaskerHome(),
    );
  }
}

class TaskerHome extends StatefulWidget {
  const TaskerHome({super.key});

  @override
  _TaskerHomeState createState() => _TaskerHomeState();
}

class _TaskerHomeState extends State<TaskerHome> {
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = 'Medium';
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');

    if (tasksJson != null) {
      // Decode the JSON string only if it's not null
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(json.decode(tasksJson));
      });
    } else {
      // Initialize _tasks with an empty list if tasksJson is null
      setState(() {
        _tasks = [];
      });
    }
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks', json.encode(_tasks));
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty && _selectedDueDate != null) {
      setState(() {
        _tasks.add({
          'title': _taskController.text,
          'isDone': false,
          'priority': _selectedPriority,
          'dueDate': _selectedDueDate?.toIso8601String(),
        });
      });
      _taskController.clear();
      _selectedDueDate = null;
      _saveTasks();
    }
  }

  void _editTask(int index) {
    setState(() {
      _taskController.text = _tasks[index]['title'];
      _selectedPriority = _tasks[index]['priority'];
      _selectedDueDate = DateTime.parse(_tasks[index]['dueDate']);
    });
    _removeTaskAt(index); // Temporarily remove to allow re-edit
  }

  void _toggleTaskDone(int index) {
    setState(() {
      _tasks[index]['isDone'] = !_tasks[index]['isDone'];
      _saveTasks();
    });
  }

  void _removeTaskAt(int index) {
    setState(() {
      _tasks.removeAt(index);
      _saveTasks();
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasker Master'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enter Task',
                      labelStyle: TextStyle(color: Colors.tealAccent),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Priority: ',
                  style: TextStyle(color: Colors.white),
                ),
                DropdownButton<String>(
                  value: _selectedPriority,
                  dropdownColor: Colors.black,
                  items: ['High', 'Medium', 'Low'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _selectDueDate(context),
                  child: const Text('Select Due Date'),
                ),
              ],
            ),
            if (_selectedDueDate != null)
              Text(
                'Due: ${DateFormat.yMMMd().format(_selectedDueDate!)}',
                style: const TextStyle(color: Colors.tealAccent),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No Tasks Yet!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Checkbox(
                            value: _tasks[index]['isDone'],
                            onChanged: (value) {
                              _toggleTaskDone(index);
                            },
                            activeColor: Colors.teal,
                          ),
                          title: Text(
                            _tasks[index]['title'],
                            style: TextStyle(
                              color: _tasks[index]['isDone']
                                  ? Colors.grey
                                  : _getPriorityColor(
                                      _tasks[index]['priority']),
                              decoration: _tasks[index]['isDone']
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(
                            'Due: ${DateFormat.yMMMd().format(DateTime.parse(_tasks[index]['dueDate']))}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editTask(index),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeTaskAt(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
