import 'dart:convert'; // Necesario para jsonEncode

class Cancion {
  final String videoId;
  final String title;
  final String duration;
  final bool isExplicit;
  final String thumbnail;
  final String author;
  String lyricsId;

  Cancion({
    this.lyricsId = "",
    this.videoId = "",
    this.title = "",
    this.duration = "",
    this.isExplicit = false,
    this.thumbnail = "",
    this.author = "",
  });

  // Método para crear una instancia de Cancion a partir de un JSON
  factory Cancion.fromJson(Map<String, dynamic> json) {
    return Cancion(
      videoId: json['videoId'] ?? "",
      title: json['title'] ?? "",
      duration: json['duration'] ?? "",
      isExplicit: json['isExplicit'] ?? false,
      thumbnail: json['thumbnail'] ?? "",
      author: json['author'] ?? "",
    );
  }

  // Método para convertir una instancia de Cancion a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'duration': duration,
      'isExplicit': isExplicit,
      'thumbnail': thumbnail,
      'author': author,
      'lyricsId': lyricsId,
    };
  }
}

class CancionesList {
  List<Cancion> canciones;

  CancionesList({required this.canciones});

  // Método estático para crear una lista de canciones a partir de un JSON
  static List<Cancion> fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> resultList;
      if (json.containsKey('result')) {
        resultList = json['result'] as List;
      } else if (json.containsKey('nextItems')) {
        resultList = json['nextItems'] as List;
      } else {
        throw Exception('JSON no contiene ni "result" ni "nextitem"');
      }

      List<Cancion> videoList =
          resultList.map((i) => Cancion.fromJson(i)).toList();
      return videoList;
    } catch (e) {
      return List.empty();
    }
  }

  // Método para convertir la lista de canciones a un JSON
  String toJson() {
    List<Map<String, dynamic>> jsonList =
        canciones.map((cancion) => cancion.toJson()).toList();
    return jsonEncode({'result': jsonList});
  }
}
