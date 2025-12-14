import 'package:k_router/k_router.dart';

import 'book_location.dart';
import 'simple_location.dart';
import 'simple_multi_location.dart';
import 'simple_shell_location.dart';

export 'book_location.dart';
export 'simple_location.dart';
export 'simple_multi_location.dart';
export 'simple_shell_location.dart';


enum Locations with LocationDiscriminator {
  simple(LocationFunctionCodec(SimpleLocation.fromOptions)),
  simpleShell(LocationFunctionCodec(SimpleShellLocation.fromOptions)),
  simpleMulti(LocationFunctionCodec(SimpleMultiLocation.fromOptions)),
  book(LocationFunctionCodec(BookLocation.fromOptions))
  ;

  const Locations(this.codec);

  @override
  final LocationCodec<Object?> codec;
}
