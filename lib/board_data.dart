import 'models.dart';

class BoardData {
  static final List<BoardNode> nodes = _generateNodes();

  static List<BoardNode> _generateNodes() {
    List<BoardNode> tempNodes = [];

    void add(int id, double x, double y) {
      // Eliminate dead space from original 500x500 box.
      // True bounds: X (100 to 400, Width=300), Y (25 to 475, Height=450)
      tempNodes.add(BoardNode(
        id: id,
        x: (x - 100.0) / 300.0,
        y: (y - 25.0) / 450.0,
        adjacentIds: [],
      ));
    }

    // Top Triangle (y=25)
    add(0, 175, 25);
    add(1, 250, 25);
    add(2, 325, 25);
    
    // Top Triangle Midline (y=62.5)
    add(3, 212.5, 62.5);
    add(4, 250, 62.5);
    add(5, 287.5, 62.5);

    // Square 5x5 (y=100 to 400)
    for (int yIdx = 0; yIdx < 5; yIdx++) {
      double y = 100 + yIdx * 75.0;
      for (int xIdx = 0; xIdx < 5; xIdx++) {
        double x = 100 + xIdx * 75.0;
        int id = 6 + yIdx * 5 + xIdx;
        add(id, x, y);
      }
    }

    // Bottom Triangle Midline (y=437.5)
    add(31, 212.5, 437.5);
    add(32, 250, 437.5);
    add(33, 287.5, 437.5);
    
    // Bottom Triangle (y=475)
    add(34, 175, 475);
    add(35, 250, 475);
    add(36, 325, 475);

    final List<List<int>> boardLines = [
      // Top Triangle Lines
      [0, 1, 2], [3, 4, 5], [0, 3, 8], [2, 5, 8], [1, 4, 8],
      // Square Horizontals
      [6, 7, 8, 9, 10], [11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21, 22, 23, 24, 25], [26, 27, 28, 29, 30],
      // Square Verticals
      [6, 11, 16, 21, 26], [7, 12, 17, 22, 27], [8, 13, 18, 23, 28], [9, 14, 19, 24, 29], [10, 15, 20, 25, 30],
      // Square Diagonals (Quadrant X's)
      [6, 12, 18], [10, 14, 18], [26, 22, 18], [30, 24, 18], [8, 12, 16], [8, 14, 20], [28, 22, 16], [28, 24, 20],
      // Bottom Triangle Lines
      [28, 31, 34], [28, 33, 36], [28, 32, 35], [31, 32, 33], [34, 35, 36],
    ];

    for (var line in boardLines) {
      for (int i = 0; i < line.length - 1; i++) {
        int u = line[i];
        int v = line[i + 1];
        if (!tempNodes[u].adjacentIds.contains(v)) tempNodes[u].adjacentIds.add(v);
        if (!tempNodes[v].adjacentIds.contains(u)) tempNodes[v].adjacentIds.add(u);
      }
    }

    return tempNodes;
  }

  static BoardNode getNode(int id) => nodes[id];

  static int? getJumpLanding(int fromId, int overId) {
    BoardNode from = nodes[fromId];
    BoardNode over = nodes[overId];
    double tx = 2 * over.x - from.x;
    double ty = 2 * over.y - from.y;
    for (var node in nodes) {
      if ((node.x - tx).abs() < 0.05 && (node.y - ty).abs() < 0.05) {
        return node.id;
      }
    }
    return null;
  }
}
