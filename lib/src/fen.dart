import 'tools.dart';
import 'manual.dart';
import 'item.dart';
import 'pos.dart';

/// A snapshot of game
class ChessFen {
  /// Initialize chess layout
  static const initFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR';

  /// Initialize chess layout
  static const emptyFen = '4k4/9/9/9/9/9/9/9/9/4K4';

  /// for col index
  static const colIndexBase = 97; // 'a'

  /// map chinese chess to code
  static const nameMap = {
    '将': 'k',
    '帅': 'K',
    '士': 'a',
    '仕': 'A',
    '象': 'b',
    '相': 'B',
    '马': 'n',
    '车': 'r',
    '炮': 'c',
    '砲': 'C',
    '卒': 'p',
    '兵': 'P'
  };

  /// map red code to chinese
  static const nameRedMap = {
    'k': '帅',
    'a': '仕',
    'b': '相',
    'n': '马',
    'r': '车',
    'c': '砲',
    'p': '兵',
  };

  /// map black code to chinese
  static const nameBlackMap = {
    'k': '将',
    'a': '士',
    'b': '象',
    'n': '马',
    'r': '车',
    'c': '炮',
    'p': '卒',
  };

  /// col name of red team
  static const colRed = ['九', '八', '七', '六', '五', '四', '三', '二', '一'];

  /// chinese numbers
  static const replaceNumber = [
    '０',
    '１',
    '２',
    '３',
    '４',
    '５',
    '６',
    '７',
    '８',
    '９'
  ];

  /// black codes
  static const colBlack = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  /// for chinese move
  static const _nameIndex = ['一', '二', '三', '四', '五'];
  static const _stepIndex = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  static const _posIndex = ['前', '中', '后'];

  String _fen = '';
  late List<ChessFenRow> _rows;

  /// 推演变化
  final deductions = <ChessFen>[];

  /// Constructor by a fenstr
  ChessFen([String fenStr = initFen]) {
    if (fenStr.isEmpty) {
      fenStr = initFen;
    }
    fen = fenStr;
  }

  /// Get row
  ChessFenRow operator [](int key) {
    return _rows[key];
  }

  /// force refresh fenstr(usually after batch of moves)
  void clearFen() {
    _fen = '';
  }

  /// Set row
  operator []=(int key, ChessFenRow value) {
    _rows[key] = value;
    _fen = '';
  }

  /// get current fenstr
  String get fen {
    if (_fen.isEmpty) {
      _fen = _rows.reversed.join('/').replaceAllMapped(
            RegExp(r'0+'),
            (match) => match[0]!.length.toString(),
          );
    }
    return _fen;
  }

  /// Set a fen str TODO:Improve
  set fen(String fenStr) {
    if (fenStr.contains(' ')) {
      fenStr = fenStr.split(' ')[0];
    }
    _rows = fenStr
        .replaceAllMapped(
          RegExp(r'\d'),
          (match) => List<String>.filled(int.parse(match[0]!), '0').join(''),
        )
        .split('/')
        .reversed
        .map<ChessFenRow>((row) => ChessFenRow(row))
        .toList();
    _fen = fenStr;
  }

  /// A copy of current situation
  ChessFen copy() => ChessFen(fen);

  /// 创建当前局面下的子力位置
  ChessFen position() {
    int chr = 65;
    String fenStr = fen;
    String positionStr = fenStr.replaceAllMapped(
      RegExp(r'[^0-9\\/]'),
      (match) => String.fromCharCode(chr++),
    );
    // print(positionStr);
    return ChessFen(positionStr);
  }

  /// Move then change the game situation
  bool move(String move) {
    int fromX = move.codeUnitAt(0) - colIndexBase;
    int fromY = int.parse(move[1]);
    int toX = move.codeUnitAt(2) - colIndexBase;
    int toY = int.parse(move[3]);
    if (fromY > 9 || fromX > 8) {
      logger.info('From pos error:$move');
      return false;
    }
    if (toY > 9 || toX > 8) {
      logger.info('To pos error:$move');
      return false;
    }
    if (fromY == toY && fromX == toX) {
      logger.info('No movement:$move');
      return false;
    }
    if (_rows[fromY][fromX] == '0') {
      logger.info('From pos is empty:$move');
      return false;
    }
    _rows[toY][toX] = _rows[fromY][fromX];
    _rows[fromY][fromX] = '0';
    _fen = '';

    return true;
  }

  /// Get item from a [ChessPos]
  String itemAtPos(ChessPos pos) => _rows[pos.y][pos.x];

  /// Get piece at the string position code
  String itemAt(String pos) => itemAtPos(ChessPos.fromCode(pos));

  /// Whether there is a valid item at pos
  bool hasItemAt(ChessPos pos, {int team = -1}) {
    String item = _rows[pos.y][pos.x];
    if (item == '0') {
      return false;
    }
    if (team < 0) {
      return true;
    }
    if ((team == 0 && item.codeUnitAt(0) < ChessFen.colIndexBase) ||
        (team == 1 && item.codeUnitAt(0) >= ChessFen.colIndexBase)) {
      return true;
    }
    return false;
  }

  /// Find a chess by a type code
  ChessPos? find(String matchCode) {
    ChessPos? pos;
    int rowNumber = 0;
    _rows.any((row) {
      int start = row.indexOf(matchCode);
      if (start > -1) {
        pos = ChessPos(start, rowNumber);
        return true;
      }
      rowNumber++;
      return false;
    });
    return pos;
  }

  /// Find all chess of a type code
  List<ChessPos> findAll(String matchCode) {
    List<ChessPos> items = [];
    int rowNumber = 0;
    for (var row in _rows) {
      int start = row.indexOf(matchCode);
      while (start > -1) {
        items.add(ChessPos(start, rowNumber));
        start = row.indexOf(matchCode, start + 1);
      }
      rowNumber++;
    }
    return items;
  }

  /// Find item in a col
  List<ChessItem> findByCol(int col, [int? min, int? max]) {
    List<ChessItem> items = [];
    for (int i = min ?? 0; i <= (max ?? _rows.length - 1); i++) {
      if (_rows[i][col] != '0') {
        items.add(ChessItem(_rows[i][col], position: ChessPos(col, i)));
      }
    }
    return items;
  }

  /// Get all valid items of this situation
  List<ChessItem> getAll() {
    List<ChessItem> items = [];
    int rowNumber = 0;
    for (var row in _rows) {
      int start = 0;
      while (start < row._fenRow.length) {
        if (row[start] != '0') {
          items
              .add(ChessItem(row[start], position: ChessPos(start, rowNumber)));
        }
        start++;
      }

      rowNumber++;
    }
    return items;
  }

  /// Get item is dead
  String getDieChr() {
    String fullChrs = initFen.replaceAll(RegExp(r'[1-9/]'), '');
    String currentChrs = getAllChr();
    if (fullChrs.length > currentChrs.length) {
      currentChrs.split('').forEach((chr) {
        fullChrs = fullChrs.replaceFirst(chr, '');
      });
      return fullChrs;
    }

    return '';
  }

  /// Get all valid item code
  String getAllChr() {
    return fen.split('/').reversed.join('/').replaceAll(RegExp(r'[1-9/]'), '');
  }

  @override
  String toString() => fen;

  /// Sort pos
  int posSort(ChessPos key1, ChessPos key2) {
    if (key1.x > key2.x) {
      return -1;
    } else if (key1.x < key2.x) {
      return 1;
    }
    if (key1.y > key2.y) {
      return -1;
    } else if (key1.y < key2.y) {
      return 1;
    }
    return 0;
  }

  /// Translate a move to positional representation
  String toPositionString(int team, String move) {
    late String code;
    late String matchCode;
    int colIndex = -1;

    if (_nameIndex.contains(move[0]) || _posIndex.contains(move[0])) {
      code = nameMap[move[1]]!;
    } else {
      code = nameMap[move[0]]!;
      colIndex =
          team == 0 ? colRed.indexOf(move[1]) : colBlack.indexOf(move[1]);
    }
    code = code.toLowerCase();
    matchCode = team == 0 ? code.toUpperCase() : code;

    List<ChessPos> items = findAll(matchCode);

    ChessPos curItem;
    // 这种情况只能是小兵
    if (_nameIndex.contains(move[0])) {
      // 筛选出有同列的兵
      List<ChessPos> nItems = items
          .where(
            (item) => items.any((pawn) => pawn != item && pawn.x == item.x),
          )
          .toList();
      nItems.sort(posSort);
      colIndex = _nameIndex.indexOf(move[0]);
      curItem =
          team == 0 ? nItems[nItems.length - colIndex - 1] : nItems[colIndex];
      // 前中后
    } else if (_posIndex.contains(move[0])) {
      // 筛选出有同列的兵
      List<ChessPos> nItems = items
          .where(
            (item) => items.any((pawn) => pawn != item && pawn.x == item.x),
          )
          .toList();
      nItems.sort(posSort);
      if (nItems.length > 2) {
        colIndex = _posIndex.indexOf(move[0]);
        curItem =
            team == 0 ? nItems[nItems.length - colIndex - 1] : nItems[colIndex];
      } else {
        if ((team == 0 && move[0] == '前') || (team == 1 && move[0] == '后')) {
          curItem = nItems[0];
        } else {
          curItem = nItems[1];
        }
      }
    } else {
      colIndex =
          team == 0 ? colRed.indexOf(move[1]) : colBlack.indexOf(move[1]);

      List<ChessPos> nItems =
          items.where((item) => item.x == colIndex).toList();
      nItems.sort(posSort);

      if (nItems.length > 1) {
        if ((team == 0 && move[2] == '进') || (team == 1 && move[2] == '退')) {
          curItem = nItems[1];
        } else {
          curItem = nItems[0];
        }
      } else if (nItems.isNotEmpty) {
        curItem = nItems[0];
      } else {
        logger.info('招法加载错误 $team $move');
        return '';
      }
    }

    ChessPos nextItem = ChessPos(0, 0);
    if (['p', 'k', 'c', 'r'].contains(code)) {
      if (move[2] == '平') {
        nextItem.y = curItem.y;
        nextItem.x =
            team == 0 ? colRed.indexOf(move[3]) : colBlack.indexOf(move[3]);
      } else if ((team == 0 && move[2] == '进') ||
          (team == 1 && move[2] == '退')) {
        nextItem.x = curItem.x;
        nextItem.y = curItem.y +
            (team == 0 ? _stepIndex.indexOf(move[3]) : int.parse(move[3]));
      } else {
        nextItem.x = curItem.x;
        nextItem.y = curItem.y -
            (team == 0 ? _stepIndex.indexOf(move[3]) : int.parse(move[3]));
      }
    } else {
      nextItem.x =
          team == 0 ? colRed.indexOf(move[3]) : colBlack.indexOf(move[3]);
      if ((team == 0 && move[2] == '进') || (team == 1 && move[2] == '退')) {
        if (code == 'n') {
          if ((nextItem.x - curItem.x).abs() == 2) {
            nextItem.y = curItem.y + 1;
          } else {
            nextItem.y = curItem.y + 2;
          }
        } else {
          nextItem.y = curItem.y + (nextItem.x - curItem.x).abs();
        }
      } else {
        if (code == 'n') {
          if ((nextItem.x - curItem.x).abs() == 2) {
            nextItem.y = curItem.y - 1;
          } else {
            nextItem.y = curItem.y - 2;
          }
        } else {
          nextItem.y = curItem.y - (nextItem.x - curItem.x).abs();
        }
      }
    }

    return '${curItem.toCode()}${nextItem.toCode()}';
  }

  /// Result of chinese
  static String getChineseResult(String result) {
    switch (result) {
      case '1-0':
        return '先胜';
      case '0-1':
        return '先负';
      case '1/2-1/2':
        return '先和';
    }
    return '未知';
  }

  /// A list of moves to chinese
  List<String> toChineseTree(List<String> moves) {
    ChessFen start = copy();
    List<String> results = [];
    for (var move in moves) {
      results.add(start.toChineseString(move));
      start.move(move);
    }
    return results;
  }

  /// Translate a move to chinese
  String toChineseString(String move) {
    if (ChessManual.results.contains(move)) {
      return getChineseResult(move);
    }

    String chineseString;

    ChessPos posFrom = ChessPos.fromCode(move.substring(0, 2));
    ChessPos posTo = ChessPos.fromCode(move.substring(2, 4));

    // 找出子
    String matchCode = _rows[posFrom.y][posFrom.x];
    if (matchCode == '0') {
      logger.info('着法错误 $fen $move');
      return '';
    }
    int team = matchCode.codeUnitAt(0) < 'a'.codeUnitAt(0) ? 0 : 1;
    String code = matchCode.toLowerCase();

    // 子名
    String name = team == 0 ? nameRedMap[code]! : nameBlackMap[code]!;

    if (code == 'k' || code == 'a' || code == 'b') {
      chineseString =
          name + (team == 0 ? colRed[posFrom.x] : colBlack[posFrom.x]);
    } else {
      int colCount = 0;
      int rowNumber = 0;

      List<int> rowIndexs = [];

      for (var row in _rows) {
        if (row[posFrom.x] == matchCode) {
          colCount++;

          rowIndexs.add(rowNumber);
        }
        rowNumber++;
      }
      if (colCount > 3) {
        int idx = rowIndexs.indexOf(posFrom.y);
        // print([colCount, idx]);
        if (team == 0) {
          chineseString = _nameIndex[idx] + name;
        } else {
          chineseString = _nameIndex[rowIndexs.length - idx - 1] + name;
        }
      } else if (colCount > 2 || (colCount > 1 && code == 'p')) {
        // 找出所有的兵
        List<ChessPos> pawns = findAll(matchCode);

        // 筛选出有同列的兵
        List<ChessPos> nPawns = pawns
            .where(
              (item) => pawns.any((pawn) => (pawn != item && pawn.x == item.x)),
            )
            .toList();
        nPawns.sort(posSort);

        int idx = nPawns.indexOf(posFrom);
        if (nPawns.length == 2) {
          if (team == 0) {
            chineseString = (idx == 0 ? '前' : '后') + name;
          } else {
            chineseString = (idx == 1 ? '前' : '后') + name;
          }
        } else if (nPawns.length == 3) {
          if (idx == 1) {
            chineseString = '中$name';
          } else {
            if (team == 0) {
              chineseString = (idx == 0 ? '前' : '后') + name;
            } else {
              chineseString = (idx == 2 ? '前' : '后') + name;
            }
          }
        } else {
          if (team == 0) {
            chineseString = _nameIndex[idx] + name;
          } else {
            chineseString = _nameIndex[nPawns.length - idx - 1] + name;
          }
        }
      } else if (colCount > 1) {
        if (team == 0) {
          chineseString = (posFrom.y > rowIndexs[0] ? '前' : '后') + name;
        } else {
          chineseString = (posFrom.y < rowIndexs[1] ? '前' : '后') + name;
        }
      } else {
        chineseString =
            name + (team == 0 ? colRed[posFrom.x] : colBlack[posFrom.x]);
      }
    }
    if (posFrom.y == posTo.y) {
      chineseString += '平${team == 0 ? colRed[posTo.x] : colBlack[posTo.x]}';
    } else {
      if ((team == 0 && posFrom.y < posTo.y) ||
          (team == 1 && posFrom.y > posTo.y)) {
        chineseString += '进';
      } else {
        chineseString += '退';
      }
      if (['p', 'k', 'c', 'r'].contains(code)) {
        int step = (posFrom.y - posTo.y).abs();
        chineseString += team == 0 ? _stepIndex[step] : step.toString();
      } else {
        chineseString += team == 0 ? colRed[posTo.x] : colBlack[posTo.x];
      }
    }

    return chineseString;
  }
}

/// A row of game board
class ChessFenRow {
  String _fenRow;

  /// constructor by a row string
  ChessFenRow(this._fenRow);

  /// get code at key position
  String operator [](int key) {
    return _fenRow[key];
  }

  /// set code at key position
  operator []=(int key, String value) {
    _fenRow = _fenRow.replaceRange(key, key + 1, value);
  }

  /// find code index of this row
  int indexOf(String matchCode, [int start = 0]) {
    return _fenRow.indexOf(matchCode, start);
  }

  @override
  String toString() => _fenRow;
}
