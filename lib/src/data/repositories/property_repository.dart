import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/property_models.dart';

/// The property management service. Its answers are plain JSON, not wrapped.
class PropertyRepository {
  PropertyRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  // -------------------------------------------------------------------- owner

  Future<bool> ownerExists() async => boolOr(asMap(await _api.get('/api/v1/owners/me/exists'))['exists']);

  /// Creates the owner profile from the person's auth-service account.
  Future<void> createOwnerProfile() => _api.post('/api/v1/owners/quick');

  Future<OwnerDashboard> dashboard() async => OwnerDashboard.fromJson(asMap(await _api.get('/api/v1/dashboard/owner')));

  Future<List<PropertyModel>> myProperties() async =>
      mapList(await _api.get('/api/v1/properties/me')).map(PropertyModel.fromJson).toList();

  Future<List<UnitModel>> units(String propertyId) async =>
      mapList(await _api.get('/api/v1/units/property/${_id(propertyId)}')).map(UnitModel.fromJson).toList();

  Future<List<LeaseModel>> ownerLeases() async =>
      mapList(await _api.get('/api/v1/leases/owner')).map(LeaseModel.fromJson).toList();

  Future<List<MaintenanceModel>> maintenanceByStatus(String status) async =>
      mapList(await _api.get('/api/v1/maintenance', query: <String, dynamic>{'status': status})).map(MaintenanceModel.fromJson).toList();

  Future<void> setMaintenanceStatus(String id, String status) =>
      _api.patch('/api/v1/maintenance/${_id(id)}/status', body: <String, dynamic>{'status': status});

  // ------------------------------------------------------------------- tenant

  /// The tenant profile, or null when the person has not registered as a tenant yet.
  Future<TenantProfile?> myTenantProfile() async {
    try {
      return TenantProfile.fromJson(asMap(await _api.get('/api/v1/tenants/me')));
    } catch (e) {
      // The service answers 404 until the person registers. Any other failure is a real problem.
      if (e.toString().toLowerCase().contains('not found') || e.toString().toLowerCase().contains('could not find')) {
        return null;
      }
      rethrow;
    }
  }

  /// Registers the person as a tenant using their auth-service account.
  Future<TenantProfile> registerAsTenant() async =>
      TenantProfile.fromJson(asMap(await _api.post('/api/v1/tenants/quick-register')));

  /// The tenant's rent position across every lease and unit they rent.
  Future<RentSummary> myRentSummary() async => RentSummary.fromJson(asMap(await _api.get('/api/v1/rent/balance/me')));

  Future<List<LeaseModel>> myLeases(String tenantId) async =>
      mapList(await _api.get('/api/v1/leases/tenant/${_id(tenantId)}')).map(LeaseModel.fromJson).toList();

  Future<List<MaintenanceModel>> myMaintenance(String tenantId) async =>
      mapList(await _api.get('/api/v1/maintenance/tenant/${_id(tenantId)}')).map(MaintenanceModel.fromJson).toList();

  Future<void> requestMaintenance({required String rentalUnitId, required String title, String? description}) =>
      _api.post('/api/v1/maintenance', body: compact(<String, dynamic>{
        'rentalUnitId': rentalUnitId,
        'title': title,
        'description': description,
      }));

  Future<List<NoticeModel>> myNotices(String tenantId) async =>
      mapList(await _api.get('/api/v1/notices/tenant/${_id(tenantId)}')).map(NoticeModel.fromJson).toList();

  Future<PaymentDue> rentDue(String rentalUnitId) async =>
      PaymentDue.fromJson(asMap(await _api.get('/api/v1/rent/units/due/${_id(rentalUnitId)}')));

  /// Pays rent for a unit from the tenant's wallet.
  Future<void> payUnitRent({required String rentalUnitId, required double amount}) =>
      _api.post('/api/v1/rent/units/pay', body: <String, dynamic>{
        'rentalUnitId': rentalUnitId,
        'amount': amount,
        'paymentMethod': 'WALLET',
      });

  /// Pays rent for a lease from the tenant's wallet.
  Future<void> payLeaseRent({required String leaseId, required double amount}) =>
      _api.post('/api/v1/rent/pay', body: <String, dynamic>{
        'leaseId': leaseId,
        'amount': amount,
        'paymentMethod': 'WALLET',
      });

  // ------------------------------------------------- everything as the service sends it
  // The methods below return the service's own JSON so every field of a record can be shown and edited.

  String _d(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Map<String, dynamic>>> _list(String path, {Map<String, dynamic>? query}) async => mapList(await _api.get(path, query: query));

  Future<Map<String, dynamic>> _one(Future<dynamic> call) async => asMap(await call);

  // ------------------------------------------------------------------- owner

  Future<Map<String, dynamic>> ownerProfile() => _one(_api.get('/api/v1/owners/me'));

  Future<Map<String, dynamic>> owner(String id) => _one(_api.get('/api/v1/owners/${_id(id)}'));

  /// Creates the owner profile with details typed in, for an owner who does not want the account details copied.
  Future<Map<String, dynamic>> createOwner(Map<String, dynamic> request) => _one(_api.post('/api/v1/owners', body: compact(request)));

  /// Changes the profile: name, phone, email, address and bank details (for payouts).
  Future<Map<String, dynamic>> updateOwner(String id, Map<String, dynamic> changes) => _one(_api.patch('/api/v1/owners/${_id(id)}', body: changes));

  /// Whether the owner profile differs from the Premisave account and could be synced.
  Future<Map<String, dynamic>> ownerSyncStatus() => _one(_api.get('/api/v1/owners/me/sync-status'));

  /// Copies name, phone and email from the Premisave account onto the owner profile.
  Future<Map<String, dynamic>> syncOwner() => _one(_api.post('/api/v1/owners/me/sync'));

  // --------------------------------------------------------------- properties

  Future<List<Map<String, dynamic>>> propertiesRaw() => _list('/api/v1/properties/me');

  Future<Map<String, dynamic>> property(String id) => _one(_api.get('/api/v1/properties/${_id(id)}'));

  /// Every unit of every property the owner has, each carrying its property's title as `propertyTitle`, so a unit can be
  /// chosen from one list without knowing which property it is in.
  Future<List<Map<String, dynamic>>> allUnitsRaw() async {
    final properties = await propertiesRaw();
    final groups = await Future.wait(properties.map((p) async {
      final id = '${p['id'] ?? p['propertyId'] ?? ''}';
      if (id.isEmpty) return <Map<String, dynamic>>[];
      try {
        final units = await unitsRaw(id);
        return <Map<String, dynamic>>[
          for (final u in units) <String, dynamic>{...u, 'propertyTitle': p['title'], 'propertyId': u['propertyId'] ?? id},
        ];
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }));
    return <Map<String, dynamic>>[for (final g in groups) ...g];
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> request) => _one(_api.post('/api/v1/properties', body: request));

  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> changes) => _one(_api.patch('/api/v1/properties/${_id(id)}', body: changes));

  Future<void> deleteProperty(String id) => _api.delete('/api/v1/properties/${_id(id)}');

  // -------------------------------------------------------------------- units

  Future<List<Map<String, dynamic>>> unitsRaw(String propertyId) => _list('/api/v1/units/property/${_id(propertyId)}');

  Future<Map<String, dynamic>> unit(String id) => _one(_api.get('/api/v1/units/${_id(id)}'));

  Future<Map<String, dynamic>> createUnit(String propertyId, Map<String, dynamic> request) =>
      _one(_api.post('/api/v1/units/property/${_id(propertyId)}', body: compact(request)));

  Future<Map<String, dynamic>> updateUnit(String id, Map<String, dynamic> changes) => _one(_api.patch('/api/v1/units/${_id(id)}', body: changes));

  Future<void> deleteUnit(String id) => _api.delete('/api/v1/units/${_id(id)}');

  // ------------------------------------------------------------------ tenants

  Future<Map<String, dynamic>> tenantProfile() => _one(_api.get('/api/v1/tenants/me'));

  /// Tenants matching part of a name, email or phone number. Contact details come back partly hidden.
  Future<List<Map<String, dynamic>>> searchTenants(String query) => _list('/api/v1/tenants/search', query: <String, dynamic>{'q': query});

  Future<Map<String, dynamic>> tenant(String id) => _one(_api.get('/api/v1/tenants/${_id(id)}'));

  /// Registers a tenant with details typed in. [request] has fullName, phoneNumber, email, idNumber and currentAddress.
  Future<Map<String, dynamic>> registerTenant(Map<String, dynamic> request) => _one(_api.post('/api/v1/tenants/register', body: compact(request)));

  Future<Map<String, dynamic>> updateMyTenantProfile(Map<String, dynamic> changes) => _one(_api.patch('/api/v1/tenants/me', body: changes));

  Future<Map<String, dynamic>> tenantSyncStatus() => _one(_api.get('/api/v1/tenants/me/sync-status'));

  Future<Map<String, dynamic>> syncTenant() => _one(_api.post('/api/v1/tenants/me/sync'));

  // ------------------------------------------------------------------- leases

  Future<List<Map<String, dynamic>>> allLeases() => _list('/api/v1/leases');

  Future<List<Map<String, dynamic>>> ownerLeasesRaw() => _list('/api/v1/leases/owner');

  Future<List<Map<String, dynamic>>> tenantLeases(String tenantId) => _list('/api/v1/leases/tenant/${_id(tenantId)}');

  Future<Map<String, dynamic>> lease(String id) => _one(_api.get('/api/v1/leases/${_id(id)}'));

  /// Needs a tenant id, a unit id or a property id (one of them), dates and the monthly rent.
  Future<Map<String, dynamic>> createLease(Map<String, dynamic> request) => _one(_api.post('/api/v1/leases', body: compact(request)));

  Future<Map<String, dynamic>> updateLease(String id, Map<String, dynamic> changes) => _one(_api.patch('/api/v1/leases/${_id(id)}', body: changes));

  Future<Map<String, dynamic>> terminateLease(String id) => _one(_api.post('/api/v1/leases/${_id(id)}/terminate'));

  Future<List<Map<String, dynamic>>> rentSchedule(String leaseId) => _list('/api/v1/rent-schedules/lease/${_id(leaseId)}');

  // --------------------------------------------------------------------- rent

  Future<Map<String, dynamic>> leaseRentDue(String leaseId) => _one(_api.get('/api/v1/rent/due/${_id(leaseId)}'));

  Future<List<Map<String, dynamic>>> leaseRentHistory(String leaseId) => _list('/api/v1/rent/history/${_id(leaseId)}');

  Future<Map<String, dynamic>> unitRentDue(String unitId, {String? tenantId}) => _one(_api.get(
        tenantId == null ? '/api/v1/rent/units/due/${_id(unitId)}' : '/api/v1/rent/units/due/${_id(unitId)}/tenant/${_id(tenantId)}',
      ));

  Future<List<Map<String, dynamic>>> unitRentHistory(String unitId) => _list('/api/v1/rent/units/history/${_id(unitId)}');

  /// [reference] makes a retry safe: the tenant is never charged twice for the same one.
  Future<Map<String, dynamic>> payLeaseRentRaw(String leaseId, double amount, {String? reference}) =>
      _one(_api.post('/api/v1/rent/pay', body: compact(<String, dynamic>{'leaseId': leaseId, 'amount': amount, 'paymentMethod': 'WALLET', 'reference': reference})));

  Future<Map<String, dynamic>> payUnitRentRaw(String unitId, double amount, {String? reference}) =>
      _one(_api.post('/api/v1/rent/units/pay', body: compact(<String, dynamic>{'rentalUnitId': unitId, 'amount': amount, 'paymentMethod': 'WALLET', 'reference': reference})));

  Future<Map<String, dynamic>> leaseBalance(String leaseId) => _one(_api.get('/api/v1/rent/balance/lease/${_id(leaseId)}'));

  Future<Map<String, dynamic>> myBalanceSummary() => _one(_api.get('/api/v1/rent/balance/me'));

  Future<Map<String, dynamic>> tenantBalanceSummary(String tenantId) => _one(_api.get('/api/v1/rent/balance/tenant/${_id(tenantId)}'));

  Future<Map<String, dynamic>> myUnitBalance(String unitId) => _one(_api.get('/api/v1/rent/balance/unit/${_id(unitId)}/me'));

  Future<Map<String, dynamic>> unitBalanceForTenant(String unitId, String tenantId) =>
      _one(_api.get('/api/v1/rent/balance/unit/${_id(unitId)}/tenant/${_id(tenantId)}'));

  // ------------------------------------------------------------- maintenance

  Future<List<Map<String, dynamic>>> maintenanceRaw(String status) => _list('/api/v1/maintenance', query: <String, dynamic>{'status': status});

  Future<List<Map<String, dynamic>>> maintenanceForTenant(String tenantId) => _list('/api/v1/maintenance/tenant/${_id(tenantId)}');

  Future<List<Map<String, dynamic>>> maintenanceForUnit(String unitId) => _list('/api/v1/maintenance/unit/${_id(unitId)}');

  Future<Map<String, dynamic>> maintenanceRequest(String id) => _one(_api.get('/api/v1/maintenance/${_id(id)}'));

  Future<Map<String, dynamic>> createMaintenance(Map<String, dynamic> request) => _one(_api.post('/api/v1/maintenance', body: compact(request)));

  /// [status] is PENDING, IN_PROGRESS, COMPLETED or CANCELLED.
  Future<Map<String, dynamic>> updateMaintenanceStatus(String id, String status) =>
      _one(_api.patch('/api/v1/maintenance/${_id(id)}/status', body: <String, dynamic>{'status': status}));

  // -------------------------------------------------------------- work orders

  Future<List<Map<String, dynamic>>> workOrders(String status) => _list('/api/v1/work-orders', query: <String, dynamic>{'status': status});

  Future<List<Map<String, dynamic>>> workOrdersForRequest(String maintenanceRequestId) =>
      _list('/api/v1/work-orders/maintenance/${_id(maintenanceRequestId)}');

  Future<List<Map<String, dynamic>>> workOrdersForAssignee(String assignedTo) => _list('/api/v1/work-orders/assignee/${_id(assignedTo)}');

  Future<Map<String, dynamic>> workOrder(String id) => _one(_api.get('/api/v1/work-orders/${_id(id)}'));

  Future<Map<String, dynamic>> createWorkOrder(Map<String, dynamic> request) => _one(_api.post('/api/v1/work-orders', body: compact(request)));

  /// [status] is ASSIGNED, IN_PROGRESS, COMPLETED or CANCELLED.
  Future<Map<String, dynamic>> updateWorkOrderStatus(String id, String status) =>
      _one(_api.patch('/api/v1/work-orders/${_id(id)}/status', body: <String, dynamic>{'status': status}));

  // -------------------------------------------------------------- inspections

  /// [status] is SCHEDULED, COMPLETED or CANCELLED.
  Future<List<Map<String, dynamic>>> myInspections(String status) => _list('/api/v1/inspections/me', query: <String, dynamic>{'status': status});

  Future<List<Map<String, dynamic>>> inspectionsForUnit(String unitId) => _list('/api/v1/inspections/unit/${_id(unitId)}');

  Future<List<Map<String, dynamic>>> inspectionsByInspector(String userId) => _list('/api/v1/inspections/inspector/${_id(userId)}');

  Future<List<Map<String, dynamic>>> inspectionsCreatedBy(String userId) => _list('/api/v1/inspections/created-by/${_id(userId)}');

  Future<Map<String, dynamic>> inspection(String id) => _one(_api.get('/api/v1/inspections/${_id(id)}'));

  Future<Map<String, dynamic>> createInspection(Map<String, dynamic> request) => _one(_api.post('/api/v1/inspections', body: compact(request)));

  Future<Map<String, dynamic>> completeInspection(String id, {required String findings, String? recommendations}) => _one(_api.post(
        '/api/v1/inspections/${_id(id)}/complete',
        body: compact(<String, dynamic>{'findings': findings, 'recommendations': recommendations}),
      ));

  Future<Map<String, dynamic>> cancelInspection(String id) => _one(_api.post('/api/v1/inspections/${_id(id)}/cancel'));

  // ------------------------------------------------------------ meter readings

  Future<Map<String, dynamic>> recordReading({required String rentalUnitId, required String meterType, required double currentReading}) => _one(
        _api.post('/api/v1/meter-readings', body: <String, dynamic>{'rentalUnitId': rentalUnitId, 'meterType': meterType, 'currentReading': currentReading}),
      );

  Future<List<Map<String, dynamic>>> readingsForUnit(String unitId) => _list('/api/v1/meter-readings/unit/${_id(unitId)}');

  Future<Map<String, dynamic>> reading(String id) => _one(_api.get('/api/v1/meter-readings/${_id(id)}'));

  // ------------------------------------------------------------ utility bills

  Future<Map<String, dynamic>> generateBill(Map<String, dynamic> request) => _one(_api.post('/api/v1/utility-bills', body: compact(request)));

  Future<Map<String, dynamic>> billFromReading(String meterReadingId, {double? ratePerUnit}) => _one(_api.post(
        '/api/v1/utility-bills/from-reading',
        body: compact(<String, dynamic>{'meterReadingId': meterReadingId, 'ratePerUnit': ratePerUnit}),
      ));

  Future<Map<String, dynamic>> payBill(String billId, double amount, {String? reference}) => _one(_api.post(
        '/api/v1/utility-bills/pay',
        body: compact(<String, dynamic>{'billId': billId, 'amount': amount, 'paymentMethod': 'WALLET', 'reference': reference}),
      ));

  Future<Map<String, dynamic>> bill(String id) => _one(_api.get('/api/v1/utility-bills/${_id(id)}'));

  Future<List<Map<String, dynamic>>> billsForUnit(String unitId) => _list('/api/v1/utility-bills/unit/${_id(unitId)}');

  Future<List<Map<String, dynamic>>> billsForTenant(String tenantId) => _list('/api/v1/utility-bills/tenant/${_id(tenantId)}');

  Future<List<Map<String, dynamic>>> outstandingBills(String tenantId) => _list('/api/v1/utility-bills/tenant/${_id(tenantId)}/outstanding');

  // ------------------------------------------------------------------ notices

  Future<Map<String, dynamic>> notice(String id) => _one(_api.get('/api/v1/notices/${_id(id)}'));

  Future<List<Map<String, dynamic>>> noticesForTenant(String tenantId, {String? type}) =>
      _list(type == null ? '/api/v1/notices/tenant/${_id(tenantId)}' : '/api/v1/notices/tenant/${_id(tenantId)}/type/${_id(type)}');

  Future<List<Map<String, dynamic>>> noticesForLease(String leaseId) => _list('/api/v1/notices/lease/${_id(leaseId)}');

  Future<Map<String, dynamic>> sendLeaseNotice({required String leaseId, required String noticeType, required String title, required String content}) =>
      _one(_api.post('/api/v1/notices/lease', body: <String, dynamic>{'leaseId': leaseId, 'noticeType': noticeType, 'title': title, 'content': content}));

  Future<Map<String, dynamic>> sendUnitNotice({required String rentalUnitId, String? tenantId, required String noticeType, required String title, required String content}) =>
      _one(_api.post('/api/v1/notices/unit', body: compact(<String, dynamic>{'rentalUnitId': rentalUnitId, 'tenantId': tenantId, 'noticeType': noticeType, 'title': title, 'content': content})));

  /// A notice to many people at once, now or at a set time. [request] has rentalUnitIds and or leaseIds, noticeType,
  /// title, content, channels (EMAIL) and scheduledAt.
  Future<Map<String, dynamic>> sendBulkNotice(Map<String, dynamic> request) => _one(_api.post('/api/v1/notices/bulk', body: compact(request)));

  Future<List<Map<String, dynamic>>> myBulkNotices() => _list('/api/v1/notices/bulk/mine');

  Future<Map<String, dynamic>> bulkNotice(String id) => _one(_api.get('/api/v1/notices/bulk/${_id(id)}'));

  Future<Map<String, dynamic>> cancelBulkNotice(String id) => _one(_api.post('/api/v1/notices/bulk/${_id(id)}/cancel'));

  // ---------------------------------------------------------------- occupancy

  Future<Map<String, dynamic>> moveInViaLease(String leaseId) => _one(_api.post('/api/v1/occupancy/move-in/lease', query: <String, dynamic>{'leaseId': leaseId}));

  Future<Map<String, dynamic>> moveOutViaLease(String leaseId) => _one(_api.post('/api/v1/occupancy/move-out/lease', query: <String, dynamic>{'leaseId': leaseId}));

  Future<Map<String, dynamic>> moveInDirect(String rentalUnitId, String tenantId) =>
      _one(_api.post('/api/v1/occupancy/move-in/direct', query: <String, dynamic>{'rentalUnitId': rentalUnitId, 'tenantId': tenantId}));

  Future<Map<String, dynamic>> moveOutDirect(String rentalUnitId, String tenantId) =>
      _one(_api.post('/api/v1/occupancy/move-out/direct', query: <String, dynamic>{'rentalUnitId': rentalUnitId, 'tenantId': tenantId}));

  Future<List<Map<String, dynamic>>> unitOccupancyHistory(String unitId) => _list('/api/v1/occupancy/unit/${_id(unitId)}');

  Future<Map<String, dynamic>> unitCurrentOccupancy(String unitId) => _one(_api.get('/api/v1/occupancy/unit/${_id(unitId)}/current'));

  Future<List<Map<String, dynamic>>> propertyOccupancyHistory(String propertyId) => _list('/api/v1/occupancy/property/${_id(propertyId)}');

  Future<Map<String, dynamic>> propertyCurrentOccupancy(String propertyId) => _one(_api.get('/api/v1/occupancy/property/${_id(propertyId)}/current'));

  Future<List<Map<String, dynamic>>> tenantOccupancyHistory(String tenantId) => _list('/api/v1/occupancy/tenant/${_id(tenantId)}');

  // ---------------------------------------------------------- security deposits

  /// [request] needs a leaseId, or a rentalUnitId with a tenantId, and an amount.
  Future<Map<String, dynamic>> holdDeposit(Map<String, dynamic> request) => _one(_api.post('/api/v1/security-deposits', body: compact(request)));

  Future<Map<String, dynamic>> refundDeposit(Map<String, dynamic> request) => _one(_api.post('/api/v1/security-deposits/refund', body: compact(request)));

  Future<Map<String, dynamic>> depositForLease(String leaseId) => _one(_api.get('/api/v1/security-deposits/lease/${_id(leaseId)}'));

  Future<Map<String, dynamic>> myDepositForUnit(String unitId) => _one(_api.get('/api/v1/security-deposits/unit/${_id(unitId)}/me'));

  Future<Map<String, dynamic>> depositForUnitTenant(String unitId, String tenantId) =>
      _one(_api.get('/api/v1/security-deposits/unit/${_id(unitId)}/tenant/${_id(tenantId)}'));

  /// Whether [amount] can be refunded now, and what would be left.
  Future<Map<String, dynamic>> checkLeaseRefund(String leaseId, double amount) =>
      _one(_api.get('/api/v1/security-deposits/lease/${_id(leaseId)}/refund-check', query: <String, dynamic>{'amount': amount}));

  Future<Map<String, dynamic>> checkUnitRefund(String unitId, String tenantId, double amount) => _one(_api.get(
        '/api/v1/security-deposits/unit/${_id(unitId)}/tenant/${_id(tenantId)}/refund-check',
        query: <String, dynamic>{'amount': amount},
      ));

  // ---------------------------------------------------------------- blacklist

  Future<List<Map<String, dynamic>>> blacklist() => _list('/api/v1/blacklisted-tenants');

  Future<Map<String, dynamic>> blacklistEntry(String tenantId) => _one(_api.get('/api/v1/blacklisted-tenants/${_id(tenantId)}'));

  Future<Map<String, dynamic>> blacklistTenant({required String tenantId, required String reason, String? notes}) => _one(
        _api.post('/api/v1/blacklisted-tenants', body: compact(<String, dynamic>{'tenantId': tenantId, 'reason': reason, 'notes': notes})),
      );

  Future<void> removeFromBlacklist(String tenantId) => _api.delete('/api/v1/blacklisted-tenants/${_id(tenantId)}');

  // ------------------------------------------------------------------ reports

  Future<Map<String, dynamic>> occupancyReport() => _one(_api.get('/api/v1/reports/owner/occupancy'));

  Future<Map<String, dynamic>> revenueReport(DateTime start, DateTime end) =>
      _one(_api.get('/api/v1/reports/owner/revenue', query: <String, dynamic>{'start': _d(start), 'end': _d(end)}));

  /// Health of the service and what it depends on.
  Future<Map<String, dynamic>> dependencies() => _one(_api.get('/system/dependencies'));
}
