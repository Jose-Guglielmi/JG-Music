import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'package:jg_music/presentation/widgets/direcciones.dart';

enum FilterType { artists, song, albums }

/// MyAudioHandler es una clase que maneja la reproducción de audio y la gestión de playlists.
/// Extiende BaseAudioHandler y mezcla SeekHandler y ChangeNotifier para proporcionar
/// funcionalidades de servicio de audio y notificación de cambios.
class MyAudioHandler extends BaseAudioHandler with SeekHandler, ChangeNotifier {
  // Instancia del reproductor de audio
  final player = AudioPlayer();

  // Cliente de YouTube para obtener información de videos
  final _yt = YoutubeExplode();

  // Caché para URLs de audio
  final _cache = <String, String>{};

  // Variables de control
  bool _isHandlingCompletion = false;
  bool cancionBucle = false;
  bool isLoading = false;
  bool miniReproduciendo = false;

  // Listas y objetos para almacenar datos de música
  List<Artist> listaArtistas = [];
  List<Album> listaAlbunes = [];
  Album albumSeleccionado = Album();
  Cancion cancionSeleccionado = Cancion();
  List<Cancion> listaCanciones = [];
  List<Cancion> listaCancionesPorReproducir = [];
  List<Cancion> listaCancionesMeGustas = [];
  Set<Cancion> conjuntoCanciones = <Cancion>{};

  // Manejo de letras sincronizadas
  LyricSynchronizer? lyricSynchronizer;
  ValueNotifier<List<String>> currentLyrics = ValueNotifier(['', '', '']);

  // Índices y controles de reproducción
  int _currentIndex = 0;
  bool _isPlayingNext = false;
  int selectedIndex = 0;
  int menuItem = 0;
  int playListSeleccionada = 0;

  // Lista de playlists
  List<PlaylistMyApp> listasDePlaylists = [];

  /// Constructor de MyAudioHandler
  MyAudioHandler() {
    _initializeHandler();
  }

  /// Inicializa el manejador de audio
  void _initializeHandler() async {
    await obtenerListaMeGusta();
    _initializePlayer();
  }

  /// Inicializa el reproductor de audio
  void _initializePlayer() {
    player.playbackEventStream.listen(_broadcastState);
    player.playerStateStream.listen(_handlePlaybackCompletion);
  }

  /// Maneja la finalización de la reproducción
  void _handlePlaybackCompletion(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      if (_isHandlingCompletion) return;
      _isHandlingCompletion = true;
      if (cancionBucle) {
        player.seek(Duration.zero);
        play();
      } else {
        playNext();
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _isHandlingCompletion = false;
      });
    }
  }

  static const String _baseUrl = 'https://youtube-music-api3.p.rapidapi.com';
  static const Map<String, String> _headers = {
    'x-rapidapi-key': '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
    'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com',
  };

  Future<void> fetchData(String artist, FilterType filter,
      {String albumId = ''}) async {
    final String endpoint = _getEndpoint(filter, artist, albumId);
    final Uri url = Uri.parse('$_baseUrl/$endpoint');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _processResponse(filter, jsonData);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle the error appropriately
    }
  }

  String _getEndpoint(FilterType filter, String artist, String albumId) {
    switch (filter) {
      case FilterType.albums when albumId.isNotEmpty:
        return 'getAlbum?id=$albumId';
      default:
        return 'search?q=$artist&type=${filter.toString().split('.').last}';
    }
  }

  void _processResponse(FilterType filter, Map<String, dynamic> jsonData) {
    switch (filter) {
      case FilterType.artists:
        listaArtistas = ArtistList.fromJson(jsonData);
      case FilterType.song:
        listaCanciones = CancionesList.fromJson(jsonData);
      case FilterType.albums:
        listaAlbunes = AlbumList.fromJson(jsonData);
    }
    notifyListeners();
  }

  /// Obtiene la lista de canciones que le gustan al usuario
  Future<void> obtenerListaMeGusta() async {
    listasDePlaylists = await obtenerPlaylists();
  }

  /// Activa o desactiva la reproducción en bucle de la canción actual
  void bucleCancion() {
    cancionBucle = !cancionBucle;
    notifyListeners();
  }

  /// Obtiene la URL del audio de un video de YouTube
  Future<String> obtenerUrlDelAudio(String idVideo) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(idVideo);
      var audio = manifest.audioOnly.withHighestBitrate();
      _cache[idVideo] = audio.url.toString();
      return audio.url.toString();
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza la URL del audio y configura el reproductor
  Future<void> actualizarUrl(String videoId) async {
    try {
      isLoading = true;
      if (player.playing) {
        await stop();
      }

      final String urlAudio = await obtenerUrlDelAudio(videoId);
      await player.setAudioSource(AudioSource.uri(Uri.parse(urlAudio)));

      await obtenerIdLetra(videoId);

      if (cancionSeleccionado.lyricsId.isNotEmpty) {
        final syncedLyrics =
            await fetchSyncedLyrics(cancionSeleccionado.lyricsId);
        _setupLyricSynchronizer(syncedLyrics);
      }

      play();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      print('Error al actualizar URL: $e');
    }
    notifyListeners();
  }

  StreamSubscription<List<String>>? lyricSubscription;

  /// Configura el sincronizador de letras
  void _setupLyricSynchronizer(List<Map<String, dynamic>> syncedLyrics) {
    if (lyricSynchronizer != null) {
      lyricSubscription?.cancel();
      lyricSynchronizer!.dispose();
    }
    currentLyrics = ValueNotifier(['', '', '']);
    lyricSynchronizer = LyricSynchronizer(player, syncedLyrics);
    lyricSubscription = lyricSynchronizer!.currentLyricStream.listen((lyrics) {
      currentLyrics.value = lyrics;
    });
  }

  /// Reproduce la canción actual
  void _playCurrent() async {
    if (_currentIndex < listaCancionesPorReproducir.length) {
      await empezarEscucharCancion(cancionSeleccionado);
    }
    notifyListeners();
  }

  /// Reproduce la siguiente canción en la lista
  void playNext() {
    if (_isPlayingNext) return;
    _isPlayingNext = true;

    if (_currentIndex < listaCancionesPorReproducir.length - 1) {
      _currentIndex++;
      cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
      _playCurrent();
    }

    _isPlayingNext = false;
    notifyListeners();
  }

  /// Reproduce la canción anterior en la lista
  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
      _playCurrent();
    }
    notifyListeners();
  }

  /// Elimina una canción de la lista de reproducción
  void eliminarCancionDeListaPorReproducir(Cancion cancion) {
    if (listaCancionesPorReproducir.contains(cancion)) {
      listaCancionesPorReproducir.remove(cancion);
      if (cancionSeleccionado == cancion) {
        if (_currentIndex >= listaCancionesPorReproducir.length) {
          _currentIndex = 0;
        }
        if (listaCancionesPorReproducir.isNotEmpty) {
          cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
          _playCurrent();
        } else {
          stop();
        }
      }
    }
    notifyListeners();
  }

  /// Agrega una canción después de la canción actual en la lista de reproducción
  void agregarCancionDespuesDeActual(Cancion nuevaCancion, bool reproduccion) {
    if (listaCancionesPorReproducir.isEmpty) {
      listaCancionesPorReproducir.add(nuevaCancion);
      cancionSeleccionado = nuevaCancion;
      _currentIndex = 0;
      if (reproduccion) {
        _playCurrent();
      }
    } else {
      int indexActual = _currentIndex;
      listaCancionesPorReproducir.insert(indexActual + 1, nuevaCancion);
    }
    notifyListeners();
  }

  /// Verifica si una canción está actualmente en reproducción
  bool estaCancionEnReproduccion(Cancion cancion) {
    return listaCancionesPorReproducir.contains(cancion) &&
        player.playing &&
        cancionSeleccionado == cancion;
  }

  /// Comienza a reproducir una canción específica
  Future<void> empezarEscucharCancion(Cancion cancion) async {
    int index = listaCancionesPorReproducir.indexOf(cancion);
    Duration duration = _parseDuration(cancion.duration);

    MediaItem mediaItemCancion = MediaItem(
        id: cancion.videoId,
        title: cancion.title,
        artist: cancion.author,
        duration: duration,
        artUri: Uri.parse(cancion.thumbnail));

    if (index == -1) {
      _handleNewSong(cancion);
    } else {
      _handleExistingSong(index, cancion);
    }

    await actualizarUrl(cancion.videoId);
    mediaItem.add(mediaItemCancion);
    play();
    notifyListeners();
  }

  /// Maneja la lógica para una nueva canción en la lista
  void _handleNewSong(Cancion cancion) {
    if (listaCancionesPorReproducir.isEmpty) {
      listaCancionesPorReproducir.add(cancion);
      _currentIndex = 0;
    } else {
      int currentIndex = _currentIndex < listaCancionesPorReproducir.length - 1
          ? _currentIndex
          : listaCancionesPorReproducir.length - 1;
      listaCancionesPorReproducir.insert(currentIndex, cancion);
      _currentIndex = currentIndex;
    }
    cancionSeleccionado = cancion;
  }

  /// Maneja la lógica para una canción existente en la lista
  void _handleExistingSong(int index, Cancion cancion) {
    _currentIndex = index;
    cancionSeleccionado = cancion;
  }

  /// Parsea una duración de string a Duration
  Duration _parseDuration(String timeString) {
    List<String> parts = timeString.split(':');
    int minutes = int.parse(parts[0]);
    int seconds = int.parse(parts[1]);
    return Duration(minutes: minutes, seconds: seconds);
  }

  /// Crea una nueva playlist
  Future<void> crearPlaylist(String nombrePlaylist) async {
    listasDePlaylists.add(PlaylistMyApp(nombre: nombrePlaylist, canciones: []));
    await guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  /// Obtiene las playlists guardadas localmente
  Future<List<PlaylistMyApp>> obtenerPlaylists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? playlistsJson = prefs.getString('playlists');
    List<PlaylistMyApp> playlists = [];

    if (playlistsJson != null) {
      playlists = PlaylistsList.fromJson(jsonDecode(playlistsJson)).playlists;
    }

    bool favoritosExiste =
        playlists.any((playlist) => playlist.nombre == 'Favoritos');
    if (!favoritosExiste) {
      PlaylistMyApp favoritos =
          PlaylistMyApp(nombre: 'Favoritos', canciones: []);
      playlists.add(favoritos);
      await guardarPlaylistsEnPreferencias(playlists);
    }

    notifyListeners();
    return playlists;
  }

  /// Guarda las playlists en las preferencias compartidas
  Future<void> guardarPlaylistsEnPreferencias(
      List<PlaylistMyApp> playlists) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String playlistsJson = PlaylistsList(playlists: playlists).toJson();
    await prefs.setString('playlists', playlistsJson);
    notifyListeners();
  }

  /// Borra una playlist específica
  Future<void> borrarPlaylist(String nombrePlaylist) async {
    listasDePlaylists
        .removeWhere((playlist) => playlist.nombre == nombrePlaylist);
    await guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  /// Borra una canción de una playlist específica
  Future<void> borrarCancionDePlaylist(
      String nombrePlaylist, String videoIdCancion) async {
    for (PlaylistMyApp playlist in listasDePlaylists) {
      if (playlist.nombre == nombrePlaylist) {
        playlist.canciones
            .removeWhere((cancion) => cancion.videoId == videoIdCancion);
        break;
      }
    }
    await guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  /// Modifica el nombre de una playlist
  Future<void> modificarNombrePlaylist(
      String nombrePlaylist, String nuevoNombre) async {
    for (PlaylistMyApp playlist in listasDePlaylists) {
      if (playlist.nombre == nombrePlaylist) {
        playlist.nombre = nuevoNombre;
        break;
      }
    }
    await guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  /// Agrega una canción a una playlist específica
  Future<bool> agregarCancionAPlaylist(
      String nombrePlaylist, Cancion nuevaCancion) async {
    final playlist = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: nombrePlaylist, canciones: []),
    );

    bool cancionYaExiste = playlist.canciones
        .any((cancion) => cancion.videoId == nuevaCancion.videoId);

    if (!cancionYaExiste) {
      playlist.canciones.add(nuevaCancion);
      await guardarPlaylistsEnPreferencias(listasDePlaylists);
      notifyListeners();
      return true;
    } else {
      playlist.canciones.remove(nuevaCancion);
      await guardarPlaylistsEnPreferencias(listasDePlaylists);
      notifyListeners();
      return false;
    }
  }

  /// Verifica si una canción está en la lista de "Me gusta"
  bool verificarMeGusta(String nombrePlaylist, Cancion nuevaCancion) {
    final playlist = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: nombrePlaylist, canciones: []),
    );

    return !playlist.canciones
        .any((cancion) => cancion.videoId == nuevaCancion.videoId);
  }

  /// Agrega una playlist completa a la cola de reproducción
  Future<void> agregarPlaylistACola(String nombrePlaylist) async {
    PlaylistMyApp? playlistSeleccionada = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: '', canciones: []),
    );

    if (playlistSeleccionada.nombre.isNotEmpty) {
      bool estaReproduciendo = player.playing;

      for (Cancion cancion in playlistSeleccionada.canciones) {
        agregarCancionDespuesDeActual(cancion, false);
      }

      if (!estaReproduciendo && playlistSeleccionada.canciones.isNotEmpty) {
        miniReproduciendo = true;
        await empezarEscucharCancion(listaCancionesPorReproducir.first);
      }
    }
    notifyListeners();
  }

  /// Agrega una playlist completa de forma aleatoria a la cola de reproducción
  Future<void> agregarPlaylistAColaAleatoria(String nombrePlaylist) async {
    PlaylistMyApp? playlistSeleccionada = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: '', canciones: []),
    );

    if (playlistSeleccionada.nombre.isNotEmpty) {
      bool estaReproduciendo = player.playing;

      List<Cancion> cancionesAleatorias =
          List.from(playlistSeleccionada.canciones)..shuffle();

      for (Cancion cancion in cancionesAleatorias) {
        agregarCancionDespuesDeActual(cancion, false);
      }

      if (!estaReproduciendo && cancionesAleatorias.isNotEmpty) {
        miniReproduciendo = true;
        await empezarEscucharCancion(listaCancionesPorReproducir.first);
      }
    }
    notifyListeners();
  }

  /// Muestra un diálogo para guardar una canción en una playlist
  Future<void> mostrarPopDeGuardarCancionEnPlaylist(
      BuildContext context, Cancion cancion) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccione la playList:'),
          actions: [
            SizedBox(
              height: 200.0,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: listasDePlaylists.length,
                itemBuilder: (BuildContext context, int index) {
                  PlaylistMyApp playlist = listasDePlaylists[index];
                  return ListTile(
                    title: Text(playlist.nombre),
                    subtitle: Text(
                        "Cantidad de canciones: ${playlist.canciones.length}"),
                    onTap: () {
                      agregarCancionAPlaylist(playlist.nombre, cancion);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Se Agrego ${cancion.title} a ${playlist.nombre}'),
                          showCloseIcon: true,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Salta a la canción anterior
  @override
  Future<void> skipToPrevious() async {
    playPrevious();
    notifyListeners();
  }

  /// Salta a la siguiente canción
  @override
  Future<void> skipToNext() async {
    playNext();
    notifyListeners();
  }

  /// Pausa la reproducción
  @override
  Future<void> pause() async {
    await player.pause();
    notifyListeners();
  }

  /// Inicia o reanuda la reproducción
  @override
  Future<void> play() async {
    await player.play();
    notifyListeners();
  }

  /// Detiene la reproducción
  @override
  Future<void> stop() async {
    await player.stop();
    notifyListeners();
  }

  /// Busca una posición específica en la canción actual
  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
    notifyListeners();
  }

  /// Transmite el estado actual de la reproducción
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    ));
    notifyListeners();
  }

  /// Cambia el índice seleccionado
  void cambiarSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  /// Cambia el ítem del menú seleccionado
  void cambiarMenuItem(int index) {
    menuItem = index;
    selectedIndex = index;
    notifyListeners();
  }

  /// Muestra un bottom sheet con la cola de reproducción
  void showBottomSheet(BuildContext context, List<Cancion> lista) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(color: Color(0xff022527)),
          width: double.infinity,
          height: MediaQuery.of(context).size.height / 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 6,
                  width: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                ),
              ),
              const Text(
                "Cola de reproduccion:",
                style: TextStyle(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                ),
              ),
              (lista.isNotEmpty)
                  ? const Expanded(child: CancionesViewCola())
                  : const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        "No hay Canciones en la cola",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  /// Obtiene canciones relacionadas con un video específico
  Future<void> obtenerCancionesRelacionadas(String videoId) async {
    const apiKey = '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df';
    const apiHost = 'youtube-music-api3.p.rapidapi.com';
    final url = 'https://$apiHost/v2/next?id=$videoId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        final cancionesList = CancionesList.fromJson(jsonResult);

        for (var cancion in cancionesList) {
          agregarCancionDespuesDeActual(cancion, false);
        }

        notifyListeners();
      } else {
        throw Exception(
            'Failed to load songs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener canciones relacionadas: $e');
    }
  }

  /// Borra toda la cola de reproducción
  void borrarColaDeReproduccion() {
    listaCancionesPorReproducir = [];
    notifyListeners();
  }

  /// Obtiene el ID de la letra de una canción
  Future<void> obtenerIdLetra(String idVideo) async {
    final url = Uri.parse(
        'https://youtube-music-api3.p.rapidapi.com/v2/next?id=$idVideo');
    final headers = {
      'x-rapidapi-key': '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
      'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com',
    };

    try {
      final response = await http.get(url, headers: headers);
      String jsonString = response.body;
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      String lyricsId = jsonMap['lyricsId'];
      cancionSeleccionado.lyricsId = lyricsId;
      notifyListeners();
    } catch (e) {
      print('Error al obtener ID de letra: $e');
    }
  }

  /// Obtiene las letras sincronizadas de una canción
  Future<List<Map<String, dynamic>>> fetchSyncedLyrics(String lyricsId) async {
    final url = Uri.parse(
        'https://youtube-music-api3.p.rapidapi.com/music/lyrics/synced?id=$lyricsId&format=json');
    final headers = {
      'x-rapidapi-key': '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
      'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com'
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResult = json.decode(response.body);
        return jsonResult.cast<Map<String, dynamic>>();
      } else {
        print(
            'Error al obtener letras sincronizadas. Status code: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error al obtener letras sincronizadas: $error');
      return [];
    }
  }
}
