import 'json_utils.dart';

class AddressModel {
  AddressModel.fromJson(Map<String, dynamic> j)
      : street = str(j['street']),
        city = str(j['city']),
        state = str(j['state']),
        country = str(j['country']);

  final String? street;
  final String? city;
  final String? state;
  final String? country;

  String get line => <String?>[street, city, country].where((e) => e != null && e.isNotEmpty).join(', ');
}

class PropertyModel {
  PropertyModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        title = strOr(j['title'], 'Property'),
        description = str(j['description']),
        propertyType = strOr(j['propertyType']),
        address = AddressModel.fromJson(asMap(j['address'])),
        registrationNumber = str(j['registrationNumber']),
        totalUnits = intOr(j['totalUnits']),
        availableUnits = intOr(j['availableUnits']),
        active = boolOr(j['isActive'] ?? j['active'], true),
        verified = boolOr(j['isVerified'] ?? j['verified']);

  final String id;
  final String title;
  final String? description;
  final String propertyType;
  final AddressModel address;
  final String? registrationNumber;
  final int totalUnits;
  final int availableUnits;
  final bool active;
  final bool verified;
}

class UnitModel {
  UnitModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        propertyId = str(j['propertyId']),
        unitNumber = str(j['unitNumber']),
        floor = str(j['floor']),
        rentAmount = doubleOrNull(j['rentAmount']),
        securityDeposit = doubleOrNull(j['securityDeposit']),
        status = strOr(j['status'], 'VACANT');

  final String id;
  final String? propertyId;
  final String? unitNumber;
  final String? floor;
  final double? rentAmount;
  final double? securityDeposit;

  /// VACANT, OCCUPIED, MAINTENANCE, RESERVED or UNAVAILABLE.
  final String status;

  String get label => unitNumber == null ? 'Unit' : 'Unit $unitNumber';
}

class LeaseModel {
  LeaseModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        tenantId = str(j['tenantId']),
        leaseType = str(j['leaseType']),
        startDate = dateOrNull(j['startDate']),
        endDate = dateOrNull(j['endDate']),
        monthlyRent = doubleOrNull(j['monthlyRent']),
        securityDeposit = doubleOrNull(j['securityDeposit']),
        status = strOr(j['status'], 'ACTIVE'),
        propertyTitle = str(asMap(j['property'])['title']),
        unitNumber = str(asMap(j['rentalUnit'])['unitNumber']),
        rentalUnitId = str(j['rentalUnitId']);

  final String id;
  final String? tenantId;
  final String? leaseType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? monthlyRent;
  final double? securityDeposit;
  final String status;
  final String? propertyTitle;
  final String? unitNumber;
  final String? rentalUnitId;

  String get where {
    final p = propertyTitle ?? 'Lease';
    return unitNumber == null ? p : '$p, unit $unitNumber';
  }
}

class RentBalanceModel {
  RentBalanceModel.fromJson(Map<String, dynamic> j)
      : leaseId = str(j['leaseId']),
        rentalUnitId = str(j['rentalUnitId']),
        balance = doubleOrNull(j['balance']) ?? 0,
        arrearsOwed = doubleOrNull(j['arrearsOwed']) ?? 0,
        creditAvailable = doubleOrNull(j['creditAvailable']) ?? 0,
        statusMessage = str(j['statusMessage']),
        lastPaymentAt = dateOrNull(j['lastPaymentAt']),
        propertyTitle = str(asMap(j['property'])['title']),
        unitNumber = str(asMap(j['unit'])['unitNumber']);

  final String? leaseId;
  final String? rentalUnitId;

  /// Positive when the tenant owes rent, negative when they are ahead.
  final double balance;
  final double arrearsOwed;
  final double creditAvailable;
  final String? statusMessage;
  final DateTime? lastPaymentAt;
  final String? propertyTitle;
  final String? unitNumber;

  String get where {
    final p = propertyTitle ?? 'Rent';
    return unitNumber == null ? p : '$p, unit $unitNumber';
  }
}

/// What a tenant owes or is ahead by in total, and the figure for each lease and unit.
class RentSummary {
  RentSummary.fromJson(Map<String, dynamic> j)
      : totalArrearsOwed = doubleOrNull(j['totalArrearsOwed']) ?? 0,
        totalCreditAvailable = doubleOrNull(j['totalCreditAvailable']) ?? 0,
        netBalance = doubleOrNull(j['netBalance']) ?? 0,
        breakdown = mapList(j['breakdown']).map(RentBalanceModel.fromJson).toList();

  final double totalArrearsOwed;
  final double totalCreditAvailable;

  /// Positive when the tenant owes rent overall, negative when they are ahead.
  final double netBalance;
  final List<RentBalanceModel> breakdown;
}

class MaintenanceModel {
  MaintenanceModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        rentalUnitId = str(j['rentalUnitId']),
        title = strOr(j['title'], 'Request'),
        description = str(j['description']),
        status = strOr(j['status'], 'PENDING'),
        unitNumber = str(asMap(j['rentalUnit'])['unitNumber']) ?? str(asMap(j['unit'])['unitNumber']),
        propertyTitle = str(asMap(j['property'])['title']),
        tenantName = str(asMap(j['tenant'])['fullName']),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final String? rentalUnitId;
  final String title;
  final String? description;

  /// PENDING, IN_PROGRESS, COMPLETED or CANCELLED.
  final String status;
  final String? unitNumber;
  final String? propertyTitle;
  final String? tenantName;
  final DateTime? createdAt;
}

class NoticeModel {
  NoticeModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        noticeType = strOr(j['noticeType']),
        title = strOr(j['title'], 'Notice'),
        content = str(j['content']),
        sentAt = dateOrNull(j['sentAt']);

  final String id;
  final String noticeType;
  final String title;
  final String? content;
  final DateTime? sentAt;
}

class TenantProfile {
  TenantProfile.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        fullName = strOr(j['fullName']),
        email = str(j['email']),
        phoneNumber = str(j['phoneNumber']);

  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
}

class OwnerDashboard {
  OwnerDashboard.fromJson(Map<String, dynamic> j)
      : totalProperties = intOr(j['totalProperties']),
        totalUnits = intOr(j['totalUnits']),
        occupiedUnits = intOr(j['occupiedUnits']),
        activeLeases = intOr(j['activeLeases']),
        monthlyRevenue = doubleOrNull(j['monthlyRevenue']) ?? 0,
        pendingMaintenance = intOr(j['pendingMaintenance']),
        occupancy = mapList(j['properties']).map(PropertyOccupancy.fromJson).toList(),
        pendingRequests = mapList(j['pendingMaintenanceRequests']).map(MaintenanceModel.fromJson).toList();

  final int totalProperties;
  final int totalUnits;
  final int occupiedUnits;
  final int activeLeases;
  final double monthlyRevenue;
  final int pendingMaintenance;
  final List<PropertyOccupancy> occupancy;
  final List<MaintenanceModel> pendingRequests;

  double get occupancyRate => totalUnits == 0 ? 0 : occupiedUnits / totalUnits;
}

class PropertyOccupancy {
  PropertyOccupancy.fromJson(Map<String, dynamic> j)
      : id = strOr(asMap(j['property'])['id']),
        title = strOr(asMap(j['property'])['title'], 'Property'),
        totalUnits = intOr(j['totalUnits']),
        occupiedUnits = intOr(j['occupiedUnits']),
        occupancyRate = doubleOrNull(j['occupancyRate']) ?? 0;

  final String id;
  final String title;
  final int totalUnits;
  final int occupiedUnits;
  final double occupancyRate;
}

/// What the tenant owes for a unit now, from GET /api/v1/rent/units/due/{unitId}.
class PaymentDue {
  PaymentDue.fromJson(Map<String, dynamic> j)
      : rentDue = doubleOrNull(j['rentDue']) ?? 0,
        depositDue = doubleOrNull(j['depositDue']) ?? 0,
        totalDue = doubleOrNull(j['totalDue']) ?? 0;

  final double rentDue;
  final double depositDue;
  final double totalDue;
}
