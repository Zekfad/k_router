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
        const PushBookButton(),
        CupertinoButton(
          child: const Text('Replace book'),
          onPressed: () {
            KNavigator.of(context).replaceLocation(BookLocation(120));
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
        const PushShellButton(),
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


class PushBookButton extends StatefulWidget {
  const PushBookButton({super.key});

  @override
  State<PushBookButton> createState() => _PushBookButtonState();
}

class _PushBookButtonState extends State<PushBookButton> with RestorationMixin {
  late RestorableLocationFuture<String> _bookLocation;

  static final random = Random();

  @override
  String get restorationId => 'push_book';
  
  @override
  void initState() {
    super.initState();
    _bookLocation = RestorableLocationFuture(
      onPresent: (navigator, arguments) =>
        navigator.pushLocation(BookLocation(arguments! as int)),
      onComplete: (result) {
        print('Book push result: $result');
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_bookLocation, 'location');
  }

  @override
  void dispose() {
    _bookLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    CupertinoButton(
      child: const Text('Push book'),
      onPressed: () => _bookLocation.present(10 + random.nextInt(10)),
    );
}


class PushShellButton extends StatefulWidget {
  const PushShellButton({super.key});

  @override
  State<PushShellButton> createState() => _PushShellButtonState();
}

class _PushShellButtonState extends State<PushShellButton> with RestorationMixin {
  late RestorableLocationFuture<Object?> _shellLocation;

  static final random = Random();

  @override
  String get restorationId => 'push_shell';
  
  @override
  void initState() {
    super.initState();
    _shellLocation = RestorableLocationFuture(
      onPresent: (navigator, arguments) =>
        navigator.pushLocation<Object?>(SimpleShellLocation(uri: Uri.parse('/shell'), title: arguments! as String)),
      onComplete: (result) {
        print('Shell push result: $result');
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_shellLocation, 'location');
  }

  @override
  void dispose() {
    _shellLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    CupertinoButton(
      child: const Text('Push shell'),
      onPressed: () => _shellLocation.present('Shell ${random.nextInt(10)}'),
    );
}
