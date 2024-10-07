import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class CancionesViewCola extends StatefulWidget {
  const CancionesViewCola({
    super.key,
  });

  @override
  State<CancionesViewCola> createState() => _CancionesViewColaState();
}

class _CancionesViewColaState extends State<CancionesViewCola> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    return ListView.builder(
      itemCount: myAudioHandler.listaCancionesPorReproducir.length,
      itemBuilder: (context, index) {
        Cancion cancion = myAudioHandler.listaCancionesPorReproducir[index];

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
          child: GestureDetector(
            onTap: () {
              myAudioHandler.empezarEscucharCancion(cancion);
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: (myAudioHandler.estaCancionEnReproduccion(cancion)
                      ? AppTheme.surface
                      : Colors.transparent)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        cancion.thumbnail,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
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
                                  color: Color.fromARGB(255, 173, 173, 173),
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
                                color: Color.fromARGB(255, 255, 252, 252),
                                fontSize: 15),
                          ),
                          (cancion.isExplicit)
                              ? const Icon(
                                  Icons.explicit,
                                  color: Colors.white,
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
                        color: Colors.white,
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
                            ? const Color.fromARGB(255, 155, 154, 154)
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

  void buttonMeGusta(
      BuildContext context, Cancion cancion, MyAudioHandler myAudioHandler) {
    myAudioHandler.agregarCancionAPlaylist("Favoritos", cancion);

    setState(() {});
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
    myAudioHandler.eliminarCancionDeListaPorReproducir(cancion);
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
}
