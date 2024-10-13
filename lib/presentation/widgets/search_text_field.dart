import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class SearchTextField extends StatelessWidget {
  const SearchTextField({super.key});

  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Buscar Artistas, Canciones....',
          // Ícono de búsqueda
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5), // Bordes redondeados
          ),
          filled: true, // Fondo rellenado
          fillColor: AppTheme.colorList[1], // Color de fondo
        ),
        onFieldSubmitted: (value) {
          myAudioHandler.fetchData(value, FilterType.artists);
          myAudioHandler.fetchData(value, FilterType.song);
        },
      ),
    );
  }
}
