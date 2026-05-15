import 'board.dart';
import 'dice.dart';
import 'house_rules.dart';
import 'player.dart';

/// A complete, immutable snapshot of a Jakki game.
class GameState {
  const GameState({
    required this.board,
    required this.toMove,
    required this.rules,
    this.dice,
    this.remainingPips = const <int>[],
    this.winner,
    this.whiteScore = 0,
    this.blackScore = 0,
  });

  final Board board;
  final Player toMove;
  final HouseRules rules;

  /// The dice rolled for the current turn, or null before the first
  /// roll of the turn.
  final Dice? dice;

  /// The pips that still need to be played this turn. When empty
  /// and `dice != null`, the player has used all of their dice and
  /// the turn can be ended.
  final List<int> remainingPips;

  /// Match-level scores accumulated across games.
  final int whiteScore;
  final int blackScore;

  /// Set once the game ends. Null means the game is in progress.
  final Player? winner;

  bool get isGameOver => winner != null;

  int scoreFor(Player player) =>
      player == Player.white ? whiteScore : blackScore;

  GameState copyWith({
    Board? board,
    Player? toMove,
    HouseRules? rules,
    Dice? dice,
    bool clearDice = false,
    List<int>? remainingPips,
    Player? winner,
    bool clearWinner = false,
    int? whiteScore,
    int? blackScore,
  }) {
    return GameState(
      board: board ?? this.board,
      toMove: toMove ?? this.toMove,
      rules: rules ?? this.rules,
      dice: clearDice ? null : (dice ?? this.dice),
      remainingPips:
          remainingPips ?? List<int>.unmodifiable(this.remainingPips),
      winner: clearWinner ? null : (winner ?? this.winner),
      whiteScore: whiteScore ?? this.whiteScore,
      blackScore: blackScore ?? this.blackScore,
    );
  }

  /// Fresh starting state for a new game.
  static GameState newGame({
    Player firstToMove = Player.white,
    HouseRules rules = HouseRules.standard,
  }) {
    return GameState(
      board: Board.startingPosition(),
      toMove: firstToMove,
      rules: rules,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'board': board.toJson(),
    'toMove': toMove.name,
    'rules': rules.toJson(),
    'dice': dice?.toJson(),
    'remainingPips': remainingPips,
    'whiteScore': whiteScore,
    'blackScore': blackScore,
    'winner': winner?.name,
  };

  factory GameState.fromJson(Map<String, Object?> json) {
    final Object? rawBoard = json['board'];
    if (rawBoard is! Map) {
      throw const FormatException('GameState.fromJson expects "board" object.');
    }
    final Board board = Board.fromJson(rawBoard.cast<String, Object?>());

    final Object? rawToMove = json['toMove'];
    if (rawToMove is! String) {
      throw const FormatException(
        'GameState.fromJson expects "toMove" string.',
      );
    }
    final Player toMove = Player.values.firstWhere(
      (Player p) => p.name == rawToMove,
      orElse: () => throw FormatException('Unknown player "$rawToMove".'),
    );

    final Object? rawRules = json['rules'];
    final HouseRules rules = rawRules is Map
        ? HouseRules.fromJson(rawRules.cast<String, Object?>())
        : HouseRules.standard;

    final Object? rawDice = json['dice'];
    final Dice? dice = rawDice is Map
        ? Dice.fromJson(rawDice.cast<String, Object?>())
        : null;

    final Object? rawPips = json['remainingPips'];
    final List<int> pips = rawPips is List
        ? <int>[
            for (final Object? entry in rawPips)
              if (entry is int) entry,
          ]
        : const <int>[];

    Player? winner;
    final Object? rawWinner = json['winner'];
    if (rawWinner is String) {
      winner = Player.values.firstWhere(
        (Player p) => p.name == rawWinner,
        orElse: () => throw FormatException('Unknown winner "$rawWinner".'),
      );
    }

    int readInt(String key) {
      final Object? value = json[key];
      return value is int ? value : 0;
    }

    return GameState(
      board: board,
      toMove: toMove,
      rules: rules,
      dice: dice,
      remainingPips: pips,
      whiteScore: readInt('whiteScore'),
      blackScore: readInt('blackScore'),
      winner: winner,
    );
  }
}
