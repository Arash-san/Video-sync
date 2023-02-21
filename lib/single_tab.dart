import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'video_data.dart';
import 'vlc_player_with_controls.dart';

class SingleTab extends StatefulWidget {
  @override
  _SingleTabState createState() => _SingleTabState();
}

class MyCustomEventType {
  String data = "";
  MyCustomEventType(this.data);
}

class _SingleTabState extends State<SingleTab> {
  VlcPlayerController _controller;
  final _key = GlobalKey<VlcPlayerWithControlsState>();

  //

  StreamController<MyCustomEventType> eventController =
      StreamController<MyCustomEventType>.broadcast();

  List<VideoData> listVideos;
  int selectedVideoIndex;

  bool hasAnythingOpend = false;
  bool clientDialogVisibility = false;
  TextEditingController serverAddressCont = TextEditingController();
  TextEditingController nameCont = TextEditingController();

  bool isServer = false;
  static bool isConnected = false;

  // Future<File> _loadVideoToFs() async {
  //   final videoData = await rootBundle.load('assets/sample.mp4');
  //   final videoBytes = Uint8List.view(videoData.buffer);
  //   var dir = (await getTemporaryDirectory()).path;
  //   var temp = File('$dir/temp.file');
  //   temp.writeAsBytesSync(videoBytes);
  //   return temp;
  // }

  List<WebSocket> websocketClients = [];
  WebSocket websocketServer;

  String otherPerson = "Helen";
  bool isAllowed = false;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void startWebSocketServer(String serverAddress, int port, String name) async {
    isServer = true;
    var server = await HttpServer.bind(serverAddress, port);
    print('WebSocket server started on port $port');

    await for (var request in server) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        websocketClients.add(webSocket);
        webSocket.add("connectToClient|$name");
        print('WebSocket client connected');
        // handle incoming messages from client
        webSocket.listen((message) {
          print('Received message: $message');
          eventController.sink.add(MyCustomEventType(message));
        });
      });
    }
  }

  connectToWebSocketServer(String ipAddress, int port, String name) async {
    isServer = false;
    var url = 'ws://$ipAddress:$port';
    WebSocket.connect(url).then((WebSocket webSocket) {
      websocketServer = webSocket;
      print('Connected to WebSocket server at $url');

      // handle incoming messages from server
      webSocket.listen((message) {
        print('Received message: $message');
        eventController.sink.add(MyCustomEventType(message));
        // webSocket.add('Echo: $message');
      });
    });
  }

  void fillVideos() {
    listVideos = <VideoData>[];
    //
    listVideos.add(VideoData(
      name: 'Network Video 1',
      path:
          'http://samples.mplayerhq.hu/MPEG-4/embedded_subs/1Video_2Audio_2SUBs_timed_text_streams_.mp4',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'Network Video 2',
      path: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'HLS Streaming Video 1',
      path: 'http://demo.unified-streaming.com/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'File Video 1',
      path: 'System File Example',
      type: VideoType.file,
    ));
    //
    listVideos.add(VideoData(
      name: 'Asset Video 1',
      path: 'assets/sample.mp4',
      type: VideoType.asset,
    ));
  }

  void sendToWebsocket(String msg) {
    try {
      !isServer ? websocketServer.add(msg) : websocketClients[0].add(msg);
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();

    eventController.stream.asBroadcastStream().listen((event) async {
      print("yesssssssssssssss ${event.data}");
      List<String> request = (event.data).split("|");
      if (request[0] == "play" && request[1] == "send") {
        sendToWebsocket("play|receive");
      } else if (request[0] == "pause" && request[1] == "send") {
        sendToWebsocket("pause|receive");
      } else if (request[0] == "replay" && request[1] == "send") {
        sendToWebsocket("replay|receive");
      } else if (request[0] == "seekMilisecond") {
        List<String> otherParams = request[1].split("/");
        if (otherParams[1] == "send") {
          sendToWebsocket("seekMilisecond|${otherParams[0]}/receive");
        }
      } else if (request[0] == "connection" && request[1] == "declined") {
        isAllowed = false;
        websocketServer.close();
        // navigatorKey.currentState.pop();
        showMessage(context, "Connection declined");
        // if (clientDialogVisibility) {
        //   Navigator.pop(context);
        //   clientDialogVisibility = false;
        // }
      } else if (request[0] == "connection" && request[1] == "allowed") {
        isConnected = true;
        isAllowed = true;
        // navigatorKey.currentState.pop();
        showMessage(context, "Connection accepted");
        // if (clientDialogVisibility) {
        //   Navigator.pop(context);
        //   clientDialogVisibility = false;
        // }
      } else if (request[0] == "connectToClient") {
        clientDialogVisibility = true;
        // showDialog(
        //     context: context,
        //     barrierDismissible: false,
        //     builder: (context) {
        //       return AlertDialog(
        //           key: navigatorKey,
        //           contentPadding: EdgeInsets.zero,
        //           clipBehavior: Clip.antiAlias,
        //           content: Stack(
        //             alignment: Alignment.center,
        //             children: <Widget>[
        //               Image.asset(
        //                 'assets/back.jpg',
        //                 fit: BoxFit.cover,
        //               ),
        //               Padding(
        //                 padding: const EdgeInsets.all(15.0),
        //                 child: Column(
        //                   mainAxisSize: MainAxisSize.min,
        //                   children: [
        //                     Text(
        //                       'Please wait until the server accepts your connection',
        //                       style: TextStyle(
        //                         color: Colors.white,
        //                         fontSize: 24,
        //                       ),
        //                     ),
        //                     SizedBox(
        //                       height: 15,
        //                     ),
        //                     Row(
        //                       children: [
        //                         FilledButton.tonalIcon(
        //                             onPressed: () {
        //                               clientDialogVisibility = false;
        //                               Navigator.of(context).pop();
        //                             },
        //                             icon: Icon(Icons.cancel),
        //                             label: Text("Cancel")),
        //                       ],
        //                     )
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ));
        //     });
      } else if (request[0] == "connectToServer") {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  content: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/back.jpg',
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${request[1]} would like to connect to you. Do you allow it?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      sendToWebsocket("connection|allowed");
                                      isAllowed = true;
                                    },
                                    icon: Icon(Icons.check_circle),
                                    label: Text("Accept")),
                                SizedBox(
                                  width: 15,
                                ),
                                FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      isAllowed = false;
                                      sendToWebsocket("connection|declined");
                                      websocketClients[0].close();
                                    },
                                    icon: Icon(Icons.cancel),
                                    label: Text("Decline")),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ));
            });
      }
      // if (event.data == "") {
      //   print('handling LOGIN COMPLETE event ' + event.toString());
      // } else {
      //   print('handling some other event ' + event.toString());
      // }
    });

    //
    fillVideos();
    selectedVideoIndex = 0;
    //
    var initVideo = VideoData(
      name: 'Intro',
      path: 'assets/intro.jpg',
      type: VideoType.asset,
    );
    switch (initVideo.type) {
      case VideoType.network:
        _controller = VlcPlayerController.network(
          initVideo.path,
          hwAcc: HwAcc.full,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            subtitle: VlcSubtitleOptions([
              VlcSubtitleOptions.boldStyle(true),
              VlcSubtitleOptions.fontSize(30),
              VlcSubtitleOptions.outlineColor(VlcSubtitleColor.black),
              VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
              // works only on externally added subtitles
              VlcSubtitleOptions.color(VlcSubtitleColor.white),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
            rtp: VlcRtpOptions([
              VlcRtpOptions.rtpOverRtsp(true),
            ]),
          ),
        );
        break;
      case VideoType.file:
        var file = File(initVideo.path);
        _controller = VlcPlayerController.file(
          file,
        );
        break;
      case VideoType.asset:
        _controller = VlcPlayerController.asset(
          initVideo.path,
          options: VlcPlayerOptions(),
        );
        break;
      // case VideoType.recorded:
      //   break;
    }
    // _controller.addOnInitListener(() async {
    //   await _controller.startRendererScanning();
    // });
    // _controller.addOnRendererEventListener((type, id, name) {
    //   print('OnRendererEventListener $type $id $name');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: MediaQuery.of(context).orientation != Orientation.portrait
              ? MediaQuery.of(context).size.height + 10
              : 350,
          child: VlcPlayerWithControls(
            key: _key,
            controller: _controller,
            eventControl: eventController,
            // onStopRecording: (recordPath) {
            //   setState(() {
            //     listVideos.add(VideoData(
            //       name: 'Recorded Video',
            //       path: recordPath,
            //       type: VideoType.recorded,
            //     ));
            //   });
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text('The recorded video file has been added to the end of list.'),
            //     ),
            //   );
            // },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: FilledButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Clearing the previous cache...'),
                  ),
                );

                // eventController.sink.add(MyCustomEventType("fuck meeeee"));
                // return;

                await FilePicker.platform.clearTemporaryFiles();
                FilePickerResult result = await FilePicker.platform.pickFiles();

                if (result != null) {
                  File file = File(result.files.single.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copying file to temporary storage...'),
                    ),
                  );
                  await Future.delayed(Duration(seconds: 1));
                  await _controller.setMediaFromFile(file);
                  setState(() {
                    hasAnythingOpend = true;
                  });
                } else {
                  // User canceled the picker
                }
              },
              icon: Icon(Icons.open_in_browser),
              label: const Text("Open a video")),
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Server address:",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: serverAddressCont,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  "Name:",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: nameCont,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    FilledButton.icon(
                        onPressed: () async {
                          await connectToWebSocketServer(
                              serverAddressCont.text, 58690, nameCont.text);
                          await Future.delayed(Duration(seconds: 2));
                          sendToWebsocket("connectToServer|${nameCont.text}");
                          showMessage(context, 'Connected to the server');
                        },
                        icon: Icon(Icons.gpp_good_outlined),
                        label: const Text("Connect")),
                    SizedBox(
                      width: 20,
                    ),
                    FilledButton.icon(
                        onPressed: () {
                          startWebSocketServer("0.0.0.0", 58690, nameCont.text);
                          showMessage(context, 'Server has been started');
                        },
                        icon: Icon(Icons.star_purple500_outlined),
                        label: const Text("Start the server")),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
    ));
  }

  @override
  void dispose() async {
    eventController.close();
    super.dispose();
    // await _controller.stopRecording();
    await _controller.stopRendererScanning();
    await _controller.dispose();
  }
}
