CChess

中国象棋规则处理，棋谱加载，局面加载，招法转换，落点获取，落子合规判断，将军判断，绝杀判断，困毙判断。

## 功能

* 棋谱加载
* 局面加载
* 招法转换
* 落点获取
* 落子合规判断
* 将军判断
* 绝杀判断
* 困毙判断



## 使用

```dart
// 加载棋谱
ChessRule rule = ChessRule.fromFen(
    'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1');
// 是否可将军
rule.teamCanCheck(0);
// 获取被吃的子
List<ChessItem> beEatens = rule.getBeEatenList(0);
// 是否正在将军
rule.isCheck(eTeam);
// 是否可应将，否则结束棋局
rule.canParryKill(eTeam)
```

## 更多

[中国象棋](https://github.com/shirne/chinese_chess)


