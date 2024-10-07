
import 'package:jg_music/presentation/domian/entitis/cancion.dart';

class Album {
  final String title;
  final String albumType;
  final String albumRelease;
  final String albumAuthor;
  final String authorThumbnail;
  final String albumCover;
  final bool isExplicit;
  final String albumTotalSong;
  final String albumTotalDuration;
  final List<Cancion> canciones;

  Album({
    this.title = "",
    this.albumType = "",
    this.albumRelease = "",
    this.albumAuthor = "",
    this.albumCover = "",
    this.isExplicit = false,
    this.albumTotalSong = "",
    this.albumTotalDuration = "",
    this.canciones = const [],
    this.authorThumbnail = "",
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      title: json['title'],
      albumType: json['albumType'],
      albumRelease: json['albumRelease'],
      albumAuthor: json['albumAuthor'],
      albumCover: json['albumCover'],
      isExplicit: json['isExplicit'],
      albumTotalSong: json['albumTotalSong'],
      albumTotalDuration: json['albumTotalDuration'],
      canciones: (json['results'] as List<dynamic>?)
              ?.map((songJson) => Cancion.fromJson(songJson))
              .toList() ??
          [],
    );
  }
}

class AlbumList {
  // Método para crear una lista de álbumes a partir de un JSON
  static List<Album> fromJson(Map<String, dynamic> json) {
    var list = json['result'] as List;
    List<Album> albumList = list.map((i) => Album.fromJson(i)).toList();

    return albumList;
  }
}
