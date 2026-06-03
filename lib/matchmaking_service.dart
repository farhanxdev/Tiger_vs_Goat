import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search for an open room. If found, join it. If not, host a new one.
  Future<Map<String, dynamic>> findOrCreateMatch() async {
    // Look for a room where status == 'waiting'
    final QuerySnapshot query = await _firestore
        .collection('waiting_rooms')
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Room found! Join it.
      final doc = query.docs.first;
      await doc.reference.update({'status': 'playing'});
      return {
        'roomId': doc.id,
        'role': 'goat', // Host is tiger, joiner is goat
        'isHost': false,
      };
    } else {
      // No room found. Create a new one.
      final DocumentReference newRoom = await _firestore.collection('waiting_rooms').add({
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        // Initial Game State Data
        'tigerPosition': 18, // Center
        'goatPositions': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        'isTigerTurn': true,
        'selectedNode': null,
        'lastEatenGoatPos': null,
        'mustJump': false,
      });

      return {
        'roomId': newRoom.id,
        'role': 'tiger', // Host plays as tiger
        'isHost': true,
      };
    }
  }

  // Stream to listen to the room's status (used by host to see when someone joins)
  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _firestore.collection('waiting_rooms').doc(roomId).snapshots();
  }
}
