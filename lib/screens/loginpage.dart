import 'package:cab_rider/brand_colors.dart';
import 'package:cab_rider/screens/main_page.dart';
import 'package:cab_rider/screens/registrationpage.dart';
import 'package:cab_rider/widgets/progress_dialog.dart';
import 'package:cab_rider/widgets/taxi_button.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  static const String id = 'login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void showSnackBar(String title) {
    final snackBar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15.0),
      ),
    );
    scaffoldKey.currentState.showSnackBar(snackBar);
  }

  var emailController = TextEditingController();

  var passwordController = TextEditingController();

  void login() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: "Logging in",
            ));

    User user;
    try {
      user = (await _auth
              .signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      )).user;
    } on Exception catch (e) {
      Navigator.pop(context);
      PlatformException thisEx = e;
      showSnackBar(thisEx.message);
      return;
    }

    if (user != null) {
      // Verify Login
      DatabaseReference userRef =
          FirebaseDatabase.instance.reference().child("users/${user.uid}");

      userRef.once().then((DataSnapshot snapshot) => {
            if (snapshot.value != null)
              {
                Navigator.pushNamedAndRemoveUntil(
                    context, MainPage.id, (route) => false)
              }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 70.0,
                ),
                Image(
                  alignment: Alignment.center,
                  height: 100.0,
                  width: 100.0,
                  image: AssetImage('images/logo.png'),
                ),
                SizedBox(
                  height: 40.0,
                ),
                Text(
                  'Sign In as Rider',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontFamily: 'Brand-Bold'),
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10.0),
                        ),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 14.0),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10.0),
                        ),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      TaxiButton(
                        title: 'LOGIN',
                        color: BrandColors.colorGreen,
                        onPressed: () async {
                          // Check network availabiility
                          var connectivityResult =
                              await (Connectivity()).checkConnectivity();

                          if (connectivityResult != ConnectivityResult.wifi &&
                              connectivityResult != ConnectivityResult.mobile) {
                            showSnackBar(
                                'You are not connected to the internet');
                            return;
                          }

                          if (!emailController.text.contains('@')) {
                            showSnackBar('Please enter a valid email address');
                          }

                          login();
                        },
                      ),
                    ],
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, RegistrationPage.id, (route) => false);
                  },
                  child: Text("Don't have an account? Sign up here"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
