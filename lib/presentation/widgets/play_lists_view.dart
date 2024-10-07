import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);
    PlaylistMyApp lista =
        myAudioHandler.listasDePlaylists[myAudioHandler.playListSeleccionada];

    final TextEditingController titleController = TextEditingController();

    Future<void> _showDialog(String nombre) async {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          final myAudioHandler = Provider.of<MyAudioHandler>(context);

          return AlertDialog(
            title: const Text('Editar nombre'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Titulo"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Aceptar'),
                onPressed: () {
                  // Aquí puedes manejar el aceptar, por ejemplo, guardar la información
                  myAudioHandler.modificarNombrePlaylist(
                      lista.nombre, titleController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            myAudioHandler.cambiarSelectedIndex(myAudioHandler.menuItem);
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
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
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      lista.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    (lista.nombre != "Favoritos")
                        ? IconButton(
                            onPressed: () {
                              _showDialog(lista.nombre);
                            },
                            color: AppTheme.text,
                            icon: const Icon(
                              Icons.edit,
                            ),
                          )
                        : Container(),
                    const Spacer(),
                    (lista.nombre != "Favoritos")
                        ? IconButton(
                            onPressed: () {
                              myAudioHandler.borrarPlaylist(lista.nombre);
                              myAudioHandler.cambiarSelectedIndex(
                                  myAudioHandler.menuItem);
                            },
                            color: Colors.white,
                            icon: const Icon(
                              Icons.delete,
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        myAudioHandler.agregarPlaylistACola(lista.nombre);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppTheme.primary),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow_outlined),
                            SizedBox(
                              width: 5,
                            ),
                            Text("Reproducir"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        myAudioHandler
                            .agregarPlaylistAColaAleatoria(lista.nombre);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppTheme.secondary),
                        child: const Row(
                          children: [
                            Icon(Icons.shuffle_rounded),
                            SizedBox(
                              width: 5,
                            ),
                            Text("Aleatorio"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: AppTheme.secondary),
                      child: const Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(
                            width: 5,
                          ),
                          Text("Descargar"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Canciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Expanded(child: CancionesViewPlaylists()),
              const MusicPlayerCard(),
            ],
          ),
        ),
      ),
    );
  }
}
