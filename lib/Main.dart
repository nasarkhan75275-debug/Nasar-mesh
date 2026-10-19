import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(NasarMeshApp());

class NasarMeshApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASAR Mesh',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  String status = "Bluetooth OFF hai";
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  Future<void> checkPermission() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
    checkBluetooth();
  }

  Future<void> checkBluetooth() async {
    bool? isEnabled = await bluetooth.isEnabled;
    setState(() {
      status = isEnabled == true ? "Bluetooth ON - Scan karo" : "Bluetooth OFF hai - ON karo";
    });
  }

  Future<void> startScan() async {
    setState(() {
      isScanning = true;
      devices.clear();
      status = "Scan kar raha hu...";
    });

    try {
      bool? isEnabled = await bluetooth.isEnabled;
      if (isEnabled != true) {
        await bluetooth.requestEnable();
      }

      List<BluetoothDevice> bonded = await bluetooth.getBondedDevices();
      List<BluetoothDiscoveryResult> results = await bluetooth.startDiscovery().toList();

      setState(() {
        devices = bonded;
        for (var r in results) {
          if (!devices.any((d) => d.address == r.device.address)) {
            devices.add(r.device);
          }
        }
        isScanning = false;
        status = "${devices.length} device mile";
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🔵 NASAR Mesh"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(status, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (isScanning) LinearProgressIndicator(),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (c, i) {
                return ListTile(
                  leading: Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(devices[i].name ?? "Unknown Device"),
                  subtitle: Text(devices[i].address),
                  trailing: ElevatedButton(
                    child: Text("Connect"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${devices[i].name} se connect - coming soon!")),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 1,
            child: ListView(
              children: messages.map((m) => ListTile(title: Text(m))).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startScan,
        icon: Icon(Icons.search),
        label: Text("SCAN"),
      ),
    );
  }
}
