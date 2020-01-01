import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_scanner/qr_scanner_overlay_shape.dart';

import 'package:http/http.dart' as http;
import 'scanner_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MainApp()));

class MainApp extends StatefulWidget {
  const MainApp({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  SharedPreferences sharedPreferences;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<bool> showLoginPage() async {
    sharedPreferences = await SharedPreferences.getInstance();

    // sharedPreferences.setString('user', 'hasuser');

    String user = sharedPreferences.getString('token');

    return user == null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: showLoginPage(),
          builder: (buildContext, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data) {
                // Return your login here
                return LoginPage();
              }

              // Return your home here
              return QRViewExample();
            } else {
              // Return loading screen while reading preferences
              return Container(
                  color: Colors.redAccent,
                  child: Center(
                      child: SpinKitPulse(
                    color: Colors.white,
                    size: 100.0,
                  )));
            }
          },
        ));
  }
}
