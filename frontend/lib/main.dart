import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

void main() {
  runApp(const MpladsSanchalanApp());
}

class MpladsSanchalanApp extends StatelessWidget {
  const MpladsSanchalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MPLADS Sanchalan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}