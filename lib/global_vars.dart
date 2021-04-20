import 'package:cab_rider/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String mapKey = "AIzaSyC6rp-knpUZ4-FXhDZkV-RvyM9-3hbFg64";
String serverKey =
    "key=AAAAlyg9M6U:APA91bHAPz5JOzl8cKwDxUpkiEOn6R97ddITVW4PnBkFkih12-wkZdVn3AXosm3qOxWQRX_AzewEVtpVYrNWzKV-xO4Qg26t8e9k1SS65K_gaekVcXyshirwi-O_1uq-gAQGohytIdph";
final CameraPosition kWuse2 = CameraPosition(
  target: LatLng(9.080306, 7.486276),
  zoom: 15.4746,
);

User currentFirebaseUser;
UserModel currentUserInfo;
