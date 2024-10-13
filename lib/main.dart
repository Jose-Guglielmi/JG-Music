import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:jg_music/presentation/widgets/direcciones.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.jg_music',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(MainApp(audioHandler: audioHandler));
}

class MainApp extends StatefulWidget {
  final MyAudioHandler audioHandler;
  const MainApp({super.key, required this.audioHandler});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audioHandler.player
        .dispose(); // Asegúrate de liberar los recursos del reproductor
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // La app ha sido completamente cerrada
      widget.audioHandler.player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: widget.audioHandler,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme().themedata(),
        home: MenuInferior(
          audioHandler: widget.audioHandler,
        ),
      ),
    );
  }
}

class MenuInferior extends StatefulWidget {
  const MenuInferior({
    super.key,
    required this.audioHandler,
  });

  final MyAudioHandler audioHandler;

  @override
  State<MenuInferior> createState() => _MenuInferiorState();
}

class _MenuInferiorState extends State<MenuInferior> {
  @override
  Widget build(BuildContext context) {
    final myAudioHandler = Provider.of<MyAudioHandler>(context);

    List<Widget> widgetOptions = <Widget>[
      const BuscadorScreen(),
      const Biblioteca(),
      const Text('Opciones'),
      MusicPlayerUI(
        myAudioHandler: myAudioHandler,
      ),
      const PlaylistView(),
    ];

    int selectedIndex = myAudioHandler.selectedIndex;
    int menuItem = myAudioHandler.menuItem;
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.colorList[0],
        body: Center(
          child: widgetOptions.elementAt(selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Biblioteca',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Opciones',
            ),
          ],
          currentIndex: menuItem,
          elevation: 20.0,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.white,
          backgroundColor: AppTheme.colorList[1],
          type: BottomNavigationBarType.fixed,
          onTap: myAudioHandler.cambiarMenuItem,
          enableFeedback: false, // Desactiva la retroalimentación táctil
        ),
      ),
    );
  }
}
