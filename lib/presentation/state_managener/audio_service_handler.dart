import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

class MyAudioHandler extends BaseAudioHandler with SeekHandler, ChangeNotifier {
  //Clase que se encarga del manejo de los datos de las apis, para mostrarlo a al usuario
  bool _isHandlingCompletion = false;
  MyAudioHandler() {
    obtenerListaMeGusta();
    player.playbackEventStream.listen(_broadcastState);
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isHandlingCompletion) return;
        _isHandlingCompletion = true;
        if (cancionBucle) {
          player.seek(Duration.zero);
          play();
        } else {
          playNext();
        }
        // Restablecer el flag después de un breve delay para permitir futuras ejecuciones
        Future.delayed(const Duration(milliseconds: 500), () {
          _isHandlingCompletion = false;
        });
      }
    });
  }

  obtenerListaMeGusta() async {
    listasDePlaylists = await obtenerPlaylists();
  }

  void bucleCancion() {
    cancionBucle = !cancionBucle;
    notifyListeners();
  }

  //reproducir en bucle
  bool cancionBucle = false;

  //Lista de artistas
  List<Artist> listaArtistas = [];

  //Lista de albunes
  List<Album> listaAlbunes = [];

  //album seleccionada para visualizar
  Album albumSeleccionado = Album();

  //cancion seleccionada para reproducir
  Cancion cancionSeleccionado = Cancion();

  //Lista de canciones
  List<Cancion> listaCanciones = [];

  //Lista de cola de canciones
  List<Cancion> listaCancionesPorReproducir = [];

  //Lista de canciones
  List<Cancion> listaCancionesMeGustas = [];
  Set<Cancion> conjuntoCanciones = <Cancion>{};

  //El que se encarga de reproducir el audio
  final player = AudioPlayer();

  //Nos indica si se esta cargando el audio
  bool isLoading = false;

  //bool que nos indica si se esta reproduciendo o no
  bool miniReproduciendo = false;

  LyricSynchronizer? lyricSynchronizer;
  ValueNotifier<List<String>> currentLyrics = ValueNotifier(['', '', '']);

  //Recibe el id del video y devuelve un link del audio del video.
  Future<String> obtenerUrlDelAudio(String idVideo) async {
    var yt = YoutubeExplode();

    var manifest = await yt.videos.streamsClient.getManifest(idVideo);
    var audio = manifest.audioOnly.withHighestBitrate();
    yt.close();
    return audio.url.toString();
  }

  //Obtener info de la api de youtube,
  //Filtros:
  //0: artists
  //1: song
  //2: albums
  Future<void> apiYoutube(String artista, int filtro,
      {String albumId = ""}) async {
    String filtrer = "";

    switch (filtro) {
      case 0:
        filtrer = "artists";
        break;
      case 1:
        filtrer = "song";
        break;
      case 2:
        filtrer = "albums";
        break;
    }
    final url = Uri.parse(
        'https://youtube-music-api3.p.rapidapi.com/search?q=$artista&type=$filtrer');
    final headers = {
      'x-rapidapi-key': '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
      'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com',
    };

    final response = await http.get(url, headers: headers);

    String jsonString = response.body;

    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    switch (filtro) {
      case 0:
        listaArtistas = [];

        listaArtistas = ArtistList.fromJson(jsonData);
        break;
      case 1:
        listaCanciones = [];

        listaCanciones = CancionesList.fromJson(jsonData);
        break;
      case 2:
        listaAlbunes = [];

        listaAlbunes = AlbumList.fromJson(jsonData);
        break;
      case 3:
        final url = Uri.parse(
            'https://youtube-music-api3.p.rapidapi.com/getAlbum?id=$albumId');
        final headers = {
          'x-rapidapi-key':
              '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
          'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com',
        };

        final response = await http.get(url, headers: headers);

        String jsonString = response.body;

        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        albumSeleccionado = Album();

        albumSeleccionado = Album.fromJson(jsonData);

        break;
    }
    notifyListeners();
  }

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
        notifyListeners();
        return [];
      }
    } catch (error) {
      notifyListeners();
      return [];
    }
  }

  Future<void> obtenerIdLetra(String idVideo) async {
    final url = Uri.parse(
        'https://youtube-music-api3.p.rapidapi.com/v2/next?id=$idVideo');
    final headers = {
      'x-rapidapi-key': '1b7ebc615amsh0e92916a60ff015p1f1bd5jsnf45ce63c33df',
      'x-rapidapi-host': 'youtube-music-api3.p.rapidapi.com',
    };

    final response = await http.get(url, headers: headers);

    String jsonString = response.body;

    // Decodifica el JSON string a un Map
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    // Extrae el valor de 'lyricsId'
    String lyricsId = jsonMap['lyricsId'];

    cancionSeleccionado.lyricsId = lyricsId;
    notifyListeners();
  }

  StreamSubscription<List<String>>? lyricSubscription;

  Future<void> actualizarUrl(String videoId) async {
    try {
      isLoading = true;

      if (player.playing) {
        stop();
        notifyListeners();
      }

      final String urlAudio = await obtenerUrlDelAudio(videoId);
      await player.setUrl(urlAudio);

      // Obtener el ID de la letra|
      await obtenerIdLetra(videoId);

      // Obtener letras sincronizadas
      if (cancionSeleccionado.lyricsId.isNotEmpty) {
        final syncedLyrics =
            await fetchSyncedLyrics(cancionSeleccionado.lyricsId);

        if (lyricSynchronizer != null) {
          lyricSubscription?.cancel();
          lyricSynchronizer!
              .dispose(); // Limpia recursos del antiguo LyricSynchronizer
          lyricSynchronizer = null;
        }
        currentLyrics = ValueNotifier(['', '', '']);
        lyricSynchronizer = LyricSynchronizer(player, syncedLyrics);
        lyricSubscription =
            lyricSynchronizer!.currentLyricStream.listen((lyrics) {
          currentLyrics.value = lyrics;
        });
      }

      play();
      isLoading = false;
    } catch (e) {
      isLoading = false;
    }

    notifyListeners();
  }

  int _currentIndex = 0;

  void _playCurrent() async {
    if (_currentIndex < listaCancionesPorReproducir.length) {
      empezarEscucharCancion(cancionSeleccionado);
    }
    notifyListeners();
  }

  bool _isPlayingNext = false;

  void playNext() {
    if (_isPlayingNext) {
      return;
    } // Salir si ya se está reproduciendo la siguiente canción
    _isPlayingNext = true;

    if (_currentIndex < listaCancionesPorReproducir.length - 1) {
      _currentIndex++;
      cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
      _playCurrent();
    }

    // Restablecer el flag
    _isPlayingNext = false;
    notifyListeners();
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
      _playCurrent();
    }
    notifyListeners();
  }

  void eliminarCancionDeListaPorReproducir(Cancion cancion) {
    // Busca la canción en la lista y la elimina si existe
    if (listaCancionesPorReproducir.contains(cancion)) {
      listaCancionesPorReproducir.remove(cancion);
      // Si la canción eliminada era la que se estaba reproduciendo, actualiza la reproducción
      if (cancionSeleccionado == cancion) {
        if (_currentIndex >= listaCancionesPorReproducir.length) {
          _currentIndex = 0; // Resetea el índice si estaba en la última canción
        }
        if (listaCancionesPorReproducir.isNotEmpty) {
          cancionSeleccionado = listaCancionesPorReproducir[_currentIndex];
          _playCurrent();
        } else {
          stop(); // Detiene la reproducción si no quedan más canciones
        }
      }
    }
    notifyListeners();
  }

  void agregarCancionDespuesDeActual(Cancion nuevaCancion, bool reproduccion) {
    // Si la lista está vacía, simplemente añade la canción y comienza a reproducirla
    if (listaCancionesPorReproducir.isEmpty) {
      listaCancionesPorReproducir.add(nuevaCancion);
      cancionSeleccionado = nuevaCancion;
      _currentIndex = 0;
      if (reproduccion) {
        _playCurrent();
      }
    } else {
      // Inserta la nueva canción después de la canción actualmente en reproducción
      int indexActual = _currentIndex;
      listaCancionesPorReproducir.insert(indexActual + 1, nuevaCancion);
    }
    notifyListeners();
  }

  bool estaCancionEnReproduccion(Cancion cancion) {
    // Verifica si la canción está en la lista de canciones por reproducir
    if (listaCancionesPorReproducir.contains(cancion)) {
      // Verifica si la canción en reproducción actualmente es la misma que la proporcionada
      return player.playing && cancionSeleccionado == cancion;
    }
    // Si la canción no está en la lista, retorna false
    return false;
  }

  Future<void> empezarEscucharCancion(Cancion cancion) async {
    // Encuentra el índice de la canción en la lista de canciones por reproducir
    int index = listaCancionesPorReproducir.indexOf(cancion);
    //parceo la duracion que viene de tipo string, a tipo duration
    String timeString = cancion.duration;
    List<String> parts = timeString.split(':');
    int minutes = int.parse(parts[0]);
    int seconds = int.parse(parts[1]);

    Duration duration = Duration(minutes: minutes, seconds: seconds);

    MediaItem mediaItemCancion = MediaItem(
        id: cancion.videoId,
        title: cancion.title,
        artist: cancion.author,
        duration: duration,
        artUri: Uri.parse(cancion.thumbnail));

    // Si la canción no está en la lista
    if (index == -1) {
      if (listaCancionesPorReproducir.isEmpty) {
        cancionSeleccionado = Cancion();
        cancionSeleccionado = cancion;
        // La lista está vacía, agrega la canción y empieza a reproducirla
        listaCancionesPorReproducir.add(cancion);
        _currentIndex = 0;
        await actualizarUrl(
            cancion.videoId); // Asegúrate de que cancion tenga el videoId

        mediaItem.add(mediaItemCancion);
        play();
      } else {
        if (!listaCancionesPorReproducir.contains(cancion)) {
          cancionSeleccionado = Cancion();
          cancionSeleccionado = cancion;
          // La lista no está vacía, agrega la canción antes del elemento actualmente seleccionado
          int currentIndex = _currentIndex;
          // Asegúrate de que el índice sea válido
          if (currentIndex > listaCancionesPorReproducir.length - 1) {
            currentIndex = listaCancionesPorReproducir.length - 1;
          }
          listaCancionesPorReproducir.insert(currentIndex, cancion);
          _currentIndex = currentIndex;
          await actualizarUrl(
              cancion.videoId); // Asegúrate de que cancion tenga el videoId
          mediaItem.add(mediaItemCancion);
          play();
        } else {
          cancionSeleccionado = Cancion();
          cancionSeleccionado = cancion;
          await actualizarUrl(
              cancion.videoId); // Asegúrate de que cancion tenga el videoId
          mediaItem.add(mediaItemCancion);
          play();
        }
      }
    } else {
      cancionSeleccionado = Cancion();
      cancionSeleccionado = cancion;
      // La canción ya está en la lista, actualiza el índice y empieza a reproducir
      _currentIndex = index;
      await actualizarUrl(
          cancion.videoId); // Asegúrate de que cancion tenga el videoId
      mediaItem.add(mediaItemCancion);
      play();
    }
    notifyListeners();
  }

  //Parte para de la lista de reproduccion
  List<PlaylistMyApp> listasDePlaylists = [];

  //Crea una playlist
  Future<void> crearPlaylist(String nombrePlaylist) async {
    List<Cancion> canciones = [];
    listasDePlaylists
        .add(PlaylistMyApp(nombre: nombrePlaylist, canciones: canciones));

    guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  //se encarga de obtener las playlist guardadas en local
  Future<List<PlaylistMyApp>> obtenerPlaylists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Recupera la lista actual de playlists guardadas
    String? playlistsJson = prefs.getString('playlists');
    List<PlaylistMyApp> playlists = [];

    if (playlistsJson != null) {
      // Convierte el JSON de playlists a una lista de objetos Playlist
      playlists = PlaylistsList.fromJson(jsonDecode(playlistsJson)).playlists;
    }

    //Verifica si la playlist de "Favoritos" ya existe
    bool favoritosExiste =
        playlists.any((playlist) => playlist.nombre == 'Favoritos');

    if (!favoritosExiste) {
      // Si no existe, la crea y la agrega a la lista
      PlaylistMyApp favoritos =
          PlaylistMyApp(nombre: 'Favoritos', canciones: []);
      playlists.add(favoritos);

      // Guarda la lista actualizada en SharedPreferences
      await guardarPlaylistsEnPreferencias(playlists);
    }

    notifyListeners();
    return playlists;
  }

  //Guarda las playlists en el celular
  Future<void> guardarPlaylistsEnPreferencias(
      List<PlaylistMyApp> playlists) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convierte la lista de playlists a JSON y la guarda en SharedPreferences
    String playlistsJson = PlaylistsList(playlists: playlists).toJson();
    await prefs.setString('playlists', playlistsJson);
    notifyListeners();
  }

  //Borra una playlist
  Future<void> borrarPlaylist(String nombrePlaylist) async {
    // Filtra para eliminar la playlist específica
    listasDePlaylists
        .removeWhere((playlist) => playlist.nombre == nombrePlaylist);

    guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  //Borra una cancion de una playlist
  Future<void> borrarCancionDePlaylist(
      String nombrePlaylist, String videoIdCancion) async {
    // Busca la playlist específica y elimina la canción
    for (PlaylistMyApp playlist in listasDePlaylists) {
      if (playlist.nombre == nombrePlaylist) {
        playlist.canciones
            .removeWhere((cancion) => cancion.videoId == videoIdCancion);
        break;
      }
    }

    guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  //Modifico el nombre de una playlist
  Future<void> modificarNombrePlaylist(
      String nombrePlaylist, String nuevoNombre) async {
    // Busca la playlist específica y elimina la canción
    for (PlaylistMyApp playlist in listasDePlaylists) {
      if (playlist.nombre == nombrePlaylist) {
        playlist.nombre = nuevoNombre;
        break;
      }
    }
    guardarPlaylistsEnPreferencias(listasDePlaylists);
    notifyListeners();
  }

  //Agrego una cancion a la playlist
  Future<bool> agregarCancionAPlaylist(
      String nombrePlaylist, Cancion nuevaCancion) async {
    // Buscar la playlist por nombre
    final playlist = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: nombrePlaylist, canciones: []),
    );

    // Verificar si la canción ya existe en la playlist
    bool cancionYaExiste = playlist.canciones
        .any((cancion) => cancion.videoId == nuevaCancion.videoId);

    if (!cancionYaExiste) {
      // Agregar la canción si no existe
      playlist.canciones.add(nuevaCancion);
      guardarPlaylistsEnPreferencias(listasDePlaylists);
      notifyListeners();
      return true;
    } else {
      playlist.canciones.remove(nuevaCancion);
      guardarPlaylistsEnPreferencias(listasDePlaylists);
      notifyListeners();
      return false;
    }
  }

  //Agrego una cancion a la playlist
  bool verificarMeGusta(String nombrePlaylist, Cancion nuevaCancion) {
    // Buscar la playlist por nombre
    final playlist = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: nombrePlaylist, canciones: []),
    );

    // Verificar si la canción ya existe en la playlist
    bool cancionYaExiste = playlist.canciones
        .any((cancion) => cancion.videoId == nuevaCancion.videoId);

    if (!cancionYaExiste) {
      return true;
    } else {
      return false; // Salir de la función si ya existe
    }
  }

// Función que agrega una playlist completa a la cola de reproducción y comienza a reproducir si no hay nada sonando
  Future<void> agregarPlaylistACola(String nombrePlaylist) async {
    // Buscar la playlist por nombre
    PlaylistMyApp? playlistSeleccionada = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: '', canciones: []),
    );

    if (playlistSeleccionada.nombre.isNotEmpty) {
      // Si la playlist existe y tiene canciones
      bool estaReproduciendo =
          player.playing; // Verifica si algo se está reproduciendo actualmente

      // Agregar todas las canciones a la cola
      for (Cancion cancion in playlistSeleccionada.canciones) {
        agregarCancionDespuesDeActual(cancion, false);
      }

      // Si no hay nada reproduciéndose, comenzamos a reproducir la primera canción
      if (!estaReproduciendo && playlistSeleccionada.canciones.isNotEmpty) {
        miniReproduciendo = true;
        await empezarEscucharCancion(listaCancionesPorReproducir.first);
      }
      // Notificar a los listeners para actualizar la UI
    } else {}
    notifyListeners();
  }

// Función que agrega una playlist completa de forma aleatoria a la cola de reproducción
  Future<void> agregarPlaylistAColaAleatoria(String nombrePlaylist) async {
    // Buscar la playlist por nombre
    PlaylistMyApp? playlistSeleccionada = listasDePlaylists.firstWhere(
      (playlist) => playlist.nombre == nombrePlaylist,
      orElse: () => PlaylistMyApp(nombre: '', canciones: []),
    );

    if (playlistSeleccionada.nombre.isNotEmpty) {
      // Si la playlist existe y tiene canciones
      bool estaReproduciendo =
          player.playing; // Verifica si algo se está reproduciendo actualmente

      // Hacer una copia de las canciones de la playlist y barajarlas (shuffle)
      List<Cancion> cancionesAleatorias =
          List.from(playlistSeleccionada.canciones)..shuffle();

      // Agregar todas las canciones barajadas a la cola
      for (Cancion cancion in cancionesAleatorias) {
        agregarCancionDespuesDeActual(cancion, false);
      }

      // Si no hay nada reproduciéndose, comenzamos a reproducir una canción al azar
      if (!estaReproduciendo && cancionesAleatorias.isNotEmpty) {
        miniReproduciendo = true;
        await empezarEscucharCancion(listaCancionesPorReproducir.first);
      }

      // Notificar a los listeners para actualizar la UI
    } else {}
    notifyListeners();
  }

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

  @override
  Future<void> skipToPrevious() async {
    playPrevious();
    notifyListeners();
  }

  @override
  Future<void> skipToNext() async {
    playNext();
    notifyListeners();
  }

  // Pausar el audio
  @override
  Future<void> pause() async {
    await player.pause();
    notifyListeners();
  }

  // Reproducir el audio
  @override
  Future<void> play() async {
    await player.play();
    notifyListeners();
  }

  // Detener la reproducción
  @override
  Future<void> stop() async {
    await player.stop();
    notifyListeners();
  }

  // Actualizar la posición de la canción actual
  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
    notifyListeners();
  }

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

  int selectedIndex = 0;
  int menuItem = 0;

  void cambiarSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void cambiarMenuItem(int index) {
    menuItem = index;
    selectedIndex = index;
    notifyListeners();
  }

  void showBottomSheet(BuildContext context, List<Cancion> lista) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(color: Color(0xff022527)),
          width: double.infinity,
          height: MediaQuery.of(context).size.height /
              1, //La mitad de la altura de la pantalla
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

  int playListSeleccionada = 0;

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

        // Agregar canciones a la cola de reproducción
        for (var cancion in cancionesList) {
          agregarCancionDespuesDeActual(cancion, false);
        }

        notifyListeners(); // Notificar a los listeners que la cola ha sido actualizada
      } else {
        throw Exception(
            'Failed to load songs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Aquí puedes manejar el error como prefieras, por ejemplo:
      // mostrar un mensaje al usuario, o intentar nuevamente
    }
  }
}
