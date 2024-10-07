import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

class SinResultados extends StatelessWidget {
  const SinResultados({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Sin Resultados",
          style: TextStyle(color: AppTheme.text),
        ),
      ],
    );
  }
}
