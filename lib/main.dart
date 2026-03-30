import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notes');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Box box;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    box = Hive.box('notes');
  }

  void addNote() {
    if (controller.text.trim().isEmpty) return;

    box.add(controller.text);
    controller.clear();
    setState(() {});
  }

  void deleteNote(int index) {
    box.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes App'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter a note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: addNote,
              child: const Text('Add Note'),
            ),
          ),
          Expanded(
            child: box.isEmpty
                ? const Center(
                    child: Text('No notes yet. Add one!'),
                  )
                : ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(box.getAt(index)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteNote(index),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}