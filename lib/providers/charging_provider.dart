import 'package:flutter/material.dart';
import '../models/charging_station.dart';
import '../services/charging_station_service.dart';

enum StationFilter { all, available, fast, nearby, saved }
enum SortMode { distance, name }

class ChargingProvider extends ChangeNotifier {
  final ChargingStationService _service = ChargingStationService();

  ChargingStation? _currentStation;
  List<ChargingStation> _allStations = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  StationFilter _activeFilter = StationFilter.all;
  SortMode _sortMode = SortMode.distance;

  ChargingStation? get currentStation => _currentStation;
  List<ChargingStation> get allStations => _allStations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  StationFilter get activeFilter => _activeFilter;
  SortMode get sortMode => _sortMode;

  List<ChargingStation> get visibleStations {
    var list = _allStations.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.neighborhood.toLowerCase().contains(q) &&
            !s.operator.toLowerCase().contains(q)) {
          return false;
        }
      }

      switch (_activeFilter) {
        case StationFilter.all:
          return true;
        case StationFilter.available:
          return pseudoStatus(s) == 'available';
        case StationFilter.fast:
          return s.powerKw >= 50;
        case StationFilter.nearby:
          const centralNairobi = [
            'CBD',
            'Westlands',
            'Kilimani',
            'Upper Hill',
            'Parklands',
            'Hurlingham',
            'Lavington',
            'Ngara',
          ];
          return centralNairobi.contains(s.neighborhood);
        case StationFilter.saved:
          return false;
      }
    }).toList();

    switch (_sortMode) {
      case SortMode.distance:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return list;
  }

  String pseudoStatus(ChargingStation s) {
    final hash = s.id.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    final bucket = hash.abs() % 100;
    if (bucket < 60) return 'available';
    if (bucket < 85) return 'busy';
    return 'offline';
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(StationFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSort(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  Future<void> loadStationById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentStation = await _service.getById(id);
      if (_currentStation == null) _error = 'Station not found';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFirstStation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentStation = await _service.getFirst();
      if (_currentStation == null) _error = 'No stations found';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cached = await _service.getFromCacheFirst();
      if (cached.isNotEmpty) {
        _allStations = cached;
        _isLoading = false;
        notifyListeners();
      }

      final fresh = await _service.getAll();
      if (fresh.isNotEmpty) {
        _allStations = fresh;
        _error = null;
      } else if (_allStations.isEmpty) {
        _error = 'No stations available. Tap refresh to retry.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentStation() {
    _currentStation = null;
    notifyListeners();
  }
}