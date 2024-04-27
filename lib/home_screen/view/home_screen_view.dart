import 'dart:convert';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:generic/configuration/view/configuration_view.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:vibration/vibration.dart';
import '../../services/secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MqttServerClient? _mqttClient;
  String payload = "";
  bool isLoading = false;
  String userTopic = "";
  String server = "";
  String clientId = "";
  String port = "";
  String screenTitle = "";
  String screenBody = "";
  String _message = "";
  String sound = "";
  String vibration = "";
  String connectionState = "Not Connected";
  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    getConnectionDetails();
  }

  getConnectionDetails() async {
    SecureStorage secureStorage = SecureStorage();
    userTopic = await secureStorage.readSecureData("topic");
    server = await secureStorage.readSecureData("server");
    clientId = await secureStorage.readSecureData("clientId");
    port = await secureStorage.readSecureData("port");
    setState(() {
      if (userTopic != "") {
        isLoading = true;
        _connectToMqtt();
      }
      print(userTopic);
      print(server);
      print(clientId);
      print(port);
    });
  }

  void _connectToMqtt() {
    _mqttClient = MqttServerClient.withPort(
        maxConnectionAttempts: 10, server, clientId, int.parse(port));
    _mqttClient!.logging(on: true);
    _mqttClient?.keepAlivePeriod = 20;

    _mqttClient!.onConnected = _onMqttConnected;
    _mqttClient!.onDisconnected = _onMqttDisconnected;
    _mqttClient!.connect();
  }

  void _onMqttConnected() {
    setState(() {
      connectionState = "Connected";
    });
    print('Connected to MQTT');
    _subscribeToMqtt();
  }

  void _onMqttDisconnected() {
    setState(() {
      connectionState = "Disconnected";
    });
    print('Disconnected from MQTT');
  }

  void _subscribeToMqtt() {
    _mqttClient!.subscribe(userTopic, MqttQos.exactlyOnce);
    _mqttClient!.updates!.listen(_onMqttMessageReceived);
  }

  void _onMqttMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    final String topic = messages[0].topic;
    final MqttPublishMessage message =
        messages[0].payload as MqttPublishMessage;
    payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);

    // Decode the received payload as JSON
    Map<String, dynamic> jsonData = jsonDecode(payload);
    String title = jsonData['title'];
    String body = jsonData['body'];
    setState(() {
      _message = payload;
      screenTitle = title;
      screenBody = body;
      AssetsAudioPlayer.newPlayer().open(
        Audio("assets/sinos.mp3"),
        autoStart: true,
        showNotification: true,
        playInBackground: PlayInBackground.enabled,
      );
      Vibration.vibrate(duration: 2000); // Vibrate for 500 milliseconds
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
            onPressed: () {
              getConnectionDetails();
              setState(() {
                screenTitle = "";
                screenBody = "";
              });
            },
            icon: const Icon(Icons.refresh)),
        title: const Text("Home"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Configuration(),
                    ));
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: screenTitle != "" && screenBody != ""
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Center(),
                Image.asset("assets/iot.png"),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Text(
                        screenTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 30.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 100, 0, 0),
                  width: MediaQuery.of(context).size.width - 40,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Message",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(height: 4.0),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          screenBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            screenTitle = "";
                            screenBody = "";
                          });
                        },
                        child: const Text("Clear"))
                  ],
                ),
                const Spacer(),
                const Divider(),
                Text(
                  "Connection Status : $connectionState",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            )
          : connectionState == "Connected"
              ? Column(
                  children: [
                    Image.asset("assets/iot.png"),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          50, MediaQuery.of(context).size.height / 4, 0, 0),
                      child: const Row(
                        children: [
                          Text(
                            "Waiting for MQTT server",
                            style: TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            width: 30,
                          ),
                          CircularProgressIndicator()
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    Text(
                      "Connection Status : $connectionState",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Image.asset("assets/iot.png"),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          0, MediaQuery.of(context).size.height / 4, 0, 0),
                      child: const Text(
                        "Please click on Settings Icon on the top right, to visit the configuration page to set up the MQTT server",
                        style: TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    Text(
                      "Connection Status : $connectionState",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
    );
  }
}
