import 'package:flutter/foundation.dart';
import '../services/saved_stations_service.dart';

class SavedStationsProvider extends ChangeNotifier {
  final SavedStationsService _service = SavedStationsService();

  final Set<String> _savedIds = {};
  final Map<String, int> _likeCounts = {};
  final Set<String> _likedByMe = {};
  bool _loaded = false;

  Set<String> get savedIds => Set<String>.from(_savedIds);
  bool get isLoaded => _loaded;

  bool isSaved(String stationId) => _savedIds.contains(stationId);
  int likeCountFor(String stationId) => _likeCounts[stationId] ?? 0;
  bool isLiked(String stationId) => _likedByMe.contains(stationId);

  Future<void> loadForUser(String uid) async {
    final ids = await _service.getSavedStationIds(uid);
    _savedIds
      ..clear()
      ..addAll(ids);
    _loaded = true;
    notifyListeners();
  }

  void clear() {
    _savedIds.clear();
    _likeCounts.clear();
    _likedByMe.clear();
    _loaded = false;
    notifyListeners();
  }

  Future<void> toggleSaved(String uid, String stationId) async {
    // 1. Optimistic local update (source of truth is _savedIds)
    if (_savedIds.contains(stationId)) {
      _savedIds.remove(stationId);
    } else {
      _savedIds.add(stationId);
    }
    notifyListeners();

    // 2. Write the ENTIRE list to Firestore atomically.
    //    No read-modify-write, no races.
    final list = _savedIds.toList();
    final ok = await _service.setSavedIds(uid, list);

    // 3. If the write failed, roll back the local change.
    if (!ok) {
      if (list.contains(stationId)) {
        _savedIds.remove(stationId);
      } else {
        _savedIds.add(stationId);
      }
      notifyListeners();
    }
  }

  Future<void> loadLikeStats(String stationId, String? uid) async {
    final stats = await _service.getLikeStats(stationId, uid);
    _likeCounts[stationId] = stats['likeCount'] as int;
    if (stats['likedByMe'] == true) {
      _likedByMe.add(stationId);
    } else {
      _likedByMe.remove(stationId);
    }
    notifyListeners();
  }

  Future<void> toggleLike(String stationId, String uid) async {
    final wasLiked = _likedByMe.contains(stationId);
    final oldCount = likeCountFor(stationId);

    // Optimistic
    if (wasLiked) {
      _likedByMe.remove(stationId);
      _likeCounts[stationId] = (oldCount - 1).clamp(0, 999999);
    } else {
      _likedByMe.add(stationId);
      _likeCounts[stationId] = oldCount + 1;
    }
    notifyListeners();

    await _service.toggleLike(stationId, uid);
  }
}