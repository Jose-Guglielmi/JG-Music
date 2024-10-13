import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class CancionesViewPlaylists extends StatefulWidget {
  const CancionesViewPlaylists({
    super.key,
  });

  @override
  State<CancionesViewPlaylists> createState() => _CancionesViewPlaylistsState();
}

class _CancionesViewPlaylistsState extends State<CancionesViewPlaylists> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    return ListView.builder(
      itemCount: myAudioHandler
          .listasDePlaylists[myAudioHandler.playListSeleccionada]
          .canciones
          .length,
      itemBuilder: (context, index) {
        Cancion cancion = myAudioHandler
            .listasDePlaylists[myAudioHandler.playListSeleccionada]
            .canciones[index];

        return Dismissible(
          key: Key(cancion.videoId),
          direction: DismissDirection
              .endToStart, // Configura la dirección del deslizamiento
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Llama a la función que deseas ejecutar cuando se deslice
              _mostrarPopDePreguntaSioNo(context, cancion, myAudioHandler);

              return false; // Devuelve false para que el item no se elimine de la lista
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            color: const Color.fromARGB(255, 127, 1, 74),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: GestureDetector(
              onTap: () {
                myAudioHandler.empezarEscucharCancion(cancion);
                myAudioHandler.cambiarSelectedIndex(3);
                myAudioHandler.miniReproduciendo = false;
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Row(
                  children: [
                    Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 17,
                              ),
                            ),
                            ScrollingText(
                              text: cancion.author,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 196, 196, 196),
                                  fontSize: 17),
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
                                color: Color.fromARGB(255, 255, 247, 247),
                                fontSize: 15),
                          ),
                          (cancion.isExplicit)
                              ? const Icon(
                                  Icons.explicit,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarPopDePreguntaSioNo(BuildContext context, Cancion cancion,
      MyAudioHandler myAudioHandler) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Desea Borrarlo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin acción
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                onSwipeRight(context, cancion, myAudioHandler);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función que se llama cuando se desliza hacia la derecha
  void onSwipeRight(
      BuildContext context, Cancion cancion, MyAudioHandler myAudioHandler) {
    PlaylistMyApp lista =
        myAudioHandler.listasDePlaylists[myAudioHandler.playListSeleccionada];
    myAudioHandler.borrarCancionDePlaylist(lista.nombre, cancion.videoId);
    setState(() {});
    // Aquí puedes implementar la funcionalidad que deseas
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${cancion.title} Se elimino de la playlist ${lista.nombre}'),
        showCloseIcon: true,
      ),
    );
    // Puedes agregar otras acciones aquí
  }
}
