import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

Future<Map<String, String?>> predictMovieDetail(String movieName) async {
  List<String> movieInfo = movieName.split(".");
  int movieYearIndex = movieInfo.indexWhere((info) => RegExp(r'^\d{4}$').hasMatch(info));

  String volume = "";
  String season = "";
  String episode = "";
  int type = 0;

  if (movieInfo.any((info) => RegExp(r'^S\d{2}E\d{2}$').hasMatch(info))) {
    type = 1;
    String seasonEpisode = movieInfo.firstWhere((info) => RegExp(r'^S\d{2}E\d{2}$').hasMatch(info));
    RegExpMatch? match = RegExp(r'^S(\d{2})E(\d{2})$').firstMatch(seasonEpisode);
    if (match != null) {
      season = match.group(1)!;
      episode = match.group(2)!;
      print('Season: $season, Episode: $episode');
    }
  }

  if (movieYearIndex == -1) {
    return {"err": "Error predicting movie detail"};
  }

  String title = movieInfo.sublist(0, movieYearIndex).join(" ");

  Map<String, String> cleanedTitle = cleanTitle(title);

  print(cleanedTitle);

  for (var key in cleanedTitle.keys) {
    if (key == "volume") {
      volume = cleanedTitle[key]!;
    } else if (key == "season") {
      season = cleanedTitle[key]!;
    } else if (key == "episode") {
      episode = cleanedTitle[key]!;
    } else {
      title = cleanedTitle[key]!;
    }
  }

  String year = movieInfo[movieYearIndex];

  String resolution = movieName.contains("2160p")
      ? "4k"
      : movieName.contains("1080p")
      ? "1080p"
      : movieName.contains("720p")
      ? "720p"
      : "";

  bool isRemux = movieName.toLowerCase().contains("remux");
  bool isBluRay = movieName.toLowerCase().contains("bluray");
  bool isAtmos = movieName.toLowerCase().contains("atmos");
  bool isINT = movieName.toLowerCase().contains("ctrlhd");


  String searchTitle = title;
  if(volume != ""){
    searchTitle += " Vol. $volume";
  }

  print(searchTitle);
  // Fetch movie poster
  List<dynamic> details = await fetchMoviePoster(searchTitle, type);
  String posterUrl = "";
  String movieID = "";

  if(details.length != 0){
    posterUrl = details[0];
    movieID = details[1].toString();
  }

  print(details);

  return {
    'title': title,
    'volume': volume,
    'season': season,
    'episode': episode,
    'year': year,
    'resolution': resolution,
    'isRemux': isRemux.toString(),
    'isBluRay': isBluRay.toString(),
    'isAtmos': isAtmos.toString(),
    'isINT': isINT.toString(),
    'posterUrl': posterUrl,
    'movieID': movieID,
    'type': type.toString()
  };
}

Future<String> downloadCastAvatar(String profilePath) async {
  const serverUrl = 'https://movie.bugsmachine.top/tmdb/image?image_link=';

  Directory homeDir = Directory(Platform.environment['HOME']!);
  Directory documentsDir = Directory('${homeDir.path}/Documents');
  Directory avatarFolder = Directory('${documentsDir.path}/cast_avatar');
  // Create the folder if it doesn't exist
  if (!await avatarFolder.exists()) {
    await avatarFolder.create(recursive: true);
  }
  // check if the file already exists
  File file = File('${avatarFolder.path}/$profilePath');
  if (file.existsSync()) {
    return file.path;
  }
  print("downloading avatar");
  final response = await http.get(Uri.parse('$serverUrl$profilePath'));
  if (response.statusCode == 200) {
    File file = File('${avatarFolder.path}/$profilePath');
    await file.writeAsBytes(response.bodyBytes);
    print('Avatar downloaded and saved to ${file.path}');
    return file.path;
  } else {
    print('Failed to download avatar: ${response.statusCode}');
    print("Failed to download avatar: ${response.body}");
    return '';
  }

}

Future<List<dynamic>> fetchMoviePoster(String movieTitle, int type) async {
  final response = await http.get(
    Uri.parse('https://movie.bugsmachine.top/tmdb/search?movie_name=$movieTitle&movie_type=$type'),
  );

  print('https://movie.bugsmachine.top/tmdb/search?movie_name=$movieTitle&movie_type=$type');
  if (response.statusCode == 200) {
    print(response.body);
    final Map<String, dynamic> data = json.decode(response.body);
    String posterPath = data['poster_link'];
    String id = data['movie_id'].toString();
    List<String> details = [posterPath, id];
    print(details);
    return details;
  } else {
    print(response.body);
    return [];
  }
}


// Future<List<dynamic>> fetchMoviePoster(String movieTitle, int type) async {
//   final apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
//   var url = Uri.parse('https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieTitle');
//   if (type == 1) {
//     url = Uri.parse('https://api.themoviedb.org/3/search/tv?api_key=$apiKey&query=$movieTitle');
//   }
//   List<dynamic> movieDetails = [];
//   final response = await http.get(url);
//
//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     if (data['results'] != null && data['results'].length > 0) {
//       // Get the poster path
//       final posterPath = data['results'][0]['poster_path'];
//       final id = data['results'][0]['id'];
//       print('id $id');
//       // get the path and pass to another fuc called abc()
//       movieDetails.add('https://image.tmdb.org/t/p/w500$posterPath');
//       movieDetails.add(id);
//       return movieDetails;
//     } else {
//       // No poster found, return error image
//       return movieDetails;
//     }
//   } else {
//     // Error during the API call, return error image
//     return movieDetails;
//   }
// }

Future<List<String>> fetchMovieKeywords(String movieID, String type) async {
  const apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
  //sample https://api.themoviedb.org/3/movie/320288/keywords?api_key=15d2ea6d0dc1d476efbca3eba2b9bbfb
  var url = Uri.parse('https://api.themoviedb.org/3/movie/$movieID/keywords?api_key=$apiKey');
  if(type == "1"){
    url = Uri.parse('https://api.themoviedb.org/3/tv/$movieID/keywords?api_key=$apiKey');
  }
  final response = await http.get(url);

  if (response.statusCode == 200) {
    if (type == "1") {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].length > 0) {
        final keywords = data['results'];
        return List<String>.from(keywords.map((keyword) => keyword['name']));
      }
    }else{
      final data = json.decode(response.body);
      if (data['keywords'] != null && data['keywords'].length > 0) {
        final keywords = data['keywords'];
        return List<String>.from(keywords.map((keyword) => keyword['name']));
      }
    }

  }

  return [];
}

Future<List<List<String>>> fetchMovieGenresAndOverview(String movieID, String type) async {
  // sample https://api.themoviedb.org/3/movie/320288?api_key=15d2ea6d0dc1d476efbca3eba2b9bbfb
  const apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
  var url = Uri.parse('https://api.themoviedb.org/3/movie/$movieID?api_key=$apiKey');
  if(type == "1"){
    url = Uri.parse('https://api.themoviedb.org/3/tv/$movieID?api_key=$apiKey');
    }
  final response = await http.get(url);

  List<List<String>> genresAndOverview = [];

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['genres'] != null && data['genres'].length > 0) {
      final genres = data['genres'];
       genresAndOverview.add(List<String>.from(genres.map((genre) => genre['name'])));
    }
    if (data['overview'] != null) {
      genresAndOverview.add([data['overview']]);
    }
  }

  return genresAndOverview;
}



Future<List<Map<String, String>>> fetchMovieCast(String movieID, String type) async {
  const apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
  var url = Uri.parse('https://api.themoviedb.org/3/movie/$movieID/credits?api_key=$apiKey');
  if(type == "1"){
    url = Uri.parse('https://api.themoviedb.org/3/tv/$movieID/credits?api_key=$apiKey');
  }
  final response = await http.get(url);

  List<Map<String, String>> cast = [];

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['cast'] != null && data['cast'].length > 0) {
      final casts = data['cast'];
      for (int i = 0; i < casts.length && i < 10; i++) {
        cast.add({
          'name': casts[i]['name'],
          'profile_path': casts[i]['profile_path'] ?? '',
          'character': casts[i]['character'] ?? '',
        });
      }
    }
  }

  return cast;
}

Map<String, String> cleanTitle(String title) {
  RegExp volPattern = RegExp(r'vol\s*\d+', caseSensitive: false);
  RegExp seasonPattern = RegExp(r's\d+e\d+', caseSensitive: false);

  if (volPattern.hasMatch(title)) {
    String volumeMatch = volPattern.firstMatch(title)!.group(0)!;
    return {
      "title": title.split(volPattern)[0].trim(),
      "volume": volumeMatch.replaceAll(RegExp(r'vol\s*', caseSensitive: false), '') // Extract volume number after "vol"
    };
  } else if (seasonPattern.hasMatch(title)) {
    String seasonEpisode = seasonPattern.firstMatch(title)!.group(0)!;
    print("Season Episode: $seasonEpisode");
    return {
      "title": title.split(seasonPattern)[0].trim(),
      "season": seasonEpisode.substring(1, 3), // Extract season number
      "episode": seasonEpisode.substring(4) // Extract episode number
    };
  } else {
    return {"title": title};
  }
}



Future<void> fetchImageWithHeaders(String imageUrl) async {
  final headers = {
    'User-Agent': 'iSearcher/1.0',
    'Accept': 'image/*',
    'Host': 'image.tmdb.org',
    "Connection": "Keep-Alive",
    "accept-encoding": "gzip, deflate, br"
    // Add more headers if needed
  };

  try {
    Uri uri = Uri.parse(imageUrl);

    Response response = await http.put(
      uri,
      headers: headers,
      body: Uint8List(0),
    ).timeout(Duration(seconds: 5), onTimeout: () {
      print('Timeout');
      return Response('', 411);
    });

    if (response.statusCode == 200) {
      print('Image loaded successfully');
      // Process image data here
    } else {
      print('Failed to load image: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching image: $e');
  }
}

String getMacOSUsername() {
  // Get the home directory path
  String homeDirectory = Platform.environment['HOME'] ?? '';
  print(homeDirectory);
  // Extract the username from the home directory path, the second one in the list
  String username = homeDirectory.split('/').elementAt(2);
  return username;
}

String getDocumentsFolderPath() {
  String homeDirectory = Platform.environment['USERPROFILE'] ?? '';
  print(homeDirectory);
  return '$homeDirectory\\Documents';
}




Future<void> cleanPosterCache() async {

}