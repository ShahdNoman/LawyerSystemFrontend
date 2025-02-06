import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SocketService {
  late IO.Socket socket;
  String? room;
  Function(dynamic)? onVideoStream;
  Function(dynamic)? onVoiceStream;
  Function(dynamic)? onScreenStream;
  Function(dynamic)? onChatMessage;
  Function(dynamic)? onRaiseHand;
  Function(dynamic)? onMuteUser;
  Function(dynamic)? onNewUserJoined;
  Function(dynamic)? onUserLeft;
  Function(dynamic)? onUsersInRoom;


  SocketService({
    this.onVideoStream,
    this.onVoiceStream,
    this.onScreenStream,
      this.onChatMessage,
    this.onRaiseHand,
    this.onMuteUser,
    this.onNewUserJoined,
    this.onUserLeft,
       this.onUsersInRoom
  }) {
    initSocket();
  }

  void initSocket() {
    socket = IO.io('http://10.0.2.2:4000',
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket.onConnect((_) {
        if (kDebugMode) {
        print('Connected to backend');
      }
    });

    socket.on('usersInRoom', (data){
        if (onUsersInRoom != null)
          {
             onUsersInRoom!(data);
          }
    });

     socket.on('newUserJoined', (data){
         if (onNewUserJoined != null)
            {
              onNewUserJoined!(data);
            }
        });

       socket.on('userLeft', (data){
        if (onUserLeft != null)
          {
              onUserLeft!(data);
          }
      });
    socket.on('video-stream', (data) {
      if (onVideoStream != null) {
        onVideoStream!(data);
      }
    });

    socket.on('voice-stream', (data) {
      if (onVoiceStream != null) {
        onVoiceStream!(data);
      }
    });

    socket.on('screen-stream', (data) {
      if (onScreenStream != null) {
        onScreenStream!(data);
      }
    });

     socket.on('chatMessage', (data) {
        if (onChatMessage != null)
            {
             onChatMessage!(data);
            }
      });

      socket.on('raiseHand', (data) {
         if (onRaiseHand != null)
           {
               onRaiseHand!(data);
           }
      });

     socket.on('muteUser', (data) {
       if (onMuteUser != null)
         {
              onMuteUser!(data);
         }
     });

    socket.onDisconnect((_) => print('Disconnected'));
    socket.on('error', (err) => print('Error: $err'));
  }

    void joinRoom(String roomName)
    {
       room=roomName;
        socket.emit('joinRoom',roomName);
    }

    void leaveRoom(String roomName)
    {
       socket.emit('leaveRoom',roomName);
       room=null;
    }

    void sendVideoStream(dynamic stream) async
    {
      if (stream != null)
      {
        if (kIsWeb)
        {
          stream.getVideoTracks().forEach((track) async {
            convertStreamTrackToBytes(track)
                .then((value) {
              if (value!=null)
              {
                 socket.emit('video-stream', {'data': base64Encode(value), 'room':room});
              }
            });
          });
        }
        else
        {
          Map<String, String> streams = {};
          stream.getAudioTracks().forEach((track) async {
            var bytes = await convertStreamTrackToBytes(track);
            if(bytes !=null){
              streams.putIfAbsent('audio', () => base64Encode(bytes));
            }
          });

          stream.getVideoTracks().forEach((track) async {
            var bytes = await convertStreamTrackToBytes(track);
            if(bytes !=null){
              streams.putIfAbsent('video', () => base64Encode(bytes));
            }
          });
            socket.emit('video-stream', {'data': streams, 'room':room});
        }

      }

    }

    void sendVoiceStream(dynamic stream) async {
      if (stream != null) {
        stream.getAudioTracks().forEach((track) {
          convertStreamTrackToBytes(track)
              .then((value) {
            if (value!=null)
            {
                socket.emit('voice-stream', {'data': base64Encode(value), 'room':room});
            }
          });
        });
      }
    }

    void sendScreenStream(dynamic stream) async {
      if (stream != null)
        stream.getVideoTracks().forEach((track) {
          convertStreamTrackToBytes(track)
              .then((value) {
            if (value!=null)
            {
                socket.emit('screen-stream', {'data': base64Encode(value), 'room':room});
            }
          });
        });
    }

   void sendChatMessage(String message)
    {
      socket.emit('chatMessage', {'message':message,'room':room});
    }

    void raiseHand(bool isRaised)
    {
        socket.emit('raiseHand', {'isRaised':isRaised, 'room':room});
    }

    void muteUser(bool isMuted)
    {
       socket.emit('muteUser', {'isMuted':isMuted,'room':room});
    }


  Future<Uint8List?> convertStreamTrackToBytes(MediaStreamTrack track) async {
    try {
      var byteBuffer = await track.captureFrame();
      return byteBuffer?.asUint8List();
    } on Exception catch (e) {
      print('error converting to bytes: $e');
      return null;
    }
  }

  void dispose() {
    socket.disconnect();
  }
}