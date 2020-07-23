

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {


  String _model = ssd;
  File _image;

  bool busy = false;
  double _imageWidth;
  double _imageHeight;
  List _recongnitions;

  @override
  void initState() {
    super.initState();
      busy = true;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget>stackChildren = [];

    List<Widget> renderBoxes(Size screen){
      if(_recongnitions == null ) return [];
      if(_imageWidth == null || _imageHeight == null ) return [];

      double factorX = screen.width;
      double factorY  = _imageHeight/_imageWidth*screen.width;

      Color red = Colors.red;
      return _recongnitions.map((re){
        return Positioned(
          left: re["rect"]["x"]*factorX,
          top: re["rect"]["y"]*factorY,
          width: re["rect"]["w"]*factorX,
          height: re["rect"]["h"]*factorY,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: red,
                width: 3,

              )
            ),
            child: Text("${re["detectedClass"]} ${(re["detectedClass"]*100.toStringAsFixed(0))}"),
          )
        );
      }).toList();
    }
    
    stackChildren.addAll(renderBoxes(size));



    if(busy){
      stackChildren.add(
        Center(
          child:CircularProgressIndicator() ,
        )
      );
    }

    stackChildren.add(Positioned(
      top: 0.0,
        left: 0.0,
        width: size.width,
        child:_image == null ? Text("No imge") : Image.file(_image)
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text("Dectector"),
        centerTitle: true,
        elevation: 0.0,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        tooltip: "Pick image from gallery",
        onPressed: selectfromPhone(),
      ),
      body: Stack(
        children: stackChildren,
      )
    );
  }

  selectfromPhone() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    } else {
      setState(() {
        busy = true;
      });
    }
    predictImage(image);
  }

  predictImage(image) async {
    if (image  == null )return;
    if(_model == yolo){
      await yolov2Tiny(image);
    }else{
    ssdMobileNet(image);
    }

    FileImage(image).resolve(ImageConfiguration()).addListener((ImageStreamListener((ImageInfo info, bool _){

      setState(() {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.width.toDouble();

      });
      setState(() {
        _image = _image;
        busy = false;
      });

    })));
  }

  yolov2Tiny(File image) async {
    var recognition =await Tflite.detectObjectOnImage(
        path: image.path,
      model: "YOLO",
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1
    );
    setState(() {
      _recongnitions = recognition;
    });
  }

  void ssdMobileNet(File image) async {
    var recognition =await Tflite.detectObjectOnImage(
        path: image.path,
        numResultsPerClass: 1
    );
    setState(() {
      _recongnitions = recognition;
    });
  }
}
