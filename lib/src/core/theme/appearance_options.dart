/// A font choice. [sans] is used for text, [display] for headings. A null family means the platform font.
class FontOption {
  const FontOption({required this.id, required this.name, required this.note, this.sans, this.display});

  final String id;
  final String name;
  final String note;
  final String? sans;
  final String? display;

  static const List<FontOption> all = <FontOption>[
    FontOption(id: 'premisave', name: 'Premisave', note: 'Plus Jakarta Sans, friendly and modern', sans: 'PlusJakartaSans', display: 'PlusJakartaSans'),
    FontOption(id: 'plex', name: 'IBM Plex', note: 'Condensed headings, engineered and compact', sans: 'IBMPlexSans', display: 'IBMPlexSansCondensed'),
    FontOption(id: 'inter', name: 'Inter', note: 'Neutral and crisp', sans: 'Inter', display: 'Inter'),
    FontOption(id: 'grotesk', name: 'Grotesk', note: 'Space Grotesk headings over DM Sans', sans: 'DMSans', display: 'SpaceGrotesk'),
    FontOption(id: 'editorial', name: 'Editorial', note: 'Fraunces headings over Source Sans', sans: 'SourceSans3', display: 'Fraunces'),
    FontOption(id: 'serif', name: 'Book', note: 'Source Serif throughout, for long reading', sans: 'SourceSerif4', display: 'SourceSerif4'),
    FontOption(id: 'legible', name: 'Legible', note: 'Atkinson Hyperlegible, built for easy reading', sans: 'AtkinsonHyperlegible', display: 'AtkinsonHyperlegible'),
    FontOption(id: 'mono', name: 'Mono', note: 'JetBrains Mono everywhere', sans: 'JetBrainsMono', display: 'JetBrainsMono'),
    FontOption(id: 'system', name: 'System', note: 'The font your device already uses'),
  ];

  static FontOption byId(String? id) => all.firstWhere((f) => f.id == id, orElse: () => all.first);
}

/// A corner style. [scale] multiplies every corner radius in the shared components.
class CornerOption {
  const CornerOption({required this.id, required this.name, required this.scale});

  final String id;
  final String name;
  final double scale;

  static const List<CornerOption> all = <CornerOption>[
    CornerOption(id: 'sharp', name: 'Sharp', scale: 0.15),
    CornerOption(id: 'standard', name: 'Standard', scale: 1),
    CornerOption(id: 'soft', name: 'Soft', scale: 1.5),
  ];

  static CornerOption byId(String? id) => all.firstWhere((c) => c.id == id, orElse: () => all[1]);
}
