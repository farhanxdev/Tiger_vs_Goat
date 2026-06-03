class BoardNode {
  final int id;
  final double x;
  final double y;
  final List<int> adjacentIds;

  BoardNode({
    required this.id,
    required this.x,
    required this.y,
    required this.adjacentIds,
  });
}

enum PieceType { tiger, goat }

class GameState {
  final int tigerPosition;
  final List<int> goatPositions;
  final bool isTigerTurn;
  final int? selectedNode;
  final String playerRole; // 'tiger' or 'goat'
  final int? lastEatenGoatPos;
  final bool mustJump;

  GameState({
    required this.tigerPosition,
    required this.goatPositions,
    this.isTigerTurn = true,
    this.selectedNode,
    this.playerRole = 'tiger',
    this.lastEatenGoatPos,
    this.mustJump = false,
  });

  GameState copyWith({
    int? tigerPosition,
    List<int>? goatPositions,
    bool? isTigerTurn,
    int? selectedNode,
    String? playerRole,
    int? lastEatenGoatPos,
    bool clearEaten = false,
    bool? mustJump,
  }) {
    return GameState(
      tigerPosition: tigerPosition ?? this.tigerPosition,
      goatPositions: goatPositions ?? this.goatPositions,
      isTigerTurn: isTigerTurn ?? this.isTigerTurn,
      selectedNode: selectedNode, // We often want to clear this, so we don't use ??
      playerRole: playerRole ?? this.playerRole,
      lastEatenGoatPos: clearEaten ? null : (lastEatenGoatPos ?? this.lastEatenGoatPos),
      mustJump: mustJump ?? this.mustJump,
    );
  }
}
