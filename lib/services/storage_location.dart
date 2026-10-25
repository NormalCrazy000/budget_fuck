import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The directory where Hive stores the app data.
///
/// - Android/iOS: the app's private documents directory, the same one used
///   by `Hive.initFlutter()` in earlier versions (existing data stays put).
/// - Desktop: the system "application data" directory instead of the user's
///   Documents folder (e.g. on Linux `~/.local/share/<application id>`).
///
/// Must not be called on the web, where Hive does not use the file system.
Future<String> appStorageDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }
  return (await getApplicationSupportDirectory()).path;
}
