import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

class MediaService {
  MediaStream? _localStream;

   Future<MediaStream?> createLocalStream(CameraDescription? camera, String type) async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': type == 'video' ? {'deviceId': camera?.name} : false,
    };
    try {
      return await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      print('Error getting media stream $e');
      return null;
    }
  }

  Future<MediaStream?> createLocalScreenStream() async {
    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': { 'mandatory': { 'chromeMediaSource': 'desktop' } },
    };
    try {
      return await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      print('Error getting screen stream $e');
      return null;
    }
  }

   Future<MediaStream?> createRemoteStream(dynamic data) async {
      try {
        return await createMediaStream(data);
      }
    catch (e)
    {
      print('error creating remote stream $e');
      return null;
    }
  }

  Future<MediaStream> createMediaStream(dynamic data) async {
      if (kIsWeb) {
        var bytes = base64Decode(data);
        return await createMediaStreamFromUint8List(bytes);
      }

    final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};

    var stream =  await navigator.mediaDevices.getUserMedia(mediaConstraints);

      var audioTrack = stream.getAudioTracks()[0];
    var videoTrack = stream.getVideoTracks()[0];

    if (data != null) {
      if (data is String) {
        try {
          var bytes = base64Decode(data);
          var videoTrackFromByte = await createMediaStreamTrackFromUint8List(bytes, 'video');
          stream.addTrack(videoTrackFromByte);
          stream.removeTrack(videoTrack);
        } catch (e) {
          print('Error decoding or adding track $e');
        }

      } else if (data is Map) {
        try {
          var audioBytes = base64Decode(data['audio']);
          var videoBytes = base64Decode(data['video']);
          var audioTrackFromByte = await createMediaStreamTrackFromUint8List(audioBytes, 'audio');
          var videoTrackFromByte = await createMediaStreamTrackFromUint8List(videoBytes, 'video');
          stream.addTrack(audioTrackFromByte);
          stream.addTrack(videoTrackFromByte);
          stream.removeTrack(audioTrack);
           stream.removeTrack(videoTrack);
        } catch (e) {
          print('Error decoding or adding track $e');
        }
      }
    }
    return stream;
  }


  Future<MediaStreamTrack> createMediaStreamTrackFromUint8List(Uint8List bytes, String type) async
  {
    if(type == 'video') {
      return  await createVideoTrack(bytes);
    }else{
      return await createAudioTrack(bytes);
    }
  }
    Future<MediaStreamTrack> createVideoTrack(Uint8List bytes) async {
    var mediaStreamTrackConstraints = <String, dynamic>{'video': true};
    return await createVideoMediaStreamTrackFromBytes(bytes, mediaStreamTrackConstraints);
  }

  Future<MediaStreamTrack> createAudioTrack(Uint8List bytes) async {
    var mediaStreamTrackConstraints = <String, dynamic>{'audio': true};
    return await createAudioMediaStreamTrackFromBytes(bytes, mediaStreamTrackConstraints);
  }
  Future<MediaStream> createMediaStreamFromUint8List(Uint8List bytes) async {
     var stream = await navigator.mediaDevices.getUserMedia({'audio':true,'video':true});
         var videoTrack = await createVideoMediaStreamTrackFromBytes(bytes,{'video':true});
     stream.addTrack(videoTrack);
     return stream;
  }

  Future<MediaStreamTrack> createVideoMediaStreamTrackFromBytes(Uint8List bytes, mediaStreamTrackConstraints) async {
     try
        {
         var videoTrack =  await createVideoTrack(bytes);
          return videoTrack;
       }on Exception catch (e)
      {
         print("error $e");
         rethrow;
      }
  }

 Future<MediaStreamTrack> createAudioMediaStreamTrackFromBytes(Uint8List bytes, mediaStreamTrackConstraints) async {
     try
      {
         var audioTrack = await createAudioTrack(bytes);
           return audioTrack;
      }on Exception catch (e)
      {
         print("error $e");
         rethrow;
      }
   }


  Future<void> startCamera(RTCVideoRenderer renderer,  Function(dynamic) sendStream, ) async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream = null;
    }
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      _localStream = await createLocalStream(firstCamera, 'video');
      if (_localStream != null)
        renderer.srcObject = _localStream;
      sendStream(_localStream);
    } else {
      print('Camera permission denied');
    }
  }

  Future<void> startMic(RTCVideoRenderer renderer,  Function(dynamic) sendStream) async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream=null;
    }
    final micPermission = await Permission.microphone.request();
    if (micPermission.isGranted) {
      _localStream = await createLocalStream(null, 'audio');
      if (_localStream != null)
        renderer.srcObject = _localStream;
      sendStream(_localStream);
    } else {
      print('Microphone permission denied');
    }
  }

  Future<void> startScreenShare(RTCVideoRenderer renderer,  Function(dynamic) sendStream, Function(bool) setScreenShareEnabled) async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream=null;
    }
    final screenSharePermission = await Permission.microphone.request();

    if (screenSharePermission.isGranted)
      _localStream = await createLocalScreenStream();
    if (_localStream != null)
      renderer.srcObject = _localStream;
    setScreenShareEnabled(true);
    sendStream(_localStream);
  }

  Future<void> stopCamera(RTCVideoRenderer renderer) async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream=null;
      renderer.srcObject = null;
    }
  }
  Future<void> stopShareScreen(RTCVideoRenderer renderer, Function(bool) setScreenShareEnabled) async {
    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      _localStream=null;
      renderer.srcObject = null;
      setScreenShareEnabled(false);
    }
  }
  void dispose()
  {
     if(_localStream != null)
       {
          _localStream?.dispose();
       }

  }
}