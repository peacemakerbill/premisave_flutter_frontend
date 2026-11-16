import 'package:flutter/material.dart';

import '../shared/overview_tone.dart';

enum ListingStatus {
  forSale('For sale', OverviewTone.accent),
  underOffer('Under offer', OverviewTone.warn),
  fresh('New', OverviewTone.good);

  const ListingStatus(this.label, this.tone);

  final String label;
  final OverviewTone tone;
}

class Listing {
  const Listing({required this.name, required this.place, required this.price, required this.status, required this.listedAt});

  final String name;
  final String place;
  final int price;
  final ListingStatus status;
  final DateTime listedAt;
}

class ActivityEvent {
  const ActivityEvent({required this.title, required this.detail, required this.at, required this.icon, required this.tone});

  final String title;
  final String detail;
  final DateTime at;
  final IconData icon;
  final OverviewTone tone;
}

class AgentResult {
  const AgentResult({required this.name, required this.role, required this.deals, required this.revenue});

  final String name;
  final String role;
  final int deals;
  final int revenue;
}

/// Operations figures. Replace [sample] with a provider once the listing service feeds this screen.
class OperationsData {
  const OperationsData({
    required this.now,
    required this.listings,
    required this.events,
    required this.agents,
    required this.activeListings,
    required this.dealsClosed,
    required this.revenue,
    required this.daysOnMarket,
  });

  final DateTime now;
  final List<Listing> listings;
  final List<ActivityEvent> events;
  final List<AgentResult> agents;
  final int activeListings;
  final int dealsClosed;
  final int revenue;
  final int daysOnMarket;

  factory OperationsData.sample(DateTime now) {
    DateTime ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));
    return OperationsData(
      now: now,
      listings: <Listing>[
        Listing(name: 'Westlands Penthouse', place: '4 bedrooms, Westlands', price: 28500000, status: ListingStatus.forSale, listedAt: ago(days: 14)),
        Listing(name: 'Karen Villa Estate', place: '5 bedrooms, Karen', price: 65000000, status: ListingStatus.underOffer, listedAt: ago(days: 7)),
        Listing(name: 'Kilimani Apartment', place: '2 bedrooms, Kilimani', price: 8200000, status: ListingStatus.forSale, listedAt: ago(days: 22)),
        Listing(name: 'Runda Mansion', place: '6 bedrooms, Runda', price: 120000000, status: ListingStatus.fresh, listedAt: ago(days: 3)),
        Listing(name: 'Lavington Townhouse', place: '3 bedrooms, Lavington', price: 18000000, status: ListingStatus.forSale, listedAt: ago(days: 19)),
      ],
      events: <ActivityEvent>[
        ActivityEvent(title: 'New offer received', detail: 'Karen Villa Estate', at: ago(hours: 2), icon: Icons.local_offer_outlined, tone: OverviewTone.warn),
        ActivityEvent(title: 'Viewing scheduled', detail: 'Westlands Penthouse', at: ago(hours: 5), icon: Icons.calendar_today_outlined, tone: OverviewTone.accent),
        ActivityEvent(title: 'Document signed', detail: 'Kilimani Apartment sale agreement', at: ago(days: 1), icon: Icons.task_alt_rounded, tone: OverviewTone.good),
        ActivityEvent(title: 'Price reduced', detail: 'Lavington Townhouse', at: ago(days: 1, hours: 4), icon: Icons.price_change_outlined, tone: OverviewTone.bad),
        ActivityEvent(title: 'Listing published', detail: 'Runda Mansion', at: ago(days: 2), icon: Icons.publish_rounded, tone: OverviewTone.good),
      ],
      agents: const <AgentResult>[
        AgentResult(name: 'Amara Osei', role: 'Senior agent', deals: 14, revenue: 18400000),
        AgentResult(name: 'Nadia Mwangi', role: 'Agent', deals: 11, revenue: 14200000),
        AgentResult(name: 'James Kariuki', role: 'Associate', deals: 9, revenue: 11800000),
        AgentResult(name: 'Priya Desai', role: 'Agent', deals: 7, revenue: 9100000),
      ],
      activeListings: 124,
      dealsClosed: 37,
      revenue: 48200000,
      daysOnMarket: 21,
    );
  }

  int daysListed(Listing l) => now.difference(l.listedAt).inDays;
}
