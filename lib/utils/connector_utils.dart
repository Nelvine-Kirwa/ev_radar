/// Utilities for matching vehicle connector types to station connectors.
///
/// Vocabulary (normalized tokens):
///   TYPE1   — J1772 / Type 1 AC
///   TYPE2   — Type 2 / Type 2 AC (Mennekes)
///   CCS     — CCS Combo 1/2 DC fast charging
///   CHADEMO — CHAdeMO DC fast charging
///
/// Station `connectorType` is a single string, potentially compound:
///   "Type 2 AC"  -> {TYPE2}
///   "Type 2 + CCS"  -> {TYPE2, CCS}
///   "Type 2 + CHAdeMO"  -> {TYPE2, CHADEMO}
///
/// Car `connectorTypes` is a List<String>:
///   ["Type 2", "CCS"]  -> {TYPE2, CCS}
class ConnectorUtils {
  /// Normalizes a single connector string to a canonical token.
  /// Returns null if the input is unrecognized.
  static String? normalizeToken(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('type 1') || s.contains('j1772')) return 'TYPE1';
    if (s.contains('type 2') || s.contains('mennekes')) return 'TYPE2';
    if (s.contains('ccs')) return 'CCS';
    if (s.contains('chademo')) return 'CHADEMO';

    return null;
  }

  /// Normalizes a station connectorType (single string, may be compound)
  /// into a set of canonical tokens.
  /// e.g. "Type 2 + CCS" -> {TYPE2, CCS}
  static Set<String> normalizeStationConnector(String raw) {
    final tokens = <String>{};
    // Split on compound separators
    final parts = raw.split(RegExp(r'\s*\+\s*|\s*,\s*|\s*/\s*'));
    for (final p in parts) {
      final t = normalizeToken(p);
      if (t != null) tokens.add(t);
    }
    return tokens;
  }

  /// Normalizes a car's connectorTypes list into a set of canonical tokens.
  static Set<String> normalizeCarConnectors(List<String> raw) {
    final tokens = <String>{};
    for (final r in raw) {
      final t = normalizeToken(r);
      if (t != null) tokens.add(t);
    }
    return tokens;
  }

  /// True if [carConnectors] and [stationConnector] share at least one token.
  static bool carMatchesStation({
    required List<String> carConnectors,
    required String stationConnector,
  }) {
    final carTokens = normalizeCarConnectors(carConnectors);
    final stationTokens = normalizeStationConnector(stationConnector);
    if (carTokens.isEmpty || stationTokens.isEmpty) return false;
    return carTokens.intersection(stationTokens).isNotEmpty;
  }
}