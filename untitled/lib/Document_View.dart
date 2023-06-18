import 'dart:io';

import 'package:document_scanner_flutter/configs/configs.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_merger/pdf_merger.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'OCR_Result.dart';
import 'Pdf Scan.dart';
import 'sql.dart';

class document_view extends StatefulWidget {
  final MetaData;
  final IP;

  const document_view({Key? key, this.MetaData, this.IP}) : super(key: key);

  @override
  State<document_view> createState() => _document_viewState();
}

class _document_viewState extends State<document_view> {
  List data = [];
  Sql DB = Sql();
  bool IsLoading = true;

  readData() async {
    List<Map> response = await DB.read("unmerged");
    data.addAll(response);
    data = data.where((element) => element["MergeID"] == widget.MetaData["id"]).toList();
    if (this.mounted) {
      setState(() {
        IsLoading = false;
      });
    }
    print(data.length);
  }

  Future<File?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return File(result.files.single.path!);
    } else {
      // User canceled the picker
      return null;
    }
  }

  openCameraScanner(BuildContext context, String IP) async {
    var image = await DocumentScannerFlutter.launch(IP, context,
        source: ScannerFileSource.CAMERA,
        labelsConfig: {
          ScannerLabelsConfig.ANDROID_NEXT_BUTTON_LABEL: "Next Step",
          ScannerLabelsConfig.ANDROID_OK_LABEL: "OK"
        });
    if (image != null) {
      print("jjjjjjjjjjjjjjjjjjj");
      print(image);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => imageView(
                    imagePath: image,
                    ip: IP,
                    data: widget.MetaData,
                    merge: true,
                  )));
      //_scannedImage = image;
    }
  }

  openGalleryScanner(BuildContext context, String IP) async {
    var image = await DocumentScannerFlutter.launch(IP, context,
        source: ScannerFileSource.GALLERY,
        labelsConfig: {
          ScannerLabelsConfig.ANDROID_NEXT_BUTTON_LABEL: "Next Step",
          ScannerLabelsConfig.ANDROID_OK_LABEL: "OK"
        });
    if (image != null) {
      print("jjjjjjjjjjjjjjjjjjj");
      print(image);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => imageView(
                    imagePath: image,
                    ip: IP,
                    data: widget.MetaData,
                    merge: true,
                  )));
      //_scannedImage = image;
    }
  }

  String getTime() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    //DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    //String datetime = tsdate.year.toString() + "-" + tsdate.month.toString() + "-" + tsdate.day.toString()+ "-" +tsdate.hour.toString()+ "-" +tsdate.minute.toString()+ "-" +tsdate.second.toString();
    String datetime = "Alnasikh_" + timestamp.toString();
    print(datetime); //output: 2021/12/4/H/M/S
    return datetime;
  }

  @override
  void initState() {
    readData();
  }

  @override
  Widget build(BuildContext c) {
    return MaterialApp(
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
        ),
      )),
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
                          child: Text("${widget.MetaData["filename"]}",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                  if (widget.MetaData["Merge"] == 0 || data.length == 1)
                    Container(
                      margin: EdgeInsets.all(8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.black,
                          ),
                          borderRadius:
                              BorderRadius.circular(25.0), //<-- SEE HERE
                        ),
                        color: Colors.black,
                        clipBehavior: Clip.hardEdge,
                        shadowColor: Color.fromRGBO(218, 148, 11, 1.0),
                        //shadowColor: Colors.blueAccent,
                        elevation: 15,
                        child: Column(children: [
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
                                    File(widget.MetaData["ImagePath"]),
                                    width: 400,
                                  ),
                                ),
                              )),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SelectableText(
                                    widget.MetaData["Sentence"],
                                    style: TextStyle(
                                        fontSize: 17,
                                        color: Color.fromRGBO(211, 207, 207, 1),
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll(
                                                  Colors.black)),
                                      onPressed: () async {
                                        await Clipboard.setData(ClipboardData(
                                            text: widget.MetaData["Sentence"]));
                                        Fluttertoast.showToast(
                                            msg: "Text Copied",
                                            fontSize: 14,
                                            backgroundColor: Color.fromRGBO(
                                                80, 80, 80, 1.0));
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    )
                  else if (IsLoading)
                    Container(
                      alignment: Alignment.center,
                      color: Colors.black,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 300,
                          ),
                          Text("Loading...",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 200,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                        reverse: false,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: data.length,
                        itemBuilder: (context, i) => Container(
                              margin: EdgeInsets.all(8),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.black,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      25.0), //<-- SEE HERE
                                ),
                                color: Colors.black,
                                clipBehavior: Clip.hardEdge,
                                shadowColor: Color.fromRGBO(218, 148, 11, 1.0),
                                elevation: 15,
                                child: Column(children: [
                                  Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 10, 0, 0),
                                      child: InteractiveViewer(
                                        panEnabled: false,
                                        // Set it to false
                                        minScale: 1,
                                        maxScale: 4,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              topRight: Radius.circular(15)),
                                          child: Image.file(
                                            File(data[i]["ImagePath"]),
                                            width: 400,
                                          ),
                                        ),
                                      )),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SelectableText(
                                            data[i]["Sentence"],
                                            style: TextStyle(
                                                fontSize: 17,
                                                color: Color.fromRGBO(
                                                    211, 207, 207, 1),
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.right,
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStatePropertyAll(
                                                          Colors.black)),
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                    ClipboardData(
                                                        text: data[i]
                                                            ["Sentence"]));
                                                Fluttertoast.showToast(
                                                    msg: "Text Copied",
                                                    fontSize: 14,
                                                    backgroundColor:
                                                        Color.fromRGBO(
                                                            80, 80, 80, 1.0));
                                              },
                                              child: Icon(
                                                Icons.copy,
                                                size: 25,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            if (i > 0)
                                              ElevatedButton(
                                                onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (BuildContextctx) => AlertDialog(
                                                          elevation: 2,
                                                          shadowColor: Colors.blue,
                                                          clipBehavior: Clip.hardEdge,
                                                          backgroundColor: Colors.black,
                                                          title: const Text('Delete'),
                                                          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                                                          content: const Text('Do you want to delete this item'),
                                                          contentTextStyle: TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold),
                                                          actions: [
                                                            TextButton(onPressed: () =>
                                                                  Navigator.of(c).pop(),
                                                              child: const Text('No',
                                                                style: TextStyle(color: Colors.blue),
                                                              ),
                                                            ),
                                                            TextButton(onPressed: () async {
                                                                int response = await DB.delete("unmerged", "id =${data[i]["id"]} ");
                                                                if (response > 0) {
                                                                  data.removeWhere((element) => element["id"] == data[i]["id"]);
                                                                  setState(() {});
                                                                  var tempDir = Directory((Platform.isAndroid
                                                                              ? await getExternalStorageDirectory() //FOR ANDROID
                                                                              : await getApplicationSupportDirectory() //FOR IOS
                                                                          )!
                                                                          .path +
                                                                      '/recent/PDF');
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
                                                                  var filename = getTime();
                                                                  var outputDirPath = widget.MetaData["PdfPath"];
                                                                  List<String> filesPath = data.map((e) => e["PdfPath"].toString()).toList();
                                                                  print(filesPath);
                                                                  MergeMultiplePDFResponse response = await PdfMerger.mergeMultiplePDF(paths: filesPath, outputDirPath: outputDirPath);
                                                                  Object pdf = response.response as Object;
                                                                  print(pdf);
                                                                  int res = await DB.update("alnasikh",
                                                                      {
                                                                        "PdfPath": pdf,
                                                                      },
                                                                      "id =${widget.MetaData["id"]} ");
                                                                  print(res);
                                                                  if (res > 0)
                                                                    Navigator.pop(c, 'Yes');
                                                                }
                                                              },
                                                              child: const Text('Yes',
                                                                style: TextStyle(
                                                                    color: Colors.blue),
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 30,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  shape: CircleBorder(),
                                                  backgroundColor: Colors.black,
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size.zero,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            )),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                elevation: 10,
                                backgroundColor: Colors.black.withOpacity(0),
                                actionsAlignment: MainAxisAlignment.center,
                                alignment: Alignment.center,
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () {
                                      openCameraScanner(context, widget.IP);
                                    },
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        backgroundColor: Colors.deepOrange,
                                        elevation: 10,
                                        padding: EdgeInsets.all(10.0),
                                        shadowColor: Colors.blue),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      openGalleryScanner(context, widget.IP);
                                    },
                                    child: Icon(
                                      Icons.photo_library_sharp,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        backgroundColor:
                                            Color.fromRGBO(91, 61, 196, 1.0),
                                        elevation: 10,
                                        padding: EdgeInsets.all(11.0),
                                        shadowColor: Colors.blue),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final path = await pickPdfFile();

                                      if (path != null) {
                                        final doc = await PdfDocument.openFile(path.path);
                                        var i = doc.pageCount;
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => pdf_scan(doc, i, widget.IP,true,widget.MetaData)));
                                        print(path);
                                      }
                                    },
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      size: 30.0,
                                      color: Colors.white,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                        backgroundColor:
                                        Colors.orange,
                                        elevation: 10,
                                        padding: EdgeInsets.all(11.0),
                                        shadowColor: Colors.blue),
                                  ),
                                ],
                              );
                            });
                      },
                      child: Icon(
                        Icons.add,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
