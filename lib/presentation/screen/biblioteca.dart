import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class Biblioteca extends StatelessWidget {
  const Biblioteca({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    Future<void> _showDialog() async {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          final myAudioHandler = Provider.of<MyAudioHandler>(context);

          return AlertDialog(
            title: const Text('Nueva Playlist'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Título'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.text),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Aceptar',
                    style: TextStyle(color: AppTheme.text)),
                onPressed: () {
                  // Aquí puedes manejar el aceptar, por ejemplo, guardar la información
                  myAudioHandler.crearPlaylist(titleController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Tu Biblioteca',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.surface),
              child: TextButton(
                  style: const ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppTheme.primary)),
                  onPressed: () {
                    _showDialog();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 15,
                      ),
                      Text(
                        " Crear PlayList",
                        style: TextStyle(
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  )),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: myAudioHandler.listasDePlaylists.length,
                itemBuilder: (context, index) {
                  PlaylistMyApp playList =
                      myAudioHandler.listasDePlaylists[index];
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildPlaylistItem(
                      icon: (playList.nombre == "Favoritos")
                          ? Icons.favorite_border
                          : Icons.music_note_outlined,
                      title: playList.nombre,
                      subtitle: "Canciones: ${playList.canciones.length}",
                      context: context,
                      index: index,
                      iconColor: (playList.nombre == "Favoritos")
                          ? Colors.red
                          : AppTheme.primary,
                    ),
                  );
                }),
          ),
          const MusicPlayerCard(),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required BuildContext context,
    required int index,
  }) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);
    return GestureDetector(
      onTap: () {
        myAudioHandler.playListSeleccionada = index;
        myAudioHandler.cambiarSelectedIndex(4);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
