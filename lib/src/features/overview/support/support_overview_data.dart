import 'package:flutter/material.dart';

import '../shared/overview_tone.dart';

enum TicketPriority {
  high('High', OverviewTone.bad),
  medium('Medium', OverviewTone.warn),
  low('Low', OverviewTone.good);

  const TicketPriority(this.label, this.tone);

  final String label;
  final OverviewTone tone;
}

class SupportTicket {
  const SupportTicket({required this.title, required this.detail, required this.priority, required this.openedAt});

  final String title;
  final String detail;
  final TicketPriority priority;
  final DateTime openedAt;
}

class SupportEvent {
  const SupportEvent({required this.title, required this.detail, required this.at, required this.icon, required this.tone});

  final String title;
  final String detail;
  final DateTime at;
  final IconData icon;
  final OverviewTone tone;
}

class SupportAgent {
  const SupportAgent({required this.name, required this.role, required this.resolved, required this.resolutionRate});

  final String name;
  final String role;
  final int resolved;
  final int resolutionRate;
}

/// Support figures. Replace [sample] with a provider once the ticketing service exists.
class SupportData {
  const SupportData({
    required this.now,
    required this.tickets,
    required this.events,
    required this.agents,
    required this.openTickets,
    required this.averageResponse,
    required this.resolutionRate,
    required this.satisfaction,
  });

  final DateTime now;
  final List<SupportTicket> tickets;
  final List<SupportEvent> events;
  final List<SupportAgent> agents;
  final int openTickets;
  final String averageResponse;
  final int resolutionRate;
  final String satisfaction;

  factory SupportData.sample(DateTime now) {
    DateTime ago({int days = 0, int hours = 0, int minutes = 0}) => now.subtract(Duration(days: days, hours: hours, minutes: minutes));
    return SupportData(
      now: now,
      tickets: <SupportTicket>[
        SupportTicket(title: 'Payment issue', detail: 'Karen Villa, invoice INV-3921', priority: TicketPriority.high, openedAt: ago(hours: 2)),
        SupportTicket(title: 'Login problem', detail: 'A Westlands user cannot sign in', priority: TicketPriority.medium, openedAt: ago(hours: 5)),
        SupportTicket(title: 'Property listing', detail: 'Request to verify Runda Mansion', priority: TicketPriority.low, openedAt: ago(days: 1)),
        SupportTicket(title: 'Commission dispute', detail: 'Lavington Townhouse', priority: TicketPriority.medium, openedAt: ago(days: 1, hours: 3)),
      ],
      events: <SupportEvent>[
        SupportEvent(title: 'Ticket resolved', detail: 'Payment issue, Karen Villa', at: ago(minutes: 12), icon: Icons.check_circle_rounded, tone: OverviewTone.good),
        SupportEvent(title: 'Ticket assigned', detail: 'SUP-4812 to James Kariuki', at: ago(minutes: 47), icon: Icons.assignment_rounded, tone: OverviewTone.accent),
        SupportEvent(title: 'User replied', detail: 'Login problem', at: ago(hours: 2), icon: Icons.reply_rounded, tone: OverviewTone.warn),
      ],
      agents: const <SupportAgent>[
        SupportAgent(name: 'Amara Osei', role: 'Senior support', resolved: 28, resolutionRate: 98),
        SupportAgent(name: 'James Kariuki', role: 'Support lead', resolved: 24, resolutionRate: 95),
        SupportAgent(name: 'Nadia Mwangi', role: 'Support agent', resolved: 19, resolutionRate: 92),
        SupportAgent(name: 'Priya Desai', role: 'Support agent', resolved: 15, resolutionRate: 89),
      ],
      openTickets: 47,
      averageResponse: '1.8 hrs',
      resolutionRate: 94,
      satisfaction: '4.7 / 5',
    );
  }

  List<SupportTicket> get urgent => tickets.where((t) => t.priority == TicketPriority.high).toList();
}
