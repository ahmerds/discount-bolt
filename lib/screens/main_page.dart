import 'dart:async';
import 'dart:io';

import 'package:cab_rider/brand_colors.dart';
import 'package:cab_rider/dataprovider/app_data.dart';
import 'package:cab_rider/global_vars.dart';
import 'package:cab_rider/helpers/fire_helper.dart';
import 'package:cab_rider/helpers/helper_methods.dart';
import 'package:cab_rider/models/direction_details.dart';
import 'package:cab_rider/models/nearby_driver.dart';
import 'package:cab_rider/ride_variables.dart';
import 'package:cab_rider/screens/search_page.dart';
import 'package:cab_rider/styles/styles.dart';
import 'package:cab_rider/widgets/CollectPaymentDialog.dart';
import 'package:cab_rider/widgets/NoDriverDialog.dart';
import 'package:cab_rider/widgets/brand_divider.dart';
import 'package:cab_rider/widgets/progress_dialog.dart';
import 'package:cab_rider/widgets/taxi_button.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class MainPage extends StatefulWidget {
  static const String id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  double searchSheetHeight = Platform.isIOS ? 300 : 275;
  double rideDetailsSheetHeight = 0; // Platform.isIOS ? 260 : 235;
  double requestingSheetHeight = 0; // Platform.isIOS ? 220 : 195;
  double tripSheetHeight = 0; // Platform.isIOS ? 300 : 275;
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  double mapBottomPadding = 0;

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  Position currentPosition;

  DirectionDetails tripDirectionDetails;

  bool drawerCanOpen = true;

  DatabaseReference rideRef;

  BitmapDescriptor nearbyIcon;

  bool nearbyDriversKeysLoaded = false;

  List<NearbyDriver> availableDrivers;

  String appState = 'NORMAL';

  StreamSubscription<Event> rideSubscription;

  bool isRequestingLocationDetails = false;

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration,
              (Platform.isIOS)
                  ? 'images/car_ios.png'
                  : 'images/car_android.png')
          .then((icon) {
        nearbyIcon = icon;
      });
    }
  }

  void setupPositionLocator() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;

    LatLng pos = LatLng(position.latitude, position.longitude);
    CameraPosition cp = CameraPosition(target: pos, zoom: 15);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

    HelperMethods.findCoordinateAddress(position, context);

    startGeofireListener();
  }

  void showDetailSheet() async {
    await getDirection();
    setState(() {
      searchSheetHeight = 0;
      rideDetailsSheetHeight = (Platform.isAndroid) ? 235 : 260;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = false;
    });
  }

  void showRequestingSheet() {
    setState(() {
      rideDetailsSheetHeight = 0;
      requestingSheetHeight = Platform.isIOS ? 220 : 195;
      mapBottomPadding = Platform.isIOS ? 190 : 200;

      drawerCanOpen = true;
    });

    createRideRequest();
  }

  void showTripSheet() {
    setState(() {
      requestingSheetHeight = 0;
      tripSheetHeight = Platform.isIOS ? 300 : 275;
      mapBottomPadding = Platform.isIOS ? 270 : 280;
    });
  }

  @override
  void initState() {
    super.initState();
    HelperMethods.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    createMarker();

    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 250,
        color: Colors.white,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.all(0),
            children: [
              Container(
                color: Colors.white,
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/user_icon.png',
                        height: 60,
                        width: 60,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "John Doe",
                            style: TextStyle(
                                fontSize: 20, fontFamily: 'Brand-Bold'),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text("View Profile"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BrandDivider(),
              SizedBox(
                height: 10,
              ),
              ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text(
                  "Free Rides",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text(
                  "Payments",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "Ride History",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.contact_support_outlined),
                title: Text(
                  "Support",
                  style: kDrawerItemStyle,
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  "About",
                  style: kDrawerItemStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapBottomPadding),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: kWuse2,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: _polylines,
            markers: _markers,
            circles: _circles,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;

              setState(() {
                mapBottomPadding = Platform.isAndroid ? 280 : 270;
              });

              setupPositionLocator();
            },
          ),

          // Menu Button
          Positioned(
            top: 44,
            left: 20,
            child: GestureDetector(
              onTap: () {
                if (drawerCanOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20.0,
                  child: Icon(
                    (drawerCanOpen) ? Icons.menu_rounded : Icons.arrow_back,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Search Sheet
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(microseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                height: searchSheetHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Nice to see you!',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Where are you going?',
                        style:
                            TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchPage()));

                          if (response == 'getDirection') {
                            showDetailSheet();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5.0,
                                    spreadRadius: 0.5,
                                    offset: Offset(0.7, 0.7))
                              ]),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text("Search Destination")
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Add Home",
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                "Your residential address",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: BrandColors.colorDimText),
                              )
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            color: BrandColors.colorDimText,
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                "Your office address",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: BrandColors.colorDimText),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // RideDetails Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 150),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ],
                ),
                height: rideDetailsSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: BrandColors.colorAccent1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset(
                                'images/taxi.png',
                                height: 70,
                                width: 70,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taxi',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Brand-Bold'),
                                  ),
                                  Text(
                                    (tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : '',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: BrandColors.colorTextLight),
                                  ),
                                ],
                              ),
                              Spacer(),
                              Text(
                                (tripDirectionDetails != null)
                                    ? "\$${HelperMethods.estimateFares(tripDirectionDetails)}"
                                    : '',
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Brand-Bold'),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.solidMoneyBillAlt,
                              size: 18,
                              color: BrandColors.colorTextLight,
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Text('Cash'),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: BrandColors.colorTextLight,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: TaxiButton(
                          title: 'REQUEST CAB',
                          color: BrandColors.colorGreen,
                          onPressed: () {
                            setState(() {
                              appState = 'REQUESTING';
                            });
                            showRequestingSheet();

                            availableDrivers = FireHelper.nearbyDriverList;
                            findDriver();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Requesting Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                height: requestingSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextLiquidFill(
                          text: 'Requesting a Ride...',
                          waveColor: BrandColors.colorTextSemiLight,
                          boxBackgroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 22.0,
                            fontFamily: 'Brand-Bold',
                          ),
                          boxHeight: 40.0,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () {
                          cancelRequest();
                          resetApp();
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  width: 1.0,
                                  color: BrandColors.colorLightGrayFair)),
                          child: Icon(
                            Icons.close,
                            size: 25,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Cancel ride',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Trip Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSize(
              vsync: this,
              duration: Duration(milliseconds: 150),
              curve: Curves.easeIn,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                height: tripSheetHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tripStatusDisplay,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontFamily: 'Brand-Bold'),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        driverCarDetails,
                        style: TextStyle(color: BrandColors.colorTextLight),
                      ),
                      Text(
                        driverFullName,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      BrandDivider(),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.call),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Call'),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.list),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Details'),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorTextLight),
                                ),
                                child: Icon(Icons.clear),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Cancel'),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDirection() async {
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    var pickupLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => ProgressDialog(
              status: 'Please wait...',
            ));

    var thisDetails = await HelperMethods.getDirectionDetails(
        pickupLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetails = thisDetails;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails.encodedPoints);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      results.forEach((PointLatLng points) {
        polylineCoordinates.add(LatLng(points.latitude, points.longitude));
      });
    }

    _polylines.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      _polylines.add(polyline);
    });

    LatLngBounds bounds;

    if (pickupLatLng.latitude > destinationLatLng.latitude &&
        pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, destinationLatLng.longitude),
          northeast:
              LatLng(destinationLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, pickupLatLng.longitude),
          northeast:
              LatLng(pickupLatLng.latitude, destinationLatLng.longitude));
    } else {
      bounds =
          LatLngBounds(southwest: pickupLatLng, northeast: destinationLatLng);
    }

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickupLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: 'Destination'),
    );

    setState(() {
      _markers.add(pickupMarker);
      _markers.add(destinationMarker);
    });

    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickupLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId('destination'),
      strokeColor: BrandColors.colorAccentPurple,
      strokeWidth: 3,
      radius: 12,
      center: pickupLatLng,
      fillColor: BrandColors.colorAccentPurple,
    );

    setState(() {
      _circles.add(pickupCircle);
      _circles.add(destinationCircle);
    });
  }

  void createRideRequest() {
    rideRef = FirebaseDatabase.instance.reference().child('rideRequest').push();
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    Map pickupMap = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };

    Map destinationMap = {
      'latitude': destination.latitude.toString(),
      'longitude': destination.longitude.toString(),
    };

    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_name': currentUserInfo.fullName,
      'rider_phone': currentUserInfo.phone,
      'pickup_address': pickup.placeName,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment_method': 'card',
      'driver_id': 'waiting',
    };

    rideRef.set(rideMap);

    rideSubscription = rideRef.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }

      // Get car details
      if (event.snapshot.value['car_details'] != null) {
        setState(() {
          driverCarDetails = event.snapshot.value['car_details'].toString();
        });
      }

      // Get driver name
      if (event.snapshot.value['driver_name'] != null) {
        setState(() {
          driverFullName = event.snapshot.value['driver_name'].toString();
        });
      }

      // Get driver phone number
      if (event.snapshot.value['driver_phone'] != null) {
        setState(() {
          driverPhoneNumber = event.snapshot.value['driver_phone'].toString();
        });
      }

      // Get and use driver location updates
      if (event.snapshot.value['driver_location'] != null) {
        double driverLat = double.parse(
            event.snapshot.value['driver_location']['latitude'].toString());
        double driverLng = double.parse(
            event.snapshot.value['driver_location']['longitude'].toString());

        LatLng driverLocation = LatLng(driverLat, driverLng);

        if (status == 'accepted') {
          updateToPickup(driverLocation);
        } else if (status == 'ontrip') {
          updateToDestination(driverLocation);
        } else if (status == 'arrived') {
          setState(() {
            tripStatusDisplay = 'Driver has arrived';
          });
        }
      }

      if (event.snapshot.value['status'] != null) {
        status = event.snapshot.value['status'].toString();
      }

      if (status == 'accepted') {
        showTripSheet();
        Geofire.stopListener();
        removeGeofireMarkers();
      }

      if (status == 'ended') {
        if (event.snapshot.value['fares'] != null) {
          int fares = int.parse(event.snapshot.value['fares'].toString());

          var response = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => CollectPayment(
                    paymentMethod: 'cash',
                    fares: fares,
                  ));

          if (response == 'close') {
            rideRef.onDisconnect();
            rideRef = null;
            rideSubscription.cancel();
            rideSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void removeGeofireMarkers() {
    setState(() {
      _markers
          .removeWhere((element) => element.markerId.value.contains('driver'));
    });
  }

  void updateToPickup(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;
      var positionLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, positionLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        tripStatusDisplay = 'Driver is arriving - ${thisDetails.durationText}';
      });
      isRequestingLocationDetails = false;
    }
  }

  void updateToDestination(LatLng driverLocation) async {
    if (!isRequestingLocationDetails) {
      isRequestingLocationDetails = true;
      var destination = Provider.of<AppData>(context).destinationAddress;
      var destinationLatLng =
          LatLng(destination.latitude, destination.longitude);
      var thisDetails = await HelperMethods.getDirectionDetails(
          driverLocation, destinationLatLng);

      if (thisDetails == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            'Driving to Destination - ${thisDetails.durationText}';
      });
      isRequestingLocationDetails = false;
    }
  }

  void cancelRequest() {
    rideRef.remove();
    setState(() {
      appState = 'NORMAL';
    });
  }

  void startGeofireListener() {
    Geofire.initialize('driversAvailable');

    (Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 10))
        .listen((map) {
      print(map);

      if (map != null) {
        var callBack = map['callBack'];
        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.nearbyDriverList.add(nearbyDriver);

            if (nearbyDriversKeysLoaded) {
              updateDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            FireHelper.removeFromList(map['key']);
            updateDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.updateNearbyLocation(nearbyDriver);
            updateDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            nearbyDriversKeysLoaded = true;
            updateDriversOnMap();

            break;
        }
      }

      setState(() {});
    });
  }

  void updateDriversOnMap() {
    setState(() {
      _markers.clear();
    });

    Set<Marker> tempMarkers = Set<Marker>();

    for (NearbyDriver driver in FireHelper.nearbyDriverList) {
      LatLng driverPosition = LatLng(driver.latitude, driver.longitude);

      Marker thisMarker = Marker(
          markerId: MarkerId("driver${driver.key}"),
          position: driverPosition,
          icon: nearbyIcon,
          rotation: HelperMethods.generateRandomNumber(360));

      tempMarkers.add(thisMarker);
    }

    setState(() {
      _markers = tempMarkers;
    });
  }

  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _polylines.clear();
      _markers.clear();
      _circles.clear();
      rideDetailsSheetHeight = 0;
      requestingSheetHeight = 0;
      tripSheetHeight = 0;
      searchSheetHeight = (Platform.isAndroid) ? 275 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
      drawerCanOpen = true;

      status = '';
      driverFullName = '';
      driverPhoneNumber = '';
      driverCarDetails = '';
      tripStatusDisplay = 'Driver is Arriving';
    });

    setupPositionLocator();
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverDialog());
  }

  void findDriver() {
    if (availableDrivers.length == 0) {
      cancelRequest();
      resetApp();
      noDriverFound();

      return;
    }

    var driver = availableDrivers[0];
    availableDrivers.removeAt(0);

    notifyDriver(driver);

    print(driver.key);
  }

  void notifyDriver(NearbyDriver driver) {
    DatabaseReference driverTripRef = FirebaseDatabase.instance
        .reference()
        .child("drivers/${driver.key}/newtrip");
    driverTripRef.set(rideRef.key);

    DatabaseReference tokenRef = FirebaseDatabase.instance
        .reference()
        .child("drivers/${driver.key}/token");
    tokenRef.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        String token = snapshot.value.toString();

        // Send notification to selected driver
        HelperMethods.sendNotification(token, context, rideRef.key);
      } else {
        return;
      }

      const oneSecTick = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecTick, (timer) {
        // Stop timer when ride request is cancelled
        if (appState != 'REQUESTING') {
          driverTripRef.set('cancelled');
          driverTripRef.onDisconnect();
          timer.cancel();
          driverRequestTimer = 30;
        }

        driverRequestTimer--;

        driverTripRef.onValue.listen((event) {
          // Confirms that the driver clicked accepted
          if (event.snapshot.value.toString() == 'accepted') {
            driverTripRef.onDisconnect();
            timer.cancel();
            driverRequestTimer = 30;
          }
        });

        if (driverRequestTimer == 0) {
          // Time out drivers ride
          driverTripRef.set('timeout');
          driverTripRef.onDisconnect();
          driverRequestTimer = 30;
          timer.cancel();

          // Find another driver
          findDriver();
        }
      });
    });
  }
}
