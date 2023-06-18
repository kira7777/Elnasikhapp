import 'dart:io';
import 'package:ALNASIKH/Pdf%20Scan.dart';
import 'package:ALNASIKH/sql.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:document_scanner_flutter/configs/configs.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:ALNASIKH/Setting.dart';
import 'Document_View.dart';
import 'splash.dart';
import 'OCR_Result.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';

Future<File?> pickPdfFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null) {
    print("upload");
    return File(result.files.single.path!);
  } else {
    // User canceled the picker
    return null;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: splashScreen(),
      // home: home(),
      //home: ip(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  final ip;
  final done;
  final pdf_path;

  MyHomePage(this.ip, this.done, this.pdf_path);

  State<MyHomePage> createState() => _MyHomePageState(ip, done, pdf_path);
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FabCircularMenuState> fabKey = GlobalKey();
  final IP;
  final Done;
  final pdf_path;
  bool IsEdit = false;
  int id = 0;
  List temp = [];
  bool IsSearch = false;
  bool isLoading = true;
  bool IsExist = false;
  bool IsEmpty = false;
  bool OnChange = false;
  TextEditingController editingController = TextEditingController();
  TextEditingController edit_name = TextEditingController();

  _MyHomePageState(this.IP, this.Done, this.pdf_path);

  DateTime timeBackPressed = DateTime.now();
  List data = [];
  Sql DB = Sql();
  List unmerged=[];

  readData() async {
    List<Map> response = await DB.read("alnasikh");
    data.addAll(response);
    List<Map> res = await DB.read("unmerged");
    unmerged.addAll(res);
    if (this.mounted) {
      setState(() {
        isLoading = false;
      });
      if(data.isEmpty &&!isLoading ){
        unmerged.forEach((element) async{
          print(element);
          int response = await DB.delete("unmerged",
              "id =${element["id"]} "); print(response); });
      }
    }
    print(data);
    print(unmerged);
  }

  bool isCamera = false;
  double r = 0;
  File? _scannedImage;

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
                    merge: false,
                    data: "",
                  )));
      //_scannedImage = image;
      setState(() {
        _scannedImage = image;
      });
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      temp = data
          .where((item) =>
              item["filename"].toLowerCase().contains(query.toLowerCase()))
          .toList();
      print(temp);
    });
  }

  Future<File> ChangeFilename(File _imageFile) async {
    File ff = _imageFile;
    final bytes = await ff.readAsBytes();
    final directory = Directory((Platform.isAndroid
                ? await getExternalStorageDirectory() //FOR ANDROID
                : await getApplicationSupportDirectory() //FOR IOS
            )!
            .path +
        '/recent/image');
    if ((await directory.exists())) {
      print("is exist");
    } else {
      directory.create(recursive: true);
      print("is create");
    }

    final imagePath = '${directory.path}/${edit_name.text}.pdf';
    final file = File(imagePath);
    await file.writeAsBytes(bytes);
    print(file.path);
    return file;
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
                    merge: false,
                    data: "",
                  )));
      //_scannedImage = image;
      setState(() {
        _scannedImage = image;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    readData();
    temp = data;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print(timeBackPressed);
        final difference = DateTime.now().difference(timeBackPressed);
        print(difference.inMilliseconds);
        final IsExistWarning = difference >= Duration(milliseconds: 900);
        print(IsExistWarning);
        timeBackPressed = DateTime.now();
        if (IsExistWarning) {
          final message = 'Press back again to exit';
          Fluttertoast.showToast(
              msg: message,
              fontSize: 16,
              backgroundColor: Color.fromRGBO(80, 80, 80, 1.0));
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          actions: [
            !IsSearch
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        IsSearch = true;
                      });
                    },
                    icon: Icon(
                      Icons.search,
                      size: 30,
                      color: Colors.white,
                    ))
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: SizedBox(
                      width: 250,
                      child: TextField(
                        style: TextStyle(color: Colors.black, fontSize: 17),
                        onChanged: (value) {
                          filterSearchResults(value);
                        },
                        controller: editingController,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(14.0),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: "Search",
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  IsSearch = false;
                                  temp = data;
                                  editingController.text = "";
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)))),
                      ),
                    ),
                  ),
          ],
        ),
        body: InkWell(
          onTap: () {
            if (fabKey.currentState!.isOpen) fabKey.currentState!.close();
          },
          child: Container(
            color: Colors.blue,
            child: ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 55,
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          "Home Page",
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                    color: Colors.black,
                  ),
                  width: double.infinity,
                  //height: 610,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 15, 0, 10),
                    child: Text(
                      "Recents",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (temp.length == 0 && !isLoading)
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    height: MediaQuery.of(context).size.height * (516 / 736),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                        ),
                        Icon(
                          Icons.document_scanner,
                          color: Colors.white,
                          size: 40,
                        ),
                        Text(" No Recent\n Documents",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                else if (isLoading)
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    height: MediaQuery.of(context).size.height * (516 / 736),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                        ),
                        Text("Loading...",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    //width: MediaQuery.of(context).size.height,
                    alignment: (temp.length) < 3 ? Alignment.topLeft : null,
                    height: (temp.length) < 3
                        ? MediaQuery.of(context).size.height * (520 / 736)
                        : null,
                    child: ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: temp.length,
                      itemBuilder: (context, i) => Container(
                        margin: const EdgeInsets.all(2.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: (i != 0)
                                  ? const EdgeInsets.fromLTRB(0, 0, 0, 10)
                                  : const EdgeInsets.fromLTRB(0, 0, 0, 50),
                              child: Card(
                                color: Colors.black,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                shadowColor: Colors.blueAccent,
                                elevation: 10,
                                child: Row(
                                  children: [
                                    //Container Image
                                    Container(
                                        margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          child: Image.file(
                                            File("${temp[i]["ImagePath"]}"),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                (103 / 360),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                (134 / 736),
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(5, 0, 0, 0),
                                        color: Colors.black,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                (144 / 736),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    if (!IsEdit ||
                                                        id != temp[i]["id"])
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                0, 15, 0, 0),
                                                        child: Text(
                                                          "${temp[i]["filename"]}",
                                                          style: TextStyle(
                                                              fontSize: 17,
                                                              color: Color.fromRGBO(
                                                                  245,
                                                                  245,
                                                                  245,
                                                                  0.8666666666666667),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    else if (IsEdit &&
                                                        id == temp[i]["id"])
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                0, 5, 0, 0),
                                                        child: Column(
                                                          children: [
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  (175 / 360),
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  (41 / 736),
                                                              child: Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .fromLTRB(
                                                                            10,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .blue,
                                                                      width: 2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              15),
                                                                ),
                                                                child:
                                                                    TextField(
                                                                  onChanged:
                                                                      OnChange
                                                                          ? (value) {
                                                                              setState(() {
                                                                                edit_name.text = value;
                                                                                edit_name.selection = TextSelection.fromPosition(TextPosition(offset: edit_name.text.length));
                                                                              });
                                                                            }
                                                                          : null,
                                                                  maxLength: 22,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          14),
                                                                  controller:
                                                                      edit_name,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .name,
                                                                  decoration: InputDecoration(
                                                                      counterText:
                                                                          '',
                                                                      hintText:
                                                                          "Enter Name",
                                                                      hintStyle: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight:
                                                                              FontWeight.bold)

                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (IsExist)
                                                              Text(
                                                                "the name is exist",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontSize:
                                                                        11),
                                                              )
                                                            else if (IsEmpty)
                                                              Text(
                                                                "Please Enter the name",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontSize:
                                                                        11),
                                                              )
                                                          ],
                                                        ),
                                                      ),
                                                    SizedBox(
                                                      height: 9,
                                                    ),
                                                    Text(
                                                        "${temp[i]["DATE"]}                                  ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.grey)),
                                                    Container(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          25, 0, 0, 0),
                                                      child: Row(
                                                        children: [
                                                          ElevatedButton(
                                                              style: ButtonStyle(
                                                                  backgroundColor:
                                                                      MaterialStatePropertyAll(
                                                                          Colors
                                                                              .black)),
                                                              onPressed: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) =>
                                                                            document_view(
                                                                              MetaData: temp[i],
                                                                              IP: IP,
                                                                            ))).then(
                                                                    (value) =>
                                                                        setState(
                                                                            () {}));
                                                                ;
                                                              },
                                                              child: Text(
                                                                "View",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    color: Color
                                                                        .fromRGBO(
                                                                            12,
                                                                            100,
                                                                            180,
                                                                            1.0),
                                                                    wordSpacing:
                                                                        2),
                                                              )),
                                                          ElevatedButton(
                                                              style: ButtonStyle(
                                                                  backgroundColor:
                                                                      MaterialStatePropertyAll(
                                                                          Colors
                                                                              .black)),
                                                              onPressed: () {
                                                                OpenFile.open(
                                                                    "${temp[i]["PdfPath"]}");
                                                              },
                                                              child: Text(
                                                                "Open pdf",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    color: Color
                                                                        .fromRGBO(
                                                                            12,
                                                                            100,
                                                                            180,
                                                                            1.0),
                                                                    wordSpacing:
                                                                        2),
                                                              )),
                                                        ],
                                                      ),
                                                    )
                                                    /*IconButton(onPressed: (){}, icon: Icon(Icons.picture_as_pdf,color: Color.fromRGBO(
                                                  203, 26, 12, 1.0),))*/
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (!IsEdit ||
                                                      id != temp[i]["id"])
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          IsExist = false;
                                                          IsEmpty = false;
                                                          IsEdit = true;
                                                          OnChange = false;
                                                          id = temp[i]["id"];
                                                          edit_name.text = temp[i]["filename"];
                                                        });
                                                      },
                                                      child: Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        shape: CircleBorder(),
                                                        backgroundColor: Colors.black,
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: Size.zero,
                                                      ),
                                                    )
                                                  else if (IsEdit && id == temp[i]["id"])
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        setState(() {
                                                          OnChange = true;
                                                        });
                                                        if (edit_name.text.isEmpty && OnChange) {
                                                          setState(() {
                                                            IsEmpty = true;
                                                            IsExist = false;
                                                            OnChange = false;
                                                          });
                                                        }
                                                        if (edit_name.text.isNotEmpty && OnChange) {
                                                          File pdf_path =
                                                              await ChangeFilename(File(temp[i]["PdfPath"]));
                                                          int response =
                                                              await DB.update("alnasikh",
                                                                  {
                                                                    "filename": edit_name.text.trim(),
                                                                    "PdfPath": pdf_path.path,
                                                                    "ImagePath": temp[i]["ImagePath"],
                                                                    "DATE": temp[i]["DATE"]
                                                                  },
                                                                  "id =${temp[i]["id"]} ");
                                                          if (response > 0) {
                                                            print(response);
                                                            setState(() {
                                                              IsEdit = false;
                                                              IsExist = false;
                                                              IsEmpty = false;
                                                              OnChange = false;
                                                            });
                                                            Navigator.pushReplacement(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (_) {
                                                              return MyHomePage(
                                                                  IP,
                                                                  widget.done,
                                                                  "");
                                                            }));
                                                          } else {
                                                            setState(() {
                                                              IsEmpty = false;
                                                              IsExist = true;
                                                              OnChange = false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      child: Icon(
                                                        Icons.done,
                                                        color: Colors.blue,
                                                        size: 30,
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        shape: CircleBorder(),
                                                        backgroundColor: Colors.black,
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: Size.zero,
                                                      ),
                                                    ),
                                                  ElevatedButton(
                                                    onPressed: () => showDialog(
                                                        context: context,
                                                        builder:
                                                            (BuildContext ctx) =>
                                                                AlertDialog(
                                                                  elevation: 2,
                                                                  shadowColor: Colors.blue,
                                                                  clipBehavior: Clip.hardEdge,
                                                                  backgroundColor: Colors.black,
                                                                  title: const Text('Delete'),
                                                                  titleTextStyle: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 18),
                                                                  content: const Text('Do you want to delete this item'),
                                                                  contentTextStyle: TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(context, 'Cancel'),
                                                                      child: const Text('No',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.blue),
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        unmerged=unmerged.where((element) => element["MergeID"]==temp[i]["id"]).toList();
                                                                        unmerged.forEach((element) async{
                                                                          print(element);
                                                                          int response = await DB.delete("unmerged",
                                                                            "id =${element["id"]} "); print(response); });
                                                                        int response = await DB.delete("alnasikh",
                                                                            "id =${temp[i]["id"]} ");
                                                                        if (response > 0) {
                                                                          temp.removeWhere((element) =>
                                                                              element["id"] == data[i]["id"]);
                                                                          setState(() {});

                                                                          Navigator.pop(context, 'Yes');
                                                                        }
                                                                      },
                                                                      child:
                                                                          const Text('Yes',
                                                                        style: TextStyle(
                                                                            color: Colors.blue),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Colors.blue,
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      shape: CircleBorder(),
                                                      backgroundColor: Colors.black,
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: Size.zero,
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await Share.shareFiles(
                                                          [data[i]["PdfPath"]],
                                                          text: 'Great Pdf');
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      shape: CircleBorder(),
                                                      backgroundColor: Colors.black,
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: Size.zero,
                                                    ),
                                                    child: Icon(
                                                      Icons.share,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
        floatingActionButton: FabCircularMenu(
            fabOpenIcon: Icon(Icons.add),
            animationCurve: Curves.easeInOutCirc,
            alignment: Alignment.bottomRight,
            ringColor: Colors.blue.withAlpha(25),
            ringDiameter: 390.0,
            ringWidth: 90.0,
            fabSize: 55.0,
            fabElevation: 8.0,
            fabIconBorder: CircleBorder(),
            key: fabKey,
            children: <Widget>[
              RawMaterialButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ip(IP, Done)));
                },
                elevation: 10.0,
                fillColor: Colors.green,
                child: Icon(
                  Icons.settings,
                  size: 30.0,
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(12.0),
                shape: CircleBorder(),
              ),
              RawMaterialButton(
                onPressed: () async {
                  final path = await pickPdfFile();

                  if (path != null) {
                    final doc = await PdfDocument.openFile(path.path);
                    var i = doc.pageCount;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                pdf_scan(doc, i, IP, false, "")));
                    print(path);
                  }
                },
                elevation: 10.0,
                fillColor: Colors.orange,
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 30.0,
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(12.0),
                shape: CircleBorder(),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Color.fromRGBO(74, 40, 168, 1.0),
                child: IconButton(
                    icon: Icon(
                      Icons.photo_library_sharp,
                      size: 30,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      openGalleryScanner(context, IP);
                    }),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.deepOrange,
                child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      openCameraScanner(context, IP);
                    }),
              ),
            ]),
      ),
    );
  }
}
