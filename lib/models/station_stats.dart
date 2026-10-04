class StationStats {
  final String stationId;
  final int likeCount;
  final bool likedByMe;

  const StationStats({
    required this.stationId,
    required this.likeCount,
    required this.likedByMe,
  });

  factory StationStats.empty(String stationId) => StationStats(
        stationId: stationId,
        likeCount: 0,
        likedByMe: false,
      );
}