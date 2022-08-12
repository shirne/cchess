import 'fen.dart';
import 'pos.dart';

/// A chess Item
class ChessItem {
  final String _code;
  bool isDie = false;
  ChessPos position;

  ChessItem(String code, {ChessPos? position})
      : _code = code,
        position = position ?? ChessPos(0, 0);

  int get team {
    if (isBlank) {
      return -1;
    }
    return _code.codeUnitAt(0) < ChessFen.colIndexBase ? 0 : 1;
  }

  String get code => _code;

  bool get isBlank => isDie || _code == '0';

  @override
  String toString() => "$code@${position.toCode()}";
}
