import 'dart:convert';

import 'package:jg_music/presentation/domian/entitis/cancion.dart';

class PlaylistMyApp {
  String nombre;
  final List<Cancion> canciones;

  PlaylistMyApp({
    required this.nombre,
    required this.canciones,
  });

  // Método para crear una instancia de Playlist a partir de un JSON
  factory PlaylistMyApp.fromJson(Map<String, dynamic> json) {
    var cancionesList = json['canciones'] as List<dynamic>;
    List<Cancion> canciones =
        cancionesList.map((c) => Cancion.fromJson(c)).toList();

    return PlaylistMyApp(
      nombre: json['nombre'],
      canciones: canciones,
    );
  }

  // Método para convertir una instancia de Playlist a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'canciones': canciones.map((cancion) => cancion.toJson()).toList(),
    };
  }
}

class PlaylistsList {
  final List<PlaylistMyApp> playlists;

  PlaylistsList({required this.playlists});

  // Método estático para crear una lista de playlists a partir de un JSON
  factory PlaylistsList.fromJson(Map<String, dynamic> json) {
    var playlistsList = json['playlists'] as List<dynamic>;
    List<PlaylistMyApp> playlists =
        playlistsList.map((p) => PlaylistMyApp.fromJson(p)).toList();

    return PlaylistsList(playlists: playlists);
  }

  // Método para convertir la lista de playlists a un JSON
  String toJson() {
    List<Map<String, dynamic>> jsonList =
        playlists.map((playlist) => playlist.toJson()).toList();
    return jsonEncode({'playlists': jsonList});
  }
}
