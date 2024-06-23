import 'package:autoposter_mobile/screen/upload_screen.dart';
import 'package:autoposter_mobile/service.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initService();

  runApp(
    MaterialApp(
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
        ),
        // scaffoldBackgroundColor: ThemeDataConst.backgroundColor,
      ),
      home: const UploadScreen(),
    ),
  );
}
