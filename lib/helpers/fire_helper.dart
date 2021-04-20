import 'package:cab_rider/models/nearby_driver.dart';

class FireHelper {
  static List<NearbyDriver> nearbyDriverList = [];

  static void removeFromList(String key) {
    int index = nearbyDriverList.indexWhere((el) => el.key == key);
    nearbyDriverList.removeAt(index);
  }

  static void updateNearbyLocation(NearbyDriver driver) {
    int index = nearbyDriverList.indexWhere((el) => el.key == driver.key);

    nearbyDriverList[index].longitude = driver.longitude;
    nearbyDriverList[index].latitude = driver.latitude;
  }
}
