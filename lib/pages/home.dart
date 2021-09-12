import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<SocketSevice>(context, listen: false);
    socketService.socket.on('active-bands', _handleActivateBands);
  }

  _handleActivateBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketSevice>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketSevice>(context);
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('BandsNames', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          actions: [
            Container(
                margin: EdgeInsets.only(right: 10),
                child: socketService.serverStatus == ServerStatus.Online
                    ? Icon(Icons.check_circle, color: Colors.blue[300])
                    : Icon(Icons.offline_bolt, color: Colors.red))
          ],
        ),
        body: Column(children: [
          if (bands.isNotEmpty) _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (BuildContext context, i) => _bandTitle(bands[i]),
            ),
          ),
        ]),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: addBand,
        ));
  }

  Widget _bandTitle(Band band) {
    final socketService = Provider.of<SocketSevice>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('delete band', style: TextStyle(color: Colors.white)),
        ),
      ),
      child: ListTile(
          leading: CircleAvatar(
            child: Text(band.name.substring(0, 2)),
            backgroundColor: Colors.blue[100],
          ),
          title: Text(band.name, style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            '${band.votes}',
            style: TextStyle(fontSize: 20),
          ),
          onTap: () => socketService.emit('vote-band', {'id': band.id})),
    );
  }

  addBand() {
    final textController = new TextEditingController();
    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) => AlertDialog(
                  title: Text('New band name'),
                  content: TextField(
                    controller: textController,
                  ),
                  actions: <Widget>[
                    MaterialButton(
                        onPressed: () => _addBandToList(textController.text),
                        textColor: Colors.blue,
                        child: Text('Add'))
                  ]));
    }

    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
              title: Text('New band name'),
              content: CupertinoTextField(
                controller: textController,
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Add'),
                  onPressed: () => _addBandToList(textController.text),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('Dismiss'),
                  onPressed: () => Navigator.pop(context),
                )
              ]);
        });
  }

  void _addBandToList(String name) {
    if (name.length > 1) {
      //*agregar el nombre de la banda

      final socketService = Provider.of<SocketSevice>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  //*mostrar el grafico de las bandas

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
        padding: EdgeInsets.only(top: 10),
        width: double.infinity,
        height: 200,
        child: PieChart(
          dataMap: dataMap,
          chartValuesOptions: ChartValuesOptions(
            showChartValuesInPercentage: true,
            showChartValuesOutside: false,
            decimalPlaces: 0,
          ),
          chartType: ChartType.ring,
        ));
  }
}
