import 'dart:async';
import 'dart:developer';
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_scanner/qr_scanner_overlay_shape.dart';

import 'package:http/http.dart' as http;
import 'package:qr_code_scanner_example/product_found.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

void main() => runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: QRViewExample()));

const flash_on = "FLASH ON";
const flash_off = "FLASH OFF";
const front_camera = "FRONT CAMERA";
const back_camera = "BACK CAMERA";

class QRViewExample extends StatefulWidget {
  const QRViewExample({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  var qrText = "";
  var flashState = flash_off;
  var scanMode = 'SCAN ON';
  var cameraState = front_camera;
  QRViewController controller;
  GlobalKey qrKey;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final assets = <String>[
    "product_exists.mp3",
    "new_product.mp3",
  ];
  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();

  var _currentAssetPosition = -1;

  void _open(int assetIndex) {
    _currentAssetPosition = assetIndex % assets.length;
    _assetsAudioPlayer.open(
      AssetsAudio(
        asset: assets[_currentAssetPosition],
        folder: "assets/sounds/",
      ),
    );
  }

  void _playPause() {
    _assetsAudioPlayer.play();
  }

  @override
  void initState() {
    print('scanner_screen loaded');
    qrKey = GlobalKey(debugLabel: 'QR');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  bool _fetching = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Stock Collector'),
          backgroundColor: Colors.redAccent,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: (_isFlashOn(flashState)
                    ? Icon(Icons.flash_off, size: 30)
                    : Icon(Icons.flash_on, size: 30)),
                tooltip: 'Toggle Flash',
                onPressed: () {
                  if (controller != null) {
                    log('flash toggled');
                    controller.toggleFlash();
                    if (_isFlashOn(flashState)) {
                      setState(() {
                        flashState = flash_off;
                      });
                    } else {
                      setState(() {
                        flashState = flash_on;
                      });
                    }
                  }
                },
              ),
            ),
          ],
        ),
        body: ModalProgressHUD(
          opacity: 0,
          progressIndicator: CircularProgressIndicator(
            backgroundColor: Colors.white,
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.redAccent),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.redAccent,
                    borderRadius: 15,
                    borderLength: 50,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
                flex: 4,
              ),
            ],
          ),
          inAsyncCall: _fetching,
        ));
  }

// isProductListed = async (capturedBarcode) => {
//   if(typeof capturedBarcode !== typeof undefined && capturedBarcode !== null && capturedBarcode.data.length > 6) {
//       await axios.get(`${this.props.serverURL}/mob-is-product-listed/${capturedBarcode.data}`)
//       .then( response => {
//           if(!response.data.isListed)
//               this.props.navigation.navigate('InsertionForm', {barcode: capturedBarcode.data, type: capturedBarcode.type});
//               this.setState({parsingResult:null,barcodeType:null,textToGenerate:null})
//       })
//       .catch( e => {
//           console.log(e);
//       })
//       .finally( () => {

//       });
//   } else {
//       console.log(`Something went wrong 'capturedBarcode'`);
//   }
// };

  isProductListed(String result) async {
    String barcode = result.split('____')[0];
    Map product = {'barcode': barcode, 'type': result.split('____')[1]};

    var response =
        await http.get("http://47.254.178.24/mob-is-product-listed/$barcode");
    if (response.statusCode == 200) {
      var data = convert.jsonDecode(response.body);

      data['barcode'] = barcode;
      if (data['isListed'] == true) {
        _open(0);
        _playPause();
        // data['barcode'] = barcode;
        _navigateToProductPage(context, data);
        // controller.resumeCamera();
        print('product was found');
      } else {
        _open(1);
        _playPause();

        _navigateToProductPage(context, data);
        // controller.resumeCamera();
        print('this is a new product');
      }
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load post');
    }
  }

  _navigateToProductPage(BuildContext context, Map product) async {
    _fetching = false;

    final tst = await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => ProductFound(
                product: product,
              )),
    ).then((result) {
      if (result.toString() == 'back_to_scanner') {
        // controller.resumeCamera(); //
        setState(() {
          scanMode = 'SCAN ON';
        });
        // to reload camera i had to flip it twice :(
        controller.flipCamera();
        controller.flipCamera();
        print(result);
      }
    });
  }

  _isFlashOn(String current) {
    return flash_on == current;
  }

  _isBackCamera(String current) {
    return back_camera == current;
  }

  void _onQRViewCreated(QRViewController controller) {
    // checkLoginStatus();
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData;
      });
      if (scanData != '') {
        _fetching = true;
        setState(() {
          scanMode = 'SCAN OFF';
        });
        controller.pauseCamera();
        isProductListed(scanData);
      }
    });
  }

  @override
  void dispose() {
    _assetsAudioPlayer.stop();
    controller.dispose();
    super.dispose();
  }
}
