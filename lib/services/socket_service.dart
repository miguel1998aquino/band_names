import 'package:socket_io_client/socket_io_client.dart';

import 'package:flutter/material.dart';

enum ServerStatus {
  Online,
  Offline,
  Connecting,
}

class SocketSevice with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;

  late Socket _socket;

  ServerStatus get serverStatus => this._serverStatus;

  Socket get socket => this._socket;
  Function get emit => this._socket.emit;

  SocketSevice() {
    this._initConfig();
  }

  void _initConfig() {
    // Dart client
    this._socket  = io(
        'http://192.168.1.43:3000/',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .enableAutoConnect() // disable auto-connection// optional
            .build());
    this._socket.onConnect((_) {
      print('connect');
      this._serverStatus = ServerStatus.Online;
      notifyListeners();
    });
    this._socket.onDisconnect((_) {
      print('disconnect');
      this._serverStatus = ServerStatus.Offline;
      notifyListeners();
    });

    
  }
}
