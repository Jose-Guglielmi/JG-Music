import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class MusicPlayerUI extends StatefulWidget {
  const MusicPlayerUI({super.key, required this.myAudioHandler});

  final MyAudioHandler myAudioHandler;

  @override
  State<MusicPlayerUI> createState() => _MusicPlayerUIState();
}

class _MusicPlayerUIState extends State<MusicPlayerUI> {
  bool _disposed = false;
  late StreamSubscription<Duration> _positionSubscription;
  final ValueNotifier<Duration> _currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _totalDuration = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _positionSubscription =
        widget.myAudioHandler.player.positionStream.listen((position) {
      if (!_disposed) {
        _currentPosition.value = position;
      }
    });
    widget.myAudioHandler.player.durationStream.listen((duration) {
      if (!_disposed) {
        _totalDuration.value = duration ?? Duration.zero;
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription.cancel();
    _currentPosition.dispose();
    _totalDuration.dispose();
    //_currentLyric.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    Cancion cancion = myAudioHandler.cancionSeleccionado;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        myAudioHandler.cambiarSelectedIndex(myAudioHandler.menuItem);
        setState(() {});
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          myAudioHandler
                              .cambiarSelectedIndex(myAudioHandler.menuItem);
                        },
                        color: Colors.white,
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                        ),
                      ),
                      const Text(
                        'Reproductor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          myAudioHandler
                              .obtenerCancionesRelacionadas(cancion.videoId);
                        },
                        color: Colors.white,
                        icon: const Icon(Icons.radio_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: ClipOval(
                      child: Image.network(
                        cancion.thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Text(
                        cancion.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cancion.author,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 18),
                      ),
                    ],
                  ),
                  const Spacer(),
                  //barra de tiempo de la cancion
                  ValueListenableBuilder<Duration>(
                    valueListenable: _totalDuration,
                    builder: (context, totalDuration, child) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: _currentPosition,
                        builder: (context, currentPosition, child) {
                          return Column(
                            children: [
                              Slider(
                                value: currentPosition.inSeconds
                                    .toDouble()
                                    .clamp(
                                        0, totalDuration.inSeconds.toDouble()),
                                max: totalDuration.inSeconds.toDouble(),
                                min: 0,
                                onChanged: (value) {
                                  final newPosition =
                                      Duration(seconds: value.toInt());
                                  widget.myAudioHandler.player
                                      .seek(newPosition);
                                },
                                activeColor: AppTheme.text,
                                inactiveColor: Colors.white54,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    _formatDuration(currentPosition),
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    _formatDuration(totalDuration),
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_outlined),
                        color: Colors.white,
                        iconSize: 40,
                        onPressed: () {
                          setState(() {
                            myAudioHandler.playPrevious();
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                        child: IconButton(
                          icon: Icon(widget.myAudioHandler.player.playing
                              ? Icons.pause
                              : Icons.play_arrow),
                          color: Colors.white,
                          iconSize: 40,
                          onPressed: () {
                            setState(() {
                              try {
                                if (widget.myAudioHandler.player.playing) {
                                  widget.myAudioHandler.pause();
                                } else {
                                  widget.myAudioHandler.play();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Error al reproducir la canción')),
                                );
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next_outlined),
                        color: Colors.white,
                        iconSize: 40,
                        onPressed: () {
                          setState(() {
                            widget.myAudioHandler.playNext();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: (myAudioHandler.verificarMeGusta("Favoritos",
                                  widget.myAudioHandler.cancionSeleccionado))
                              ? const Color.fromARGB(255, 155, 154, 154)
                              : Colors.pinkAccent,
                        ),
                        color: Colors.white,
                        iconSize: 30,
                        onPressed: () async {
                          myAudioHandler.agregarCancionAPlaylist(
                              "Favoritos", cancion);
                        },
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        color: Colors.white,
                        iconSize: 30,
                        onPressed: () {
                          myAudioHandler.mostrarPopDeGuardarCancionEnPlaylist(
                              context, myAudioHandler.cancionSeleccionado);
                        },
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: (widget.myAudioHandler.cancionBucle)
                              ? Colors.pink
                              : Colors.white,
                        ),
                        color: Colors.white,
                        iconSize: 30,
                        onPressed: () {
                          widget.myAudioHandler.bucleCancion();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      setState(() {});
                      showBottomSheet(
                          context,
                          widget.myAudioHandler.listaCancionesPorReproducir,
                          myAudioHandler);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.queue_music,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text("Cola de reproduccion"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showBottomSheet(BuildContext context, List<Cancion> lista,
      MyAudioHandler myAudioHandler) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          width: double.infinity,
          height: MediaQuery.of(context).size.height /
              1, // La mitad de la altura de la pantalla
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Cola de reproduccion:",
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                      onPressed: () {
                        myAudioHandler.borrarColaDeReproduccion();
                      },
                      icon: const Icon(Icons.delete_outline))
                ],
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
}
