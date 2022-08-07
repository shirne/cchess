import 'dart:io';

import 'package:cchess/cchess.dart';
import 'package:logging/logging.dart';

void main(List<String> arguments) {
  final logger = Logger.root;
  logger.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.time}: ${record.message}');
  });

  // 加载一个局面
  ChessRule rule = ChessRule.fromFen(
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1');

  logger.fine('是否可将军：${rule.teamCanCheck(0)}');

  rule = ChessRule.fromFen(
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1');

  // 获取将被吃的子
  List<ChessItem> beEatens = rule.getBeEatenList(0);

  for (var item in beEatens) {
    List<ChessItem> beEats = rule.getBeEatList(item.position);
    logger.info(
        '${item.code} <= ${beEats.map<String>((item) => item.code).join(',')}');
  }

  // 加载初始局面
  ChessManual manual =
      ChessManual(fen: '4k4/4a4/2P5n/5N3/9/5R3/9/9/2p2p2r/C3K4');

  // 加载步骤
  manual.addMoves(
      ['f6d7', 'e9d9', 'a0d0', 'c1d1', 'f4f9', 'e8e9', 'd7f8', '1-0']);

  // 定位到第一步
  manual.loadHistory(0);

  logger.info('初始局面：${manual.currentFen.fen}');

  while (manual.hasNext) {
    logger.info(manual.next());
    logger.info('当前局面：${manual.currentFen.fen}');

    // 局面判断
    rule = ChessRule(manual.currentFen);
    int eTeam = manual.getMove()!.hand == 0 ? 1 : 0;
    // 判断是否将军，并进一步判断是否绝杀
    if (rule.isCheck(eTeam)) {
      if (rule.canParryKill(eTeam)) {
        logger.info('将军!');
      } else {
        logger.info('绝杀!');
      }
    }
  }
  // 步数走完后可返回结果
  logger.info(manual.next());
}
