// Example file
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:k_router/k_router.dart';

import 'locations/locations.dart';


/// Random counter to show when parts are rebuilt.
final rnd = Random(1337);

Widget pageContentBuilder(BuildContext context, BaseLocation location) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('Hero tag for force back button: back_${KNavigator.of(context).heroPrefixFor(location, allowCrossBorders: false)}'),
    Text(location.runtimeType.toString()),
    Wrap(
      children: [
        Hero(
          tag: 'back_${KNavigator.of(context).heroPrefixFor(location, allowCrossBorders: false)}',
          child: CupertinoButton(
            child: const Text('< Force back'),
            onPressed: () {
              KNavigator.of(context).forcePop('test');
            },
          ),
        ),
        CupertinoButton(
          child: Text('< Back | ${rnd.nextInt(10000)}'),
          onPressed: () async {
            await KNavigator.of(context).maybePop('test');
          },
        ),
        CupertinoButton(
          child: const Text('Update Uri'),
          onPressed: () {
            location.uri = location.uri.replace(query: 'test${rnd.nextInt(10000)}}');
          },
        ),
      ],
    ),
    Wrap(
      children: [
        CupertinoButton(
          child: const Text('Push book'),
          onPressed: () async {
            final result = await KNavigator.of(context).pushLocation(BookLocation(90));
            print('Pushed book result: $result');
          },
        ),
        CupertinoButton(
          child: const Text('Replace book'),
          onPressed: () async {
            final result = await KNavigator.of(context).replaceLocation(BookLocation(120));
            print('Replaced with book result: $result');
          },
        ),
        CupertinoButton(
          child: const Text('Push normal'),
          onPressed: () {
            KNavigator.of(context).pushLocation(
              SimpleLocation(uri: Uri.parse('/normal'), title: 'Normal'),
            );
          },
        ),
        CupertinoButton(
          child: const Text('Push shell'),
          onPressed: () {
            KNavigator.of(context).pushLocation(
              SimpleShellLocation(uri: Uri.parse('/shell'), title: 'Shell'),
            );
          },
        ),
        CupertinoButton(
          child: const Text('Push multi'),
          onPressed: () {
            KNavigator.of(context).pushLocation(
              SimpleMultiLocation(uri: Uri.parse('/multi'), title: 'Multi'),
            );
          },
        ),
        const CupertinoTextField(
          placeholder: 'Restorable textfield',
          restorationId: 'text',
        ),
      ],
    ),
  ],
);
