import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttPage extends StatefulWidget {
  @override
  _MqttPageState createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  final String broker = 'broker.hivemq.com';
  final String clientId = 'clientId-Test';
  final int port = 8884;
  final String topic = 'test';
  late MqttServerClient client;
  String connectionState = "";

  String _message = "";
// Change this to your desired topic

  MqttServerClient? _client;

  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect() async {
    client = MqttServerClient('broker.hivemq.com', 'clientId-oWJTeX3iw8');
    client.port = 8884;
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.onUnsubscribed = (String? topic) {
      if (kDebugMode) {
        print('Unsubscribed: $topic');
      }
    };
    client.pongCallback = pong;
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('clientId-Test')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      if (kDebugMode) {
        print('Exception: $e');
      }
      client.disconnect();
    }
    client.subscribe('accidentdata', MqttQos.atLeastOnce);
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message);
      setState(() {
        _message = payload;
      });
    });
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  void onConnected() {
    setState(() {
      connectionState = "Connected";
    });
    if (kDebugMode) {
      print('Connected');
    }
  }

  void onDisconnected() {
    setState(() {
      connectionState = "Disconnected";
    });
    if (kDebugMode) {
      print('Disconnected');
    }
  }

  void onSubscribed(String topic) {
    if (kDebugMode) {
      print('Subscribed to $topic');
    }
  }

  void onSubscribeFail(String topic) {
    if (kDebugMode) {
      print('Failed to subscribe to $topic');
    }
  }

  void onUnsubscribed(String topic) {
    if (kDebugMode) {
      print('Unsubscribed from $topic');
    }
  }

  void pong() {
    if (kDebugMode) {
      print('Ping response client callback invoked');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MQTT Subscriber')),
      body: Center(
        child: Text('Listening for messages on topic "$topic"'),
      ),
    );
  }
}
