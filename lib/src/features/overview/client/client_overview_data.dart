class UpcomingStay {
  const UpcomingStay({required this.property, required this.place, required this.start, required this.nights, required this.total});

  final String property;
  final String place;
  final DateTime start;
  final int nights;
  final int total;

  DateTime get end => start.add(Duration(days: nights));
}

class TrendingProperty {
  const TrendingProperty({required this.title, required this.location, required this.nightly, required this.rating, required this.image});

  final String title;
  final String location;
  final int nightly;
  final double rating;
  final String image;
}

/// A client's bookings and suggestions. Replace [sample] with a provider once the booking service exists.
class ClientData {
  const ClientData({required this.now, required this.stays, required this.trending, required this.savedCount, required this.totalSpent});

  final DateTime now;
  final List<UpcomingStay> stays;
  final List<TrendingProperty> trending;
  final int savedCount;
  final int totalSpent;

  factory ClientData.sample(DateTime now) {
    return ClientData(
      now: now,
      stays: <UpcomingStay>[
        UpcomingStay(property: 'Ocean View Villa', place: 'Diani Beach', start: now.add(const Duration(days: 12)), nights: 5, total: 950),
        UpcomingStay(property: 'Mountain Cabin', place: 'Mount Kenya', start: now.add(const Duration(days: 31)), nights: 3, total: 275),
      ],
      trending: const <TrendingProperty>[
        TrendingProperty(title: 'Ocean View Villa', location: 'Diani Beach', nightly: 190, rating: 4.9, image: 'https://picsum.photos/id/1015/400/220'),
        TrendingProperty(title: 'Modern Penthouse', location: 'City centre', nightly: 95, rating: 4.8, image: 'https://picsum.photos/id/106/400/220'),
        TrendingProperty(title: 'Forest Retreat', location: 'Aberdare', nightly: 75, rating: 4.95, image: 'https://picsum.photos/id/1018/400/220'),
      ],
      savedCount: 12,
      totalSpent: 3400,
    );
  }

  /// Whole days until the first stay starts, or null when nothing is booked.
  int? get daysToNextStay {
    if (stays.isEmpty) return null;
    final first = stays.map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month, first.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
