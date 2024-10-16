import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:home_cinema_app/service/main_service.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import '../component/inner_top_bar.dart';
import '../repository/db.dart';
import '../models/video_file.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import '../component/modal.dart';
import 'package:url_launcher/url_launcher.dart';


class UnrecordedFilmsView extends StatefulWidget {
  @override
  _UnrecordedFilmsViewState createState() => _UnrecordedFilmsViewState();
}

class _UnrecordedFilmsViewState extends State<UnrecordedFilmsView> {
  String? _filmsFolder;
  String? _selectedOption = 'All Folder';
  final List<String> _options = ['All Folder'];
  List<VideoFile> _videoFiles = [VideoFile(name: "empty", path: "empty_placeholder", size: 0, lastModified: DateTime.now())];
  bool _isLoading = false;
  List<Widget> tagFields = [];
  String? _searchEngine;
  String? _modalErrorMessage;
  String? _platform;

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

  @override
  void initState() {
    super.initState();
    _loadFilmsFolder();
    _loadOther();
  }


  Future<void> _loadOther() async{
    String platform = await getConfig('platform');
    // print("platform: $platform");
    List<String> categories = await getCategories();
    String engine = await getConfig('search_engine');
    // print("engine: $engine");

    //load the folders
    setState(() {
      _platform = platform;

      if (categories.isNotEmpty) {
        _categories.addAll(categories);
        _selectedCategory = categories[0];
      }
      _searchEngine = engine;
    });
  }


  Future<void> _loadFilmsFolder() async {
    final secureBookmarks = SecureBookmarks();
    List <Map<String,dynamic>> allFilmFolder = await loadAllUserDefaultDESCInTime();
    print("allFilmFolder: $allFilmFolder");
    String? bookmark;
    setState(() {
      _allFilmsFolder = allFilmFolder;
      for (var folder in _allFilmsFolder) {
        String fileFolder = folder['films_folder'];
        String lastFolder = fileFolder.split(Platform.pathSeparator).last;
        // add only if the folder is not already in the options
        if (!_options.contains(lastFolder) && lastFolder != 'null1') {
          _options.add(lastFolder);
          _optionsMap[lastFolder] = [fileFolder, folder['bookMarks']];
        }
      }
      print("options: $_options");
    });
    bookmark = _allFilmsFolder[0]['bookMarks'];
    if (bookmark == "bookmark_placeholder") {
      final folder = _allFilmsFolder[0]['films_folder'];
      // print("folder: $folder");
      String? lastFolder = folder?.split('\\').last;
      // print("lastFolder: $lastFolder");

      setState(() {
        _selectedOption = lastFolder;
        _filmsFolder = folder;
        _isLoading = true;
      });
      await _loadVideoFiles();
      setState(() {
        _isLoading = false;
      });

    }else if (bookmark != null && bookmark != "null1") {
      final resolvedFile = await secureBookmarks.resolveBookmark(bookmark);
      print("resolvedFile path: ${resolvedFile.path}");
      List<String> folders = resolvedFile.path.split('/');
      String lastFolder = folders[folders.length - 1];
      print("lastFolder: $lastFolder");

      setState(() {
        _selectedOption = lastFolder;
      });

      await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);

      try {
        setState(() {
          _filmsFolder = resolvedFile.path;
          _isLoading = true;
        });
        // await Future.delayed(Duration(milliseconds: 200));
        await _loadVideoFiles();
        setState(() {
          _isLoading = false;
        });
      } finally {
        await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
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
          allList.addAll(list);
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
        final resolvedFile = await secureBookmarks.resolveBookmark(bookmark!);
        await secureBookmarks.startAccessingSecurityScopedResource(resolvedFile);
        try{
          await _loadVideoFiles();
        }finally{
          await secureBookmarks.stopAccessingSecurityScopedResource(resolvedFile);
        }
      }else{
        _filmsFolder = _optionsMap[newValue]?[0];
        await _loadVideoFiles();
      }

    }
    print("Selected: $_selectedOption");
  }



  Future<void> _rescanFolder() async {
    if (_filmsFolder != null) {
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
        await _loadVideoFiles();
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
                                    'Size: ${videoFile.size >= 1024 * 1024 * 1024 ? (videoFile.size / 1024 / 1024 / 1024).toStringAsFixed(2) + " GB" : (videoFile.size / 1024 / 1024).toStringAsFixed(2) + " MB"}',
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
                                if (_platform == "macos"){
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



  Future<void> _showEditFilmDetailsModal(BuildContext context, VideoFile videoFile) async {
    String imagePath = '';
    GlobalKey<State> modalKey = GlobalKey<State>();
    tagFields.add(_buildTagField(0, modalKey));
    String filmName = '';
    String fileExtension = '.${videoFile.name.split('.').last}';
    String newFilePath = '${_filmsFolder!}/recorded_films/${videoFile.name}';

    filmNameController.text = "";
    categoryController.text = "";

    tagFields.clear();
    _tagControllers.clear();
    tagFields.add(_buildTagField(0, modalKey));
    _tagControllers.add(TextEditingController());

    Map<String, String?> movieInfo = await predictMovieDetail(videoFile.name);
    for(var key in movieInfo.keys){
      if (key == "err") {
        print("Error predicting movie detail");
      }else if (key == "title") {
        filmName = movieInfo[key]!;
        filmNameController.text = filmName;
      }else if (key == "posterUrl") {
        imagePath = movieInfo[key]!;
        print("imagePath: $imagePath");
        setState(() {
          coverImg = imagePath;
        });
      }
    }


    CustomModal.show(
      context,
      'Edit Film Details',
      StatefulBuilder(
        key: modalKey,
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: filmNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Film Name',
                                      labelStyle: TextStyle(height: 0.8), // Adjust the height to move the label down
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        filmName = value;
                                        newFilePath = '${_filmsFolder!}/recorded_films/$filmName$fileExtension';
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  fileExtension,
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            _buildNonEditableField('File Path', newFilePath),
                            SizedBox(height: 16),
                            _categories.isNotEmpty
                                ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Category:'),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedCategory = newValue!;
                                        });
                                      },
                                      items: _categories.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    // set the categoryController text to empty
                                    categoryController.text = '';
                                    CustomModal.show(
                                      context,
                                      'Add New Category',
                                      TextField(
                                        controller: categoryController,
                                        decoration: InputDecoration(
                                          labelText: 'Category Name',
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
                                          child: Text('Create'),
                                          onPressed: () async {
                                            String newCategory = categoryController.text;
                                            if (newCategory.isNotEmpty) {
                                              await insertCategory(newCategory);
                                              setState(() {
                                                _categories.add(newCategory);
                                                _selectedCategory = newCategory;
                                              });
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                  tooltip: 'Add New Category',
                                  iconSize: 24,
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.manage_history),
                                  onPressed: () {
                                    CustomModal.show(
                                      context,
                                      'Manage Categories',
                                      StatefulBuilder(
                                        builder: (BuildContext context, StateSetter modalSetState) {
                                          return Column(
                                            children: [
                                              ..._categories.map((category) {
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(category),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete),
                                                      onPressed: () async {
                                                        await deleteCategory(category);
                                                        setState(() {
                                                          _categories.remove(category);
                                                          if (_selectedCategory == category && _categories.isNotEmpty) {
                                                            _selectedCategory = _categories[0];
                                                          } else if (_categories.isEmpty) {
                                                            _selectedCategory = '';
                                                          }
                                                        });
                                                        modalSetState(() {}); // Update the modal's state
                                                      },
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        },
                                      ),
                                      [
                                        TextButton(
                                          child: Text('Close'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                  tooltip: 'Manage Categories',
                                  iconSize: 24,
                                )
                              ],
                            )
                                : Row(
                              children: [
                                const Text('Category:'),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    CustomModal.show(
                                      context,
                                      'Add New Category',
                                      TextField(
                                        controller: categoryController,
                                        decoration: InputDecoration(
                                          labelText: 'Category Name',
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
                                          child: Text('Create'),
                                          onPressed: () async {
                                            String newCategory = categoryController.text;
                                            if (newCategory.isNotEmpty) {
                                              await insertCategory(newCategory);
                                              setState(() {
                                                _categories.add(newCategory);
                                                _selectedCategory = newCategory;
                                              });
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                  tooltip: 'Add New Category',
                                  iconSize: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Create a category first.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...tagFields,
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int newIndex = tagFields.length;
                                    setState(() {
                                      tagFields.add(_buildTagField(newIndex, modalKey));
                                    });
                                    print('Total tag fields: ${tagFields.length}');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Container(
                              width: 200,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imagePath.isEmpty
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    child: Text('Upload'),
                                    onPressed: () {
                                      FilePicker.platform.pickFiles(allowMultiple: false).then((result) {
                                        if (result != null && result.files.isNotEmpty) {
                                          if (result.files.single.path != null) {
                                            print('Image Path: ${result.files.single.path}');
                                            setState(() {
                                              imagePath = result.files.single.path!;
                                              coverImg = imagePath;
                                              print('Image Path: $imagePath');
                                            });
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    child: Text('Search from Google'),
                                    onPressed: () async {
                                      if (filmName.isNotEmpty) {
                                        final query = Uri.encodeComponent('$filmName movie cover image');
                                        final url = Uri.parse('$_searchEngine/search?tbm=isch&q=$query');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        } else {
                                          CustomModal.show(
                                            context,
                                            'Error',
                                            Text('Could not launch the browser.'),
                                            [
                                              TextButton(
                                                child: Text('OK'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        }
                                      } else {
                                        CustomModal.show(
                                          context,
                                          'Error',
                                          Text('Please enter a film name first.'),
                                          [
                                            TextButton(
                                              child: Text('OK'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              )
                              :FutureBuilder(
                                future: imagePath.contains('http')
                                    ? Future.value(true)
                                    : File(imagePath).exists(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError ||
                                      (!snapshot.data! && !imagePath.contains('http'))) {
                                    return Center(child: Text('File does not exist'));
                                  } else {
                                    return Container(
                                      width: 200,
                                      height: 250,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imagePath.contains('http')
                                            ? Image.network(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                    (loadingProgress.expectedTotalBytes ?? 1)
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            print(error);
                                            return Center(child: Text('Failed to load image'));
                                          },
                                        )
                                            : Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                tagFields.removeAt(index);
                // add an empty view at the place delete tagFileds
                tagFields.insert(index, SizedBox.shrink()); // Add an empty view at the same index

                _tagControllers.removeAt(index);
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

  // Method to collect all tags
  List<List<String>> _collectInfo() {
    List<List<String>> info = [];
    List<String> tags = _tagControllers.map((controller) => controller.text).toList();
    // get the movie name
    String movieName = filmNameController.text;
    // get the category
    String category = _selectedCategory;
    String imgPath = coverImg;
    List<String> movieInfo = [movieName, category, imgPath];
    info.add(movieInfo);
    info.add(tags);
    return info;
  }

  Widget _buildNonEditableField(String label, String value) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
      ),
      controller: TextEditingController(text: value),
      readOnly: true,
    );
  }

}