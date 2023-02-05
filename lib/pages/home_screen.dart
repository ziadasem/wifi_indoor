// ignore_for_file: deprecated_member_use, package_api_docs, public_member_api_docs
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as l;
import 'package:toast/toast.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xcl;
import 'package:path_provider/path_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String outputLabel = "N/A";

  Timer? t;
  String text = "not finished";
  Map data = {"result": [], "lat-position": [], "lng-position": [] , "index": []};
  Map ssidWithBssid = {};

  String outputMap = "";
  bool _isButtonLoading = false;
  bool _isSaving = false;
  Map<String, double> inputMap = {};

  TextEditingController sampleRateController = TextEditingController();
  TextEditingController indexController = TextEditingController();

  @override
  initState() {
    indexController.text = "0";
    sampleRateController.text = "100";
    workbook = xcl.Workbook();
    workbook2 = xcl.Workbook();

    sheet = workbook.worksheets[0];
    sheet2 = workbook2.worksheets[0];

    super.initState();
  }

  bool isIn = false;

  xcl.Workbook workbook = xcl.Workbook();
  xcl.Worksheet? sheet;

  xcl.Workbook workbook2 = xcl.Workbook();
// Accessing worksheet via index.
  xcl.Worksheet? sheet2;

  int offset = 0;

  // [sAPSSID, sPreSharedKey]
  Future<List<String>> getWiFiAPInfos() async {
    String? sAPSSID;
    String? sPreSharedKey;

    try {
      sAPSSID = await WiFiForIoTPlugin.getWiFiAPSSID();
    } on Exception {
      sAPSSID = "";
    }

    try {
      sPreSharedKey = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
    } on Exception {
      sPreSharedKey = "";
    }

    return [sAPSSID!, sPreSharedKey!];
  }

  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = <WifiNetwork>[];
    }

    return htResultNetwork;
  }

  @override
  Widget build(BuildContext poContext) {

    return MaterialApp(
      title: "Indoor Wifi",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(title: const Text("Enable Stoarge permission")),
          floatingActionButton:_isSaving?CircularProgressIndicator(): FloatingActionButton.extended(
              label: const Text("Save Values"),
              onPressed:postHeaderInvoice), // startSavingData),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("current number wifi SSIDs are ${data.keys.length}"),
                SwitchListTile(
                  title: const Text("inside region (result)"),
                  onChanged: (value) {
                    setState(() {
                      isIn = value;
                    });
                  },
                  value: isIn,
                  activeColor: Theme.of(context).primaryColor,
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(controller: sampleRateController,
                   decoration: const InputDecoration(labelText: "Sample rate in ms (default is 100ms)", hintText: "100"), ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(controller: indexController, 
                  decoration: const InputDecoration(labelText: "index label"),),
                ),
                _isButtonLoading
                    ? const Center( child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: () async {
                          try {
                            setState(() {
                              _isButtonLoading = true;
                            });
                            await appendNewReading();
                            offset++;
                          } catch (e) {
                            SnackBar snackBar = SnackBar(
                              content: Text(e.toString()),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } finally {
                            setState(() {
                              _isButtonLoading = false;
                            });
                          }
                        },
                        child: const Text("Take a read")),
                TextButton(
                    onPressed: () {
                      int counts = 0;
                      setState(() {
                        _isButtonLoading = true;
                      });
                      Timer.periodic(Duration(milliseconds: int.tryParse(sampleRateController.text ) ?? 100),
                          (timer) async {
                        await appendNewReading();
                        counts++;
                        if (counts > 50) {
                          timer.cancel();
                          setState(() {
                            _isButtonLoading = false;
                          });
                        }
                      });
                    },
                    child: const Text("Take continous sampling")),
              ],
            ),
          )
          ),
    );
  }

  void startSavingData() async {
      setState(() {
        _isSaving = true;
       });
       await saveXCL();
       // ignore: use_build_context_synchronously
       openToast1(context, "Done");
       setState(() {
          _isSaving = false;
       });
   }

  Future<void> appendNewReading() async {
    List<WifiNetwork> htResultNetwork = await loadWifiList();
    Position pos = await _getCurrentPosition();
    for (int i = 0; i < htResultNetwork.length; i++) {
      if (data[htResultNetwork[i].bssid.toString()] == null) {
        data[htResultNetwork[i].bssid.toString()] = [];
       ssidWithBssid[htResultNetwork[i].bssid.toString()] = htResultNetwork[i].ssid.toString();
        data[htResultNetwork[i].bssid.toString()] =
            List.generate(offset, (index) => -95);
      }
      data[htResultNetwork[i].bssid.toString()].add(htResultNetwork[i].level);
    }
    data["result"].add(isIn ? 1 : 0);
    data["lat-position"].add(pos.latitude);
    data["lng-position"].add(pos.longitude);
    data["index"].add(indexController.text);

    data.keys.toList().forEach((key) {
      try {
        if (data[key.toString()][offset] == null) {
          data[key.toString()].add(-95);
        }
      } catch (e) {
        data[key.toString()].add(-95);
        log(e.toString());
      }
    });
    offset++;
    log(data.toString());
  }

  Future saveXCL() async {
    int colIndex = 1;
    data.forEach((key, value) {
      List temp = data[key] as List;
      for (int rowIndex = 0; rowIndex < temp.length; rowIndex++) {
        sheet!
            .getRangeByIndex(rowIndex + 1, colIndex)
            .setNumber(data[key][rowIndex] * 1.0);
      }
      colIndex++;
    });

    int i = 1;
    data.forEach((key, value) {
      sheet2!.getRangeByName("A$i").setText(key.toString());
      sheet2!.getRangeByName("B$i").setText(ssidWithBssid[key] ??"Error");
      i++;
    });

    var dir = await getExternalStorageDirectory();
    String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    //final String path = (await getApplicationDocumentsDirectory()).path;
    final String filename = dir!.path + '/$timestamp values.xlsx';
    //final File file = File(filename);

    final String filename2 = '${dir.path}/$timestamp labels.xlsx';
    final File file2 = File(filename2);

    // Save the document.
    final List<int> bytes = workbook.saveAsStream();

    final List<int> bytes2 = workbook2.saveAsStream();

    await File(filename).writeAsBytes(bytes);
    await File(filename2).writeAsBytes(bytes2);

    log(filename);
  }

  Future<Position> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best)
        .timeout(Duration(seconds: 10));
    return position;
  }

  void a() async {
    l.Location location = new l.Location();

    bool _serviceEnabled;
    l.PermissionStatus _permissionGranted;
    l.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == l.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != l.PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

  //long length
  void openToast1(context, message) {
    if (context != null) {
      ToastContext().init(context);
      Toast.show(message,
          textStyle: TextStyle(color: Colors.white),
          backgroundRadius: 20,
          duration: Toast.lengthLong);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }


  Future postHeaderInvoice() async {
    Uri uri = Uri.parse('https://ziadasem.pythonanywhere.com/');
    try {
      String payload = jsonEncode({"input":"حزين" });
      final response = await http.post(uri,
          headers: {
            "Content-Type": "application/json",
          },
          body: payload);
      log(payload);
      log(response.statusCode.toString());
      log("${response.body} post header1");
      openToast1(context, response.body);
       
    } catch (e) {
      log("post invoice ${e.toString()}");
      rethrow;
    }
  }
}

class PopupCommand {
  String command;
  String argument;

  PopupCommand(this.command, this.argument);
}

 /*setState(() {
                    _text = "started";
                  });
              t =Timer.periodic(const Duration(milliseconds: 100), (timer) async{
              t = timer;
              //t!.cancel();
               
               if (offset < endNumber){
                   print(offset);
                    await appendNewReading();
               }else{
                 //offset = 0 ;
                  timer.cancel();
                  log("bye");
                  setState(() {
                    _text = "end";
                  });
               }
              });*/