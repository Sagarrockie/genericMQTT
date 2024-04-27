import 'package:flutter/material.dart';
import 'package:generic/home_screen/view/home_screen_view.dart';

import '../../services/secure_storage.dart';

class Configuration extends StatefulWidget {
  const Configuration({super.key});

  @override
  ConfigurationState createState() => ConfigurationState();
}

class ConfigurationState extends State<Configuration> {
  String topic = "";
  String server = "";
  String clientId = "";
  String port = "";
  TextEditingController topicController = TextEditingController();
  TextEditingController serverController = TextEditingController();
  TextEditingController clientIdController = TextEditingController();
  TextEditingController portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getConnectionDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Configuration'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: serverController,
                decoration: const InputDecoration(labelText: 'Server'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: clientIdController,
                decoration: const InputDecoration(labelText: 'Client Id'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  saveData();
                },
                child: const Text('Save & Connect'),
              ),
              SizedBox(height: 30),
              Image.asset("assets/iott.jpeg")
            ],
          ),
        ),
      ),
    );
  }

  getConnectionDetails() async {
    SecureStorage secureStorage = SecureStorage();
    topic = await secureStorage.readSecureData("topic");
    server = await secureStorage.readSecureData("server");
    clientId = await secureStorage.readSecureData("clientId");
    port = await secureStorage.readSecureData("port");
    setState(() {
      topicController.text = topic;
      serverController.text = server;
      clientIdController.text = clientId;
      portController.text = port;
    });
  }

  Future<void> saveData() async {
    SecureStorage secureStorage = SecureStorage();
    await secureStorage.writeSecureData('topic', topicController.text);
    await secureStorage.writeSecureData('server', serverController.text);
    await secureStorage.writeSecureData('clientId', clientIdController.text);
    await secureStorage.writeSecureData('port', portController.text);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ));
  }
}
