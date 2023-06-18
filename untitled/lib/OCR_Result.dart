import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:image/image.dart' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'main.dart';
import 'sql.dart';
import 'package:pdf_merger/pdf_merger.dart';
class imageView extends StatefulWidget {
  imageView({super.key, required this.imagePath, required this.ip,this.merge,this.data});

  final imagePath;
  final ip;
  final merge;
  final data;
  @override
  State<imageView> createState() => _imageViewState(imagePath, ip);
}

class _imageViewState extends State<imageView> {
  Sql DB=Sql();
  var filename;
  _imageViewState(this.imageFile, this.IP);
  bool done=false;
String pdf_path="";
  var IP;
  double font=16;
  var chr = "";
  int n = 0;
  final imageFile;
  final GlobalKey<TooltipState> tooltipkey = GlobalKey<TooltipState>();
  bool NotCopy = true;
  ocr() async {
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    // get file length
    var length = await imageFile.length();

    // string to uri
    var uri = Uri.parse("$IP/to_detection");

    // create multipart request
    var request = new http.MultipartRequest("POST", uri);

    // multipart that takes file
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));

    // add file to multipart
    request.headers.addAll({"ngrok-skip-browser-warning": "0"});
    request.files.add(multipartFile);
    // send
    var response = await request.send();
    print(response.statusCode);

    // listen for response
    response.stream.transform(utf8.decoder).listen((value) async {
      var str = "";
      for (int i = 0; i < int.parse(value); i++) {
        final res =
            await http.get(Uri.parse("$IP/to_ocr?number=$i"),headers:{"ngrok-skip-browser-warning": "0"});
        if (res.statusCode == 200) {
          str = str + res.body;
          setState(() {
            chr = str;
          });
        }
      }
      var tempDir=Directory((Platform.isAndroid
          ? await getExternalStorageDirectory() //FOR ANDROID
          : await getApplicationSupportDirectory() //FOR IOS
      )!
          .path + '/recent/PDF');
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      if ((await tempDir.exists())) {
        print("is exist");
      } else {
        tempDir.create(recursive: true);
        print("is create");
      }

      await download(Dio(), "$IP/return_PDF",
          tempDir.path + "/$filename.pdf");
      setState(() {
        NotCopy = false;
      });
      print(str);
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    ocr();
    filename=getTime();
  }
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(color: Colors.black),
            color: Colors.deepPurpleAccent,
            foregroundColor: Colors.black,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.black,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.dark,
            ),)
      ),
      home: Scaffold(
            backgroundColor: Colors.black,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: SafeArea(
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(10),
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Center(
                          child: Container(

                              padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text("OCR Results",style: TextStyle(fontSize: 24, color: Colors.white,fontWeight: FontWeight.bold))),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.black,
                            ),
                            borderRadius: BorderRadius.circular(25.0), //<-- SEE HERE
                          ),
                          color: Colors.black,
                          clipBehavior: Clip.hardEdge,
                          shadowColor: Color.fromRGBO(218, 148, 11, 1.0),
                          //shadowColor: Colors.blueAccent,
                          elevation: 15,
                          child: Column(
                              children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: InteractiveViewer(
                                panEnabled: false, // Set it to false
                                minScale: 1,
                                maxScale: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15)),
                                  child: Image.file(
                                    imageFile,
                                    width: 400,
                                  ),
                                ),
                              )
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: chr==""?null:Colors.black,
                              ),
                              child: chr==""?Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator()
                              ):Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: NotCopy?Text(chr,
                                      style: TextStyle(fontSize: font, color: Color.fromRGBO(211, 207, 207, 1),fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,textDirection: TextDirection.rtl,):SelectableText(chr,
                                        style: TextStyle(fontSize: font, color: Color.fromRGBO(211, 207, 207, 1),fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,textDirection: TextDirection.rtl,),
                                  ),
                                  if (!NotCopy)  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [

                                      ElevatedButton(
                                        style: ButtonStyle(
                                            backgroundColor:
                                            MaterialStatePropertyAll(Colors.black)),
                                        onPressed: () async{
                                          await Clipboard.setData(ClipboardData(text: chr));
                                          Fluttertoast.showToast(msg: "Text Copied",fontSize: 14,backgroundColor: Color.fromRGBO(
                                              80, 80, 80, 1.0));

                                        },
                                        child: Icon(Icons.copy,size: 25,color: Colors.white,),
                                      ),
                                      SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ButtonStyle(
                                            backgroundColor:
                                            MaterialStatePropertyAll(Colors.black)),
                                        onPressed: NotCopy?(){}:() async {
                                          OpenFile.open(pdf_path);
                                        },
                                        child: Image.asset("assets/landing-pdf-converter.png",width: 30,height: 30,),),
                                    ],
                                  ) ,
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: NotCopy?(){Fluttertoast.showToast(msg: "This button is disabled until the OCR finishs",fontSize: 14,backgroundColor: Color.fromRGBO(
    80, 80, 80, 1.0));}:() {
                              setState(() {
                                if (font > 10) {
                                  font -= 1;
                                }
                                else{
                                  Fluttertoast.showToast(msg: "This is the min font size",fontSize: 14,backgroundColor: Color.fromRGBO(
                                      80, 80, 80, 1.0));
                                }
                              });
                            },
                            child: Icon(Icons.remove, size:25,color: font>10&&!NotCopy?Colors.blue:Colors.grey),
                            style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                backgroundColor: Colors.black
                            ),
                          ),
                          ElevatedButton(
                            onPressed:NotCopy?(){Fluttertoast.showToast(msg: "This button is disabled until the OCR finishs",fontSize: 14,backgroundColor: Color.fromRGBO(
    80, 80, 80, 1.0));}: () {
                              setState(() {
                                if (font < 23) {
                                  font += 1;
                                }
                                else{
                                  Fluttertoast.showToast(msg: "This is the max font size",fontSize: 14,backgroundColor: Color.fromRGBO(
                                      80, 80, 80, 1.0));
                                }
                              });
                            },
                            child: Icon(Icons.add,size: 25, color: font<23&&!NotCopy?Colors.blue:Colors.grey),
                            style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                backgroundColor: Colors.black
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: NotCopy
                  ?Colors.grey:Colors.green,
                onPressed: NotCopy?(){Fluttertoast.showToast(msg: "This button is disabled until the OCR finishs",fontSize: 14,backgroundColor: Color.fromRGBO(
                    80, 80, 80, 1.0));}:() async{
                try{
                  int timestamp = DateTime.now().millisecondsSinceEpoch;
                  DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  String datetime = tsdate.year.toString() + "-" + tsdate.month.toString() + "-" + tsdate.day.toString();
                  File save_image=await saveImage(imageFile);
                  if(widget.merge){
                    if(widget.data["Merge"]==0){
                      DB.insert("unmerged", {
                        "filename":widget.data["filename"],
                        "PdfPath":widget.data["PdfPath"],
                        "ImagePath":widget.data["ImagePath"],
                        "DATE":widget.data["DATE"],
                        "Sentence":widget.data["Sentence"],
                        "MergeID":widget.data["id"]

                      });
                    }
                    DB.insert("unmerged", {
                      "filename":filename,
                      "PdfPath":pdf_path,
                      "ImagePath":save_image.path,
                      "DATE":datetime,
                      "Sentence":chr,
                      "MergeID":widget.data["id"]

                    });
                    var tempDir=Directory((Platform.isAndroid
                        ? await getExternalStorageDirectory() //FOR ANDROID
                        : await getApplicationSupportDirectory() //FOR IOS
                    )!
                        .path + '/recent/PDF');
                    var status = await Permission.storage.status;
                    if (!status.isGranted) {
                      await Permission.storage.request();
                    }
                    if ((await tempDir.exists())) {
                      print("is exist");
                    } else {
                      tempDir.create(recursive: true);
                      print("is create");
                    }
                    var outputDirPath=tempDir.path + "/merge_$filename.pdf";
                    List<String> filesPath=[];
                    filesPath.add(widget.data["PdfPath"]);
                    filesPath.add(pdf_path);
                    MergeMultiplePDFResponse response  = await PdfMerger.mergeMultiplePDF(paths: filesPath, outputDirPath: outputDirPath);
                    Object pdf=response.response as Object;
                    DB.update("alnasikh",{
                      "PdfPath":pdf,
                      "Merge":1
                    },
                        "id =${widget.data["id"]} "
                    );

                  }
                  else{ DB.insert("alnasikh",{
                    "filename":filename,
                    "PdfPath":pdf_path,
                    "ImagePath":save_image.path,
                    "DATE":datetime,
                    "Sentence":chr,
                    "Merge":0
                  }
                  );}
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_){
                    return MyHomePage(IP,done,pdf_path);
                  }),
                        (route) => false,);
                }
                catch (e){
                  Fluttertoast.showToast(msg: "Try Again",fontSize: 14,backgroundColor: Color.fromRGBO(
                      80, 80, 80, 1.0));
                }

                },
                child: Icon(Icons.done_outline,
                color: Colors.black,))

          ),
    );
  }

  double progress = 0;

  // Track if the PDF was downloaded here.
  bool didDownloadPDF = false;

  // Show the progress status to the user.
  String progressString = 'File has not been downloaded yet.';

  void updateProgress(done, total) {
    progress = done / total;
    setState(() {
      if (progress >= 1) {
        progressString =
            '✅ File has finished downloading. Try opening the file.';
        didDownloadPDF = true;
      } else {
        progressString = 'Download progress: ' +
            (progress * 100).toStringAsFixed(0) +
            '% done.';
      }
    });
  }

  Future download(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        onReceiveProgress: updateProgress,
        options: Options(
          headers: {"ngrok-skip-browser-warning": "0"},
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      var file = File(savePath).openSync(mode: FileMode.write);
      print(savePath);
      file.writeFromSync(response.data);
      //OpenFile.open(savePath);
      setState(() {
        done=true;
        pdf_path=savePath;
      });
      // Here, you're catching an error and printing it. For production
      // apps, you should display the warning to the user and give them a
      // way to restart the download.
    } catch (e) {
      print(e);
    }
  }
  String getTime(){
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    //DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    //String datetime = tsdate.year.toString() + "-" + tsdate.month.toString() + "-" + tsdate.day.toString()+ "-" +tsdate.hour.toString()+ "-" +tsdate.minute.toString()+ "-" +tsdate.second.toString();
    String datetime ="Alnasikh_"+timestamp.toString();
    print(datetime); //output: 2021/12/4/H/M/S
    return datetime;
  }
  Future<File> saveImage(File _imageFile) async{
    File ff=_imageFile;
    final bytes=await ff.readAsBytes();
    final img=ui.decodeImage(bytes);
    final directory = Directory((Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationSupportDirectory() //FOR IOS
    )!
        .path + '/recent/image');
    if ((await directory.exists())) {
      print("is exist");
    } else {
      directory.create(recursive: true);
      print("is create");
    }

    final imagePath = '${directory.path}/$filename.jpg';
    final file = File(imagePath);
    final uti=ui.encodeJpg(img!);
    await file.writeAsBytes(uti);
    print(file.path);
    return file;

  }

renamePDFFile(File oldPath) async {
  final directory = Directory((Platform.isAndroid
      ? await getExternalStorageDirectory() //FOR ANDROID
      : await getApplicationSupportDirectory() //FOR IOS
  )!
      .path + '/recent/image');
    File old=oldPath;
    String newName=directory.path+'/$filename.jpg';
    old.rename(newName);
    print('File renamed to $newName and moved to ${directory.path}');
    return old;
  }
}
