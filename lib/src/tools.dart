import 'dart:developer';

import 'package:logging/logging.dart';

/// package log
final logger = Logger.root
  ..onRecord.listen((record) {
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
    logger.level = Level.OFF;
  }

  /// default to log info level
  static void openLog() {
    logger.level = Level.INFO;
  }

  /// set log level of cchess package
  static set logLevel(Level level) {
    logger.level = level;
  }
}
