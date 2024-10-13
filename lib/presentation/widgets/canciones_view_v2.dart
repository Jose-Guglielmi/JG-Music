import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class CancionesViewV2 extends StatefulWidget {
  const CancionesViewV2({
    super.key,
  });

  @override
  State<CancionesViewV2> createState() => _CancionesViewV2State();
}

class _CancionesViewV2State extends State<CancionesViewV2> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    return ListView.builder(
      itemCount: myAudioHandler.listaCanciones.length,
      itemBuilder: (context, index) {
        Cancion cancion = myAudioHandler.listaCanciones[index];

        return Dismissible(
          key: Key(cancion.videoId),
          direction: DismissDirection
              .endToStart, // Configura la dirección del deslizamiento
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Llama a la función que deseas ejecutar cuando se deslice
              onSwipeRight(context, cancion, myAudioHandler);
              return false; // Devuelve false para que el item no se elimine de la lista
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            color: AppTheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.queue_music, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: () {
              myAudioHandler.empezarEscucharCancion(cancion);
              myAudioHandler.cambiarSelectedIndex(3);
            },
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    const ClipOval(
                      child: Icon(
                        Icons.music_note_outlined,
                        color: Colors.purple,
                        size: 40,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ScrollingText(
                              text: cancion.title,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontSize: 17,
                              ),
                            ),
                            ScrollingText(
                              text: cancion.author,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            cancion.duration,
                            style: const TextStyle(
                                color: AppTheme.text, fontSize: 15),
                          ),
                          (cancion.isExplicit)
                              ? const Icon(
                                  Icons.explicit,
                                  color: AppTheme.text,
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        myAudioHandler.mostrarPopDeGuardarCancionEnPlaylist(
                            context, cancion);
                      },
                      icon: const Icon(
                        Icons.playlist_add,
                        color: AppTheme.text,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        buttonMeGusta(context, cancion, myAudioHandler);
                      },
                      icon: Icon(
                        Icons.favorite_border,
                        color: (myAudioHandler.verificarMeGusta(
                                "Favoritos", cancion))
                            ? AppTheme.text
                            : Colors.pinkAccent,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Función que se llama cuando se desliza hacia la derecha
  void onSwipeRight(
      BuildContext context, Cancion cancion, MyAudioHandler myAudioHandler) {
    myAudioHandler.agregarCancionDespuesDeActual(cancion, false);
    setState(() {});

    // Aquí puedes implementar la funcionalidad que deseas
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cancion.title} Se agrego a la cola de reproduccion'),
        showCloseIcon: true,
      ),
    );
    // Puedes agregar otras acciones aquí
  }

  void buttonMeGusta(
      BuildContext context, Cancion cancion, MyAudioHandler myAudioHandler) {
    myAudioHandler.agregarCancionAPlaylist("Favoritos", cancion);
    setState(() {});
  }
}
