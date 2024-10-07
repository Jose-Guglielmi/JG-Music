import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class BuscadorScreen extends StatelessWidget {
  const BuscadorScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    return Scaffold(
      backgroundColor: AppTheme.colorList[0],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SearchTextField(),
          /*const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Artistas",
              style: TextStyle(color: AppTheme.text, fontSize: 20.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: double.infinity,
              height: 130,
              child: (myAudioHandler.listaCanciones.isNotEmpty)
                  ? const ArtistasView()
                  : const SinResultados(),
            ),
          ),*/
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Canciones",
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: double.infinity,
                child: (myAudioHandler.listaCanciones.isNotEmpty)
                    ? const CancionesViewV2()
                    : const SinResultados(),
              ),
            ),
          ),
          const MusicPlayerCard(),
        ],
      ),
    );
  }
}
