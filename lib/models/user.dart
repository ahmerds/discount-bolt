import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String fullName;
  String email;
  String phone;
  String id;

  UserModel({this.email, this.fullName, this.phone, this.id});

  UserModel.fromSnapshot(DataSnapshot snapshot) {
    id = snapshot.key;
    phone = snapshot.value['phone'];
    fullName = snapshot.value['fullName'];
    email = snapshot.value['email'];
  }
}
