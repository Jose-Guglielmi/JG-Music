import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class ArtistasView extends StatelessWidget {
  const ArtistasView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    final List<Artist> listaArtistas = myAudioHandler.listaArtistas;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: listaArtistas.length,
      itemBuilder: (context, index) {
        Artist artista = listaArtistas[index];

        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.network(
                        artista.thumbnail,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // Retorna la imagen cuando ha sido cargada completamente
                          } else {
                            return CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              radius: 40, // Ajusta el tamaño del ícono
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.primary,
                                size: 40,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                      child: ScrollingText(
                        centerWhenNoScroll: true,
                        text: artista.title,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
