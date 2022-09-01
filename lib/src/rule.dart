import 'fen.dart';
import 'item.dart';
import 'pos.dart';

/// Rule validator 行棋规则
class ChessRule {
  /// 棋子初始权重
  static const chessWeight = {
    'k': 99,
    'r': 19,
    'n': 8,
    'c': 8,
    'a': 2,
    'b': 2,
    'p': 1
  };

  /// current fenstr
  ChessFen fen;

  /// constructor of a validator
  ChessRule(this.fen);

  /// constructor of a validator
  ChessRule.fromFen([String fenStr = ChessFen.initFen])
      : fen = ChessFen(fenStr);

  /// Weight of a chess (Experimental nature)
  int getChessWeight(ChessPos pos) {
    String chess = fen[pos.y][pos.x];
    if (chess == '0') return 0;
    int weight = chessWeight[chess.toLowerCase()]!;

    int chessCount = fen.getAllChr().length;
    ChessPos kPos =
        fen.find(chess.codeUnitAt(0) > ChessFen.colIndexBase ? 'K' : 'k')!;

    // 开局，中局炮价值增加
    if (chess == 'c' || chess == 'C') {
      if (chessCount > 25) {
        weight = (weight * 1.5).toInt();
      }

      // 炮和将一线权重翻倍
      if (kPos.y == pos.y || kPos.x == pos.x) {
        weight = weight * 2;
      }
    }

    // 残局 马价值增加
    if (chess == 'n' || chess == 'N') {
      if (chessCount < 15) {
        weight = (weight * 1.5).toInt();
      }
    }

    // 兵过河价值翻倍，接近9宫3倍，占宫4倍
    if (chess == 'p') {
      if (pos.y < 5) {
        weight *= 2;
        if (pos.y < 4 && pos.x > 1 && pos.x < 8) {
          weight *= 2;
          if (pos.y < 3 && pos.x > 2 && pos.x < 7) {
            weight *= 2;
          }
        }
      }
    } else if (chess == 'P') {
      if (pos.y > 4) {
        weight *= 2;
        if (pos.y > 5 && pos.x > 1 && pos.x < 8) {
          weight *= 2;
          if (pos.y > 6 && pos.x > 2 && pos.x < 7) {
            weight *= 2;
          }
        }
      }
    }

    return weight;
  }

  /// is trapped 是否困毙
  bool isTrapped(int team) {
    List<ChessItem> pieces = fen.getAll();
    return !pieces.any((item) {
      if (item.team == team) {
        List<String> points = movePoints(item.position);
        return points.any((point) {
          ChessRule rule = ChessRule(fen.copy());
          rule.fen.move(item.position.toCode() + point);
          if (rule.isKingMeet(team)) {
            return false;
          }
          if (rule.isCheck(team)) {
            return false;
          }
          return true;
        });
      }
      return false;
    });
  }

  /// Can the deadlock be solved 是否可以解杀
  bool canParryKill(int team) {
    ChessPos? kPos = fen.find(team == 0 ? 'K' : 'k');
    if (kPos == null) {
      // 老将没了
      return false;
    }

    List<ChessItem> pieces = fen.getAll();

    return pieces.any((item) {
      if (item.team == team) {
        List<String> points = movePoints(item.position);
        return points.any((point) {
          ChessRule rule = ChessRule(fen.copy());
          rule.fen.move(item.position.toCode() + point);
          if (rule.isKingMeet(team)) {
            return false;
          }
          if (rule.isCheck(team)) {
            return false;
          }
          // print('$item $point');
          return true;
        });
      }
      return false;
    });
  }

  /// is king meet 老将是否照面
  bool isKingMeet(int team) {
    ChessPos? kPos = fen.find(team == 0 ? 'K' : 'k');
    if (kPos == null) {
      // 老将没了
      return true;
    }

    // 是否与对方老将同列，并且中间无子
    ChessPos? enemyKing = fen.find(team == 0 ? 'k' : 'K');
    if (enemyKing != null && kPos.x == enemyKing.x) {
      final isMax = enemyKing.y > kPos.y;
      List<ChessItem> items = fen.findByCol(
        kPos.x,
        isMax ? kPos.y : enemyKing.y,
        isMax ? enemyKing.y : kPos.y,
      );

      // 原则上没有小于2的情况，这里统一按照面计算
      if (items.length <= 2) {
        return true;
      }
    }
    return false;
  }

  /// whether the team `team` can do checkmate 检查方是否能将军
  bool teamCanCheck(int team) {
    return fen
        .getAll()
        .any((item) => item.team == team && itemCanCheck(item.position, team));
  }

  /// 检查某个子是否能将军
  bool itemCanCheck(ChessPos pos, int team) {
    ChessPos? kPos = fen.find(team == 0 ? 'k' : 'K');
    if (kPos == null) return true;
    List<String> points = movePoints(pos, kPos);
    return points.any((point) {
      ChessFen newFen = fen.copy();
      newFen.move(pos.toCode() + point);
      return ChessRule(newFen).isCheck(team == 0 ? 1 : 0);
    });
  }

  /// is checkmate and deadlock 检查是否被将死
  bool isCheckMate(int team) {
    return (isCheck(team) && !canParryKill(team)) || isTrapped(team);
  }

  /// is checkmate 检查是否被将军
  bool isCheck(int team) {
    ChessPos? kPos = fen.find(team == 0 ? 'K' : 'k');
    if (kPos == null) {
      // 老将没了
      return true;
    }

    List<ChessItem> pieces = fen.getAll();

    return pieces.any((item) {
      if (item.team != team &&
          !['K', 'k', 'A', 'a', 'B', 'b'].contains(item.code)) {
        // 这里传入目标位置，返回的可行点有针对性
        List<String> points = movePoints(item.position, kPos);
        if (points.contains(kPos.toCode())) {
          // print('$item $kPos');
          return true;
        }
      }
      return false;
    });
  }

  /// 获取某个位置的根数
  int rootCount(ChessPos pos, int team) {
    ChessFen cFen = fen.copy();
    String chess = cFen[pos.y][pos.x];
    if (chess == '0' ||
        (chess.codeUnitAt(0) < ChessFen.colIndexBase && team == 0) ||
        (chess.codeUnitAt(0) >= ChessFen.colIndexBase && team == 1)) {
      cFen[pos.y][pos.x] = team == 0 ? 'p' : 'P';
      cFen.clearFen();
    }

    List<ChessItem> items = cFen.getAll();
    return items
        .where(
          (item) =>
              item.position != pos &&
              item.team == team &&
              ChessRule(cFen)
                  .movePoints(item.position, pos)
                  .contains(pos.toCode()),
        )
        .length;
  }

  /// 位置权重
  int positionWeight(ChessPos pos) {
    String item = fen[pos.y][pos.x];
    List<String> points = movePoints(pos);
    int team = item.codeUnitAt(0) < ChessFen.colIndexBase ? 0 : 1;
    int weight = 0;
    for (var point in points) {
      ChessPos cPos = ChessPos.fromCode(point);
      String code = fen[cPos.y][cPos.x];
      if ((team == 0 && code == 'K') || (team == 1 && code == 'k')) {
      } else if (code != '0') {
        if (code == 'p') {
          if (cPos.y < 5) {
            code = 'p+';
            if (cPos.y < 3 && cPos.x > 2 && cPos.x < 7) {
              code = 'p++';
            }
          }
        } else if (code == 'P') {
          if (cPos.y > 4) {
            code = 'P+';
            if (cPos.y > 6 && cPos.x > 2 && cPos.x < 7) {
              code = 'P++';
            }
          }
        }
        weight += chessWeight[code.toLowerCase()]!;
      }
    }
    return weight;
  }

  /// 获取要被吃的子，无根，或者吃子者权重低， 不含老将
  List<ChessItem> getBeEatenList(int team) {
    List<ChessItem> items = [];
    List<ChessItem> pieces = fen.getAll();
    int eTeam = team == 0 ? 1 : 0;
    for (var item in pieces) {
      if (item.team == team && !['K', 'k'].contains(item.code)) {
        int rc = rootCount(item.position, team);
        int erc = rootCount(item.position, eTeam);
        if (rc == 0 && erc > 0) {
          items.add(item);
        } else {
          List<ChessItem> canEatMe = getBeEatList(item.position);
          for (ChessItem eItem in canEatMe) {
            if (chessWeight[eItem.code.toLowerCase()]! <
                chessWeight[item.code.toLowerCase()]!) {
              items.add(item);
              break;
            }
          }
        }
      }
    }
    items.sort(
      (a, b) => chessWeight[b.code.toLowerCase()]!
          .compareTo(chessWeight[a.code.toLowerCase()]!),
    );
    return items;
  }

  /// 获取能吃的子的列表
  List<ChessItem> getEatList(ChessPos pos) {
    List<String> moves = movePoints(pos);
    List<ChessItem> items = [];
    for (var move in moves) {
      ChessPos toPos = ChessPos.fromCode(move);
      String chr = fen[toPos.y][toPos.x];
      if (chr != '0') {
        items.add(ChessItem(chr, position: toPos));
      }
    }
    items.sort(
      (a, b) => chessWeight[b.code.toLowerCase()]!
          .compareTo(chessWeight[a.code.toLowerCase()]!),
    );
    return items;
  }

  /// 获取被吃子的列表
  List<ChessItem> getBeEatList(ChessPos pos) {
    List<ChessItem> items = [];
    List<ChessItem> pieces = fen.getAll();
    String chr = fen[pos.y][pos.x];
    ChessItem curChess = ChessItem(chr, position: pos);
    for (var item in pieces) {
      if (item.team != curChess.team) {
        List<String> points = movePoints(item.position, pos);
        if (points.contains(pos.toCode())) {
          items.add(item);
        }
      }
    }
    items.sort(
      (a, b) => chessWeight[b.code.toLowerCase()]!
          .compareTo(chessWeight[a.code.toLowerCase()]!),
    );
    return items;
  }

  /// TODO 获取抽子招法 将军同时吃对方无根子
  /// 1.一个子将军，另一个子吃子，判断被吃子能否解将
  /// 2.躲将后是否有子被吃，被吃子能否解将
  List<String> getCheckEat(int team) {
    List<String> moves = [];

    // todo

    return moves;
  }

  /// 获取某方所有的将军招法
  List<String> getCheckMoves(int team) {
    List<String> moves = [];
    // 对方老将
    ChessPos? kPos = fen.find(team == 0 ? 'k' : 'K');
    if (kPos == null) {
      // 老将没了
      return moves;
    }
    List<ChessItem> pieces = fen.getAll();

    for (var item in pieces) {
      if (item.team == team) {
        // 这里传入目标位置，返回的可行点有针对性
        List<String> points = movePoints(item.position);
        // 挪子后其它子可将军
        for (var point in points) {
          ChessRule nRule = ChessRule(fen.copy());
          nRule.fen.move(item.position.toCode() + point);
          if (nRule.isCheck(team == 0 ? 1 : 0)) {
            moves.add(item.position.toCode() + point);
          }
        }
      }
    }
    return moves;
  }

  /// TODO 获取杀招 ，连将，连将过程中局面不会复原，不会被解将
  List<String> getCheckMate(int team, [int depth = 10]) {
    List<String> moves = [];

    List<ChessItem> pieces = fen.getAll();
    ChessPos kPos = fen.find(team == 0 ? 'k' : 'K')!;

    // 正在将军，直接查出吃老将的招法
    int enemyTeam = team == 0 ? 1 : 0;
    if (isCheck(enemyTeam)) {
      for (final item in pieces) {
        if (item.team == team) {
          List<String> moves = movePoints(item.position, kPos);
          if (moves.contains(kPos.toCode())) {
            moves.add(item.position.toCode() + kPos.toCode());
            return moves;
          }
        }
      }
    }

    final currentFen = fen.copy();
    ChessFen startFen = currentFen;

    int curDepth = 0;

    // 获取连将的杀着
    while (true) {
      moves.add('');
      final checkMoves = ChessRule(startFen).getCheckMoves(team);
      for (final move in checkMoves) {
        moves[curDepth] = move;
        ChessFen fend = currentFen.copy();
        fend.move(move);
        if (!ChessRule(fend).canParryKill(team == 0 ? 1 : 0)) {
          return moves;
        }
        currentFen.deductions.add(fend);
        startFen = fend;
      }

      curDepth++;
      if (curDepth >= depth) {
        break;
      }
    }

    return moves;
  }

  /// 获取当前子力能移动的位置 target 为目标位置，如果传入了目标位置，则会优化检测
  List<String> movePoints(ChessPos activePos, [ChessPos? target]) {
    String code = fen[activePos.y][activePos.x];
    if (code.isEmpty || code == '0') return [];
    int team = code.codeUnitAt(0) < ChessFen.colIndexBase ? 0 : 1;
    code = code.toLowerCase();
    switch (code) {
      case 'p':
        return _moveP(team, code, activePos, target);
      case 'c':
        return _moveC(team, code, activePos, target);
      case 'r':
        return _moveR(team, code, activePos, target);
      case 'n':
        return _moveN(team, code, activePos, target);
      case 'b':
        return _moveB(team, code, activePos, target);
      case 'a':
        return _moveA(team, code, activePos, target);
      case 'k':
        return _moveK(team, code, activePos, target);
      default:
        return [];
    }
  }

  List<String> _moveP(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var m in [
      [1, 0],
      [0, 1],
      [-1, 0],
      [0, -1]
    ]) {
      if (team == 0) {
        // 不允许退
        if (m[1] < 0) {
          continue;
        }
        // 不过河不能横走
        if (activePos.y < 5 && m[0] != 0) {
          continue;
        }
      } else {
        // 不允许退
        if (m[1] > 0) {
          continue;
        }
        // 不过河不能横走
        if (activePos.y > 4 && m[0] != 0) {
          continue;
        }
      }
      ChessPos newPoint = ChessPos(activePos.x + m[0], activePos.y + m[1]);
      if (target != null && newPoint != target) {
        continue;
      }
      if (newPoint.x < 0 || newPoint.x > 8) {
        continue;
      }
      if (newPoint.y < 0 || newPoint.y > 9) {
        continue;
      }
      // 目标位置是否有己方子
      if (fen.hasItemAt(newPoint, team: team)) {
        continue;
      }
      points.add(newPoint.toCode());
    }
    return points;
  }

  List<String> _moveC(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var step in [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ]) {
      bool hasRack = false;
      ChessPos movePoint =
          ChessPos(activePos.x + step[0], activePos.y + step[1]);

      while (movePoint.x >= 0 &&
          movePoint.x <= 8 &&
          movePoint.y >= 0 &&
          movePoint.y <= 9) {
        // 是否有炮架
        ChessItem current = ChessItem(fen.itemAtPos(movePoint));
        // print([movePoint, current]);
        if (!current.isBlank) {
          // 遇到对方子就吃
          if (hasRack) {
            if (current.team != team) {
              points.add(movePoint.toCode());
            }
            break;
          }
          hasRack = true;
        }
        if (!hasRack) {
          points.add(movePoint.toCode());
        }

        movePoint.x += step[0];
        movePoint.y += step[1];
      }
    }
    return points;
  }

  List<String> _moveR(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var step in [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ]) {
      ChessPos movePoint =
          ChessPos(activePos.x + step[0], activePos.y + step[1]);
      while (movePoint.x >= 0 &&
          movePoint.x <= 8 &&
          movePoint.y >= 0 &&
          movePoint.y <= 9) {
        // 遇到已方子立即停止
        ChessItem current = ChessItem(fen.itemAtPos(movePoint));
        if (!current.isBlank && current.team == team) {
          break;
        }
        points.add(movePoint.toCode());
        // 遇到对方子吃完停止
        if (!current.isBlank) {
          break;
        }

        movePoint.x += step[0];
        movePoint.y += step[1];
      }
    }
    return points;
  }

  List<String> _moveN(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var m in [
      [2, 1],
      [1, 2],
      [-2, -1],
      [-1, -2],
      [-2, 1],
      [-1, 2],
      [2, -1],
      [1, -2]
    ]) {
      ChessPos newPoint = ChessPos(activePos.x + m[0], activePos.y + m[1]);
      if (target != null && newPoint != target) {
        continue;
      }
      if (newPoint.x < 0 || newPoint.x > 8) {
        continue;
      }
      if (newPoint.y < 0 || newPoint.y > 9) {
        continue;
      }
      // 是否别马腿
      if (fen.hasItemAt(
        ChessPos(activePos.x + m[0] ~/ 2, activePos.y + m[1] ~/ 2),
      )) {
        //print([newPoint, activePos.x + m[0] ~/ 2, activePos.y + m[1] ~/ 2]);
        continue;
      }
      // 目标位置是否有己方子
      if (fen.hasItemAt(newPoint, team: team)) {
        continue;
      }
      points.add(newPoint.toCode());
    }
    return points;
  }

  List<String> _moveB(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var m in [
      [2, 2],
      [-2, 2],
      [-2, -2],
      [2, -2]
    ]) {
      ChessPos newPoint = ChessPos(activePos.x + m[0], activePos.y + m[1]);
      if (target != null && newPoint != target) {
        continue;
      }
      if (newPoint.x < 0 || newPoint.x > 8) {
        continue;
      }
      if (team == 0) {
        if (newPoint.y < 0 || newPoint.y > 4) {
          continue;
        }
      } else {
        if (newPoint.y < 5 || newPoint.y > 9) {
          continue;
        }
      }
      // 是否别象腿
      if (fen.hasItemAt(
        ChessPos(activePos.x + m[0] ~/ 2, activePos.y + m[1] ~/ 2),
      )) {
        continue;
      }
      // 目标位置是否有己方子
      if (fen.hasItemAt(newPoint, team: team)) {
        continue;
      }
      points.add(newPoint.toCode());
    }
    return points;
  }

  List<String> _moveA(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var m in [
      [1, 1],
      [-1, 1],
      [-1, -1],
      [1, -1]
    ]) {
      ChessPos newPoint = ChessPos(activePos.x + m[0], activePos.y + m[1]);
      if (target != null && newPoint != target) {
        continue;
      }
      if (newPoint.x < 3 || newPoint.x > 5) {
        continue;
      }
      if (team == 0) {
        if (newPoint.y < 0 || newPoint.y > 2) {
          continue;
        }
      } else {
        if (newPoint.y < 7 || newPoint.y > 9) {
          continue;
        }
      }
      // 目标位置是否有己方子
      if (fen.hasItemAt(newPoint, team: team)) {
        continue;
      }
      points.add(newPoint.toCode());
    }
    return points;
  }

  List<String> _moveK(
    int team,
    String code,
    ChessPos activePos, [
    ChessPos? target,
  ]) {
    List<String> points = [];

    for (var m in [
      [1, 0],
      [0, 1],
      [-1, 0],
      [0, -1]
    ]) {
      ChessPos newPoint = ChessPos(activePos.x + m[0], activePos.y + m[1]);
      if (target != null && newPoint != target) {
        continue;
      }
      if (newPoint.x < 3 || newPoint.x > 5) {
        continue;
      }
      if (team == 0) {
        if (newPoint.y < 0 || newPoint.y > 2) {
          continue;
        }
      } else {
        if (newPoint.y < 7 || newPoint.y > 9) {
          continue;
        }
      }

      // 目标位置是否有己方子
      if (fen.hasItemAt(newPoint, team: team)) {
        continue;
      }
      // 是否与对方老将同列，并且中间无子
      ChessPos? enemyKing = fen.find(team == 0 ? 'k' : 'K');
      if (enemyKing != null && newPoint.x == enemyKing.x) {
        List<ChessItem> items = fen.findByCol(newPoint.x);

        // 原则上没有小于1的情况，这里统一按只有对方老将一个
        if (items.length <= 1) {
          continue;
        }

        // 这里已经出错了
        if (items.length == 2 && activePos.x == enemyKing.x) {
          continue;
        }
      }

      points.add(newPoint.toCode());
    }
    return points;
  }
}
