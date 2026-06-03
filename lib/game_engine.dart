import 'dart:math';
import 'models.dart';
import 'board_data.dart';

class GameEngine {
  static GameState createInitialState(String playerRole) {
    // 16 Goats: Perfectly symmetric filling (IDs 0-15)
    // This fills the top triangle (6 nodes) + the top two rows of the square (10 nodes)
    List<int> goats = List.generate(16, (i) => i);
    // Tiger in the dead center (x=250, y=250) -> ID 18
    int tiger = 18; 

    return GameState(
      tigerPosition: tiger,
      goatPositions: goats,
      isTigerTurn: true,
      playerRole: playerRole,
    );
  }

  static bool isValidMove(GameState state, int fromId, int toId) {
    if (state.goatPositions.contains(toId) || state.tigerPosition == toId) {
      return false;
    }

    BoardNode from = BoardData.getNode(fromId);

    // Check if move is a jump
    bool isJump = false;
    if (state.isTigerTurn && fromId == state.tigerPosition) {
      for (int adjId in from.adjacentIds) {
        if (state.goatPositions.contains(adjId)) {
          int? landingId = BoardData.getJumpLanding(fromId, adjId);
          if (landingId == toId) {
            isJump = true;
            break;
          }
        }
      }
    }

    // If forced to multi-jump, only allow jump moves
    if (state.mustJump) {
      return isJump;
    }

    if (isJump) return true;

    // Normal move (adjacent)
    if (from.adjacentIds.contains(toId)) {
      return true;
    }

    return false;
  }

  static GameState makeMove(GameState state, int fromId, int toId) {
    if (!isValidMove(state, fromId, toId)) return state;

    int newTigerPos = state.tigerPosition;
    List<int> newGoats = List.from(state.goatPositions);
    bool captured = false;
    int? eatenGoatId;

    if (state.isTigerTurn) {
      BoardNode from = BoardData.getNode(fromId);
      if (!from.adjacentIds.contains(toId)) {
        // Must be a jump. Find which goat was jumped over.
        for (int adjId in from.adjacentIds) {
          if (state.goatPositions.contains(adjId)) {
            if (BoardData.getJumpLanding(fromId, adjId) == toId) {
              newGoats.remove(adjId);
              captured = true;
              eatenGoatId = adjId;
              break;
            }
          }
        }
      }
      newTigerPos = toId;
    } else {
      // Goat move
      int goatIdx = newGoats.indexOf(fromId);
      if (goatIdx != -1) {
        newGoats[goatIdx] = toId;
      }
    }

    // Check if tiger can multi-jump
    bool canMultiJump = false;
    if (captured) {
      canMultiJump = _canTigerJumpFrom(newTigerPos, newGoats);
    }

    return state.copyWith(
      tigerPosition: newTigerPos,
      goatPositions: newGoats,
      isTigerTurn: canMultiJump ? true : !state.isTigerTurn,
      selectedNode: canMultiJump ? newTigerPos : null,
      lastEatenGoatPos: eatenGoatId,
      clearEaten: eatenGoatId == null,
      mustJump: canMultiJump,
    );
  }

  static bool _canTigerJumpFrom(int pos, List<int> goats) {
    BoardNode node = BoardData.getNode(pos);
    for (int adjId in node.adjacentIds) {
      if (goats.contains(adjId)) {
        int? landing = BoardData.getJumpLanding(pos, adjId);
        if (landing != null && !goats.contains(landing) && pos != landing && stateTigerPosNotLanding(pos, landing)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool stateTigerPosNotLanding(int pos, int landing) {
     return pos != landing;
  }

  static String? checkWin(GameState state) {
    if (state.goatPositions.length < 5) return "Tiger Wins!";

    bool canTigerMove = false;
    BoardNode tigerNode = BoardData.getNode(state.tigerPosition);
    for (int adjId in tigerNode.adjacentIds) {
      if (!state.goatPositions.contains(adjId)) {
        canTigerMove = true;
        break;
      }
      int? landing = BoardData.getJumpLanding(state.tigerPosition, adjId);
      if (landing != null && !state.goatPositions.contains(landing)) {
        canTigerMove = true;
        break;
      }
    }

    if (!canTigerMove) return "Goats Win!";
    return null;
  }

  static List<Move> getAllPossibleMoves(GameState state) {
    List<Move> moves = [];
    if (state.isTigerTurn) {
      for (var node in BoardData.nodes) {
        if (isValidMove(state, state.tigerPosition, node.id)) {
          moves.add(Move(state.tigerPosition, node.id));
        }
      }
    } else {
      for (int goatPos in state.goatPositions) {
        BoardNode goatNode = BoardData.getNode(goatPos);
        for (int adjId in goatNode.adjacentIds) {
          if (isValidMove(state, goatPos, adjId)) {
            moves.add(Move(goatPos, adjId));
          }
        }
      }
    }
    return moves;
  }

  static int evaluateState(GameState state, String aiRole) {
    String? winner = checkWin(state);
    if (winner != null) {
      if (winner.contains('Tiger')) return aiRole == 'tiger' ? 100000 : -100000;
      if (winner.contains('Goats')) return aiRole == 'goat' ? 100000 : -100000;
    }

    int goatsEaten = 16 - state.goatPositions.length;
    int tigerScore = goatsEaten * 500;

    int tigerMobility = 0;
    BoardNode tigerNode = BoardData.getNode(state.tigerPosition);
    for (int adjId in tigerNode.adjacentIds) {
      if (!state.goatPositions.contains(adjId)) tigerMobility++;
      int? landing = BoardData.getJumpLanding(state.tigerPosition, adjId);
      if (landing != null && !state.goatPositions.contains(landing)) tigerMobility++;
    }
    
    int goatScore = (10 - tigerMobility) * 50;

    if (aiRole == 'tiger') {
      return tigerScore - goatScore;
    } else {
      return goatScore - tigerScore;
    }
  }

  static int minimax(GameState state, int depth, int alpha, int beta, bool isAiTurn, String aiRole) {
    String? winner = checkWin(state);
    if (depth == 0 || winner != null) {
      return evaluateState(state, aiRole);
    }

    List<Move> moves = getAllPossibleMoves(state);
    if (moves.isEmpty) return evaluateState(state, aiRole);

    if (isAiTurn) {
      int maxEval = -999999;
      for (Move move in moves) {
        GameState nextState = makeMove(state, move.from, move.to);
        bool nextIsAiTurn = (nextState.isTigerTurn == (aiRole == 'tiger'));
        int eval = minimax(nextState, depth - 1, alpha, beta, nextIsAiTurn, aiRole);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (Move move in moves) {
        GameState nextState = makeMove(state, move.from, move.to);
        bool nextIsAiTurn = (nextState.isTigerTurn == (aiRole == 'tiger'));
        int eval = minimax(nextState, depth - 1, alpha, beta, nextIsAiTurn, aiRole);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  static GameState makeComputerMove(GameState state) {
    String aiRole = state.playerRole == 'goat' ? 'tiger' : 'goat';
    List<Move> moves = getAllPossibleMoves(state);
    
    if (moves.isEmpty) return state;

    Move bestMove = moves.first;
    int bestScore = -999999;

    // Depth 3 allows the AI to look multiple turns ahead
    int searchDepth = 3; 

    for (Move move in moves) {
      GameState nextState = makeMove(state, move.from, move.to);
      bool nextIsAiTurn = (nextState.isTigerTurn == (aiRole == 'tiger'));
      
      int score = minimax(nextState, searchDepth, -999999, 999999, nextIsAiTurn, aiRole);
      score += Random().nextInt(10); 
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return makeMove(state, bestMove.from, bestMove.to);
  }
}

class Move {
  final int from;
  final int to;
  final bool isJump;
  Move(this.from, this.to, {this.isJump = false});
}
