import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/move.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/state/game_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('build() returns a fresh starting position', () {
    final GameState s = container.read(gameControllerProvider);
    expect(s.toMove, Player.white);
    expect(s.board.pointAt(24).topCount, 15);
    expect(s.dice, isNull);
    expect(s.isGameOver, isFalse);
  });

  test('newGame() with a chosen first-to-move resets and switches sides', () {
    final GameController c = container.read(gameControllerProvider.notifier);
    c.setDice(const Dice(5, 3));
    c.newGame(firstToMove: Player.black);
    final GameState s = container.read(gameControllerProvider);
    expect(s.toMove, Player.black);
    expect(s.dice, isNull);
    expect(s.remainingPips, isEmpty);
  });

  test('setDice + applyMoves + endTurn drives a full turn cycle', () {
    final GameController c = container.read(gameControllerProvider.notifier);
    c.setDice(const Dice(6, 1));
    expect(container.read(gameControllerProvider).remainingPips, <int>[6, 1]);

    final List<List<Move>> seqs = c.legalSequences();
    expect(seqs, isNotEmpty);
    c.applyMoves(seqs.first);

    expect(container.read(gameControllerProvider).remainingPips, isEmpty);

    c.endTurn();
    expect(container.read(gameControllerProvider).toMove, Player.black);
    expect(container.read(gameControllerProvider).dice, isNull);
  });

  test('legalNextMovesFrom only returns moves that originate from the '
      'requested point and are deduplicated', () {
    final GameController c = container.read(gameControllerProvider.notifier);
    c.setDice(const Dice(6, 6));
    final List<Move> from24 = c.legalNextMovesFrom(24);
    expect(from24, isNotEmpty);
    for (final Move m in from24) {
      expect(m.from, 24);
    }
    // Distinct (from, pips, bearsOff) triples only.
    final Set<String> keys = from24
        .map((Move m) => '${m.from}:${m.pips}:${m.bearsOff}')
        .toSet();
    expect(keys.length, from24.length);
  });

  test('hasLegalMove is false before rolling, true after a normal roll', () {
    final ProviderContainer c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final GameController controller = c2.read(gameControllerProvider.notifier);
    // No dice rolled yet: no legal moves are available to commit.
    expect(controller.hasLegalMove, isFalse);
    controller.setDice(const Dice(3, 2));
    expect(controller.hasLegalMove, isTrue);
    final List<Move> moves = controller.legalNextMovesFrom(24);
    expect(moves, isNotEmpty);
  });
}
