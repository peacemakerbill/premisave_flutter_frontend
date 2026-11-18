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
}
