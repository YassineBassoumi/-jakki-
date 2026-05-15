# Rules of Jakki Tunisie (Mahbousseh variant)

This document is the **source of truth** for the game engine. It
describes the rules the engine must implement. The Tunisian game
*Jakki* (also spelled *chiche-biche* or *tawla*) is most commonly
played in the **Mahbousseh** (محبوسة, "imprisoned") variant of tavla
/ backgammon. It uses the same physical board as Western backgammon
but has different movement and capture rules.

> Primary references used:
> - French Wikipedia, *Tavla*, section *Règles du jeu du Mahbousseh*
>   (https://fr.wikipedia.org/wiki/Tavla).
> - *Mahbousseh* rules summary
>   (https://mahbousseh.wordpress.com/rules/).
> - Cross-reference: Plakoto (Greek) and Tapa (Bulgarian/Macedonian/
>   Syrian) are the same game family.
>
> Tunisian play has local conventions (e.g. terminology, scoring of
> "mars"/gammon) that vary by region and household. The engine should
> expose these as configurable house rules — see
> [§ 9 House rules / variants](#9-house-rules--variants).

## 1. Equipment

- A standard backgammon board: two halves of 12 narrow triangles
  ("points"/"flèches"), 24 points in total, divided into 4 quadrants
  of 6 points each.
- **15 checkers** per player (one colour each).
- **Two six-sided dice**.
- Optional: a doubling cube (rarely used in casual Tunisian play).

## 2. Board coordinates used in this document

We number the points 1–24 from each player's own perspective:

- Each player's **home board** is points 1–6.
- Each player's **outer board** is points 7–12.
- The opponent's outer board is points 13–18 from your perspective.
- The opponent's home board is points 19–24 from your perspective.
- Point **24** is the starting corner ("tête") — the farthest from
  your bear-off tray.
- Players move in **opposite directions**: each player moves their
  checkers from point 24 down to point 1, then bears them off.

## 3. Starting position

- Both players place **all 15 checkers on their own point 24**
  (their starting corner, diagonally opposite to where they will
  bear off).
- This is the key difference from Western backgammon, which starts
  with checkers spread across 24/13/8/6.
- Traditionally, players put only 2 or 3 checkers on the board at
  the very start and hold the rest in their non-rolling hand, adding
  them as the game develops. This is cosmetic and the engine should
  treat all 15 as already placed.

## 4. Starting the game

- Each player rolls one die. The higher roll plays first, using the
  two values that were just rolled (their own die + the opponent's
  die) as their opening move.
- On ties (doubles), reroll until a non-tie occurs.

## 5. Movement

- A player rolls two dice and moves checkers a number of points
  equal to the value on each die.
- Each die is a **separate sub-move**. The two sub-moves can be made
  with the same checker (in two steps) or with two different
  checkers.
- **Doubles** are played **four times**, not two: a roll of `(5,5)`
  produces four sub-moves of 5 pips each.
- When moving a single checker with both dice as one combined hop,
  the **intermediate point** must also be legal to land on.
- A sub-move is **legal** if the destination point:
  1. is empty, **or**
  2. contains only your own checkers (any number), **or**
  3. contains **exactly one** opponent checker (this is a *pin* —
     see § 6), **or**
  4. contains your own checker(s) already stacked on top of a pinned
     opponent checker (you may keep stacking).
- A sub-move is **illegal** if the destination is **blocked** — i.e.
  it holds two or more opponent checkers, or a single opponent
  checker stacked on top of an opponent's pinned checker (an
  opponent *anchor*).
- A player **must** play both dice if any legal sequence exists.
  If only one die can be played, the player must play that one. If
  neither can be played, the turn is forfeited.
- If both individual dice are legal but only one *order* yields a
  legal turn, the player must choose that order. (The engine should
  enumerate the legal move space; the UI should help the user pick.)
- *Khanah*: a local term for using both dice on two different
  checkers that end up stacking together on a previously empty
  point. No special scoring; purely descriptive.

## 6. Pinning (the defining rule)

This is what makes Jakki / Mahbousseh different from Western
backgammon:

- If you land on a point holding **exactly one** opponent checker,
  you **do not hit** it (no "bar"). Instead you place your checker
  **on top of it**, **pinning** ("emprisonner") the opponent's
  checker in place.
- A pinned checker **cannot move** until its captor moves away. The
  pinning player can leave it pinned as long as they like.
- You can stack **additional own checkers** on top of a pin; the
  point then acts like an own-anchor and is blocked for the
  opponent.
- The pinning player can pin **multiple opponent checkers** per
  turn.
- You **cannot** pin a checker that is already pinning one of your
  own checkers (the opponent's pinning checker is on top, so the
  point is blocked for you).
- **Liberation:** the pinned player does **not** have to wait to
  play — they can move their other checkers freely. The pinned
  checker is freed automatically the moment the pinning player
  moves their pinning checker off that point.
- There is **no bar** in Mahbousseh and no re-entry; pinned checkers
  stay where they are on the board.

## 7. Bearing off

- Once **all 15** of your checkers are in your home board (points
  1–6), you may start bearing them off.
- A die value `n` bears off a checker from point `n`.
- If you roll a value larger than your highest occupied point, you
  bear off from your highest occupied point.
- You may also use a die to move a checker further within the home
  board instead of bearing off, if that is legal and preferred.
- If, while bearing off, an opponent checker becomes pinned by one
  of your checkers in your home board, that is fine — but **you may
  not bear off a checker that is currently pinning an opponent
  checker** (because moving it would free the opponent in a way that
  takes the checker off the board, which is not allowed). The
  engine must check this when filtering legal bear-off moves.
- If a checker of yours is **pinned** while you are bearing off,
  you cannot bear off until you free it (which requires the
  opponent to move first). This is rare in late game.

## 8. Winning and scoring

- The first player to bear off all 15 checkers wins the game.
- **Single (1 point):** opponent has borne off at least one checker.
- **Mars / Gammon (2 points):** opponent has not borne off any
  checker.
- **Backgammon (3 points)** as in Western backgammon (opponent
  still has a checker in your home board or, in some Tunisian
  variants, has a pinned checker anywhere) is **optional** and
  configurable.
- Doubling cube: **off by default** for Jakki; available as an
  option (this matches casual Tunisian play, where the cube is
  uncommon).
- Match play: first to N points (default N = 5, configurable).

## 9. House rules / variants

The engine must expose these as feature flags so that local
preferences can be honoured:

| Flag                       | Default | Effect |
| -------------------------- | ------- | ------ |
| `doublesPlayedFourTimes`   | `true`  | If `false`, doubles play only twice (very rare). |
| `mustPlayBothDice`         | `true`  | Standard rule. |
| `mustPlayLargerDieWhenOne` | `true`  | If only one die can be played, the larger one must be chosen. |
| `enableBackgammonScoring`  | `false` | Adds 3-point backgammon win condition. |
| `enableDoublingCube`       | `false` | Casual Tunisian play omits it. |
| `pinFromBearOff`           | `false` | If `true`, allow off-the-board pinning (non-standard). |
| `holdCheckersInHand`       | `false` | Cosmetic UX — start with only a few checkers on the board. |

## 10. Glossary (Tunisian / Persian terminology)

Tunisian players announce dice rolls using Persian-derived names
(this matches the wider Levantine/Maghreb tavla tradition):

| Roll  | Name (Tunisian/Persian) | Double name |
| ----- | ----------------------- | ----------- |
| 1     | *yek*                   | *habyek* (double 1) |
| 2     | *dou*                   | *doubara* (double 2) |
| 3     | *seh*                   | *dousseh* (double 3) |
| 4     | *tchoar*                | *derjeh* (double 4) |
| 5     | *pench / penj*          | *doubech* (double 5) |
| 6     | *chèche / chèch*        | *douchèche* (double 6) |

Mixed rolls are named higher die first, e.g. *chèche-yek* (6-1),
*chèche-bech* (6-5). The "*chèche-bech*" name is also the colloquial
Tunisian name of the game itself.

Other terms:

- *Jakki / Tawla / Chiche-biche* — the board and the game.
- *Mahbousseh* (محبوسة) — "the imprisoned one", the variant played.
- *Mars* — gammon, a 2-point win.
- *Khanah* — landing two dice on the same previously-empty point.

## 11. Engine acceptance checklist

The Dart game engine should pass the following golden tests:

1. Setup places 15 checkers on each player's point 24, with no
   pinned checkers.
2. Opening roll uses both players' dice with the higher roller
   playing first.
3. A roll of doubles produces 4 sub-moves.
4. A legal sub-move targets an empty point, an own-occupied point,
   a point with exactly one opponent checker (creates a pin), or a
   point with own checker(s) stacked on top of pinned opponent
   checkers.
5. Landing on a point with exactly one opponent checker pins it,
   does not send it to a bar (no bar exists).
6. A pinned checker cannot move while it is pinned.
7. The pinning player can move their pinning checker off the point;
   doing so immediately frees the pinned checker.
8. Bear-off is allowed only when all 15 own checkers are in points
   1–6, and is forbidden for a checker currently pinning an
   opponent (the engine filters this out of legal moves).
9. A turn must play both dice if any legal sequence exists.
10. Scoring: 1 point for a single, 2 for mars (gammon), 3 for
    backgammon when the flag is enabled.
