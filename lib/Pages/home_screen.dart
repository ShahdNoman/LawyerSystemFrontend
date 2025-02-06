import 'package:flutter/material.dart';
import 'socket_service.dart';
import 'media_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Screen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Screen> {
  late SocketService socketService;
  late MediaService mediaService;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isScreenShareEnabled = false;
  String message = '';
  String remoteUserId = '';
  List<String> users = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _initServices();
  }

  _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  _initServices() async {
    mediaService = MediaService();
    socketService = SocketService(
      onVideoStream: (data) {
        _handleVideoStream(data);
      },
      onVoiceStream: (data) {
        _handleVoiceStream(data);
      },
      onScreenStream: (data) {
        _handleScreenStream(data);
      },
      onChatMessage: (data) {
        _handleChatMessage(data);
      },
      onRaiseHand: (data) {
        _handleRaiseHand(data);
      },
      onMuteUser: (data) {
        _handleMuteUser(data);
      },
      onNewUserJoined: (data) {
        _handleNewUserJoined(data);
      },
      onUserLeft: (data) {
        _handleUserLeft(data);
      },
        onUsersInRoom: (data){
        _handleUsersInRoom(data);
      }
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socketService.dispose();
    mediaService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendVideoStream(dynamic stream) {
    socketService.sendVideoStream(stream);
  }

  void _sendVoiceStream(dynamic stream) {
    socketService.sendVoiceStream(stream);
  }

  void _sendScreenStream(dynamic stream) {
    socketService.sendScreenStream(stream);
  }

  void _sendChatMessage() {
   if (_messageController.text.isNotEmpty)
      {
        socketService.sendChatMessage(_messageController.text);
         _messageController.clear();
      }
  }

  void _handleVideoStream(dynamic data) async {
    var remoteStream = await mediaService.createRemoteStream(data.data);
    if (remoteStream != null) _remoteRenderer.srcObject = remoteStream;
    setState(() {
      remoteUserId = data.userId;
    });
  }

  _handleVoiceStream(dynamic data) async {
    var remoteStream = await mediaService.createRemoteStream(data.data);
    if (remoteStream != null) _remoteRenderer.srcObject = remoteStream;
    setState(() {
      remoteUserId = data.userId;
    });
  }

  _handleScreenStream(dynamic data) async {
    var remoteStream = await mediaService.createRemoteStream(data.data);
    if (remoteStream != null) _remoteRenderer.srcObject = remoteStream;
    setState(() {
      remoteUserId = data.userId;
    });
  }

  _handleChatMessage(dynamic data) {
    setState(() {
      message = data.message;
      remoteUserId = data.userId;
    });
  }

  _handleRaiseHand(dynamic data) {
    print('user ${data.userId} raise hand ${data.isRaised}');
  }

  _handleMuteUser(dynamic data) {
    print('user ${data.userId} mute  ${data.isMuted}');
  }

  _handleNewUserJoined(dynamic data) {
    print('new user ${data}');
    setState(() {
      users.add(data);
    });
  }
   _handleUsersInRoom(dynamic data)
   {
     setState(() {
      users = List<String>.from(data);
      print('users ${data}');
    });
   }


  _handleUserLeft(dynamic data) {
    print('user left ${data}');
    setState(() {
      users.remove(data);
    });
  }

  void _joinRoom(String roomName) {
    socketService.joinRoom(roomName);
  }

  void _leaveRoom(String roomName) {
    socketService.leaveRoom(roomName);
  }

  void _handleRaiseHandButton() {
    socketService.raiseHand(true);
  }

  void _handleMuteButton() {
    socketService.muteUser(true);
  }
    void _setScreenShareEnabled(bool value)
  {
   setState(() {
        _isScreenShareEnabled=value;
     });
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Realtime App')),
      body: SingleChildScrollView(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Users : ${users.join(',')}'),
            Text('Remote user id  : $remoteUserId'),
            Text('Message : $message'),
            SizedBox(
              height: 200,
              width: 200,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              width: 200,
              child: RTCVideoView(_remoteRenderer),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _joinRoom('testRoom'),
              child: Text('Join Room'),
            ),
             ElevatedButton(
              onPressed: () => _leaveRoom('testRoom'),
               child: Text('Leave Room'),
             ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await mediaService.startCamera(_localRenderer, _sendVideoStream);
                    },
                    child: Text('Start Camera'),
                  ),
                ),
                 Expanded(
                     child: ElevatedButton(
                      onPressed: () async {
                        await mediaService.stopCamera(_localRenderer);
                      },
                      child: Text('Stop Camera'),
                    ),
                 ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await mediaService.startMic(_localRenderer, _sendVoiceStream);
                    },
                    child: Text('Start Mic'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await mediaService.stopCamera(_localRenderer);
                    },
                    child: Text('Stop Mic'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 Expanded(
                   child:ElevatedButton(
                      onPressed: () async {
                        await mediaService.startScreenShare(
                            _localRenderer, _sendScreenStream, _setScreenShareEnabled);
                      },
                      child: Text('Share Screen'),
                    ),
                ),
                Expanded(
                   child: ElevatedButton(
                      onPressed: () async {
                         await mediaService.stopShareScreen(_localRenderer,_setScreenShareEnabled);
                      },
                      child: Text('Stop Share Screen'),
                    ),
                ),
              ],
            ),
            Visibility(
              visible: _isScreenShareEnabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child:ElevatedButton(
                    onPressed: () async {
                      _sendScreenStream(_localRenderer.srcObject);
                     },
                     child: Text('Continue share screen'),
                   ),
                 ),
                ],
              ),
            ),
           Padding(
            padding: const EdgeInsets.all(10.0),
               child:TextField(
                    controller: _messageController,
                  decoration: InputDecoration(
                      hintText: "Type your message here",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                ),
            ),
            ElevatedButton(
             onPressed: () => _sendChatMessage(),
                 child: Text('Send message'),
             ),
              ElevatedButton(
                onPressed: () => _handleRaiseHandButton(),
                  child: Text('Raise hand'),
              ),
             ElevatedButton(
               onPressed: () => _handleMuteButton(),
                 child: Text('Mute'),
              ),
          ],
        ),
      ),
    ),
    );
  }
}