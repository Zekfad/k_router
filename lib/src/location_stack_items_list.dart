import 'dart:collection';
import 'package:meta/meta.dart';

import 'location_stack.dart';
import 'location_stack_item.dart';


@internal
final class LocationStackItemsList extends LinkedList<LocationStackItem> {
  @internal
  LocationStackItemsList();

  late LocationStack stack;
}
