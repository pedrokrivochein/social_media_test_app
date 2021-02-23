import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

List<CameraDescription> cameras;
final databaseReference = FirebaseDatabase.instance.reference();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(new MaterialApp(
    title: 'Social Media Test',
    theme: ThemeData(
      primarySwatch: Colors.red,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: MyHomePage(camera: cameras.first),
  ));
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;
  MyHomePage({Key key, this.camera}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Post> imagesList = [];
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  CameraController controller;
  Future<void> _initializeControllerFuture;
  String list;
  final whatAreYouThinkingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Firebase.initializeApp().whenComplete(() {
      print("Completed");
    });

    updateImagesList();
    // To display the current output from the camera,
    // create a CameraController.
    controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.red,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TabBarView(children: [
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        color: Colors.red,
                        height: 40,
                        margin: EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.article_outlined,
                              color: Colors.white,
                            ),
                            Text(
                              "Feed",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      readData()
                    ],
                  ),
                  cameraTab(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.panorama_fish_eye_outlined,
                        color: Colors.white,
                        size: 150.0,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                          color: Colors.white,
                          width: 60,
                          height: 2,
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 0.0)),
                      Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        child: Text(
                          "Você não está logado.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                          color: Colors.white,
                          width: 60,
                          height: 2,
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 0.0)),
                      SizedBox(
                        height: 20,
                      ),
                      FlatButton(
                        color: Colors.white,
                        minWidth: 200.0,
                        child: Text(
                          "Entrar",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        onPressed: () {},
                      ),
                      FlatButton(
                        color: Colors.white,
                        minWidth: 200.0,
                        child: Text(
                          "Registrar",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ]),
              ),
              TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.article_outlined,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.account_circle_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> updateImagesList() async {
    refreshKey.currentState?.show();
    List<Post> insideImagesList = [];

    await databaseReference.once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
      snapshot.value["images"].forEach((key, value) {
        var i, t, l;
        value.forEach((k, v) {
          if (k == "id") {
            i = v;
          }
          if (k == "type") {
            t = v;
          }
          if (k == "link") {
            l = v;
          }
        });
        if (t != null) {
          print("Id: ${i} Type: ${t} Link: ${l}");
          insideImagesList.add(Post(id: int.parse(i), type: t, link: l));
        }
      });
    });
    List<Post> holder = List<Post>(insideImagesList.length);
    for(int i = 0; i < insideImagesList.length; i++){
      holder[insideImagesList[i].id] = insideImagesList[i];
    }
    insideImagesList = holder.reversed.toList();
    print(insideImagesList[0].type);
    setState(() {
      imagesList = insideImagesList;
    });
    return null;
  }

  Widget readData() {
    var size = MediaQuery.of(context).size.width;
    return Expanded(
      child: RefreshIndicator(
          child: ListView(
            children: <Widget>[
              Container(
                height: 60,
                color: Colors.red[800],
                padding: EdgeInsets.all(10.0),
                child: new ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 60.0,
                  ),
                  child: new Scrollbar(
                    child: new SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      reverse: true,
                      child: SizedBox(
                        height: 60.0,
                        child: new TextField(
                          controller: whatAreYouThinkingController,
                          maxLines: 100,
                          decoration: new InputDecoration(
                            border: InputBorder.none,
                            hintText: "O que você está pensando?",
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 40,
                color: Colors.red[600],
                child: FlatButton(
                  color: Colors.red[600],
                  onPressed: () async {
                    //if(whatAreYouThinkingController.text != ""){
                      try {
                        await _initializeControllerFuture;
                        DatabaseReference imagesRef =
                            databaseReference.child("images");
                        DatabaseReference newImagesRef = imagesRef.push();
                        newImagesRef.set({
                          "id": imagesList.length.toString(),
                          "author": "Unknown",
                          "Date": "Unkown",
                          "type": "text",
                          "link": whatAreYouThinkingController.text,
                        });
                      } catch (e) {
                        print(e);
                      }
                      whatAreYouThinkingController.clear();
                      updateImagesList();
                    //}
                  },
                  child: Text("Enviar"),
                ),
              ),
              for (int i = 0; i < imagesList.length; i++)
                (imagesList[i].type == "image")
                    ? Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 10.0),
                        width: size,
                        height: size,
                        child: Image.network(
                          imagesList[i].link,
                          fit: BoxFit.fitWidth,
                        ),
                      )
                    : Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 10.0),
                        color: Colors.white,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                          child: Text(
                            imagesList[i].link,
                            style: TextStyle(),
                          ),
                        ),
                      ),
            ],
          ),
          onRefresh: updateImagesList),
    );
  }

  Widget cameraTab() {
    var size = MediaQuery.of(context).size.width;
    return Container(
      child: (controller.value.isInitialized)
          ? Column(
              children: <Widget>[
                Container(
                  width: size,
                  height: size,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                          width: size,
                          height: size / 0.68,
                          child: CameraPreview(
                              controller), // this is my CameraPreview
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: FloatingActionButton(
                            child: Icon(
                              Icons.camera_rear_outlined,
                              size: 20,
                            ),
                            // Provide an onPressed callback.
                            onPressed: () {
                              var controllerHolder = CameraController(
                                  cameras[1], ResolutionPreset.medium);
                              setState(() {
                                controller = controllerHolder;
                              });
                              _initializeControllerFuture =
                                  controller.initialize();
                              updateImagesList();
                            },
                          ),
                        ),
                        FloatingActionButton(
                          child: Icon(Icons.camera_alt),
                          // Provide an onPressed callback.
                          onPressed: () async {
                            try {
                              await _initializeControllerFuture;
                              final image = await controller.takePicture();
                              final _firebaseStorage = FirebaseStorage.instance;
                              var file = File(image?.path);
                              var snapshot = await _firebaseStorage
                                  .ref()
                                  .child(
                                      'images/' + imagesList.length.toString())
                                  .putFile(file);
                              var downloadUrl =
                                  await snapshot.ref.getDownloadURL();
                              print("Download URL: " + downloadUrl);
                              DatabaseReference imagesRef =
                                  databaseReference.child("images");
                              DatabaseReference newImagesRef = imagesRef.push();
                              newImagesRef.set({
                                "id": imagesList.length.toString(),
                                "author": "Unknown",
                                "Date": "Unkown",
                                "type": "image",
                                "link": downloadUrl,
                              });
                              updateImagesList();
                            } catch (e) {
                              print(e);
                            }
                          },
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: FloatingActionButton(
                            child: Icon(
                              Icons.camera_rear_outlined,
                              size: 20,
                            ),
                            // Provide an onPressed callback.
                            onPressed: () {
                              var controllerHolder = CameraController(
                                  cameras[0], ResolutionPreset.medium);
                              setState(() {
                                controller = controllerHolder;
                              });
                              _initializeControllerFuture =
                                  controller.initialize();
                              updateImagesList();
                            },
                          ),
                        ),
                      ]),
                ),
              ],
            )
          : Container(),
    );
  }
}

class Post {
  int id;
  String type;
  String link;
  Post({this.id, this.type, this.link});
}
