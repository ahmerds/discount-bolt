import 'package:cab_rider/dataprovider/app_data.dart';
import 'package:cab_rider/global_vars.dart';
import 'package:cab_rider/helpers/request_helper.dart';
import 'package:cab_rider/models/address.dart';
import 'package:cab_rider/models/prediction.dart';
import 'package:cab_rider/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../brand_colors.dart';

class PredictionTile extends StatelessWidget {
  PredictionTile({this.prediction});
  final Prediction prediction;

  void getPlaceDetails(String placeId, context) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => ProgressDialog(
              status: 'Please wait...',
            ));

    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$mapKey";

    var response = await RequestHelper.getRequest(url);

    Navigator.pop(context);

    if (response == 'Failed') {
      return;
    }

    if (response['status'] == 'OK') {
      Address thisPlace = Address();
      thisPlace.placeName = response['result']['name'];
      thisPlace.placeId = placeId;
      thisPlace.latitude = response['result']['geometry']['location']['lat'];
      thisPlace.longitude = response['result']['geometry']['location']['lng'];

      Provider.of<AppData>(context, listen: false)
          .updateDestinationAddress(thisPlace);

      // Navigate back to the homepage with args
      Navigator.pop(context, 'getDirection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () {
        getPlaceDetails(prediction.placeId, context);
      },
      padding: EdgeInsets.all(0),
      child: Container(
        child: Column(
          children: [
            SizedBox(
              height: 8.0,
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: BrandColors.colorDimText,
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.mainText,
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        prediction.secondaryText,
                        style: TextStyle(
                            fontSize: 12, color: BrandColors.colorDimText),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 8.0,
            ),
          ],
        ),
      ),
    );
  }
}
