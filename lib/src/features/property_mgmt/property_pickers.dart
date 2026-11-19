import '../../core/utils/money.dart';
import '../../data/repositories/property_repository.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';

/// Choosing a person, unit or property by searching, so nobody has to copy an id from another screen.

String _join(Iterable<String> parts, [String separator = '  ']) => parts.where((e) => e.isNotEmpty).join(separator);

/// A tenant, found by typing part of a name, email or phone number.
FieldSpec tenantPicker(
  PropertyRepository repo, {
  String key = 'tenantId',
  String label = 'Tenant',
  bool required = false,
  String? helper,
}) {
  return FieldSpec(
    key,
    label,
    kind: FieldKind.picker,
    required: required,
    helper: helper ?? 'Search by name, email or phone number.',
    resolve: (id) async {
      final t = await repo.tenant(id);
      return PickOption(id, pick(t, <String>['fullName'], 'Tenant'));
    },
    searcher: (q) async {
      final found = await repo.searchTenants(q);
      return <PickOption>[
        for (final t in found)
          if (pick(t, <String>['id']).isNotEmpty)
            PickOption(
              pick(t, <String>['id']),
              pick(t, <String>['fullName'], 'Tenant'),
              description: _join(<String>[
                pick(t, <String>['email']),
                pick(t, <String>['phoneNumber']),
                t['isBlacklisted'] == true ? 'Blacklisted' : '',
              ]),
            ),
      ];
    },
  );
}

/// A unit out of every unit the owner has. The list shows the property it belongs to and what it rents for.
FieldSpec unitPicker(
  PropertyRepository repo, {
  String key = 'rentalUnitId',
  String label = 'Unit',
  bool required = false,
  String? helper,
}) {
  return FieldSpec(
    key,
    label,
    kind: FieldKind.picker,
    required: required,
    helper: helper,
    loader: () async {
      final units = await repo.allUnitsRaw();
      return <PickOption>[
        for (final u in units)
          if (pick(u, <String>['id', 'rentalUnitId']).isNotEmpty)
            PickOption(
              pick(u, <String>['id', 'rentalUnitId']),
              _join(<String>['Unit ${pick(u, <String>['unitNumber'], '-')}', pick(u, <String>['propertyTitle'])], ', '),
              description: _join(<String>[
                pick(u, <String>['status']).isEmpty ? '' : sentenceCase(pick(u, <String>['status'])),
                u['rentAmount'] is num ? '${formatMoney((u['rentAmount'] as num).toDouble())} a month' : '',
              ], ', '),
            ),
      ];
    },
  );
}

/// One of the owner's properties.
FieldSpec propertyPicker(
  PropertyRepository repo, {
  String key = 'propertyId',
  String label = 'Property',
  bool required = false,
  String? helper,
}) {
  return FieldSpec(
    key,
    label,
    kind: FieldKind.picker,
    required: required,
    helper: helper,
    loader: () async {
      final list = await repo.propertiesRaw();
      return <PickOption>[
        for (final p in list)
          if (pick(p, <String>['id', 'propertyId']).isNotEmpty)
            PickOption(
              pick(p, <String>['id', 'propertyId']),
              pick(p, <String>['title'], 'Property'),
              description: _join(<String>[pick(p, <String>['address.street']), pick(p, <String>['address.city'])], ', '),
            ),
      ];
    },
  );
}

String sentenceCase(String raw) {
  final s = raw.replaceAll('_', ' ').toLowerCase();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// The address fields of a property or a person, written the same way everywhere: a country box, a street search that
/// fills in the city, state, postal code and coordinates, and the boxes it fills.
List<FieldSpec> addressFields({
  String prefix = 'address',
  bool required = true,
  bool coordinates = true,
}) {
  String k(String name) => prefix.isEmpty ? name : '$prefix.$name';
  return <FieldSpec>[
    FieldSpec(k('country'), 'Country', kind: FieldKind.country, required: required),
    FieldSpec(
      k('street'),
      'Street or building',
      kind: FieldKind.address,
      required: required,
      countryKey: k('country'),
      fills: <String, String>{
        'street': k('street'),
        'city': k('city'),
        'state': k('state'),
        'postcode': k('postalCode'),
        'country': k('country'),
        if (coordinates) 'latitude': 'latitude',
        if (coordinates) 'longitude': 'longitude',
      },
    ),
    FieldSpec(k('city'), 'City or town', required: required),
    FieldSpec(k('state'), 'State or county'),
    FieldSpec(k('postalCode'), 'Postal code'),
  ];
}
