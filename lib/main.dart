import 'dart:convert';
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import 'package:home_cinema_app/view/all_movies_view.dart';
import 'package:home_cinema_app/view/unrecorded_films_view.dart';
import 'package:home_cinema_app/web_server/server_main.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'component/pop_up_menu.dart';
import 'generated/l10n.dart';
import 'repository/db.dart';
import 'service/main_service.dart';
import 'package:home_cinema_app/app_config/colors.dart';
import '../component/modal.dart';
import 'view/settings.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // IGNORE THIS IN MACOS
  // // Initialize FFI
  // sqfliteFfiInit();
  //
  // // Set the database factory
  // databaseFactory = databaseFactoryFfi;

  if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty ? const {} : jsonDecode(args[2]) as Map<String, dynamic>;

    if (arguments['view'] == 'settings') {
      runApp(SettingsApp());
    } else {
      // Handle other potential windows here
    }
    return;
  }

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Remove the title bar
  if (Platform.isMacOS) {
    WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // control windows size
      await windowManager.setSize(const Size(1100, 700));
      await windowManager.setPosition(const Offset(230, 120));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // await startFlaskServer();

  await iniDB();

  //check the running platform
  String? platform = await getConfig("platform");
  if(platform == "null2") {
    if (Platform.isWindows) {
      updateConfig("platform", "windows");
    } else {
      updateConfig("platform", "macos");
    }
  }

  await FFmpegKitConfig.init();
  await insertAllGenres();
  runApp(const MyApp(locale: Locale("en")));

  // await executePythonScript();
  // await checkPythonInstallation();

  // print(getMacOSUsername());

  await startServer();

  var libraryPermission = await getConfig("library_permission");

  if (libraryPermission == "no") {
    await promptAndSaveConfig(navigatorKey.currentContext!);
  }


  // // Use the navigatorKey to get the context and call promptAndSaveConfig
  // WidgetsBinding.instance.addPostFrameCallback((_) async {
  //   await promptAndSaveConfig(navigatorKey.currentContext!);
  // });

  if (Platform.isWindows) {
    initWindowAppDataForder();
    await startFlaskServer();
  }

  await storeUsername();

  // print("name"+getMacOSUsername());
  const platform1 = MethodChannel('com.example.app/settings');

  platform1.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'openSettings') {
      openSettingsWindow();
    }
  });
}

Future<void> storeUsername() async {
  String username = getMacOSUsername();

  await getConfig("username").then((value) async {
    if (value == null) {
      await insertConfig("username", username);
    }else if (value != username) {
      await updateConfig("username", username);
    }
  });
  print("username: $username");
  var name = await getConfig("username");
  print("name: $name");
}

Future<void> promptAndSaveConfig(BuildContext context) async {
  // Show an initial alert dialog explaining the need for access.
  bool? userConfirmed = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permission Required'),
      content: Container(
        width: 300, // Set the desired width
        child: Text('To store configuration files, please select the '
            '~/Library folder. This will allow the app to access '
            'the configuration even after updates.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Proceed'),
        ),
      ],
    ),
  );

  if (userConfirmed == true) {
    // Show the directory picker with `/Users/<username>/Library` as the start point.
    String containerHomeDir = Directory(Platform.environment['HOME']!).path;

    // Extract the username from the sandboxed path
    List<String> parts = path.split(containerHomeDir);
    String username = parts[2];

    String libraryPath = "/Users/$username/Library";

    // Open file picker and request access to the `~/Library` directory.
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select ~/Library Directory. We only store the config file and db file here.',
      initialDirectory: libraryPath,
    );

    // Validate the user's selection.
    if (selectedDirectory != null) {
      if (path.basename(selectedDirectory) == 'Library') {
        // Save the path for your app’s configuration
        String appFolder = path.join(selectedDirectory, 'iSearcher');
        await Directory(path.join(selectedDirectory, 'iSearcher')).create(recursive: true);
        print('create: $appFolder');

        final directory = Directory(appFolder);
        final secureBookmarks = SecureBookmarks();
        try {
          final bookmark = await secureBookmarks.bookmark(directory);

          await updateConfig("library_permission", bookmark);

          var a = await getConfig("library_permission");
          print("a: $a");

        } catch (e) {
          print('Error creating bookmark: $e');
        }


      } else {
        // Show an error if the user didn't select ~/Library
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invalid Selection'),
            content: Text('Please select the ~/Library directory.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}



void initWindowAppDataForder() async {
  String appDataPath = Platform.environment['LOCALAPPDATA'] ?? '';
  String appDataFolder = '$appDataPath\\iSearcher';
  Directory appDataDir = Directory(appDataFolder);
  if (!appDataDir.existsSync()) {
    appDataDir.createSync();
  }

  String posterCacheFolder = '$appDataFolder\\Posters';
  Directory posterCacheDir = Directory(posterCacheFolder);
  if (!posterCacheDir.existsSync()) {
    posterCacheDir.createSync();
  }
}

Future<void> startFlaskServer() async {
  // Ensure Flask is installed
  try {
    final result = await Process.run('python', ['-m', 'pip', 'install', 'flask', 'requests']);
    if (result.stdout.isNotEmpty) {
      print('Pip output: ${result.stdout}');
    }
    if (result.stderr.isNotEmpty) {
      print('Pip error: ${result.stderr}');
    }
  } catch (e) {
    print('Error installing Flask: $e');
    return;
  }

  // Start the Flask server
  final process = await Process.start('python', ['-u', '-c', '''
from flask import Flask, request, send_file, jsonify
import requests
from io import BytesIO
import os

app = Flask(__name__)

@app.route('/fetch_and_download_poster', methods=['GET'])
def fetch_and_download_poster():
    movie_title = request.args.get('movieTitle')
    store_path = request.args.get('storePath')
    print(f"Movie title: {movie_title}, Store path: {store_path}")
    
    if not movie_title:
        return jsonify({"error": "No movie title provided"}), 400
    if not store_path:
        return jsonify({"error": "No store path provided"}), 400

    api_key = '15d2ea6d0dc1d476efbca3eba2b9bbfb'
    url = f'https://api.themoviedb.org/3/search/movie?api_key={api_key}&query={movie_title}'

    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if data['results'] and len(data['results']) > 0:
            poster_path = data['results'][0]['poster_path']
            image_url = f'https://image.tmdb.org/t/p/w500{poster_path}'
            
            print(f"Downloading image from: {image_url}")
            # Download the image
            image_response = requests.get(image_url)
            if image_response.status_code == 200) {
                image_path = os.path.join(store_path, poster_path.strip('/'))
                print(f"Saving image to: {image_path}")
                os.makedirs(os.path.dirname(image_path), exist_ok=True)
                
                with open(image_path, 'wb') as f {
                    f.write(image_response.content)
                }
                
                return jsonify({"message": "Image successfully saved", "imagePath": image_path}), 200
            } else {
                return jsonify({"error": f"Failed to download image. Status code: {image_response.status_code}"}), image_response.status_code
            }
        } else {
            return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=No+Poster+Found'})
        }
    } else {
        return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=Error+Fetching+Poster'}), response.status_code
    }
}

@app.route('/image', methods=['GET'])
def download_image() {
    image_path = request.args.get('image_path')
    if not image_path {
        return jsonify({"error": "No image path provided"}), 400
    }

    url = f"https://image.tmdb.org/t/p/w500/{image_path}"
    response = requests.get(url)

    if response.status_code == 200 {
        img = BytesIO(response.content)
        return send_file(img, mimetype='image/jpeg', as_attachment=True, download_name='downloaded_image.jpg')
    } else {
        return jsonify(
            {"error": f"Failed to download image. Status code: {response.status_code}"}), response.status_code
    }
}

@app.route('/fetch_movie_poster', methods=['GET'])
def fetch_movie_poster() {
    movie_title = request.args.get('movieTitle')
    if not movie_title {
        return jsonify({"error": "No movie title provided"}), 400
    }

    api_key = '15d2ea6d0dc1d476efbca3eba2b9bbfb'
    url = f'https://api.themoviedb.org/3/search/movie?api_key={api_key}&query={movie_title}'

    response = requests.get(url)

    if response.status_code == 200 {
        data = response.json()
        if data['results'] and len(data['results']) > 0 {
            poster_path = data['results'][0]['poster_path']
            return jsonify({"posterUrl": f'https://image.tmdb.org/t/p/w500{poster_path}'})
        } else {
            return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=No+Poster+Found'})
        }
    } else {
        return jsonify({"posterUrl": 'https://via.placeholder.com/500?text=Error+Fetching+Poster'}), response.status_code
    }
}

@app.route('/hello', methods=['GET'])
def hello() {
    return "Hello, World!"
}

if __name__ == '__main__' {
    app.run(debug=True,port=12139)
}
''']);
  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });
  process.stderr.transform(utf8.decoder).listen((data) {
    print(data);
  });
}

Future<void> openSettingsWindow() async {
  final window = await DesktopMultiWindow.createWindow(jsonEncode({
    'view': 'settings',
  }));

  window
    ..setFrame(const Offset(100, 100) & const Size(800, 400))
    ..center()
    ..setTitle('Settings')
    ..show();
}

class SettingsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SettingsWindow(),
      theme: ThemeData(useMaterial3: true),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final Locale locale;
  const MyApp({super.key, required this.locale});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'iSearcher',
      localizationsDelegates: const [
        AppLocalizationDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const AppLocalizationDelegate().supportedLocales,
      locale: locale,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}




class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _groups = [];
  Map<String, bool> _isHovered = {}; // Track hover state for each subitem
  String? _selectedItem;
  Map<int,List<Map<String, dynamic>>> _genres = {};

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    List<Map<String, dynamic>> groups = await getGroups();
    Map<int,List<Map<String, dynamic>>> allGenres = {};
    for (var group in groups) {
      var groupID = group['id'];
      List<Map<String, dynamic>> genres = await getGenres(groupID);
      allGenres[group['id']] = genres;
      print('Group ID: ${group['id']}, Name: ${group['name']} , Password: ${group['password']}');
    }
    setState(() {
      _groups = groups;
      _genres = allGenres;
    });
  }

  @override
  void onWindowClose() {
    // do something
    print('Window closed');
  }

  late S lang;

  _updateLang() async {
    AppLocalizationDelegate delegate = const AppLocalizationDelegate();
    //获取当前系统语言
    Locale myLocale = Localizations.localeOf(context);
    //根据当前语言获取对应的语言数据
    lang = await delegate.load(myLocale);
  }

  @override
  Widget build(BuildContext context) {
    _updateLang();
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: 200,
                child: _buildSidebar(),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTitleBar(),
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(
            left: 200,
            top: 0,
            bottom: 0,
            child: VerticalDivider(thickness: 1, width: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 40,
      color: Colors.white60,
      child: Row(
        children: [
          const SizedBox(width: 5),
          CustomPopupMenuButton(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.grey[105]),
                    onPressed: () {
                      print("Search icon clicked!");
                    },
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                ),
                style: TextStyle(color: AppColors.black),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.yellow),
              onPressed: () {
                CustomModal.show(
                  context,
                  'Modal Title',
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter something...',
                        ),
                      ),
                    ],
                  ),
                  [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Submit'),
                      onPressed: () {
                        // Handle submit action
                      },
                    ),
                  ],
                  width: 300,
                  height: 200,
                );
              },
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }


  Map<String, IconData> iconMap = {
    'Icons.video_library_outlined': Icons.video_library_outlined,
    'Icons.group': Icons.group,
    'Icons.settings_outlined': Icons.settings_outlined,
    'Icons.movie': Icons.movie,
    'Icons.play_circle_outline': Icons.play_circle_outline,
    'Icons.photo_library': Icons.photo_library,
    'Icons.photo_camera': Icons.photo_camera,
    'Icons.camera_alt': Icons.camera_alt,
    'Icons.videocam': Icons.videocam,
    'Icons.videocam_outlined': Icons.videocam_outlined,
    'Icons.play_arrow': Icons.play_arrow,
    'Icons.pause': Icons.pause,
    'Icons.stop': Icons.stop,
    'Icons.favorite': Icons.favorite,
    'Icons.favorite_outline': Icons.favorite_outline,
    'Icons.share': Icons.share,
    'Icons.download': Icons.download,
    'Icons.file_download': Icons.file_download,
    'Icons.bookmark': Icons.bookmark,
    'Icons.bookmark_border': Icons.bookmark_border,
    'Icons.subtitles': Icons.subtitles,
    'Icons.tv': Icons.tv,
    'Icons.star': Icons.star,
    'Icons.star_border': Icons.star_border,
    'Icons.rate_review': Icons.rate_review,
    'Icons.thumb_up': Icons.thumb_up,
    'Icons.thumb_down': Icons.thumb_down,
    'Icons.slideshow': Icons.slideshow,
    'Icons.add_to_photos': Icons.add_to_photos,
    'Icons.collections': Icons.collections,
    'Icons.album': Icons.album,
  };

  List<Map<String, dynamic>> _subOptions = [
    {'name': 'All', 'icon': Icons.list},
    // Add more sub-options as needed
  ];

  IconData getIconData(String iconName) {
    return iconMap[iconName] ?? Icons.help_outline; // Default icon if no match is found
  }


  Widget _buildSidebar() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              lang.app_title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.video_library_outlined),
                  title: Text(
                    'Unrecorded Films',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                      _selectedItem = 'Unrecorded Films';
                    });
                  },
                  selected: _selectedItem == 'Unrecorded Films',
                  selectedTileColor: Colors.deepPurple,
                ),
                ..._groups.map((group) {
                  return ExpansionTile(
                    leading: Icon(getIconData(group['icon'])),
                    title: Text(
                      group['name'],
                      style: TextStyle(fontSize: 13),
                    ),
                    children: [
                      for (var genre in _genres[group['id']]!) _buildSubItem(group, genre['name']),
                    ],
                  );
                }).toList(),
                ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text(
                    'Settings',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = _groups.length + 1;
                      _selectedItem = 'Settings';
                    });
                    openSettingsWindow();
                  },
                  selected: _selectedItem == 'Settings',
                  selectedTileColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(Map<String, dynamic> group, String subItem) {
    String key = '${group['name']}-$subItem';
    return ListTile(
      title: InkWell(
        onTap: () {
          setState(() {
            _selectedItem = key;
          });
          print("Clicked on $subItem in ${group['name']}");
        },
        onHover: (isHovered) {
          setState(() {
            _isHovered[key] = isHovered;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _selectedItem == key
                ? Colors.blue
                : _isHovered[key] == true
                ? Colors.blue.shade100
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            subItem,
            style: TextStyle(
              color: _selectedItem == key
                  ? Colors.white
                  : _isHovered[key] == true
                  ? Colors.blue
                  : Colors.black,
            ),
          ),
        ),
      ),
      dense: true,
      visualDensity: VisualDensity(vertical: -4),
    );
  }


  Widget _buildMainContent() {
    if (_selectedIndex == 0) {
      return UnrecordedFilmsView(lang: lang);
    } else if (_selectedIndex == _groups.length + 1) {
      return const Center(child: Text('Settings')); // Placeholder for settings
    } else if (_selectedIndex > 0 && _selectedIndex <= _groups.length) {
      final group = _groups[_selectedIndex - 1];
      return Center(child: Text('Group: ${group['name']}')); // Placeholder for group content
    } else {
      return const Center(child: Text('Unknown Page'));
    }
  }




}

class ImageDownloader {
  static const platform = MethodChannel('image_download_channel');

  Future<Image> downloadImage(String imageName) async {
    try {
      final String base64Image = await platform.invokeMethod('getImage', {'imageName': imageName});
      final bytes = base64.decode(base64Image);
      return Image.memory(Uint8List.fromList(bytes));
    } catch (e) {
      print("Error downloading image: $e");
      return Image.asset('assets/err_img2.png'); // Fallback image in case of error
    }
  }

  Future<List<String>?> getImageStorageInfo() async {
    try {
      final List<String>? info = await platform.invokeMethod("info");
      print('Image storage info: $info');
      return info;
    } on PlatformException catch (e) {
      print("Error getting image storage info: '${e.message}'.");
      return null;
    }
  }
}