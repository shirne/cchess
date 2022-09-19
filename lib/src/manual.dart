import 'tools.dart';
import 'fen.dart';
import 'item.dart';
import 'pos.dart';
import 'rule.dart';
import 'step.dart';

/// All infomations of a chess game
class ChessManual {
  /// full game start fenstr
  static const startFen = '${ChessFen.initFen} w - - 0 1';

  /// red win result
  static const resultFstWin = '1-0';

  /// red loose result
  static const resultFstLoose = '0-1';

  /// draw result
  static const resultFstDraw = '1/2-1/2';

  /// have no result
  static const resultUnknown = '*';

  /// all result list
  static const results = [
    resultFstWin,
    resultFstLoose,
    resultFstDraw,
    resultUnknown
  ];

  /// 游戏类型
  String game = 'Chinese Chess';

  /// 比赛名
  String event = '';
  // EventDate、EventSponsor、Section、Stage、Board、Time

  /// 比赛地点
  String site = '';

  /// 比赛日期，格式统一为“yyyy.mm.dd”
  String date = '';

  /// 比赛轮次
  String round = '';

  /// 红方棋手
  String red = '';

  /// red team
  String redTeam = '';

  // RedTitle、RedElo、RedType

  /// 别名
  String get redNA => redTeam;

  /// set read team name
  set redNA(String value) {
    redTeam = value;
  }

  /// 黑方棋手
  String black = '';

  /// black team
  String blackTeam = '';

  /// 比赛结果 1-0 0-1 1/2-1/2 *
  String result = '*';

  /// result in chinese
  String get chineseResult => ChessFen.getChineseResult(result);

  /// 开局
  String opening = '';

  /// 变例
  String variation = '';

  /// 开局编号
  String ecco = '';

  /// 开始局面
  String fen = '';

  /// 开局方
  int startHand = 0;

  /// 子力位置图
  late ChessFen fenPosition;

  /// 当前
  late ChessFen currentFen;

  /// 记谱方法 Chinese(中文纵线格式)、WXF(WXF纵线格式)和ICCS(ICCS坐标格式)
  String format = 'Chinese';

  /// 时限
  String timeControl = '';

  /// 结论
  String termination = '';
  // Annotator、Mode、PlyCount

  /// 着法
  final _moves = <ChessStep>[];
  int _step = -1;

  /// 获取所有招法记录
  List<ChessStep> get moves => _moves;

  /// 是否最后一步
  bool get isLast => _step == _moves.length - 1;

  /// Current step index
  int get currentStep => _step + 1;

  /// Move counts
  int get moveCount => _moves.length;

  /// The current move
  ChessStep? get currentMove =>
      (_moves.isEmpty || _step < 0) ? null : _moves[_step];

  /// The last move
  ChessStep? get lastMove => _moves.isEmpty ? null : _moves.last;

  /// constructor of a chess game
  ChessManual({
    this.fen = startFen,
    this.red = 'Red',
    this.black = 'Black',
    this.redTeam = 'RedTeam',
    this.blackTeam = 'BlackTeam',
    this.event = '',
    this.site = '',
    this.date = '',
    this.round = '1',
    this.ecco = '',
    this.timeControl = '',
  }) {
    initFen(fen);
  }

  /// 默认开局资料
  void initDefault() {
    fen = startFen;
    red = 'Red';
    black = 'Black';
    redTeam = 'RedTeam';
    blackTeam = 'BlackTeam';
    event = '';
    site = '';
    date = '';
    round = '1';
    ecco = '';
    timeControl = '';
    //currentFen = null;
    //fenPosition = null;
  }

  /// 初始化棋局
  void initFen(String fenStr) {
    List<String> fenParts = fenStr.split(' ');
    currentFen = ChessFen(fenParts[0]);
    fenPosition = currentFen.position();
    if (fenParts.length > 1) {
      if (fenParts[1] == 'b' || fenParts[1] == 'B') {
        startHand = 1;
      } else {
        startHand = 0;
      }
    }
    logger.info('clear items');
    _items = [];
  }

  /// load from a pgn format string
  ChessManual.load(String content) {
    int idx = 0;
    String line = '';
    String description = '';
    content = content.replaceAllMapped(
      RegExp('[${ChessFen.replaceNumber.join('')}]'),
      (match) => ChessFen.replaceNumber.indexOf(match[0]!).toString(),
    );
    bool isInit = false;
    logger.info(content);
    while (true) {
      String chr = content[idx];
      switch (chr) {
        case '[':
          int endIdx = content.indexOf(']', idx);
          if (endIdx > idx) {
            line = content.substring(idx + 1, endIdx - 1);
            List<String> parts = line.trim().split(RegExp(r'\s+'));
            String value = parts[1].trim();
            if (value[0] == '"') {
              int lastIndex = value.lastIndexOf('"');
              value = value.substring(1, lastIndex > 1 ? lastIndex - 1 : null);
            }
            switch (parts[0].toLowerCase()) {
              case 'game':
                game = value;
                break;
              case 'event':
                event = value;
                break;
              case 'site':
                site = value;
                break;
              case 'date':
                date = value;
                break;
              case 'round':
                round = value;
                break;
              case 'red':
                red = value;
                break;
              case 'redteam':
                redTeam = value;
                break;
              case 'black':
                black = value;
                break;
              case 'blackteam':
                blackTeam = value;
                break;
              case 'result':
                result = value;
                break;
              case 'opening':
                opening = value;
                break;
              case 'variation':
                variation = value;
                break;
              case 'ecco':
                ecco = value;
                break;
              case 'fen':
                fen = value;
                isInit = true;
                initFen(fen);
                break;
              case 'format':
                format = value;
                break;
              case 'timecontrol':
                timeControl = value;
                break;
              case 'termination':
                termination = value;
                break;
            }
          } else {
            logger.info('Analysis pgn failed at $idx');
            break;
          }
          line = '';
          idx = endIdx + 1;
          break;
        case '{':
          int endIdx = content.indexOf('}');
          description = content.substring(idx + 1, endIdx - 1);
          idx = endIdx + 1;
          break;
        case ' ':
        case '\t':
        case '\n':
        case '\r':
          if (line.isNotEmpty) {
            if (line.endsWith('.')) {
              // step = int.tryParse(line.substring(0, line.length - 2)) ?? 0;
              line = '';
            } else {
              addMove(line, description: description);
              description = '';
              line = '';
            }
          }
          break;
        // 这几个当作结尾注释吧
        case '=':
          return;
        default:
          line += chr;
          if (!isInit) {
            isInit = true;
            if (fen.isEmpty) {
              fen = startFen;
            }
            initFen(fen);
          }
      }

      idx++;
      if (idx >= content.length) {
        if (line.isNotEmpty) {
          addMove(line, description: description);
        }
        break;
      }
    }
    logger.info(_moves);
  }

  /// export to a pgn format
  String export() {
    List<String> lines = [];
    lines.add('[Game "$game"]');
    lines.add('[Event "$event"]');
    lines.add('[Round "$round"]');
    lines.add('[Date "$date"]');
    lines.add('[Site "$site"]');
    lines.add('[RedTeam "$redTeam"]');
    lines.add('[Red "$red"]');
    lines.add('[BlackTeam "$blackTeam"]');
    lines.add('[Black "$black"]');
    lines.add('[Result "$result"]');
    lines.add('[ECCO "$ecco"]');
    lines.add('[Opening "$opening"]');
    lines.add('[Variation "$variation"]');
    if (fen != startFen && fen != ChessFen.initFen) {
      lines.add('[FEN "$fen"]');
    }

    for (int myStep = 0; myStep < _moves.length; myStep += 2) {
      lines.add('${(myStep ~/ 2) + 1}. ${_moves[myStep].toChineseString()} '
          '${myStep < _moves.length - 1 ? _moves[myStep + 1].toChineseString() : result}');
    }
    if (_moves.length % 2 == 0) {
      lines.add(result);
    }

    lines.add('=========================');
    lines.add('中国象棋 (https://www.shirne.com/demo/chinesechess/)');
    return lines.join("\n");
  }

  /// track to history
  void loadHistory(int index) {
    if (index < 1) {
      currentFen.fen = fen.split(' ')[0];
      fenPosition = currentFen.position();
    } else {
      currentFen.fen = _moves[index - 1].fen;
      fenPosition.fen = _moves[index - 1].fenPosition;
      doMove(_moves[index - 1].move);
    }
    _step = index;
  }

  /// set init fenstr
  void setFen(String fenStr) {
    ChessFen startFen = ChessFen(fen);
    String initChrs = startFen.getAllChr();
    String initPositions = startFen.position().getAllChr();

    currentFen.fen = fenStr;
    fenPosition.fen = currentFen.fen.replaceAllMapped(
      RegExp(r'[^0-9\\/]'),
      (match) {
        String chr = initPositions[initChrs.indexOf(match[0]!)];
        initChrs = initChrs.replaceFirst(match[0]!, '0');
        return chr;
      },
    );
  }

  /// 设置某个位置，设置为空必真，设置为子会根据初始局面查找当前没在局面中的子的位置，未查找到会设置失败
  bool setItem(ChessPos pos, String chr) {
    String posChr = '0';
    if (chr != '0') {
      ChessFen startFen = ChessFen(fen);
      String initChrs = startFen.getAllChr();
      String initPositions = startFen.position().getAllChr();

      String positions = fenPosition.getAllChr();

      int index = initChrs.indexOf(chr);
      while (index > -1) {
        String curPosChr = initPositions[index];
        if (!positions.contains(curPosChr)) {
          posChr = curPosChr;
          break;
        }
        index = initChrs.indexOf(chr, index + 1);
      }
      if (posChr == '0') {
        return false;
      }
    }
    currentFen[pos.y][pos.x] = chr;
    fenPosition[pos.y][pos.x] = posChr;
    currentFen.clearFen();
    fenPosition.clearFen();
    _items = [];
    return true;
  }

  /// move
  void doMove(String move) {
    currentFen.move(move);
    fenPosition.move(move);
  }

  /// if not at end
  bool get hasNext => _step < _moves.length;

  /// go to next step
  String next() {
    if (_step < _moves.length) {
      _step++;
      String move = _moves[_step - 1].move;
      String result = currentFen.toChineseString(move);
      doMove(move);
      return result;
    } else {
      return ChessFen.getChineseResult(result);
    }
  }

  List<ChessItem> _items = [];

  /// 获取棋谱中所有子力
  List<ChessItem> getChessItems() {
    ChessFen startFen = ChessFen(fen);

    if (_items.isEmpty) {
      _items = startFen.getAll();
    }

    // 初始位置编码
    String initPositions = startFen.position().getAllChr();
    // 当前位置编码
    String positions = fenPosition.getAllChr();
    int index = 0;

    for (var item in _items) {
      // 当前子对应的初始序号
      String chr = initPositions[index];
      // 序号当前的位置
      int newIndex = positions.indexOf(chr);

      if (newIndex > -1) {
        // print('${item.code}@${item.position.toCode()}: $chr @ $index => $newIndex');
        item.position = fenPosition.find(chr)!;
        item.isDie = false;
      } else {
        item.isDie = true;
      }
      index++;
    }

    return _items;
  }

  /// 获取当前招法
  ChessStep? getMove() {
    if (_step < 1) return null;
    if (_step > _moves.length) return null;
    return _moves[_step - 1];
  }

  /// 清除所有或部分记录
  void clearMove([int fromStep = 0]) {
    if (fromStep < 1) {
      _moves.clear();
    } else {
      _moves.removeRange(fromStep, _moves.length);
    }
    logger.info('Clear moves $fromStep $_moves');
  }

  /// 记录中增加多步棋
  void addMoves(List<String> moves) {
    for (var move in moves) {
      addMove(move);
    }
  }

  /// 记录中增加一步棋
  void addMove(String move, {String description = '', int addStep = -1}) {
    if (results.contains(move)) {
      result = move;
    } else {
      if (addStep > -1) {
        clearMove(addStep);
      }
      int team = _moves.length % 2;

      // TODO 自动解析所有格式
      if (isChineseMove(move)) {
        move = currentFen.toPositionString(team, move);
      }
      final origFen = currentFen.copy();

      doMove(move);
      _moves.add(
        ChessStep(
          team,
          move,
          code: origFen.itemAt(move),
          description: description,
          round: (_moves.length ~/ 2) + 1,
          fen: origFen.fen,
          fenPosition: fenPosition.fen,
          isEat: origFen.hasItemAt(ChessPos.fromCode(move.substring(2, 4))),
          isCheckMate: ChessRule(currentFen).isCheck(team == 1 ? 0 : 1),
        ),
      );

      _step = _moves.length - 1;
    }
  }

  /// 获取循环回合数
  int repeatRound() {
    int rewind = _step - 1;
    int round = 0;

    while (rewind > 1) {
      if (_moves[rewind].fen == _moves[rewind - 1].fen &&
          _moves[rewind].move == _moves[rewind - 1].move) {
        round++;
      } else {
        break;
      }
      rewind -= 2;
    }
    return round;
  }

  /// is a move in chess code
  static bool isNumberMove(String move) {
    return RegExp(r'[abcrnkpABCRNKP][0-9a-e][+\-\.][0-9]').hasMatch(move);
  }

  /// Is position move
  /// is a move in position
  static bool isPosMove(String move) {
    return RegExp(r'[a-iA-I][0-9]-?[a-iA-I][0-9]').hasMatch(move);
  }

  /// is a move in chinese
  static bool isChineseMove(String move) {
    return !isNumberMove(move) && !isPosMove(move);
  }
}
