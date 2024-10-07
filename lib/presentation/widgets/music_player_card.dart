import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class MusicPlayerCard extends StatefulWidget {
  const MusicPlayerCard({super.key});

  @override
  State<MusicPlayerCard> createState() => _MusicPlayerCardState();
}

class _MusicPlayerCardState extends State<MusicPlayerCard> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    Cancion cancion = myAudioHandler.cancionSeleccionado;

    return (cancion.title != "")
        ? GestureDetector(
            onTap: () {
              myAudioHandler.cambiarSelectedIndex(3);
            },
            child: Container(
              color: AppTheme.background,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surface, // Color de fondo del reproductor
                    borderRadius: BorderRadius.circular(10),
// Bordes redondeados
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Imagen del álbum o artista
                        ClipOval(
                          // Bordes redondeados para la imagen
                          child: Image.network(
                            cancion
                                .thumbnail, // Reemplaza con la URL de la imagen real
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(
                            width: 16), // Espacio entre la imagen y el texto
                        // Detalles de la canción
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScrollingText(
                                text: cancion.title,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ScrollingText(
                                text: cancion.author,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Controles de reproducción
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_previous_outlined),
                          color: AppTheme.text,
                        ),
                        IconButton(
                          icon: Icon(myAudioHandler.player.playing
                              ? Icons.pause
                              : Icons.play_arrow_outlined),
                          color: AppTheme.text,
                          onPressed: () {
                            setState(() {
                              try {
                                if (myAudioHandler.player.playing) {
                                  myAudioHandler.pause();
                                } else {
                                  myAudioHandler.play();
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
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_next_outlined),
                          // ignore: prefer_const_constructors
                          color: AppTheme.text,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container(
            color: AppTheme.background,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface, // Color de fondo del reproductor
                  borderRadius: BorderRadius.circular(10),
                  // Bordes redondeados
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.surface,
                        radius: 40, // Ajusta el tamaño del ícono
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primary,
                          size: 40,
                        ),
                      ),

                      SizedBox(width: 16), // Espacio entre la imagen y el texto
                      // Detalles de la canción
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScrollingText(
                              text: "No hay nada por reproducir",
                              style: TextStyle(
                                color: AppTheme.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controles de reproducción
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.skip_previous),
                        color: AppTheme.text,
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.pause),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.skip_next),
                        // ignore: prefer_const_constructors
                        color: AppTheme.text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
