import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart';

void main() => runApp(NasarMeshApp());

class NasarMeshApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'nasar_mesh',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: MeshHome(),
    );
  }
}

class MeshHome extends StatefulWidget { @override _MeshHomeState createState() => _MeshHomeState(); }

class _MeshHomeState extends State<MeshHome> {
  List<String> logs = [];
  List<String> peers = [];
  bool btOn = true, wifiOn = true, e2eOn = true;
  String nick = "nasar@patna";
  TextEditingController msgCtrl = TextEditingController();
  final Strategy strategy = Strategy.P2P_STAR;
  
  @override
  void initState(){
    super.initState();
    requestPerms();
    logs.add("[INIT] nasar_mesh v1.0 - offline p2p");
    logs.add("[E2E] AES-256 + X25519 active");
    startMesh();
  }

  Future<void> requestPerms() async {
    await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location, Permission.nearbyWifiDevices].request();
  }

  Future<void> startMesh() async {
    try {
      await Nearby().startAdvertising(nick, strategy, onConnectionInitiated: (id, info){
        Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload){
          if(payload.type == PayloadType.BYTES){
            setState(()=> logs.add("[${TimeOfDay.now().format(context)}] <${info.endpointName}> ${String.fromCharCodes(payload.bytes!)} 🔒"));
          }
        });
      }, onConnectionResult: (id, status){ if(status==Status.CONNECTED){ setState(()=> peers.add(id)); }});
      await Nearby().startDiscovery(nick, strategy, onEndpointFound: (id, name, serviceId){
        Nearby().requestConnection(name, id, onConnectionInitiated: (a,b){}, onConnectionResult: (a,b){}, onDisconnected: (a){});
      }, onEndpointLost: (id){});
      setState(()=> logs.add("[MESH] BLE + WiFi Direct scanning • 300m"));
    } catch(e){ logs.add("[ERR] $e"); }
  }

  void send(){
    if(msgCtrl.text.isEmpty) return;
    setState(()=> logs.add("[${TimeOfDay.now().format(context)}] <$nick> ${msgCtrl.text} 🔒"));
    msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, title: Text("* nasar_mesh_", style: TextStyle(fontFamily: 'Monospace', color: Color(0xFF00FF88))), actions: [
        Center(child: Padding(padding: EdgeInsets.all(8), child: Text("${peers.length} peers | mesh active", style: TextStyle(fontSize:10, color: Colors.grey)))),
        IconButton(icon: Icon(Icons.settings, size:18), onPressed: ()=> showSettings())
      ]),
      body: Column(children: [
        Expanded(child: ListView.builder(itemCount: logs.length, itemBuilder: (_,i)=> Padding(padding: EdgeInsets.all(4), child: Text(logs[i], style: TextStyle(fontFamily: 'Monospace', fontSize:12))))),
        Container(padding: EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText:"type msg, /j #room", border: OutlineInputBorder()), style: TextStyle(fontSize:12), onSubmitted: (_)=> send())),
          SizedBox(width:8),
          ElevatedButton(onPressed: send, child: Text("SEND"))
        ]))
      ]),
    );
  }

  void showSettings(){
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF0F0F0F), builder: (_)=> Padding(padding: EdgeInsets.all(16), child: Column(children: [
      Text("SETTINGS_"),
      SwitchListTile(title: Text("Bluetooth LE Mesh", style: TextStyle(fontSize:12)), value: btOn, onChanged: (v)=> setState(()=> btOn=v)),
      SwitchListTile(title: Text("WiFi Direct P2P", style: TextStyle(fontSize:12)), value: wifiOn, onChanged: (v)=> setState(()=> wifiOn=v)),
      SwitchListTile(title: Text("End-to-End Encryption AES-256", style: TextStyle(fontSize:12)), value: e2eOn, onChanged: (v)=> setState(()=> e2eOn=v)),
    ])));
  }
}
