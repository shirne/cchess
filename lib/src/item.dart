import 'fen.dart';
import 'pos.dart';

/// blank item code
const chessBlankCode = '0';

/// A chess item at game board
class ChessItem {
  final String _code;

  /// whether is dead
  bool isDie = false;

  /// position of this item
  ChessPos position;

  /// constructor a blank item
  ChessItem.blank({ChessPos? position})
      : this(chessBlankCode, position: position);

  /// constructor by a code and position
  ChessItem(String code, {ChessPos? position})
      : _code = code,
        position = position ?? ChessPos(0, 0);

  /// get team of this code
  int get team {
    if (isBlank) {
      return -1;
    }
    return _code.codeUnitAt(0) < ChessFen.colIndexBase ? 0 : 1;
  }

  /// get code of this item
  String get code => _code;

  /// is a black item
  bool get isBlank => isDie || _code == '0';

  @override
  String toString() => "$code@${position.toCode()}";
}
