import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

List<CameraDescription> cameras; //Lista de cameras do dispositivo.
final databaseReference =
    FirebaseDatabase.instance.reference(); //Referencia ao banco de dados.

class MessageHandler extends StatefulWidget {
  @override
  _MessageHandlerState createState() => _MessageHandlerState();
}

class _MessageHandlerState extends State<MessageHandler> {
  final FirebaseMessaging _fcm = FirebaseMessaging();

  @override
  void initState() {
    super.initState();

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // TODO optional
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // TODO optional
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); //Pegar cameras disponiveis no celular.
  runApp(new MaterialApp(
    title: 'Social Media Test',
    theme: ThemeData(
      primarySwatch: Colors.red,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: MyHomePage(
        camera: cameras.first), //Passa o dado da camera para a interface.
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
  final whatAreYouThinkingController =
      TextEditingController(); //Texto em "O que voce esta pensando?".
  final usernameController =
      TextEditingController(text: "Unknown"); //Texto no nome de usuario.

  @override
  void initState() {
    super.initState();

    Firebase.initializeApp().whenComplete(() {
      print("Completed"); //Firebase iniciado com sucesso.
    });

    updateImagesList(); //Atualiza inicialmente a lista de items.
    controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture =
        controller.initialize(); //Variavel controle da camera.
  }

  @override
  void dispose() {
    //Se livra do controle quando nao e mais necessario.
    controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    //Desenha a interface.
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
                      updateFeed()
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
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: 40,
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        child: TextField(
                          controller: usernameController,
                          style: TextStyle(fontSize: 20),
                        ),
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

  //Atualizar a lista de imagens, puxar novas imagens do banco de dados.
  Future<Null> updateImagesList() async {
    refreshKey.currentState?.show();
    List<Post> insideImagesList = [];

    await databaseReference.once().then((DataSnapshot snapshot) {
      // Se conecta ao banco de dados.
      snapshot.value["images"].forEach((key, value) {
        //Recebe as novas imagens.
        var i, a, t, l; //Id, Autor, Tipo e Link.
        value.forEach((k, v) {
          //Separa os tipos de variaveis.
          if (k == "id")
            i = v;
          else if (k == "author")
            a = v;
          else if (k == "type")
            t = v;
          else if (k == "link") l = v;
        });

        if (t != null) {
          //Se o dado realmente for uma postagem, adicionar a lista de imagens.
          insideImagesList
              .add(Post(id: int.parse(i), author: a, type: t, link: l));
        }
      });
    });

    List<Post> holder =
        List<Post>(insideImagesList.length); //Variavel auxiliar.

    //Reordenando as imagens (Mais recentes em cima).
    for (int i = 0; i < insideImagesList.length; i++) {
      holder[insideImagesList[i].id] = insideImagesList[i];
    }
    insideImagesList = holder.reversed.toList();
    setState(() {
      imagesList = insideImagesList;
      for (int i = 0; i < imagesList.length; i++) {
        print(imagesList[i].link);
      }
    });
    return null;
  }

  //Atualizar e Desenhar o Feed.
  Widget updateFeed() {
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
                          scrollController: ScrollController(
                            initialScrollOffset: 0.0,
                          ),
                          controller: whatAreYouThinkingController,
                          maxLines: 3,
                          decoration: new InputDecoration(
                            border: InputBorder.none,
                            hintText: "O que você está pensando?",
                          ),
                          style: TextStyle(color: Colors.white),
                          textAlignVertical: TextAlignVertical.center,
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
                  //Postar texto.
                  onPressed: () async {
                    if (whatAreYouThinkingController.text != "") {
                      try {
                        await _initializeControllerFuture;
                        DatabaseReference imagesRef =
                            databaseReference.child("images");
                        DatabaseReference newImagesRef = imagesRef.push();
                        //Criar o JSON do texto, adicionar a lista de postagens.
                        getListLenght().then((value) {
                          newImagesRef.set({
                            "id": value,
                            "author": usernameController.text,
                            "Date": "Unkown",
                            "type": "text",
                            "link": whatAreYouThinkingController.text,
                          });
                          whatAreYouThinkingController.clear();
                          updateImagesList(); //Atualizar lista apos postagem.
                        });
                      } catch (e) {
                        print(e);
                      }
                    }
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
                        child: Column(children: <Widget>[
                          Container(
                            color: Colors.white,
                            width: size,
                            height: 40,
                            padding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 0.0),
                            child: Row(children: <Widget>[
                              CircleAvatar(
                                backgroundColor: Colors.grey,
                              ),
                              Text(
                                imagesList[i].author,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                              ),
                            ]),
                          ),
                          Container(
                            width: size,
                            height: size,
                            child: Image.network(
                              imagesList[i].link,
                              fit: BoxFit.fitWidth,
                            ),
                          )
                        ]),
                      )
                    : Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 10.0),
                        color: Colors.white,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                color: Colors.white,
                                width: size,
                                height: 40,
                                padding: EdgeInsets.symmetric(
                                    vertical: 5.0, horizontal: 0.0),
                                child: Row(children: <Widget>[
                                  CircleAvatar(
                                    backgroundColor: Colors.grey,
                                  ),
                                  Text(
                                    imagesList[i].author,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                ]),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                child: Text(
                                  imagesList[i].link,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ]),
                      ),
            ],
          ),
          onRefresh: updateImagesList),
    );
  }

  //Interface da camera
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
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: FloatingActionButton(
                                  heroTag: "1",
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
                                heroTag: "2",
                                child: Icon(Icons.camera_alt),
                                //Tirar foto
                                onPressed: () async {
                                  try {
                                    await _initializeControllerFuture;
                                    final image =
                                        await controller.takePicture();
                                    //Envia a foto tirada para a aba de confirmação.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfirmPictureScreen(
                                          possibleId:
                                              imagesList.length.toString(),
                                          author: usernameController.text,
                                          imagePath: image?.path,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print(e);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: FloatingActionButton(
                                  heroTag: "3",
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
                        SizedBox(
                          height: 20,
                        ),
                      ]),
                ),
              ],
            )
          : Container(),
    );
  }
}

//Aba de confirmação
class ConfirmPictureScreen extends StatelessWidget {
  final String possibleId;
  final String author;
  final String imagePath;
  const ConfirmPictureScreen(
      {Key key, this.possibleId, this.author, this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.red,
      body: Stack(children: <Widget>[
        Container(
          width: size,
          height: size,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Container(
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                  width: size,
                  height: size / 0.68,
                  child:
                      Image.file(File(imagePath)), // this is my CameraPreview
                ),
              ),
            ),
          ),
        ),
        Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FloatingActionButton(
                      heroTag: "4",
                      child: Icon(Icons.check_circle_outline),
                      // Postar foto.
                      onPressed: () async {
                        try {
                          var id = possibleId;
                          getListLenght().then((value) {
                            id = value; //ID da foto = Numero de postagens + 1
                          });
                          final _firebaseStorage = FirebaseStorage.instance;
                          var file = File(imagePath);
                          Random random = new Random();
                          var snapshot = await _firebaseStorage
                              .ref()
                              .child('images/' +
                                  id +
                                  " " +
                                  random.nextInt(1000).toString())
                              .putFile(file);
                          var downloadUrl = await snapshot.ref.getDownloadURL();
                          DatabaseReference imagesRef =
                              databaseReference.child("images");
                          DatabaseReference newImagesRef = imagesRef.push();
                          //Montar JSON da foto
                          newImagesRef.set({
                            "id": id,
                            "author": author,
                            "Date": "Unkown",
                            "type": "image",
                            "link": downloadUrl,
                          });
                          Navigator.pop(context);
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                    FloatingActionButton(
                      heroTag: "5",
                      child: Icon(Icons.cancel_outlined),
                      // Provide an onPressed callback.
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ]),
              SizedBox(
                height: 20,
              ),
            ]),
      ]),
    );
  }
}

//Dados da postagem
class Post {
  int id;
  String author;
  String type;
  String link;
  Post({this.id, this.author, this.type, this.link});
}

//Quantidade de postagens feitas
Future<String> getListLenght() async {
  int i = 0;
  await databaseReference.once().then((DataSnapshot snapshot) {
    snapshot.value["images"].forEach((key, value) {
      i++;
    });
  });
  return i.toString();
}
