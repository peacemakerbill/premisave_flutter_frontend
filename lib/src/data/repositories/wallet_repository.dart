import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/listing_models.dart';
import '../models/wallet_models.dart';
import 'envelope.dart';

/// The wallet service: balance, deposits, withdrawals, transfers and history.
class WalletRepository {
  WalletRepository(this._api);

  final ApiClient _api;

  Future<WalletModel> wallet() async => WalletModel.fromJson(unwrapMap(await _api.get('/wallet')));

  /// Opens the wallet for a person who does not have one yet.
  Future<WalletModel> createWallet() async => WalletModel.fromJson(unwrapMap(await _api.post('/wallet/create')));

  Future<List<WalletTransaction>> transactions() async =>
      unwrapList(await _api.get('/transactions/history')).map(WalletTransaction.fromJson).toList();

  Future<WalletStatement> statement({required DateTime from, DateTime? to, String? type}) async {
    final body = compact(<String, dynamic>{
      'fromDate': isoDate(from),
      'toDate': to == null ? null : isoDate(to),
      'type': type,
    });
    return WalletStatement.fromJson(unwrapMap(await _api.post('/wallet/statement', body: body)));
  }

  Future<List<TransferRecord>> transfers() async =>
      unwrapList(await _api.get('/wallet/transfer/history')).map(TransferRecord.fromJson).toList();

  Future<List<DepositRecord>> deposits() async =>
      unwrapList(await _api.get('/deposits/history')).map(DepositRecord.fromJson).toList();

  Future<List<DisbursementRecord>> withdrawals() async =>
      unwrapList(await _api.get('/disbursements/history')).map(DisbursementRecord.fromJson).toList();

  /// Starts an M-Pesa deposit. The phone gets a prompt to enter its PIN, and the wallet is credited when it is paid.
  Future<PaymentResult> depositMpesa({required double amount, required String phoneNumber}) async {
    final res = await _api.post('/wallet/deposit', body: <String, dynamic>{
      'amount': amount,
      'provider': 'MPESA',
      'phoneNumber': phoneNumber,
    });
    return PaymentResult.fromJson(unwrapMap(res), messageOf(res, 'Deposit started'));
  }

  /// Sends money to another wallet. [recipient] is the email address of the other wallet.
  Future<PaymentResult> transfer({required double amount, required String recipient, String? description}) async {
    final res = await _api.post('/wallet/transfer', body: compact(<String, dynamic>{
      'amount': amount,
      'recipientAccountNumber': recipient,
      'description': description,
    }));
    return PaymentResult.fromJson(unwrapMap(res), messageOf(res, 'Transfer successful'));
  }

  /// Withdraws to the person's own M-Pesa number.
  Future<PaymentResult> withdrawMpesa({required double amount, String? remarks}) async {
    final res = await _api.post('/disbursements', body: compact(<String, dynamic>{
      'amount': amount,
      'provider': 'MPESA',
      'remarks': remarks,
    }));
    return PaymentResult.fromJson(unwrapMap(res), messageOf(res, 'Withdrawal started'));
  }

  // Finance reports. These routes are open to the Admin, Finance and Operations roles only.

  Future<DailyFinance> financeDaily(DateTime day) async =>
      DailyFinance.fromJson(unwrapMap(await _api.get('/admin/finance/reports/daily', query: <String, dynamic>{'date': isoDate(day)})));

  Future<BalanceOverview> balanceOverview({int topN = 5}) async => BalanceOverview.fromJson(
      unwrapMap(await _api.get('/admin/finance/reports/balance-overview', query: <String, dynamic>{'topN': topN})));

  /// The newest deposits across every wallet.
  Future<List<AdminDeposit>> latestDeposits({int size = 8}) async {
    final body = unwrap(await _api.get('/admin/finance/deposits', query: <String, dynamic>{'size': size, 'sort': 'createdAt,desc'}));
    return pageContent(body).map(AdminDeposit.fromJson).toList();
  }
}
