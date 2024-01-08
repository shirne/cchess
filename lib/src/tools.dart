import 'dart:developer';

import 'package:logging/logging.dart';

/// override logger level
Level loggerLevel = Level.ALL;

/// package log
final logger = Logger('CCHESS')
  ..onRecord.listen((record) {
    if (loggerLevel.value > record.level.value) {
      return;
    }
    log(
      record.message,
      time: record.time,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
      sequenceNumber: record.sequenceNumber,
    );
  });

/// control package
class CChess {
  /// close log of cchess package
  static void closeLog() {
    loggerLevel = Level.OFF;
  }

  /// default to log info level
  static void openLog() {
    loggerLevel = Level.INFO;
  }

  /// set log level of cchess package
  static set logLevel(Level level) {
    loggerLevel = level;
  }
}
