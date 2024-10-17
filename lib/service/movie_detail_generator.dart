Map<String, String?> predictMovieDetail(String movieName) {
  // Sample movie name: "Avengers.Endgame.2019.PROPER.2160p.BluRay.REMUX.HEVC.DTS-HD.MA.TrueHD.7.1.Atmos-FGT.mkv"
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
  print(cleanedTitle);
  for (var key in cleanedTitle.keys) {
    if (key == "volume") {
      volume = cleanedTitle[key]!;
    } else if (key == "season") {
      season = cleanedTitle[key]!;
    } else if (key == "episode") {
      episode = cleanedTitle[key]!;
    }else{
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
    'isINT': isINT.toString()
  };
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