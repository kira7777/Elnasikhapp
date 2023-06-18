import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart'as p;
import 'package:ALNASIKH/OCR_Result.dart';
class blacks extends StatefulWidget {
  final image;
  final ip;
  final merge;
  final data;
  blacks(this.image,this.ip,this.merge,this.data);
  @override
  State<blacks> createState() => _blacks(image,ip);
}

class _blacks extends State<blacks> {
  ColorFilter greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);
  late File white;
  var _imageFile;
  final IP;
  bool black=false;
  _blacks(this._imageFile,this.IP);
  late File file;
  late String basename;
  @override
  void initState() {
    file = new File(_imageFile.toString());
    basename = p.basename(file.path);
    basename=basename.replaceAll('image_cropper_', "");
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          actions:[
            TextButton.icon(onPressed: () async{
              try{
                var w=await saveImage(_imageFile);
                setState(() {
                  if(!black)
                    white=_imageFile;
                  _imageFile=w;
                  print(_imageFile);
                  print(white);
                  black=true;
                });
              }
              catch(e){
                Fluttertoast.showToast(msg: "Try Again",fontSize: 14,backgroundColor: Color.fromRGBO(
                    80, 80, 80, 1.0));
              }
                  }, icon: Icon(Icons.water_drop_outlined),label: Text("Black & white")),
            TextButton.icon(onPressed: () { setState(() {
              black=false;
              _imageFile=white;
            }); }, icon: Icon(Icons.image),label: Text("Original")),
          ]
      ),
      body:Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imageFile != null) ...[
              Image.file(
                _imageFile,
                width: 400,
                height: 600,
              ),
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStatePropertyAll(Colors.blue),
                      minimumSize: MaterialStatePropertyAll(Size.fromHeight(40))),
                  onPressed: () {
                    Navigator.push(context,MaterialPageRoute(builder: (context) => imageView(imagePath:_imageFile,ip:IP,merge: widget.merge,data: widget.data,)));
                  },
                  child: Text("Done",
                      style: TextStyle(color: Colors.white))),
            ] else ...[
              Text('No image selected.'),
            ]
          ],
        ),
      ),
    );
  }

  Future<File> saveImage(File _imageFile) async{
    File ff=_imageFile;
    final bytes=await ff.readAsBytes();
    final img=ui.decodeImage(bytes);
    final gray=ui.grayscale(img!);
    final directory = Directory((Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationSupportDirectory() //FOR IOS
    )!
        .path + '/recent/image');
    final imagePath = '${directory.path}/$basename';
    if ((await directory.exists())) {
      print("is exist");
    } else {
      directory.create(recursive: true);
      print("is create");
    }

    final file = File(imagePath);
    final uti=ui.encodeJpg(gray);
    await file.writeAsBytes(uti);
    print(file.path);
    return file;

  }

}
