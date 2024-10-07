import 'dart:convert'; // Necesario para jsonEncode

class Artist {
  final String title;
  final String thumbnail;
  final String author;
  final String subscriberText;
  final bool isExplicit;

  Artist({
    required this.title,
    required this.thumbnail,
    required this.author,
    required this.subscriberText,
    required this.isExplicit,
  });

  // Método para crear una instancia de Artist a partir de un JSON
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      title: json['title'],
      thumbnail: json['thumbnail'],
      author: json['author'],
      subscriberText: json['subscriberText'],
      isExplicit: json['isExplicit'],
    );
  }

  // Método para convertir una instancia de Artist a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'thumbnail': thumbnail,
      'author': author,
      'subscriberText': subscriberText,
      'isExplicit': isExplicit,
    };
  }
}

class ArtistList {
  List<Artist> artists;

  ArtistList({required this.artists});

  // Método estático para crear una lista de artistas a partir de un JSON
  static List<Artist> fromJson(Map<String, dynamic> json) {
    try {
      var list = json['result'] as List;
      List<Artist> artistList = list.map((i) => Artist.fromJson(i)).toList();
      return artistList;
    } catch (e) {
      return List.empty();
    }
  }

  // Método para convertir la lista de artistas a un JSON
  String toJson() {
    List<Map<String, dynamic>> jsonList =
        artists.map((artist) => artist.toJson()).toList();
    return jsonEncode({'result': jsonList});
  }
}
