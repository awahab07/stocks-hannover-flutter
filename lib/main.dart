import 'dart:async';
import 'dart:math';

import 'package:stocks_hannover_flutter/data_adapter/dal.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:notifications/notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import './alerts/error_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Stocks Hannover'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Notifications? _notifications;
  StreamSubscription<NotificationEvent>? _subscription;

  // Data Access Layer
  final dal = DAL();

  int _counter = 0;
  bool _shouldForwardPin = true;
  int _numSentPins = 0;
  DateTime _lastForwarded = DateTime(0);

  @override
  void initState() {
    super.initState();
    _hydrateState();
  }

  @override
  Widget build(BuildContext context) {
    _listenNotifications();

    const _dividerHeight = 12.0;

    final listHPadding =
        Theme.of(context).listTileTheme.contentPadding?.horizontal ?? 16;
    final listVPadding =
        Theme.of(context).listTileTheme.contentPadding?.vertical ?? 16;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(children: [
              SizedBox(width: listHPadding, height: listVPadding),
              const Text(
                'You have pushed the button this many times:',
              ),
              const Spacer(),
              Text(
                '$_counter',
                style: labelStyle,
              ),
              SizedBox(width: listHPadding, height: listVPadding),
            ]),
            const Divider(height: _dividerHeight),
            Row(children: [
              SizedBox(width: listHPadding, height: listVPadding),
              const Text(
                'Number of times pin forwarded:',
              ),
              const Spacer(),
              Text(
                '$_numSentPins',
                style: labelStyle,
              ),
              SizedBox(width: listHPadding, height: listVPadding),
            ]),
            const Divider(height: _dividerHeight),
            Row(children: [
              SizedBox(width: listHPadding, height: listVPadding),
              const Text(
                'Last forwarded on:',
              ),
              const Spacer(),
              Text(
                timeago.format(_lastForwarded, locale: 'en-short'),
                style: labelStyle,
              ),
              SizedBox(width: listHPadding, height: listVPadding),
            ]),
            const Divider(height: _dividerHeight),
            SwitchListTile(
                title: const Text('Send Pin Code'),
                value: _shouldForwardPin,
                onChanged: (value) {
                  _updateState(shouldForwardPin: value);
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _listenNotifications() {
    _notifications = Notifications();
    try {
      _subscription = _notifications!.notificationStream!.listen(_onData);
    } on NotificationException catch (exception) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error listening notifications' + exception.message),
      ));
    } catch (exception) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error listening notifications' + exception.toString()),
      ));
    }
  }

  void _onData(NotificationEvent event) {
    if ((event.packageName?.contains('traderepublic') ?? false) &&
        (event.title?.contains('verification code') ?? false)) {
      _handlePinNotification(event);
    }

    // To update time
    setState(() {});
  }

  void _hydrateState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shouldForwardPin = (prefs.getBool('shf_shouldForwardPin') ?? true);
      _numSentPins = (prefs.getInt('shf_numSentPins') ?? 0);
    });
  }

  void _updateState(
      {bool? shouldForwardPin,
      int? numSentPins,
      DateTime? lastForwarded}) async {
    if (shouldForwardPin != null || numSentPins != null) {
      final prefs = await SharedPreferences.getInstance();
      final forwardPin = shouldForwardPin ?? _shouldForwardPin;
      final sentPin = numSentPins ?? _numSentPins;

      setState(() {
        _shouldForwardPin = forwardPin;
        _numSentPins = sentPin;
        _lastForwarded = lastForwarded ?? _lastForwarded;

        prefs.setBool('shf_shouldForwardPin', forwardPin);
        prefs.setInt('shf_numSentPins', sentPin);
      });
    } else if (lastForwarded != null) {
      setState(() {
        _lastForwarded = lastForwarded;
      });
    }
  }

  void _handlePinNotification(NotificationEvent event) {
    if (_shouldForwardPin) {
      final pin = event.title?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Captured PIN: $pin'),
      ));

      _forwardPin(pin);
    }
  }

  void _forwardPin(String pin) async {
    dal.writePin(pin);
    _updateState(numSentPins: ++_numSentPins, lastForwarded: DateTime.now());
  }
}
