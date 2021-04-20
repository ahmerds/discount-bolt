import 'dart:io';

import 'package:cab_rider/dataprovider/app_data.dart';
import 'package:cab_rider/global_vars.dart';
import 'package:cab_rider/screens/loginpage.dart';
import 'package:cab_rider/screens/main_page.dart';
import 'package:cab_rider/screens/registrationpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    options: Platform.isIOS || Platform.isMacOS
        ? FirebaseOptions(
            appId: 'ENTER YOUR APP ID',
            apiKey: 'ENTER YOUR API KEY',
            projectId: 'PROJECT ID',
            messagingSenderId: '649215161253',
            databaseURL: 'DB URL',
          )
        : FirebaseOptions(
            appId: 'ENTER YOUR APP ID',
            apiKey: 'ENTER YOUR API KEY',
            projectId: 'PROJECT ID',
            messagingSenderId: '649215161253',
            databaseURL: 'DB URL',
          ),
  );
  

  currentFirebaseUser = FirebaseAuth.instance.currentUser;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'Brand-Regular',
          primarySwatch: Colors.lightBlue,
        ),
        initialRoute: (currentFirebaseUser == null) ? LoginPage.id : MainPage.id,
        routes: {
          RegistrationPage.id: (context) => RegistrationPage(),
          LoginPage.id: (context) => LoginPage(),
          MainPage.id: (context) => MainPage(),
        },
      ),
    );
  }
}
