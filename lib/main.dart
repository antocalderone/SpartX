import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // Per Path e Offset

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:smx/calendar_page.dart';
import 'package:smx/metronome_page.dart';
import 'package:uuid/uuid.dart';

// Punto di ingresso principale dell'applicazione.
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const SheetMusicApp());
}

// Istanza globale di Uuid per generare ID univoci.
const Uuid uuid = Uuid();

// ------------------- MODELLI ------------------- //

/// Rappresenta una playlist di spartiti.
class Playlist {
  final String id;
  String name;
  List<String> sheetMusicPaths;

  Playlist({required this.id, required this.name, this.sheetMusicPaths = const []});

  /// Converte l'oggetto Playlist in una mappa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sheetMusicPaths': sheetMusicPaths,
      };

  /// Crea un'istanza di Playlist da una mappa JSON.
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        // Se l'ID è mancante, ne genera uno nuovo per retrocompatibilità.
        id: json['id'] ?? uuid.v4(),
        name: json['name'],
        sheetMusicPaths: List<String>.from(json['sheetMusicPaths']),
      );
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      offset: Offset(json['x'], json['y']),
      paint: Paint()
        ..color = Color(json['color'])
        ..strokeWidth = json['strokeWidth']
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke,
    );
  }
}

// ------------------- APPLICAZIONE ------------------- //

/// Il widget principale dell'applicazione.
class SheetMusicApp extends StatefulWidget {
  const SheetMusicApp({super.key});

  @override
  State<SheetMusicApp> createState() => _SheetMusicAppState();
}

class _SheetMusicAppState extends State<SheetMusicApp> {
  Color _primaryColor = Colors.teal;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }
  
  Future<void> _loadInitialSettings() async {
    final settings = await loadSettings();
    if (mounted) {
      setState(() {
        _themeMode = settings['themeMode'] ?? ThemeMode.system;
      });
    }
  }

  void _changeThemeColor(Color newColor) {
    setState(() {
      _primaryColor = newColor;
    });
  }

  void _changeThemeMode(ThemeMode newMode) {
    setState(() {
      _themeMode = newMode;
    });
    saveSettings(_themeMode);  
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      title: 'SpartX',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
         bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor.withOpacity(0.8),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
         bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: RootPage(
        onColorChanged: _changeThemeColor,
        currentColor: _primaryColor,
        onThemeModeChanged: _changeThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

// ------------------- PAGINA PRINCIPALE con Navigazione Inferiore ------------------- //

/// La pagina principale dell'app, che gestisce la navigazione inferiore.
class RootPage extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;
  final Color currentColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const RootPage({super.key, required this.onColorChanged, required this.currentColor, required this.onThemeModeChanged, required this.currentThemeMode});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final _pages = [
      const SheetMusicPage( // Hardcoded title to SpartX
        title: 'SpartX',
      ),
      const PlaylistsPage(),
      const CalendarPage(),
      const MetronomePage(),
      SettingsPage(
        onColorChanged: widget.onColorChanged,
        currentColor: widget.currentColor,
        onThemeModeChanged: widget.onThemeModeChanged,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack( // Usa IndexedStack per preservare lo stato delle pagine.
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_outlined),
            label: 'Spartiti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_outlined),
            label: 'Playlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Metronomo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}

// ------------------- SETTINGS PAGE ------------------- //

class SettingsPage extends StatelessWidget {
  final ValueChanged<Color> onColorChanged;
  final Color currentColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const SettingsPage({super.key, required this.onColorChanged, required this.currentColor, required this.onThemeModeChanged, required this.currentThemeMode});

  final List<Color> availableColors = const [
    Colors.teal,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.brown,
  ];
  
  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Chiaro';
      case ThemeMode.dark:
        return 'Scuro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 30),
          Text(
            'Colore Principale',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 20, thickness: 1),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: availableColors
                .map(
                  (color) => GestureDetector(
                    onTap: () => onColorChanged(color),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentColor == color ? Theme.of(context).colorScheme.onBackground : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: currentColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 30),
          Text(
            'Modalità Tema',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 20, thickness: 1),
          ListTile(
            title: Text(_getThemeModeLabel(currentThemeMode)),
            subtitle: const Text('Seleziona tra Chiaro, Scuro o Sistema'),
            trailing: const Icon(Icons.palette),
            onTap: () async {
              final newMode = await showDialog<ThemeMode>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Seleziona Modalità Tema'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ThemeMode.values.map((mode) {
                      return RadioListTile<ThemeMode>(
                        title: Text(_getThemeModeLabel(mode)),
                        value: mode,
                        groupValue: currentThemeMode,
                        onChanged: (ThemeMode? value) {
                          Navigator.of(context).pop(value);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
              if (newMode != null) {
                onThemeModeChanged(newMode);
              }
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Nota: Le modifiche al nome e al tema vengono salvate localmente nell\'app.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ------------------- FUNZIONI DI UTILITÀ PER I DATI ------------------- //

/// Restituisce la directory in cui sono memorizzati i PDF degli spartiti.
Future<Directory> getSheetMusicDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  final musicDir = Directory('${appDir.path}/sheet_music');

  if (!await musicDir.exists()) {
    await musicDir.create(recursive: true);
  }
  return musicDir;
}

/// Restituisce il file in cui sono memorizzati i dati delle playlist.
Future<File> getPlaylistsFile() async {
  final appDir = await getApplicationDocumentsDirectory();
  return File('${appDir.path}/playlists.json');
}

/// Restituisce il file in cui sono memorizzate le impostazioni.
Future<File> getSettingsFile() async {
  final appDir = await getApplicationDocumentsDirectory();
  return File('${appDir.path}/settings.json');
}

/// Carica tutte le playlist dal file JSON.
Future<List<Playlist>> loadPlaylists() async {
  final file = await getPlaylistsFile();
  if (await file.exists()) {
    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      // Se la decodifica fallisce, restituisce una lista vuota.
      return [];
    }
  }
  return [];
}

/// Salva un elenco di playlist nel file JSON.
Future<void> savePlaylists(List<Playlist> playlists) async {
  final file = await getPlaylistsFile();
  final jsonList = playlists.map((p) => p.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
}

/// Saves global settings to the JSON file.
Future<void> saveSettings(ThemeMode themeMode) async {
  final file = await getSettingsFile();
  final settings = {
    'themeModeIndex': themeMode.index,
  };
  await file.writeAsString(jsonEncode(settings));
}

/// Fetches global settings, returning a Map containing ThemeMode and AppName.
Future<Map<String, dynamic>> loadSettings() async {
  final file = await getSettingsFile();
  final defaultSettings = {
    'themeModeIndex': ThemeMode.system.index,
  };

  if (await file.exists()) {
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(content);
      return {
        'themeMode': ThemeMode.values[jsonMap['themeModeIndex'] ?? defaultSettings['themeModeIndex']],
      };
    } catch (e) {
      // If decoding fails, return defaults
      return {
        'themeMode': ThemeMode.values[defaultSettings['themeModeIndex'] ?? 0],
      };
    }
  }
  // If file doesn't exist, return defaults
  return {
    'themeMode': ThemeMode.values[defaultSettings['themeModeIndex'] ?? 0],
  };
}


// ------------------- PAGINA SPARTITI ------------------- //

/// Pagina che visualizza l'elenco di tutti gli spartiti.
class SheetMusicPage extends StatefulWidget {
  final String title; // Nuovo parametro
  const SheetMusicPage({super.key, required this.title});

  @override
  State<SheetMusicPage> createState() => _SheetMusicPageState();
}

class _SheetMusicPageState extends State<SheetMusicPage> {
  List<File> _sheetMusicFiles = [];
  List<File> _filteredSheetMusicFiles = []; // Added for search functionality
  bool _isLoading = true;
  bool _isSearching = false; // Added for search bar visibility
  final TextEditingController _searchController = TextEditingController(); // Added for search input
  String _searchQuery = ''; // Added for current search query

  @override
  void initState() {
    super.initState();
    _loadSheetMusic();
    _searchController.addListener(_onSearchChanged); // Listen for search input changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterSheetMusic();
    });
  }

  void _filterSheetMusic() {
    if (_searchQuery.isEmpty) {
      _filteredSheetMusicFiles = List.from(_sheetMusicFiles);
    } else {
      _filteredSheetMusicFiles = _sheetMusicFiles.where((file) {
        final fileName = p.basename(file.path).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return fileName.contains(query);
      }).toList();
    }
  }

  /// Carica l'elenco degli spartiti dalla directory.
  Future<void> _loadSheetMusic() async {
    setState(() => _isLoading = true);
    final musicDir = await getSheetMusicDirectory();
    final files = musicDir.listSync();
    if (mounted) {
      setState(() {
        _sheetMusicFiles = files.whereType<File>().where((file) => file.path.endsWith('.pdf')).toList();
        _filterSheetMusic(); // Filter after loading
        _isLoading = false;
      });
    }
  }

  /// Apre il selettore di file per scegliere e salvare un nuovo spartito.
  Future<void> _pickAndSaveFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final musicDir = await getSheetMusicDirectory();
      final fileName = p.basename(pickedFile.path);
      final newPath = '${musicDir.path}/$fileName';

      if (await File(newPath).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lo spartito "$fileName" esiste già.')),
        );
        return;
      }

      final newFile = await pickedFile.copy(newPath);

      setState(() {
        _sheetMusicFiles.add(newFile);
        _filterSheetMusic(); // Re-filter after adding
      });
    }
  }

  /// Apre la visualizzazione PDF per un dato spartito.
  void _openPdfViewer(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(pdfFile: file),
      ),
    );
  }

  /// Rinomina un file di spartito.
  Future<void> _renameFile(File oldFile) async {
    final oldName = p.basename(oldFile.path).replaceAll('.pdf', '');
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rinomina Spartito'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nuovo nome')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          TextButton(
            onPressed: () => controller.text.isNotEmpty ? Navigator.of(context).pop(controller.text) : null,
            child: const Text('Rinomina'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final musicDir = await getSheetMusicDirectory();
      final newPath = '${musicDir.path}/$newName.pdf';
      if (await File(newPath).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esiste già un file chiamato "$newName.pdf".')));
        return;
      }
      final newFile = await oldFile.rename(newPath);
      // Aggiorna le playlist con il nuovo nome del file.
      final playlists = await loadPlaylists();
      for (var playlist in playlists) {
        playlist.sheetMusicPaths = playlist.sheetMusicPaths.map((path) => path == oldFile.path ? newPath : path).toList();
      }
      await savePlaylists(playlists);

      setState(() {
        final index = _sheetMusicFiles.indexWhere((f) => f.path == oldFile.path);
        if (index != -1) _sheetMusicFiles[index] = newFile;
        _filterSheetMusic(); // Re-filter after renaming
      });
    }
  }

  /// Elimina un file di spartito.
  Future<void> _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare lo Spartito?'),
        content: Text('Sei sicuro di voler eliminare "${p.basename(file.path)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await file.delete();
      // Rimuove lo spartito da tutte le playlist.
      final playlists = await loadPlaylists();
      for (var playlist in playlists) {
        playlist.sheetMusicPaths.removeWhere((path) => path == file.path);
      }
      await savePlaylists(playlists);

      // Delete annotations file as well
      final annotationsFile = await _getAnnotationsFile(file);
      if (await annotationsFile.exists()) {
        await annotationsFile.delete();
      }

      setState(() {
        _sheetMusicFiles.removeWhere((f) => f.path == file.path);
        _filterSheetMusic(); // Re-filter after deleting
      });
    }
  }

  Future<File> _getAnnotationsFile(File pdfFile) async {
    final musicDir = await getSheetMusicDirectory();
    final fileName = p.basenameWithoutExtension(pdfFile.path);
    return File('${musicDir.path}/$fileName.json');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cerca spartiti...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                autofocus: true,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title),
                  const Text(
                    'developed by A.Calderone',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterSheetMusic();
                }
              });
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSheetMusic),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSheetMusicFiles.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'Nessuno spartito ancora.\nPremi il pulsante + per aggiungere un PDF.' : 'Nessun risultato per "${_searchQuery}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSheetMusic,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredSheetMusicFiles.length,
                    itemBuilder: (context, index) {
                      final file = _filteredSheetMusicFiles[index];
                      final fileName = p.basename(file.path);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(fileName.replaceAll('.pdf', '')),
                          leading: const Icon(Icons.music_note_outlined),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _renameFile(file)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteFile(file)),
                            ],
                          ),
                          onTap: () => _openPdfViewer(file),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSaveFile,
        tooltip: 'Aggiungi Spartito',
        heroTag: 'addSheetMusicButton',
        child: const Icon(Icons.add),
      ),
    );
  }
}


// ------------------- PAGINA PLAYLIST ------------------- //

/// Pagina che visualizza l'elenco di tutte le playlist.
class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshPlaylists();
  }

  /// Aggiorna l'elenco delle playlist.
  Future<void> _refreshPlaylists() async {
    setState(() => _isLoading = true);
    final playlists = await loadPlaylists();
    if (mounted) {
      // Questo controllo garantisce che le playlist create prima del sistema di ID
      // vengano aggiornate nello storage.
      bool needsResave = playlists.any((p) => p.id == null);
      if (needsResave) {
        await savePlaylists(playlists);
      }

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  /// Crea una nuova playlist.
  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final newPlaylistName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Playlist'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nome Playlist')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          TextButton(onPressed: () => controller.text.isNotEmpty ? Navigator.of(context).pop(controller.text) : null, child: const Text('Crea')),
        ],
      ),
    );

    if (newPlaylistName != null && newPlaylistName.isNotEmpty) {
      if (_playlists.any((p) => p.name == newPlaylistName)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esiste già una playlist chiamata "$newPlaylistName".')));
        return;
      }
      final newPlaylist = Playlist(id: uuid.v4(), name: newPlaylistName);
      setState(() => _playlists.add(newPlaylist));
      await savePlaylists(_playlists);
    }
  }
  
  /// Rinomina una playlist.
  Future<void> _renamePlaylist(Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final newName = await showDialog<String>(
      context: context,
       builder: (context) => AlertDialog(
        title: const Text('Rinomina Playlist'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nuovo nome')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
          TextButton(onPressed: () => controller.text.isNotEmpty ? Navigator.of(context).pop(controller.text) : null, child: const Text('Rinomina')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != playlist.name) {
      if (_playlists.any((p) => p.name == newName && p.id != playlist.id)) {
         if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esiste già una playlist chiamata "$newName".')));
        return;
      }
      setState(() => playlist.name = newName);
      await savePlaylists(_playlists);
    }
  }

  /// Elimina una playlist.
  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la Playlist?'),
        content: Text('Sei sicuro di voler eliminare "${playlist.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _playlists.removeWhere((p) => p.id == playlist.id));
      await savePlaylists(_playlists);
    }
  }

  /// Naviga alla pagina di dettaglio della playlist.
  void _navigateToDetails(Playlist playlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailsPage(
          playlist: playlist,
        ),
      ),
    );
    // Aggiorna la lista dopo essere tornati dalla pagina di dettaglio.
    _refreshPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPlaylists)],),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? const Center(child: Text('Nessuna playlist ancora.\nPremi il pulsante + per crearne una.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _refreshPlaylists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(playlist.name),
                          leading: const Icon(Icons.queue_music),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${playlist.sheetMusicPaths.length} elementi'),
                              const SizedBox(width: 8),
                              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _renamePlaylist(playlist), tooltip: 'Rinomina Playlist',),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deletePlaylist(playlist), tooltip: 'Elimina Playlist',),
                            ],
                          ),
                          onTap: () => _navigateToDetails(playlist),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        tooltip: 'Crea Playlist',
        heroTag: 'createPlaylistButton',
        child: const Icon(Icons.add),
      ),
    );
  }
}


// ------------------- PAGINA DETTAGLI PLAYLIST ------------------- //

/// Pagina che visualizza i dettagli di una singola playlist.
class PlaylistDetailsPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  late Playlist _playlist; // Copia locale per modificare

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  /// Salva le modifiche apportate alla playlist.
  Future<void> _saveChanges() async {
    final playlists = await loadPlaylists();
    final index = playlists.indexWhere((p) => p.id == _playlist.id);
    if (index != -1) {
      playlists[index] = _playlist;
    }
    await savePlaylists(playlists);
  }

  /// Apre la visualizzazione PDF per un dato spartito.
  void _openPdfViewer(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(pdfFile: File(path)),
      ),
    );
  }

  /// Mostra un dialogo per aggiungere uno spartito alla playlist.
  Future<void> _showAddSheetMusicDialog() async {
    final musicDir = await getSheetMusicDirectory();
    final allFiles = musicDir.listSync().whereType<File>().where((f) => f.path.endsWith('.pdf')).toList();
    
    // Filtra i file già presenti nella playlist.
    final availableFiles = allFiles.where((file) => !_playlist.sheetMusicPaths.contains(file.path)).toList();

    if (!mounted) return;
    final selectedFile = await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi alla Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableFiles.isEmpty
              ? const Text('Nessun altro spartito disponibile da aggiungere.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableFiles.length,
                  itemBuilder: (context, index) {
                    final file = availableFiles[index];
                    return ListTile(
                      title: Text(p.basename(file.path).replaceAll('.pdf', '')),
                      onTap: () => Navigator.of(context).pop(file),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla'))],
      ),
    );

    if (selectedFile != null) {
      setState(() {
        _playlist.sheetMusicPaths.add(selectedFile.path);
      });
      await _saveChanges();
    }
  }

  /// Rimuove uno spartito dalla playlist.
  Future<void> _removeFromPlaylist(String path) async {
    setState(() {
      _playlist.sheetMusicPaths.remove(path);
    });
    await _saveChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.name),
      ),
      body: _playlist.sheetMusicPaths.isEmpty
          ? const Center(child: Text('Questa playlist è vuota.\nPremi il pulsante + per aggiungere uno spartito.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _playlist.sheetMusicPaths.length,
              itemBuilder: (context, index) {
                final path = _playlist.sheetMusicPaths[index];
                final fileName = p.basename(path);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(fileName.replaceAll('.pdf', '')),
                    leading: const Icon(Icons.music_note_outlined),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: () => _removeFromPlaylist(path),
                      tooltip: 'Rimuovi dalla Playlist',
                    ),
                    onTap: () => _openPdfViewer(path),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheetMusicDialog,
        tooltip: 'Aggiungi alla Playlist',
        heroTag: 'addSheetMusicToPlaylistButton',
        child: const Icon(Icons.add),
      ),
    );
  }
}


// ------------------- PAGINA VISUALIZZATORE PDF ------------------- //

/// Pagina che visualizza un file PDF.
class PdfViewerPage extends StatefulWidget {
  final File pdfFile;

  const PdfViewerPage({super.key, required this.pdfFile});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isAnnotationMode = false;
  Color _selectedColor = Colors.red;
  // Mappa che associa un numero di pagina a una lista di tratti
  Map<int, List<List<DrawingPoint>>> _annotations = {};
  int _currentPage = 0;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  Future<File> _getAnnotationsFile() async {
    final musicDir = await getSheetMusicDirectory();
    final fileName = p.basenameWithoutExtension(widget.pdfFile.path);
    return File('${musicDir.path}/$fileName.json');
  }

  Future<void> _loadAnnotations() async {
    final file = await _getAnnotationsFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(content);
      setState(() {
        _annotations = jsonMap.map((key, value) {
          final pageIndex = int.parse(key);
          final paths = (value as List).map((path) {
            return (path as List).map((point) => DrawingPoint.fromJson(point)).toList();
          }).toList();
          return MapEntry(pageIndex, paths);
        });
      });
    }
  }

  Future<void> _saveAnnotations() async {
    final file = await _getAnnotationsFile();
    final jsonMap = _annotations.map((key, value) {
      final paths = value.map((path) => path.map((point) => point.toJson()).toList()).toList();
      return MapEntry(key.toString(), paths);
    });
    await file.writeAsString(jsonEncode(jsonMap));
  }

  void _toggleAnnotationMode() {
    setState(() {
      _isAnnotationMode = !_isAnnotationMode;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isAnnotationMode) return;

    final newPath = <DrawingPoint>[];
    final point = DrawingPoint(
      offset: details.localPosition,
      paint: Paint()
        ..color = _selectedColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke,
    );
    newPath.add(point);

    setState(() {
      _annotations.putIfAbsent(_currentPage, () => []).add(newPath);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isAnnotationMode) return;

    final point = DrawingPoint(
      offset: details.localPosition,
      paint: _annotations[_currentPage]!.last.last.paint, // Usa la stessa paint dell'ultimo punto
    );

    setState(() {
      _annotations[_currentPage]!.last.add(point);
    });
  }

  @override
  void dispose() {
    _saveAnnotations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CORREZIONE: Usa MediaQuery per ottenere il padding della safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.pdfFile.path)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: _isAnnotationMode ? Theme.of(context).colorScheme.onBackground : Colors.white),
            tooltip: 'Modalità Annotazione',
            onPressed: _toggleAnnotationMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfFile.path,
            // Disabilita lo swipe solo quando si è in modalità annotazione
            swipeHorizontal: !_isAnnotationMode,
            onViewCreated: (controller) {
              _pdfController = controller;
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
          // Layer per il disegno delle annotazioni
          IgnorePointer(
            ignoring: !_isAnnotationMode, // CORREZIONE: ignora i tocchi se non si è in modalità annotazione
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: CustomPaint(
                painter: AnnotationPainter(annotations: _annotations[_currentPage] ?? []),
                child: Container(), // Un container vuoto per coprire l'intera area
              ),
            ),
          ),
          // Barra degli strumenti per le annotazioni
          if (_isAnnotationMode)
            Positioned(
              // CORREZIONE: Aggiungi il padding della safe area
              bottom: 20 + bottomPadding,
              left: 0,
              right: 0,
              child: AnnotationToolbar(
                selectedColor: _selectedColor,
                onColorChanged: (color) => setState(() => _selectedColor = color),
                onUndo: () {
                  if (_annotations.containsKey(_currentPage) && _annotations[_currentPage]!.isNotEmpty) {
                    setState(() {
                      _annotations[_currentPage]!.removeLast();
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<List<DrawingPoint>> annotations;

  AnnotationPainter({required this.annotations});

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in annotations) {
      for (int i = 0; i < path.length - 1; i++) {
        if (path[i] != null && path[i + 1] != null) {
          canvas.drawLine(path[i].offset, path[i + 1].offset, path[i].paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnnotationToolbar extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onUndo;

  const AnnotationToolbar({super.key, required this.selectedColor, required this.onColorChanged, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.black];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ...colors.map((color) => _buildColorButton(context, color)),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Annulla',
              onPressed: onUndo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Theme.of(context).colorScheme.onBackground : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}