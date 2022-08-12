CChess

Chinese chess rule analysis, supported Chess-manual load, piece move, checkmate, move translate.

## Features

* Load from manual
* Load from fenstr
* Translate move
* Get all moves of a piece
* Check whether the move complies with the rules
* Check is checkmate
* Check killed
* Check tracked



## Usage

```dart
// Load from fenstr
ChessRule rule = ChessRule.fromFen(
    'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1');
// can checkmate
rule.teamCanCheck(0);
// get pieces has been eaten
List<ChessItem> beEatens = rule.getBeEatenList(0);
// is checkmating
rule.isCheck(eTeam);
// can parry checkmate or will be kill
rule.canParryKill(eTeam)
```

## Additional information

[Full Demo](https://github.com/shirne/chinese_chess)


