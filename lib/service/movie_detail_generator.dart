import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

Future<Map<String, String?>> predictMovieDetail(String movieName) async {
  List<String> movieInfo = movieName.split(".");
  int movieYearIndex = movieInfo.indexWhere((info) => RegExp(r'^\d{4}$').hasMatch(info));

  if (movieYearIndex == -1) {
    return {"err": "Error predicting movie detail"};
  }

  String title = movieInfo.sublist(0, movieYearIndex).join(" ");
  String volume = "";
  String season = "";
  String episode = "";
  Map<String, String> cleanedTitle = cleanTitle(title);

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
      ? "2160p"
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
  if (season != "") {
    searchTitle += " season $season";
  }else if(volume != ""){
    searchTitle += " Vol. $volume";
  }

  print(searchTitle);
  // Fetch movie poster
  String posterUrl = await fetchMoviePoster(searchTitle);

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
    'posterUrl': posterUrl
  };
}

Future<String> fetchMoviePoster(String movieTitle) async {
  final apiKey = '15d2ea6d0dc1d476efbca3eba2b9bbfb';
  final url = Uri.parse('https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieTitle');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'] != null && data['results'].length > 0) {
      // Get the poster path
      final posterPath = data['results'][0]['poster_path'];
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    } else {
      // No poster found, return error image
      return 'https://via.placeholder.com/500?text=No+Poster+Found';
    }
  } else {
    // Error during the API call, return error image
    return 'https://via.placeholder.com/500?text=Error+Fetching+Poster';
  }
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
    return {
      "title": title.split(seasonPattern)[0].trim(),
      "season": seasonEpisode.split('e')[0].substring(1), // Extract season number
      "episode": seasonEpisode.split('e')[1] // Extract episode number
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