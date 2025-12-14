import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:k_router/k_router.dart';

import 'locations/locations.dart';


void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({ super.key, });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  /// Cache router in a variable to preserve state during hot reload
  final router = AppRouterConfig(
    initialLocation: SimpleLocation(
      uri: Uri(path: '/'),
      title: 'Home',
    ),
    locationCodecs: Locations.values.toLocationCodecMap(),
    onDeepLink: (uri) => DeepLinkResult.push(
      SimpleLocation(
        uri: uri,
        title: 'Deep link $uri',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) =>
    CupertinoApp.router(
      onGenerateTitle: (context) => 'Test app',
      restorationScopeId: 'app',
      routerConfig: router,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        barBackgroundColor: Colors.white,
      ),
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
}
