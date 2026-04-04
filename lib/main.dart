import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

// Global box accessor with safety checks
Box? _notesBox;

Future<Box?> getNotesBox() async {
  try {
    if (_notesBox != null && _notesBox!.isOpen) {
      return _notesBox;
    }
    _notesBox = await Hive.openBox('notes');
    return _notesBox;
  } catch (e) {
    debugPrint('Error getting notes box: $e');
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handler first
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await Hive.initFlutter();
    _notesBox = await Hive.openBox('notes');
  } catch (e) {
    debugPrint('Fatal error initializing Hive: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
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
  Box? box;
  final searchController = TextEditingController();
  List<int> filteredIndices = [];

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    try {
      if (mounted) {
        box = await getNotesBox();
        if (box != null && mounted) {
          _updateFilteredNotes();
        }
      }
    } catch (e) {
      debugPrint('Error initializing HomePage: $e');
    }
  }

  void _updateFilteredNotes() {
    try {
      if (box == null || !box!.isOpen) {
        debugPrint('Box not available');
        return;
      }
      final query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredIndices = List.generate(box!.length, (i) => i);
      } else {
        filteredIndices = [];
        for (int i = 0; i < box!.length; i++) {
          final note = box!.getAt(i);
          if (note != null && note.toString().toLowerCase().contains(query)) {
            filteredIndices.add(i);
          }
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error updating filtered notes: $e');
    }
  }

  void _deleteNoteWithConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                try {
                  if (box == null || !box!.isOpen) {
                    throw Exception('Database not available');
                  }
                  if (index >= 0 && index < box!.length) {
                    box!.deleteAt(index);
                  }
                  if (mounted) {
                    searchController.clear();
                    _updateFilteredNotes();
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('Error deleting note: $e');
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error deleting note')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (_) => _updateFilteredNotes(),
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: box == null || !box!.isOpen
                ? const Center(
                    child: Text('Loading notes...'),
                  )
                : filteredIndices.isEmpty
                    ? Center(
                        child: Text(
                          searchController.text.isEmpty
                              ? 'No notes yet. Create one!'
                              : 'No notes found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredIndices.length,
                        itemBuilder: (context, listIndex) {
                          try {
                            final actualIndex = filteredIndices[listIndex];
                            if (actualIndex < 0 || actualIndex >= box!.length) {
                              return const SizedBox.shrink();
                            }
                            final noteData = box!.getAt(actualIndex);
                            if (noteData == null) {
                              return const SizedBox.shrink();
                            }
                            final note = noteData.toString();
                            final preview = note.length > 100
                                ? '${note.substring(0, 100)}...'
                                : note;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(preview),
                                trailing: SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final result = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return EditNotePage(
                                                  note: note,
                                                  index: actualIndex,
                                                );
                                              },
                                            ),
                                          );
                                          if (result != null && mounted) {
                                            searchController.clear();
                                            _updateFilteredNotes();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteNoteWithConfirmation(actualIndex);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return EditNotePage(
                                          note: note,
                                          index: actualIndex,
                                        );
                                      },
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    searchController.clear();
                                    _updateFilteredNotes();
                                  }
                                },
                              ),
                            );
                          } catch (e) {
                            debugPrint('Error building list item: $e');
                            return const SizedBox.shrink();
                          }
                        },
                      ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNotePage(),
            ),
          );
          if (result != null && mounted) {
            searchController.clear();
            _updateFilteredNotes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  Box? box;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    try {
      if (mounted) {
        box = await getNotesBox();
      }
    } catch (e) {
      debugPrint('Error initializing AddNotePage: $e');
    }
  }

  void _saveNote() {
    try {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a note')),
        );
        return;
      }
      if (box == null || !box!.isOpen) {
        throw Exception('Database not available');
      }
      box!.add(controller.text);
      if (mounted) {
        Navigator.pop(context, controller.text);
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving note')),
        );
      }
    }
  }

  void _showDiscardConfirmation() {
    if (controller.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes'),
          content: const Text('Are you sure you want to discard this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showDiscardConfirmation,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Start typing your note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showDiscardConfirmation,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class EditNotePage extends StatefulWidget {
  final String note;
  final int index;

  const EditNotePage({
    super.key,
    required this.note,
    required this.index,
  });

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  Box? box;
  late final TextEditingController controller;
  late String originalNote;

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    try {
      if (mounted) {
        box = await getNotesBox();
        originalNote = widget.note;
        controller = TextEditingController(text: widget.note);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing EditNotePage: $e');
    }
  }

  void _saveNote() {
    try {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a note')),
        );
        return;
      }
      if (box == null || !box!.isOpen) {
        throw Exception('Database not available');
      }
      if (widget.index >= 0 && widget.index < box!.length) {
        box!.putAt(widget.index, controller.text);
      }
      if (mounted) {
        Navigator.pop(context, controller.text);
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving note')),
        );
      }
    }
  }

  void _showDiscardConfirmation() {
    if (controller.text == originalNote) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes'),
          content:
              const Text('Are you sure you want to discard your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showDiscardConfirmation,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Edit your note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showDiscardConfirmation,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}