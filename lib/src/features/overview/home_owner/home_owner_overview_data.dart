import 'package:flutter/material.dart';

import '../shared/overview_tone.dart';

enum RequestStatus {
  urgent('Urgent', OverviewTone.bad),
  open('Open', OverviewTone.warn),
  scheduled('Scheduled', OverviewTone.accent),
  done('Done', OverviewTone.good);

  const RequestStatus(this.label, this.tone);

  final String label;
  final OverviewTone tone;
}

class OwnerProperty {
  const OwnerProperty({required this.name, required this.kind, required this.rent, this.leaseEnds, this.vacantSince});

  final String name;
  final String kind;
  final int rent;
  final DateTime? leaseEnds;
  final DateTime? vacantSince;

  bool get rented => leaseEnds != null;
}

class OwnerRequest {
  const OwnerRequest({required this.title, required this.property, required this.status, required this.at, required this.icon});

  final String title;
  final String property;
  final RequestStatus status;
  final DateTime at;
  final IconData icon;

  bool get active => status == RequestStatus.urgent || status == RequestStatus.open;
}

class OwnerPayment {
  const OwnerPayment({required this.label, required this.property, required this.amount, required this.due, required this.income});

  final String label;
  final String property;
  final int amount;
  final DateTime due;
  final bool income;
}

/// A home owner's portfolio. Every figure on the overview is worked out from these lists, so the hero,
/// the cards and the chart always agree. Replace [sample] with a provider once the property service exists.
class HomeOwnerData {
  const HomeOwnerData({
    required this.now,
    required this.properties,
    required this.requests,
    required this.payments,
    required this.history,
  });

  final DateTime now;
  final List<OwnerProperty> properties;
  final List<OwnerRequest> requests;
  final List<OwnerPayment> payments;

  /// Rent collected in each of the last six months, oldest first.
  final List<int> history;

  factory HomeOwnerData.sample(DateTime now) {
    DateTime ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));
    DateTime ahead(int days) => now.add(Duration(days: days));
    return HomeOwnerData(
      now: now,
      properties: <OwnerProperty>[
        OwnerProperty(name: 'Riverside Apartment', kind: '2 bedrooms, apartment', rent: 45000, leaseEnds: ahead(280)),
        OwnerProperty(name: 'Garden Cottage', kind: '3 bedrooms, cottage', rent: 50000, leaseEnds: ahead(150)),
        OwnerProperty(name: 'City Studio', kind: '1 bedroom, studio', rent: 22000, vacantSince: ago(days: 12)),
      ],
      requests: <OwnerRequest>[
        OwnerRequest(title: 'Leaking tap', property: 'Riverside Apartment', status: RequestStatus.open, at: ago(hours: 2), icon: Icons.water_drop_outlined),
        OwnerRequest(title: 'Broken gate lock', property: 'Garden Cottage', status: RequestStatus.urgent, at: ago(hours: 26), icon: Icons.lock_outline_rounded),
        OwnerRequest(title: 'Plumbing inspection', property: 'Garden Cottage', status: RequestStatus.scheduled, at: ahead(5), icon: Icons.plumbing_outlined),
        OwnerRequest(title: 'Repainting finished', property: 'City Studio', status: RequestStatus.done, at: ago(days: 3), icon: Icons.format_paint_outlined),
      ],
      payments: <OwnerPayment>[
        OwnerPayment(label: 'Service charge', property: 'Riverside Apartment', amount: 5000, due: ahead(3), income: false),
        OwnerPayment(label: 'Rent', property: 'Garden Cottage', amount: 50000, due: ahead(5), income: true),
        OwnerPayment(label: 'Rent', property: 'Riverside Apartment', amount: 45000, due: ahead(7), income: true),
        OwnerPayment(label: 'Insurance premium', property: 'All properties', amount: 12000, due: ahead(14), income: false),
      ],
      history: const <int>[78000, 82000, 85000, 90000, 90000, 95000],
    );
  }

  List<OwnerProperty> get rentedProperties => properties.where((p) => p.rented).toList();

  int get monthlyIncome => rentedProperties.fold<int>(0, (sum, p) => sum + p.rent);

  int get occupancyPercent => properties.isEmpty ? 0 : (rentedProperties.length * 100 / properties.length).round();

  int get openRequests => requests.where((r) => r.active).length;

  int get urgentRequests => requests.where((r) => r.status == RequestStatus.urgent).length;

  int get expectedIn => payments.where((p) => p.income).fold<int>(0, (sum, p) => sum + p.amount);

  int get expectedOut => payments.where((p) => !p.income).fold<int>(0, (sum, p) => sum + p.amount);
}
