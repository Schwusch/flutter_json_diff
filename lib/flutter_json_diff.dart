library flutter_json_diff;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_diff/json_diff.dart';
import 'package:widget_arrows/arrows.dart';
import 'package:widget_arrows/widget_arrows.dart';

extension ScopingFunctions<T> on T {
  /// Calls the specified function [block] with `this` value
  /// as its argument and returns its result.
  R let<R>(R Function(T it) block) => block(this);

  /// Calls the specified function [block] with `this` value
  /// as its argument and returns `this` value.
  T also(void Function(T it) block) {
    block(this);
    return this;
  }
}

class JsonDiffWidget extends StatelessWidget {
  final dynamic left;
  final dynamic right;
  final DiffNode _diff;
  final int indent;

  JsonDiffWidget({Key key, this.left, this.right, this.indent})
      : _diff = JsonDiffer.fromJson(left, right).diff(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyText2;
    final removedStyle = theme.copyWith(
      decoration: TextDecoration.lineThrough,
      backgroundColor: Colors.red.withAlpha(100),
    );
    final addedStyle = theme.copyWith(
      backgroundColor: Colors.green.withAlpha(100),
    );
    final movedStyle = theme.copyWith(
      backgroundColor: Colors.yellow.withAlpha(100),
      color: theme.color.withAlpha(150),
    );
    final movedToStyle = theme.copyWith(
      color: theme.color.withAlpha(100),
    );
    return ArrowContainer(
      child: ListView(
        shrinkWrap: true,
        children: foo(_diff, left, right, indent, removedStyle, addedStyle, movedStyle,
            movedToStyle),
      ),
    );
  }
}

List<Widget> foo(
    DiffNode diff,
    dynamic leftJson,
    dynamic rightJson,
    int indent,
    TextStyle removedStyle,
    TextStyle addedStyle,
    TextStyle movedStyle,
    TextStyle movedToStyle) {
  final leftPad = (diff.path.length * indent).toDouble();
  final isList = leftJson is List && rightJson is List;

  final encoder = JsonEncoder.withIndent(' ' * indent);
  return [
    Padding(
      padding: EdgeInsets.only(left: leftPad.toDouble()),
      child: Text(isList ? '[' : '{'),
    ),
    if (isList)
      for (final key in List<int>.from(diff.keys)..sort()) ...[
        if (diff.added.containsKey(key))
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: ArrowElement(
              id: '${[...diff.path, key]}',
              child: Text(
                '$key: ${encoder.convert(diff.added[key])},',
                style: addedStyle,
              ),
            ),
          ),
        if (diff.removed.containsKey(key))
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: ArrowElement(
              id: '${[...diff.path, key]}',
              child: Text(
                '$key: ${encoder.convert(diff.removed[key])},',
                style: removedStyle,
              ),
            ),
          ),
        if (diff.changed.containsKey(key)) ...[
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: Text(
              '$key: ${encoder.convert(diff.changed[key].first)},',
              style: removedStyle,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: Text(
              '$key: ${encoder.convert(diff.changed[key].last)},',
              style: addedStyle,
            ),
          ),
        ],
        if (diff.moved.containsKey(key))
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: ArrowElement(
              id: '${[...diff.path, key]}',
              targetId: '${[...diff.path, diff.moved[key]]}',
              width: 2,
              padStart: 2,
              padEnd: 2,
              tipLength: 5,
              straights: false,
              flip: true,
              bow: 0.01 * (leftPad + indent),
              stretch: 0,
              arcDirection: ArcDirection.Left,
              child: RichText(
                text: TextSpan(
                  text: '$key: ',
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: '=> ${diff.moved[key]}',
                      style: movedStyle,
                    )
                  ],
                ),
              ),
            ),
          ),
        if (diff.moved.containsValue(key) && diff.onlyMoved(key))
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: ArrowElement(
              id: '${[...diff.path, key]}',
              child: Text(
                '${key}:',
                style: movedToStyle,
              ),
            ),
          ),
        if (diff.node.containsKey(key)) ...[
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: Text('$key: ${isList ? '[' : '{'}'),
          ),
          ...foo(diff.node[key], leftJson[key], rightJson[key], indent, removedStyle,
              addedStyle, movedStyle, movedToStyle),
          Padding(
            padding: EdgeInsets.only(left: leftPad + indent),
            child: Text('$key: ${isList ? ']' : '}'}'),
          ),
        ]
      ],
    Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Text(isList ? ']' : '}'),
    ),
  ];
}

extension on DiffNode {
  List<Object> get keys => {
        ...removed.keys.toSet(),
        ...added.keys.toSet(),
        ...changed.keys.toSet(),
        ...moved.keys.toSet(),
        ...moved.values.toSet(),
        ...node.keys.toSet(),
      }.toList();

  bool onlyMoved(Object value) =>
      !added.containsKey(value) &&
      !removed.containsKey(value) &&
      !changed.containsKey(value);
}
