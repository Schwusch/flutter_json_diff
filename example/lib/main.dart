import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_json_diff/flutter_json_diff.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus.unfocus();
          }
        },
        child: MaterialApp(
          theme:
              ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
          home: MyHomePage(),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final leftController = TextEditingController();
  final rightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JsonInputWidget(
                    title: 'left.json',
                    controller: leftController,
                  ),
                  JsonInputWidget(
                    title: 'right.json',
                    controller: rightController,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: leftController,
              builder: (_, __) => AnimatedBuilder(
                animation: rightController,
                builder: (_, __) {
                  Object left;
                  Object right;
                  try {
                    left = jsonDecode(leftController.text);
                    right = jsonDecode(rightController.text);
                  } catch(_) {
                    return Container();
                  }

                  return JsonDiffWidget(
                    indent: 32,
                    left: left,
                    right: right,
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class JsonInputWidget extends StatelessWidget {
  static final encoder = JsonEncoder.withIndent('  ');
  final TextEditingController controller;
  final String title;

  const JsonInputWidget({
    Key key,
    @required this.controller,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(title),
                ),
                RaisedButton(
                  child: Text('Format'),
                  onPressed: () {
                    try {
                      controller.text =
                          encoder.convert(jsonDecode(controller.text));
                    } catch (_) {}
                  },
                )
              ],
            ),
            TextFormField(
              autovalidate: true,
              decoration: InputDecoration(border: OutlineInputBorder()),
              controller: controller,
              maxLines: 10,
              validator: validateJson,
            ),
          ],
        ),
      );

  String validateJson(String value) {
    try {
      jsonDecode(value);
    } catch (e) {
      return e.toString();
    }
    return null;
  }
}
