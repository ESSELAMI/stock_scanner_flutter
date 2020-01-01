import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_scanner/qr_scanner_overlay_shape.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:http/http.dart' as http;
import 'scanner_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProductFound(
      product: null,
    )));

class ProductFound extends StatefulWidget {
  final Map product;
  ProductFound({Key key, @required this.product}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProductFoundState();
}

class _ProductFoundState extends State<ProductFound> {
  SharedPreferences sharedPreferences;
  bool _perishable = false;
  bool _weighable = false;
  var _productName = TextEditingController();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    setState(() {
      _productName.text = widget.product['productName'].toString();
      _perishable = widget.product['is_perishable'];
      _weighable = widget.product['is_weighable'];
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Colors.redAccent,
              title: Text("Product found"),
              leading: Padding(
                padding: const EdgeInsets.all(0),
                child: IconButton(
                  icon: Icon(Icons.chevron_left, size: 40),
                  tooltip: 'Back to Scanner ',
                  onPressed: () {
                    //Navigator.pop(context);
                    Navigator.pop(context,'back_to_scanner');
                  },
                ),
              ),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                      icon: Icon(Icons.save, size: 35),
                      tooltip: 'Save',
                      onPressed: () {
                        log('save button clicked');
                        print('is_weighable $_weighable');
                        print('is_perishable $_perishable');
                        print(_productName.text);
                        Navigator.pop(context,'back_to_scanner');
                      }),
                ),
              ],
            ),
            // Return loading screen while reading preferences
            body: Container(
              color: Colors.grey.shade200,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                              // title: Text(widget.product['barcode'],
                              //     style: TextStyle(fontWeight: FontWeight.w500,fontSize: 20)),
                              // subtitle: Text('My City, CA 99984'),
                              title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Chip(
                                backgroundColor: Colors.grey.shade300,
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(
                                    Icons.fullscreen,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                ),
                                label: Text(widget.product['barcode'],
                                    style: TextStyle(
                                        color: Colors.grey.shade900,
                                        fontSize: 20)),
                              ),
                            ],
                          )),
                          ListTile(
                            contentPadding:
                                EdgeInsets.only(left: 50, right: 50),
                            title: BarcodeWidget(
                              width: 200,
                              height: 80,
                              backgroundColor: Colors.white,
                              style: TextStyle(color: Colors.white),
                              barcode: Barcode.ean13(),
                              data: widget.product['barcode'].toString(),
                            ),
                          ),
                          Divider(thickness: 1),
                          ListTile(
                              title: Text('Product Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18)),
                              subtitle: Text(_productName.text,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18)),
                              leading: Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.shopping_cart,
                                  size: 30,
                                  color: Colors.redAccent,
                                ),
                              ),
                              trailing: Icon(
                                Icons.edit,
                                size: 30,
                                color: Colors.redAccent,
                              ),
                              onTap: () {
                                _displayDialog(context);
                              }),
                          Divider(
                            thickness: 1,
                          ),
                          SwitchListTile(
                            activeColor: Colors.deepOrange,
                            title: Text(
                              'Perishable',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 18),
                            ),
                            value: _perishable,
                            onChanged: (bool value) {
                              setState(() {
                                _perishable = value;
                              });
                            },
                            secondary: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.date_range,
                                size: 30,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            activeColor: Colors.deepOrange,
                            title: Text(
                              'Weighable',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 18),
                            ),
                            value: _weighable,
                            onChanged: (bool value) {
                              setState(() {
                                _weighable = value;
                              });
                            },
                            secondary: Padding(
                              padding: EdgeInsets.all(11),
                              child: Text(
                                'KG',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                          // Divider(
                          //   thickness: 1,
                          // ),
                        ],
                      ),
                    )
                  ]),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context,'back_to_scanner');
              },
              label: Text(
                'CANCEL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              icon: Icon(
                Icons.cancel,
              ),
              backgroundColor: Colors.red,
            )));
  }

  _displayDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
   final productNameField = TextFormField(
                  decoration: InputDecoration(
                    hintText: "Product Name..",
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  controller: _productName,
                );
    print(_productName.text.length);
    if (_productName.text.length < 1) {
      _productName.text = widget.product['productName'].toString();
    }
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Edit Product Name'),
            content: Container(
                width: 300,
                child: Form(child: productNameField,key: _formKey,)),
            actions: <Widget>[
              new IconButton(
                tooltip: 'Save',
                iconSize: 25,
                padding: EdgeInsets.all(8),
                color: Colors.redAccent,
                icon: Icon(
                  Icons.done,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _productName.text = this._productName.text;
                        
                   
                  });
                  Navigator.of(context).pop('dialog');
                },
              )
            ],
          );
        });
  }

  @override
  void dispose() {
    _productName.dispose();
    // add perishable and weighable here too
    super.dispose();
  }
}
