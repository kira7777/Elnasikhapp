import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui' as ui;
import 'package:carousel_slider/carousel_slider.dart';

import 'crop.dart';

class pdf_scan extends StatefulWidget {
  pdf_scan(this.doc, this.count, this.IP,this.merge,this.data);
final merge;
  final doc;
  final count;
  final IP;
final data;
  @override
  State<pdf_scan> createState() => _pdf_scanState();
}

class _pdf_scanState extends State<pdf_scan> {
  List<File> imagefile = [];
  var n = 0;
  var activePage;
  final _textController = TextEditingController();
  late PageController _pageController;
  bool complete = false;
  bool please = false;

  creat_image() async {
    for (int i = 1; i <= widget.count; i++) {
      PdfPage page = await widget.doc.getPage(i);
      PdfPageImage pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );
      //final image=img.Image.fromBytes(width: page.width.toInt(), height: page.height.toInt(), bytes: pageImage.imageIfAvailable)
      //final imageWidget = pageImage.pixels;
      await pageImage.createImageIfNotAvailable();
      var image = pageImage.imageIfAvailable;
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/$i.jpg';

        ByteData? imageBytes =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (imageBytes != null) {
          final compressedImageBytes =
              await FlutterImageCompress.compressWithList(
            imageBytes.buffer.asUint8List(),
            minHeight: 800,
            minWidth: 800,
          );

          final file = File(imagePath);
          await file.writeAsBytes(compressedImageBytes);
          print("MMMMMMMMMMMMMMMMMMMMMMMMMM");
          print(file.path);
          imagefile.add(file);
        }
      }
    }
    setState(() {
      complete = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    if (n == 0) {
      creat_image();
      _textController.text = "1";
      n++;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Pdf View'),
        ),
        body: Container(
          color: Colors.black,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: SingleChildScrollView(
                child: Center(
              child: Column(
                children: [
                  complete
                      ? CarouselSlider.builder(
                          itemCount: widget.count,
                          itemBuilder: (BuildContext context, int itemIndex,
                              int pageViewIndex) {
                            return Container(
                                child: Column(
                              children: [
                                Text("${itemIndex + 1} /${widget.count}",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22)),
                                InteractiveViewer(
                                    panEnabled: false,
                                    minScale: 1,
                                    maxScale: 4,
                                    child: Image.file(
                                      imagefile[itemIndex],
                                      width: 400,
                                      height: 400,
                                    )),
                              ],
                            ));
                          },
                          options: CarouselOptions(
                            height: 500,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.8,
                            initialPage: 0,
                            enableInfiniteScroll: widget.count<4?false:true,
                            reverse: false,
                            autoPlay: false,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              _textController.text = (index + 1).toString();
                              setState(() {
                                please = false;
                              });
                            },
                            enlargeFactor: 0.3,
                            scrollDirection: Axis.horizontal,
                          ),
                        )
                      : CircularProgressIndicator(),
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: SizedBox(
                      // <-- SEE HERE
                      width: 120,
                      child: TextField(
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                        controller: _textController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: "Enter the num page",
                            hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)
                            //prefixStyle:TextStyle(color: Colors.white)

                            ),
                      ),
                    ),
                  ),
                  if (please)
                    Text("Please enter the num page",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.bold))
                ],
              ),
            )),
          ),
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              print("KKKKKKKKKKKKK");
              print(_textController.text);
              if (_textController.text == "") {
                setState(() {
                  please = true;
                });
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return crop(imagefile[int.parse(_textController.text) - 1],
                      widget.IP,widget.merge,widget.data);
                }));
              }
            },
            child: Icon(
              Icons.done_outline,
              color: Colors.black,
            )),
      ),
    );
  }
}
