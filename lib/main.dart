import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'models.dart';
import 'board_data.dart';
import 'game_engine.dart';
import 'matchmaking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TigerVsGoatsApp());
}

class TigerVsGoatsApp extends StatelessWidget {
  const TigerVsGoatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiger vs Goats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2F3338),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _showComputerRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3E4247),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CHOOSE YOUR ROLE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              const Text('Who will you command in this battle?', style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen(role: 'tiger')));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 28),
                    SizedBox(width: 12),
                    Text('PLAY AS TIGER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF55595F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.white30, width: 2),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen(role: 'goat')));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grass, size: 28),
                    SizedBox(width: 12),
                    Text('PLAY AS GOATS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF3E4247),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TIGER vs GOATS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              const Text('Classic Strategy Game', style: TextStyle(fontSize: 16, color: Colors.white60)),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(220, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showComputerRoleDialog(context),
                child: const Text('PLAY VS COMPUTER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen())),
                child: const Text('PLAY ONLINE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen(role: 'two_player'))),
                child: const Text('2 PLAYERS (LOCAL)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final MatchmakingService _service = MatchmakingService();
  String _status = "Searching for opponent...";
  bool _searching = true;
  StreamSubscription? _roomSub;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  void _startMatchmaking() async {
    try {
      final matchData = await _service.findOrCreateMatch();
      final roomId = matchData['roomId'];
      final role = matchData['role'];
      final isHost = matchData['isHost'];

      if (!mounted) return;

      if (isHost) {
        setState(() {
          _status = "Waiting for an opponent to join...\nRoom ID: $roomId";
        });
        
        // Listen for player to join
        _roomSub = _service.getRoomStream(roomId).listen((doc) {
          if (doc.exists && doc.get('status') == 'playing') {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => GameScreen(role: 'online', onlineRoomId: roomId, myOnlineRole: role)),
            );
          }
        });
      } else {
        // We joined an existing room
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GameScreen(role: 'online', onlineRoomId: roomId, myOnlineRole: role)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Error: $e";
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_searching) const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 30),
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white60)),
            )
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String role;
  final String? onlineRoomId;
  final String? myOnlineRole;
  const GameScreen({super.key, required this.role, this.onlineRoomId, this.myOnlineRole});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  StreamSubscription? _onlineSub;

  @override
  void initState() {
    super.initState();
    state = GameEngine.createInitialState(widget.role);
    
    if (widget.role == 'online') {
      _onlineSub = FirebaseFirestore.instance
          .collection('waiting_rooms')
          .doc(widget.onlineRoomId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            state = state.copyWith(
              tigerPosition: data['tigerPosition'],
              goatPositions: List<int>.from(data['goatPositions']),
              isTigerTurn: data['isTigerTurn'],
              selectedNode: data['selectedNode'],
              lastEatenGoatPos: data['lastEatenGoatPos'],
              mustJump: data['mustJump'],
              clearEaten: data['lastEatenGoatPos'] == null,
            );
          });
          _checkGameOver();
        }
      });
    } else {
      if (state.playerRole == 'goat' && state.isTigerTurn) {
        _triggerComputerMove();
      }
    }
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    super.dispose();
  }

  void _updateOnlineState(GameState newState) {
    FirebaseFirestore.instance
        .collection('waiting_rooms')
        .doc(widget.onlineRoomId)
        .update({
      'tigerPosition': newState.tigerPosition,
      'goatPositions': newState.goatPositions,
      'isTigerTurn': newState.isTigerTurn,
      'selectedNode': newState.selectedNode,
      'lastEatenGoatPos': newState.lastEatenGoatPos,
      'mustJump': newState.mustJump,
    });
  }

  void _triggerComputerMove() async {
    if (widget.role == 'two_player' || widget.role == 'online') return; // Local/Online: No AI
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      state = GameEngine.makeComputerMove(state);
    });
    _checkGameOver();
    
    bool computerIsTiger = (state.playerRole == 'goat');
    if (state.isTigerTurn == computerIsTiger) {
       _triggerComputerMove();
    }
  }

  void _onNodeTap(int id) {
    if (widget.role == 'online') {
      bool isMyTurn = (state.isTigerTurn && widget.myOnlineRole == 'tiger') ||
                      (!state.isTigerTurn && widget.myOnlineRole == 'goat');
      if (!isMyTurn) return;
    }

    bool isComputerTurn = (widget.role != 'two_player' && widget.role != 'online') && 
                          ((state.isTigerTurn && state.playerRole == 'goat') || 
                          (!state.isTigerTurn && state.playerRole == 'tiger'));
    if (isComputerTurn) return;

    setState(() {
      if (state.isTigerTurn) {
        // Tiger only has one piece, so auto-attempt move from tigerPosition to tapped id
        GameState newState = GameEngine.makeMove(state, state.tigerPosition, id);
        if (newState != state) {
          if (widget.role == 'online') {
            _updateOnlineState(newState);
          } else {
            state = newState;
            _checkGameOver();
            
            bool nextIsComputer = (state.isTigerTurn && state.playerRole == 'goat') || 
                                  (!state.isTigerTurn && state.playerRole == 'tiger');
            if (nextIsComputer) {
              _triggerComputerMove();
            }
          }
        }
      } else {
        // Goat logic (needs selection since there are 16 goats)
        if (state.selectedNode == null) {
          if (state.goatPositions.contains(id)) {
            state = state.copyWith(selectedNode: id);
          }
        } else {
          if (state.selectedNode == id) {
            if (!state.mustJump) {
              state = state.copyWith(selectedNode: null);
            }
          } else {
            GameState newState = GameEngine.makeMove(state, state.selectedNode!, id);
            if (newState != state) {
              if (widget.role == 'online') {
                _updateOnlineState(newState);
              } else {
                state = newState;
                _checkGameOver();
                
                bool nextIsComputer = (state.isTigerTurn && state.playerRole == 'goat') || 
                                      (!state.isTigerTurn && state.playerRole == 'tiger');
                if (nextIsComputer) {
                  _triggerComputerMove();
                }
              }
            } else {
               if (!state.mustJump) {
                 if (state.goatPositions.contains(id)) {
                    state = state.copyWith(selectedNode: id);
                 }
               }
            }
          }
        }
      }
    });
  }

  void _checkGameOver() {
    String? winner = GameEngine.checkWin(state);
    if (winner != null) {
      if (widget.role == 'online') {
        _onlineSub?.cancel();
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF3E4247),
          title: Text(winner, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            winner.contains('Tiger') ? 'The Tiger has decimated the goats.' : 'The Goats have trapped the Tiger.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('EXIT TO MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool flipBoard = (widget.role == 'online') 
        ? (widget.myOnlineRole == 'goat') 
        : (state.playerRole == 'goat');
    double getX(double x) => flipBoard ? 1.0 - x : x;
    double getY(double y) => flipBoard ? 1.0 - y : y;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isTigerTurn ? "TIGER'S TURN" : "GOATS' TURN"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  double height = constraints.maxHeight;
                  
                  double boardWidth, boardHeight;
                  // True aspect ratio of the board geometry is 300:450 (2:3)
                  double targetRatio = 300 / 450;

                  if (width / height > targetRatio) {
                    // Height is the limiting factor
                    boardHeight = height * 0.90;
                    boardWidth = boardHeight * targetRatio;
                  } else {
                    // Width is the limiting factor
                    boardWidth = width * 0.90;
                    boardHeight = boardWidth / targetRatio;
                  }

                  return Center(
                    child: SizedBox(
                      width: boardWidth,
                      height: boardHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BoardPainter(flipBoard),
                            ),
                          ),
                          ...BoardData.nodes.map((node) => Positioned(
                            left: getX(node.x) * boardWidth - 25,
                            top: getY(node.y) * boardHeight - 25,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onNodeTap(node.id),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.transparent,
                              ),
                            ),
                          )),
                          _buildPiece(
                            id: state.tigerPosition,
                            color: Colors.orangeAccent,
                            boardWidth: boardWidth,
                            boardHeight: boardHeight,
                            isSelected: state.selectedNode == state.tigerPosition,
                            label: 'T',
                            flipBoard: flipBoard,
                          ),
                          ...state.goatPositions.map((id) => _buildPiece(
                            id: id,
                            color: Colors.white,
                            boardWidth: boardWidth,
                            boardHeight: boardHeight,
                            isSelected: state.selectedNode == id,
                            label: 'G',
                            flipBoard: flipBoard,
                          )),
                          if (state.lastEatenGoatPos != null) 
                            _buildDeathEffect(state.lastEatenGoatPos!, boardWidth, boardHeight, flipBoard),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Text(
                'GOATS REMAINING: ${state.goatPositions.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiece({required int id, required Color color, required double boardWidth, required double boardHeight, required bool isSelected, required String label, required bool flipBoard}) {
    BoardNode node = BoardData.getNode(id);
    double x = flipBoard ? 1.0 - node.x : node.x;
    double y = flipBoard ? 1.0 - node.y : node.y;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: x * boardWidth - 18,
      top: y * boardHeight - 18,
      child: IgnorePointer(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? color : color.withValues(alpha: 0.9),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.black45,
              width: isSelected ? 4 : 2,
            ),
            boxShadow: [
              if (isSelected) const BoxShadow(color: Colors.blueAccent, blurRadius: 15, spreadRadius: 2),
              const BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color == Colors.white ? Colors.black : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeathEffect(int id, double boardWidth, double boardHeight, bool flipBoard) {
    BoardNode node = BoardData.getNode(id);
    double x = flipBoard ? 1.0 - node.x : node.x;
    double y = flipBoard ? 1.0 - node.y : node.y;
    return Positioned(
      left: x * boardWidth - 25,
      top: y * boardHeight - 25,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('death_${id}_${state.tigerPosition}'),
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 1.0 + (1.5 * (1.0 - value)),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                ),
                child: const Center(
                  child: Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final bool flipBoard;
  BoardPainter(this.flipBoard);

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double getX(double x) => flipBoard ? 1.0 - x : x;
    double getY(double y) => flipBoard ? 1.0 - y : y;

    Set<String> drawnEdges = {};

    for (var node in BoardData.nodes) {
      for (int adjId in node.adjacentIds) {
        String edgeId = node.id < adjId ? '${node.id}-$adjId' : '$adjId-${node.id}';
        if (!drawnEdges.contains(edgeId)) {
          BoardNode other = BoardData.getNode(adjId);
          canvas.drawLine(
            Offset(getX(node.x) * size.width, getY(node.y) * size.height),
            Offset(getX(other.x) * size.width, getY(other.y) * size.height),
            linePaint,
          );
          drawnEdges.add(edgeId);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
