import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:home_cinema_app/component/movie_label.dart';
import 'package:home_cinema_app/component/overlay.dart';
import 'package:home_cinema_app/service/db_ansy.dart';
import 'package:home_cinema_app/service/main_service.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import '../component/inner_top_bar.dart';
import '../component/tags.dart';
import '../main.dart';
import '../repository/db.dart';
import '../models/video_file.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import '../component/modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../service/local_file_operation.dart';


class UnrecordedFilmsView extends StatefulWidget {
  @override
  _UnrecordedFilmsViewState createState() => _UnrecordedFilmsViewState();
}

class _UnrecordedFilmsViewState extends State<UnrecordedFilmsView> {
  bool _tagsAdded = false;
  Map<String,String> movieLabels = {};
  String? _filmsFolder;
  String? _selectedOption = 'All Folder';
  final List<String> _options = ['All Folder'];
  List<VideoFile> _videoFiles = [VideoFile(name: "empty", path: "empty_placeholder", size: 0, lastModified: DateTime.now())];
  bool _isLoading = false;
  List<Widget> tagFields = [];
  String? _searchEngine;
  String? _modalErrorMessage;
  String? _platform;
  String? _selectedSubtitlePath = "";
  List<String> _subtitles = [];

  List<Map<String, String>> _cast = [];



  // a map to hold the options and their values, default is 'All Folder': 'All Folder'
  Map<String, List<String>> _optionsMap = {'All Folder': ['All Folder', 'All Folder']};
  List<Map<String, dynamic>> _allFilmsFolder = [];

  List<TextEditingController> _tagControllers = [];
  TextEditingController filmNameController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  String coverImg = "";

  // Define _selectedCategory and _categories
  String _selectedCategory = ''; // Default category
  final List<String> _categories = [];

  String _selectedFileType = 'Movie'; // Add this state variable

  String _movieOverview = '';

  final List<Color> lightColors = [
    Colors.red.shade200,
    Colors.pink.shade200,
    Colors.purple.shade200,
    Colors.deepPurple.shade200,
    Colors.indigo.shade200,
    Colors.blue.shade200,
    Colors.lightBlue.shade200,
    Colors.cyan.shade200,
    Colors.teal.shade200,
    Colors.green.shade200,
    Colors.lightGreen.shade200,
    Colors.lime.shade200,
    Colors.yellow.shade200,
    Colors.amber.shade200,
    Colors.orange.shade200,
    Colors.deepOrange.shade200,

    // Additional light colors
    Colors.brown.shade200,
    Colors.grey.shade200,
    Colors.blueGrey.shade200,
    Colors.pink.shade100,
    Colors.purple.shade100,
    Colors.deepPurple.shade100,
    Colors.indigo.shade100,
    Colors.blue.shade100,
    Colors.cyan.shade100,
    Colors.teal.shade100,
    Colors.green.shade100,
    Colors.lightGreen.shade100,
    Colors.yellow.shade100,
    Colors.amber.shade100,
    Colors.orange.shade100,
    Colors.deepOrange.shade100,
    Colors.brown.shade100,
  ];

  List<Map<String, dynamic>> tagsWithColors = [
    // {"tag": "Pineapple", "color": Colors.orange.shade200},
    // {"tag": "Lemons", "color": Colors.yellow.shade300},
    // {"tag": "Watermelon", "color": Colors.green.shade200},
  ];

  List<Map<String, dynamic>> genresWithColors = [

  ];



  void addTag(String tag, [Color? color]) {
    setState(() {
      tagsWithColors.add({
        'tag': tag,
        'color': color ?? _getRandomColor(),
      });
    });
  }

  void addGenres(String genre) {
    setState(() {
      genresWithColors.add({
        'tag': genre,
        'color': Colors.brown.shade200,
      });
    });
  }

  void addCast(List<Map<String,String>> casts){
    setState(() {
      _cast = casts;
    });
  }

  void addOverview(String overview) {
    setState(() {
      _movieOverview = overview;
    });
  }

  Color _getRandomColor() {
    // Generate a random color
    final Random random = Random();
    return lightColors[random.nextInt(lightColors.length)];
  }


  void _updateFileType(String fileType) {
    setState(() {
      _selectedFileType = fileType;
    });
  }

  void _updateSubtitlePath(String? subTitlePath) {
    setState(() {
      _selectedSubtitlePath = subTitlePath;
      if (subTitlePath != null) {
        _subtitles.add(subTitlePath);
        _subtitles = _subtitles.toSet().toList(); // Remove duplicates
      }
    });

    print("Selected Subtitle Path: $_selectedSubtitlePath");
    print("Subtitles: $_subtitles");
  }

  @override
  void initState() {
    super.initState();
    _loadFilmsFolder();
    _loadOther();
    check();
  }

  Future<void> check() async {
  var bookmarks = SecureBookmarks();
  var permission = await getConfig("library_permission");
  final resolvedFile = await bookmarks.resolveBookmark(permission!);
  try {
    await bookmarks.startAccessingSecurityScopedResource(resolvedFile);
    print("Permission granted");

    // List the contents of the directory and print each file name
    final directory = Directory(resolvedFile.path);
    final List<FileSystemEntity> entities = directory.listSync();
    for (var entity in entities) {
      print(entity.path);
    }
  } catch (e) {
    print("Permission denied");
  } finally {
    await bookmarks.stopAccessingSecurityScopedResource(resolvedFile);
  }
}


  Future<void> _loadOther() async{
    String? platform = await getConfig('platform');
    // print("platform: $platform");
    // List<String> categories = await getCategories();
    String? engine = await getConfig('search_engine');
    // print("engine: $engine");
    await downloadCastAvatar("6DdoTgW9jdJwDmVFZRP8D0AtVFs.jpg");
    await downloadDB();

    //load the folders
    setState(() {
      _platform = platform;

      // if (categories.isNotEmpty) {
      //   _categories.addAll(categories);
      //   _selectedCategory = categories[0];
      // }
      _searchEngine = engine;
    });
  }


  Future<void> _loadFilmsFolder() async {
  final secureBookmarks = SecureBookmarks();
  List<Map<String, dynamic>> allFilmFolder = await loadAllUserDefaultDESCInTime();
  String? bookmark;

  setState(() {
    _allFilmsFolder = allFilmFolder;
    for (var folder in _allFilmsFolder) {
      String fileFolder = folder['films_folder'];
      String lastFolder = fileFolder.split(Platform.pathSeparator).last;
      if (!_options.contains(lastFolder) && lastFolder != 'null1') {
        _options.add(lastFolder);
        _optionsMap[lastFolder] = [fileFolder, folder['bookMarks']];
      }
    }
  });

  bookmark = _allFilmsFolder[0]['bookMarks'];
  String lastFolder = _allFilmsFolder[0]['films_folder'].split(Platform.pathSeparator).last;
  final folder = _allFilmsFolder[0]['films_folder'];

  setState(() {
    _filmsFolder = folder;
  });

  if (bookmark == "bookmark_placeholder") {
    final folder = _allFilmsFolder[0]['films_folder'];
    String? lastFolder = folder?.split('\\').last;

    setState(() {
      _selectedOption = lastFolder;
      _filmsFolder = folder;
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 100)); // Yield control back to the UI thread
    await _loadVideoFiles();

    setState(() {
      _isLoading = false;
    });

  } else if (bookmark != null && bookmark != "null1") {
    try {
      final resolvedFile = await secureBookmarks.resolveBookmark(bookmark);
      List<String> folders = resolvedFile.path.split('/');
      String lastFolder = folders[folders.length - 1];

      setState(() {
        _selectedOption = lastFolder;
      });

      try {
        await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);

        setState(() {
          _filmsFolder = resolvedFile.path;
          _isLoading = true;
        });

        // addSubtitleToVideo(
        //     '/Volumes/movie-disk-1/Home Cinema/The.Wolverine.2013.1080p.BluRay.DDP7.1.x264-MOMOHD.mkv',
        //     '/Volumes/movie-disk-1/Home Cinema/subtitle/Iron.Man.2008.US.2160p.BluRay.x265.10bit.SDR.DTS-HD.MA.TrueHD.7.1.Atmos-SWTYBLZ.zh.ass',
        //     '/Volumes/movie-disk-1/Home Cinema/subtitle/a.mkv');

        // moveFile('/Volumes/movie-disk-1/Home Cinema/The.Wolverine.2013.1080p.BluRay.DDP7.1.x264-MOMOHD.mkv',
        //     '/Volumes/movie-disk-1/Home Cinema/subtitle/abc.mkv');

        await Future.delayed(Duration(milliseconds: 100)); // Yield control back to the UI thread
        await _loadVideoFiles();

        setState(() {
          _isLoading = false;
        });
      } finally {
        await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
      }
    } on PlatformException catch (e) {
      if (e.code == 'UnexpectedError' && e.message?.contains('NSCocoaErrorDomain Code=4') == true) {
        print("Error: The file doesn’t exist.");
        print(e);
        setState(() {
          _isLoading = false;
          _videoFiles = [VideoFile(name: "F01", path: "No such file or directory", size: -9999, lastModified: DateTime.now())];
          _selectedOption = lastFolder;
        });
      } else {
        print("Erroraaaaa: $e");
      }
    }
  } else {
    setState(() {
      _filmsFolder = 'null1';
    });
  }
}

  Future<void> _loadAllVideoFilesWindows() async {
    List<VideoFile> allList = [];
    for (var option in _optionsMap.entries) {
      if(option.key != 'All Folder'){
        _filmsFolder = option.value[0];
        List<VideoFile> list = await readVideoFiles(_filmsFolder!);
        allList.addAll(list);
      }
    }
    setState(() {
      _videoFiles = allList;
    });
  }


  Future<void> _loadAllVideoFilesMacOS() async {
    final secureBookmarks = SecureBookmarks();
    List<VideoFile> allList = [];
    for (var option in _optionsMap.entries) {
      if(option.key != 'All Folder'){
        _filmsFolder = option.value[0];
        String? bookmark = option.value[1];
        final resolvedFile = await secureBookmarks.resolveBookmark(bookmark);
        await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
        try {
          List<VideoFile> list = await readVideoFiles(_filmsFolder!);
          if (list[0].size != -9999) {
            allList.addAll(list);
          }
        } finally {
          await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
        }
      }
    }
    setState(() {
      _videoFiles = allList;
    });
  }

  Future<void> _loadVideoFiles() async {
    List<VideoFile> list = await readVideoFiles(_filmsFolder!);
    print(_filmsFolder);
    setState(() {
      _videoFiles = list;
    });
  }

  Future<void> _onDropdownChanged(String? newValue) async {
    final secureBookmarks = SecureBookmarks();
    setState(() {
      _selectedOption = newValue;
    });
    if (newValue == 'All Folder') {
      _filmsFolder = "All Folder";
      if(_platform == 'macos') {
        await _loadAllVideoFilesMacOS();
      }else{
        await _loadAllVideoFilesWindows();
      }
    }else{
      if(_platform == 'macos'){
        _filmsFolder = _optionsMap[newValue]?[0];
        String? bookmark = _optionsMap[newValue]?[1];
        try{
          final resolvedFile = await secureBookmarks.resolveBookmark(bookmark!);
          await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
          try{
            await _loadVideoFiles();
          }finally{
            await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
          }
        }on PlatformException catch(e){
          if (e.code == 'UnexpectedError' && e.message?.contains('NSCocoaErrorDomain Code=4') == true) {
            print("Error: The file doesn’t exist.");
            // Handle the specific error here

            setState(() {
              _isLoading = false;
              _videoFiles = [VideoFile(name: "F01", path: "No such file or directory", size: -9999, lastModified: DateTime.now())];
              _selectedOption = _filmsFolder!.split(Platform.pathSeparator).last;
            });
          } else {
            print("Error: $e");
          }
        }


      }else{
        _filmsFolder = _optionsMap[newValue]?[0];
        await _loadVideoFiles();
      }

    }
    print("Selected: $_selectedOption");
  }



  Future<void> _rescanFolder() async {
    print("Rescanning folder...");
    if (_filmsFolder != null) {
      print("Rescanning folder: $_filmsFolder");
      if(_selectedOption == 'All Folder'){
        if(_platform == 'macos') {
          await _loadAllVideoFilesMacOS();
        }else{
          await _loadAllVideoFilesWindows();
        }
      }else{
        setState(() {
          _isLoading = true;
        });
        if(_platform == 'macos'){
          final secureBookmarks = SecureBookmarks();
          String? bookmark = _optionsMap[_selectedOption]?[1];
          try{
            final resolvedFile = await secureBookmarks.resolveBookmark(bookmark!);
            await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
            try {
              await _loadVideoFiles();
            } finally {
              await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
            }
          }on PlatformException catch (e) {
            if (e.code == 'UnexpectedError' && e.message?.contains('NSCocoaErrorDomain Code=4') == true) {
              print("Error: The file doesn’t exist111111111.");
              // add a 1 second delay
              await Future.delayed(Duration(milliseconds: 500));
              setState(() {
                _videoFiles = [VideoFile(name: "F01", path: "No such file or directory", size: -9999, lastModified: DateTime.now())];
              });
            } else {
              print("Erroraaaaa: $e");
            }
          }

        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addFolder() async{
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if(_platform == 'macos'){
        final secureBookmarks = SecureBookmarks();
        final directory = Directory(selectedDirectory);
        try {
          final bookmark = await secureBookmarks.bookmark(directory);
          await appConfigInit(selectedDirectory);
          if(_filmsFolder == 'null1'){
            await setUserDefaultOfLine1(bookmark, selectedDirectory);
          }else{
            await addNewUserDefault(bookmark, selectedDirectory);
          }
          await _loadFilmsFolder();
        } catch (e) {
          print('Error creating bookmark: $e');
        }
      }else{
        // For Windows
        try {
          // Get last folder name
          setState(() {
            _isLoading = true;
          });
          await appConfigInit(selectedDirectory);
          if(_filmsFolder == 'null1'){
            await setUserDefaultOfLine1("bookmark_placeholder", selectedDirectory);
          }else{
            await addNewUserDefault("bookmark_placeholder", selectedDirectory);
          }
          await _loadFilmsFolder();
          setState(() {
            _isLoading = false;
          });
        } catch (e) {
          print('Error handling directory: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey[300]),
          InnerTopBar(
            label: 'Current Folder:',
            options: _options,
            selectedOption: _selectedOption,
            onChanged: _onDropdownChanged,
            additionalWidgetsAfterSelector: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  await _addFolder();
                },
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  // open the custom modal to manage the file folders can delete or add new
                },
              ),
            ],
            additionalWidgets: [
              Row(
                children: [
                  const Text("File detected: "),
                  _isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('${_videoFiles.length}'),
                ],
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _rescanFolder();
                },
              ),
            ],
          ),
          Expanded(
            child: _filmsFolder == 'null1'
                ? Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _addFolder();
                },

                child: Text('Select Folder'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
                : _isLoading || _videoFiles[0].name == "empty"
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading video files...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : _videoFiles[0].name == "F02"
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No video files found.', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _rescanFolder,
                    child: Text('Re-scan'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
            : _videoFiles[0].size == -9999
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // show an error icon
                  const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 48),
                  SizedBox(height: 5),
                  Text('iSearcher cannot open the folder or scan the video file', style: TextStyle(color: Colors.grey[600])),
                  // show the error code and content
                  Text('Error Code: ${_videoFiles[0].name}', style: TextStyle(color: Colors.grey[600])),
                  Text('Error Detail: ${_videoFiles[0].path}', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 10),
                  Row( // Use a Row widget for horizontal alignment
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _rescanFolder,
                        child: Text('Re-scan'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // Add spacing between the buttons
                      ElevatedButton(
                        onPressed: _rescanFolder,
                        child: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            :ListView.builder(
              itemCount: _videoFiles.length,
              itemBuilder: (context, index) {
                final videoFile = _videoFiles[index];
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _showEditFilmDetailsModal(context, videoFile);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.movie, color: Colors.blue, size: 24),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    videoFile.name,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Size: ${videoFile.size >= 1000 * 1000 * 1000 ? (videoFile.size / 1000 / 1000 / 1000).toStringAsFixed(2) + " GB" : (videoFile.size / 1024 / 1024).toStringAsFixed(2) + " MB"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Modified: ${videoFile.lastModified}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            // Add a Play button here
                            IconButton(
                              icon: Icon(Icons.play_circle_outline_outlined, color: Colors.blue),
                              onPressed: () async {
                                LoadingOverlay.show(
                                  context,
                                  'Opening video...',
                                  width: 200,
                                  height: 120,
                                );
                                if (_platform == "macos"){
                                  // add 5 second delay
                                  await Future.delayed(Duration(seconds: 5));
                                  final secureBookmarks = SecureBookmarks();
                                  String? bookmark = _optionsMap[_selectedOption]?[1];
                                  final resolvedFile = await secureBookmarks.resolveBookmark(bookmark!);
                                  await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
                                  final videoPath = videoFile.path;
                                  final Uri videoUri = Uri.file(videoPath);
                                  try{
                                    if (await canLaunchUrl(videoUri)) {
                                      await launchUrl(videoUri);
                                    } else {
                                      print('Could not launch $videoPath');
                                    }
                                  }finally{
                                    LoadingOverlay.hide(context);
                                    await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
                                  }
                                }else{
                                  final videoPath = videoFile.path;
                                  final Uri videoUri = Uri.file(videoPath);
                                  if (await canLaunchUrl(videoUri)) {
                                    await launchUrl(videoUri);
                                  } else {
                                    print('Could not launch $videoPath');
                                  }
                                }
                              },
                            ),
                            SizedBox(width: 28),
                          ],
                        ),
                      ),
                    ),
                    if (index < _videoFiles.length - 1)
                      Divider(height: 1, color: Colors.grey[300]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _movieLabels() {
    List<Widget> labelWidgets = [];
    print("movieLabels: $movieLabels");

    if (movieLabels.containsKey("year")) {
      labelWidgets.add(MovieLabel(text: movieLabels["year"]!, width: 22, height: 18, backgroundColor: Colors.grey));
    }
    if (movieLabels.containsKey("resolution")) {
      labelWidgets.add(SizedBox(width: 6));
      labelWidgets.add(MovieLabel(text: movieLabels["resolution"]!, width: 26, height: 18, backgroundColor: Colors.deepOrangeAccent));
    }
    if (movieLabels["remux"] == "true") {
      labelWidgets.add(SizedBox(width: 6));
      labelWidgets.add(MovieLabel(text: "REMUX", width: 30, height: 18, backgroundColor: Colors.greenAccent));
    }
    if (movieLabels["bluray"] == "true") {
      // labelWidgets.add(SizedBox(width: 6));
      // labelWidgets.add(MovieLabel(text: "REMUX", width: 33, height: 18, backgroundColor: Colors.greenAccent));
      labelWidgets.add(SizedBox(width: 6));
      labelWidgets.add(MovieLabel(text: "BluRay", width: 30, height: 18, backgroundColor: Colors.blue));
    }
    if (movieLabels["atmos"] == "true") {
      labelWidgets.add(SizedBox(width: 6));
      labelWidgets.add(MovieLabel(text: "ATMOS", width: 33, height: 18, backgroundColor: Colors.orange));
    }
    if (movieLabels["INT"] == "true") {
      labelWidgets.add(SizedBox(width: 6));
      labelWidgets.add(MovieLabel(text: "INT", width: 18, height: 18, backgroundColor: Colors.purple));
    }

    return InkWell(
      onTap: () {
        print("Row clicked");
        // Handle the click event for the entire row
      },
      child: Row(
        children: labelWidgets,
      ),
    );
  }




    // call this api https://movie.bugsmachine.top/tmdb/search?movie_name=loki&movie_type=1
    // to get the movie details

    Future<Map<String, dynamic>> _loadMovieDetails(String movieID, String type) async {
      final response = await http.get(
        Uri.parse('https://movie.bugsmachine.top/tmdb/details?movie_id=$movieID&movie_type=$type'),
      );

      print('https://movie.bugsmachine.top/tmdb/search?movie_id=$movieID&movie_type=$type');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'keywords': List<String>.from(data['keywords']),
          'genres': List<String>.from(data['genres']),
          'overview': data['overview'],
          'cast': List<Map<String, String>>.from(data['cast'].map((item) => Map<String, String>.from(item))),
        };
      } else {
        print(response.body);
        throw Exception('Failed to load movie details');
      }
    }




  Future<void> _showEditFilmDetailsModal(BuildContext context, VideoFile videoFile) async {
    setState(() {
      coverImg = "";
      _tagsAdded = false; // Reset the flag here
      tagsWithColors.clear();
      _movieOverview = "";
      genresWithColors.clear();
      _cast.clear();
    });
    String imagePath = '';
    GlobalKey<State> modalKey = GlobalKey<State>();
    tagFields.add(_buildTagField(0, modalKey));
    String filmName = '';
    String fileExtension = '.${videoFile.name.split('.').last}';

    filmNameController.text = "";
    categoryController.text = "";

    tagFields.clear();
    _tagControllers.clear();
    tagFields.add(_buildTagField(0, modalKey));
    _tagControllers.add(TextEditingController());

    String movieID = "";
    String type = "0";

    LoadingOverlay.show(
      context,
      'Predicting Movie Detail...',
      width: 250,
      height: 150,
    );

    Map<String, String?> movieInfo = await predictMovieDetail(videoFile.name);
    print("movieInfo: $movieInfo");
    for (var key in movieInfo.keys) {
      if (key == "err") {
        print("Error predicting movie detail");
        setState(() {
          _selectedFileType = "video";
        });
      } else if (key == "title") {
        filmName = movieInfo[key]!;
        filmNameController.text = filmName;
      } else if (key == "posterUrl") {
        imagePath = movieInfo[key]!;
        print("imagePath: $imagePath");
        setState(() {
          coverImg = imagePath;
        });
      } else if (key == "year") {
        movieLabels["year"] = movieInfo[key]!;
      } else if (key == "resolution") {
        movieLabels["resolution"] = movieInfo[key]!;
      } else if (key == "isRemux") {
        movieLabels["remux"] = movieInfo[key]!;
      } else if (key == "isBluRay") {
        movieLabels["bluray"] = movieInfo[key]!;
      } else if (key == "isAtmos") {
        movieLabels["atmos"] = movieInfo[key]!;
      } else if (key == "isINT") {
        movieLabels["INT"] = movieInfo[key]!;
      } else if (key == "movieID") {
        movieID = movieInfo[key]!;
      } else if(key == "type") {
        type = movieInfo[key]!;
      }
    }

    String newFilePath = '${_filmsFolder!}/recorded_films/$filmName/${videoFile.name}';

    LoadingOverlay.hide(context);

    if(movieID.isEmpty) {
      setState(() {
        _tagsAdded = true;
      });
    }

    CustomModal.show(
      context,
      'Edit Film Details',
      StatefulBuilder(
        key: modalKey,
        builder: (BuildContext context, StateSetter modalSetState) {
          return Container(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with film details and poster
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Main content
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Film name and search section
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: filmNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Film Name (English Name is better for the Poster search)',
                                      labelStyle: TextStyle(height: 0.8),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        filmName = value;
                                        newFilePath = '${_filmsFolder!}/recorded_films/$filmName/$filmName$fileExtension';
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Tooltip(
                                  message: 'Search detail information for the movie: $filmName',
                                  child: IconButton(
                                    icon: Icon(Icons.search_rounded),
                                    onPressed: () {
                                      print("Search for movie detail");
                                    },
                                  ),
                                )
                              ],
                            ),
                            _buildNonEditableField('File Path', newFilePath, "This is the new planned file path. Original path ${videoFile.path}"),
                            _fileType(_updateFileType, _updateSubtitlePath),
                            SizedBox(height: 10),

                            // Genres Section
                            StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Genres:', style: TextStyle(fontSize: 13, color: Colors.black)),
                                    SizedBox(height: 8),
                                    if (!_tagsAdded)
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Loading Genres...',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Tags(
                                        tagsWithColors: genresWithColors,
                                        onRemove: (tag) {
                                          setState(() {
                                            genresWithColors.removeWhere((tagData) => tagData['tag'] == tag);
                                          });
                                        },
                                      ),

                                    if(_tagsAdded)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => _showAddGenreDialog(context, setState),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add a new genre',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                );
                              },
                            ),

                            // Categories Section
                            // _buildCategoriesSection(),

                            SizedBox(height: 10),

                            // Tags Section
                            StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tags:', style: TextStyle(fontSize: 13, color: Colors.black)),
                                    SizedBox(height: 8),
                                    if (!_tagsAdded)
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Loading tags...',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Tags(
                                        tagsWithColors: tagsWithColors,
                                        onRemove: (tag) {
                                          setState(() {
                                            tagsWithColors.removeWhere((tagData) => tagData['tag'] == tag);
                                          });
                                        },
                                      ),

                                    if(_tagsAdded)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => _showAddTagDialog(context, setState),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add a new tag',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 13),
                      // Right column - Movie poster
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 300,
                          maxWidth: 200,
                        ),
                        child: _movieImageBox(),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Main Cast:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _cast.isEmpty
                          ? const Center(
                        child: CircularProgressIndicator(),
                      )
                          : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _cast.map((castMember) {
                            final name = castMember['name'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Tooltip(
                                      message: name,
                                      child: FutureBuilder<String>(
                                        future: downloadCastAvatar(castMember['profile_path'] ?? ''),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircleAvatar(
                                              radius: 50,
                                              child: CircularProgressIndicator(),
                                            );
                                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                            return const CircleAvatar(
                                              radius: 50,
                                              child: Icon(Icons.person, size: 40),
                                            );
                                          } else {
                                            return CircleAvatar(
                                              radius: 50,
                                              backgroundImage: FileImage(File(snapshot.data!)),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 20,
                                      child: Tooltip(
                                        message: name,
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 32,
                                      child: Text(
                                        castMember['character'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 16,
                                      child: Text(
                                        castMember['episodes'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  // Movie Details Section
                  movieID.isEmpty
                      ? Center(child: Text('No movie details available'))
                      : FutureBuilder<Map<String, dynamic>>(
                    future: _loadMovieDetails(movieID, type),
                    builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox.shrink();
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading movie details: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        var movieDetails = snapshot.data!;
                        var genres = movieDetails['genres'] as List<String>;
                        var keywords = movieDetails['keywords'] as List<String>;
                        var cast = movieDetails['cast'] as List<Map<String, String>>;
                        String overview = movieDetails['overview'];

                        print(cast);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _addTags(keywords, overview, modalSetState, genres, cast);
                        });

                        return SizedBox.shrink();
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Text('Genres: ${genres.join(', ')}'),
                        //     Text('Keywords: ${keywords.join(', ')}'),
                        //     Text('Cast: ${cast.map((c) => c['name']).join(', ')}'),
                        //   ],
                        // );
                      } else {
                        return Center(child: Text('No movie details available'));
                      }
                    },
                  )
                ],
              ),
            ),
          );
        },
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
            print(_collectInfo());
          },
        ),
      ],
      width: 600,
      height: 400,
    );
  }

// Helper method to show add genre dialog
  void _showAddGenreDialog(BuildContext context, StateSetter setState) {
    TextEditingController newGenreController = TextEditingController();

    CustomModal.show(
      context,
      'Add New Genre',
      StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return TextField(
            controller: newGenreController,
            decoration: InputDecoration(
              labelText: 'Genre Name',
            ),
          );
        },
      ),
      [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Create'),
          onPressed: () {
            String newGenreName = newGenreController.text.trim();
            if (newGenreName.isNotEmpty) {
              setState(() {
                addGenres(newGenreName);
              });
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

// Helper method to show add tag dialog
  void _showAddTagDialog(BuildContext context, StateSetter setState) {
    TextEditingController newTagController = TextEditingController();

    CustomModal.show(
      context,
      'Add New Tag',
      StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return TextField(
            controller: newTagController,
            decoration: InputDecoration(
              labelText: 'Tag Name',
            ),
          );
        },
      ),
      [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Create'),
          onPressed: () {
            String newTagName = newTagController.text.trim();
            if (newTagName.isNotEmpty) {
              setState(() {
                addTag(newTagName);
              });
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }


  void _addTags(List<String> keywords, String overview, StateSetter modalSetState,
      List<String> genres, List<Map<String,String>> cast) {
    if (!_tagsAdded) {
      modalSetState(() {
        for (var keyword in keywords) {
          addTag(keyword);
        }
        for (var genre in genres) {
          addGenres(genre);
        }
        addCast(cast);
        addOverview(overview);
        _tagsAdded = true;
      });
    }
  }



  Widget _movieImageBox() {
    final imageDownloader = ImageDownloader();
    String imageName = coverImg.split('/').last;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Centered header row
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Movie Poster',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              SizedBox(width: 4),
              Tooltip(
                message: 'Poster image from tmdb.org, NO commercial use!',
                child: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Centered poster container
        Center(
          child: coverImg == ""
              ? Container(
            width: 150,
            height: 230,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset('assets/no_img.png'),
            ),
          )
              : FutureBuilder<Image>(
            future: imageDownloader.downloadImage(imageName),
            builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 150,
                  height: 230,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Container(
                  width: 150,
                  height: 230,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else {
                return Container(
                  width: 150,
                  height: 230,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    image: snapshot.hasData
                        ? DecorationImage(
                      image: snapshot.data!.image,
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                );
              }
            },
          ),
        ),
        SizedBox(height: 8),
        // Centered buttons
        Center(
          child: coverImg == ""
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Handle upload action
                },
                child: Text('Upload'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Handle search action
                },
                child: Text('Search'),
              ),
            ],
          )
              : ElevatedButton(
            onPressed: () {
              // Handle delete action
            },
            child: Text('Delete Poster'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagField(int index, GlobalKey modalKey) {
    // Ensure the controller list is large enough
    if (_tagControllers.length <= index) {
      _tagControllers.add(TextEditingController());
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _tagControllers[index],
            decoration: InputDecoration(
              labelText: 'Tag ${index + 1}',
            ),
          ),
        ),
        if (index > 0) // Only show the delete icon if the index is greater than 0
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              if (tagFields.length == 1) {
                CustomModal.show(
                  context,
                  'Error',
                  Text('At least one tag field is required.'),
                  [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
                return;
              }
              // Update both modal and parent state to reflect the change
              modalKey.currentState?.setState(() {
                print(index);
                tagFields.removeAt(index);
                // add an empty view at the place delete tagFileds
                tagFields.insert(index, SizedBox.shrink()); // Add an empty view at the same index
                // get the controller at the index and set the value to empty
                _tagControllers[index].text = '';
                // _tagControllers.removeAt(index);
              });
              // setState(() {
              //   print(_tagControllers.length);
              //   tagFields.removeAt(index);
              //   _tagControllers.removeAt(index);
              // });
              print('removed tag field at index $index');
              print(tagFields);
            },
          ),
      ],
    );
  }

  Widget _fileType(void Function(String) updateFileType, void Function(String?) updateSubtitlePath) {
    List<bool> isSelected = [
      _selectedFileType == 'Movie',
      _selectedFileType == 'TV Show',
      _selectedFileType == 'Video'
    ]; // Initial selection state

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Select File Type:',
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                SizedBox(width: 8),
                ToggleButtons(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Movie'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('TV Show'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Video'),
                    ),
                  ],
                  isSelected: isSelected,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < isSelected.length; i++) {
                        isSelected[i] = i == index;
                      }

                      if (isSelected[0]) {
                        setState(() {
                          _selectedFileType = 'Movie';
                        });
                        updateFileType('Movie');
                      } else if (isSelected[1]) {
                        setState(() {
                          _selectedFileType = 'TV Show';
                        });
                        updateFileType('TV Show');
                      } else {
                        setState(() {
                          _selectedFileType = 'Video';
                        });
                        updateFileType('Video');
                      }
                      print('Selected: ${isSelected[0] ? 'Movie' : isSelected[1] ? 'TV Show' : 'Video'}');
                    });
                  },
                  color: Colors.black, // Color of the text when not selected
                  selectedColor: Colors.white, // Color of the text when selected
                  fillColor: Colors.blue, // Background color when selected
                  borderRadius: BorderRadius.circular(8.0),
                  constraints: BoxConstraints(minHeight: 24.0, minWidth: 44.0), // Make the buttons smaller
                ),
                SizedBox(width: 8),
                // if (_selectedFileType == 'Movie') _movieLabels(),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedFileType == 'Movie')
              Column(
        children: [
          Row(
            children: [
              _movieLabels()
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              const Text(
                "Subtitle:",
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
              const SizedBox(width: 8),
              if (_selectedSubtitlePath == null || _selectedSubtitlePath!.isEmpty) ...[
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      setState(() {
                        _selectedSubtitlePath = file.path;
                        _subtitles.add(file.path!);
                        _subtitles = _subtitles.toSet().toList(); // Remove duplicates
                      });
                      updateSubtitlePath(file.path); // Update parent state
                      print("Subtitle path: $_selectedSubtitlePath");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10),
                  ),
                  child: const Text("Upload Subtitle"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Handle search subtitle
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10),
                  ),
                  child: const Text("Search Subtitle"),
                ),
              ] else ...[
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 200), // Set the max width to 200
                      child: DropdownButton<String>(
                        isExpanded: true, // Allow DropdownButton to take full width of 200
                        value: _selectedSubtitlePath,
                        icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.black),
                        dropdownColor: Colors.white,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        items: _subtitles.map<DropdownMenuItem<String>>((String value) {
                          String displayValue = value.split('/').last;
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center( // Center the text
                              child: Tooltip(
                                message: value, // Full file path as tooltip
                                waitDuration: Duration(milliseconds: 200), // Delay of 0.3s
                                child: Text(
                                  displayValue,
                                  overflow: TextOverflow.ellipsis, // Truncate long text
                                  maxLines: 1, // Keep text to a single line
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSubtitlePath = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    // Handle manage subtitle
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      setState(() {
                        _selectedSubtitlePath = file.path;
                        _subtitles.add(file.path!);
                        _subtitles = _subtitles.toSet().toList(); // Remove duplicates
                      });
                      updateSubtitlePath(file.path); // Update parent state
                      print("new Subtitle path: $_selectedSubtitlePath");
                    }
                  },
                ),
                const SizedBox(width: 3),
                IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  onPressed: () {
                    // Handle manage subtitle
                  },
                ),
                const SizedBox(width: 3),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    // Handle manage subtitle
                  },
                ),
              ],
            ],
          )
        ],
         )

            else
              SizedBox.shrink(),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Overview:',
                      style: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    SizedBox(width: 8),
                    !_tagsAdded
                        ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading overview, please wait...',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.mode_edit_outlined),
                          onPressed: () {
                            // Handle edit overview

                            TextEditingController overviewController = TextEditingController(text: _movieOverview);

                            CustomModal.show(
                              context,
                              'Edit Overview',
                              Container(
                                width: 500, // Set the desired width
                                child: TextField(
                                  controller: overviewController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    labelText: 'Overview',
                                  ),
                                ),
                              ),
                              [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Save'),
                                  onPressed: () {
                                    // get the new overview
                                    String newOverview = overviewController.text;
                                    print('New overview: $newOverview');

                                    setState(() {
                                      _movieOverview = newOverview;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Text(
                          'Edit Overview',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    )
                  ],
                ),
                if (_movieOverview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text(
                      _movieOverview,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ],
        );

      },
    );
  }



  // Method to collect all tags
  List<List<String>> _collectInfo() {
    List<List<String>> info = [];
    List<String> tags = _tagControllers.map((controller) => controller.text).toList();
    // get the movie name
    String movieName = filmNameController.text;
    // get the category
    String category = _selectedCategory;
    String imgPath = coverImg;
    String fileType = _selectedFileType;
    String subtitlePath = _selectedSubtitlePath ?? '';
    List<String> movieInfo = [movieName, category, imgPath];
    info.add(movieInfo);
    info.add(tags);
    info.add([fileType, subtitlePath]);
    return info;
  }

  Widget _buildNonEditableField(String label, String value, String tooltipMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF616060)
              ),

            ),
            SizedBox(width: 4),
            Tooltip(
              message: tooltipMessage,
              preferBelow: false, // This makes the tooltip appear above the icon
              verticalOffset: -50,
              child: Icon(
                Icons.help_outline,
                size: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        TextField(
          decoration: InputDecoration(
            labelText: null, // Remove the label
            isDense: true, // Makes the TextField more compact
            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0), // Adjusts vertical and horizontal padding
          ),
          controller: TextEditingController(text: value),
          readOnly: true,
        ),
        SizedBox(height: 10),
      ],
    );
  }
}