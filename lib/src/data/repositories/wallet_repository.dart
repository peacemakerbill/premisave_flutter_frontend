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

  /// Sends money to another wallet. [body] holds recipientAccountNumber, amount, description and a reference that makes
  /// a retry safe. The answer is the envelope the server sent.
  Future<Map<String, dynamic>> transferRaw(Map<String, dynamic> body) async => asMap(await _api.post('/wallet/transfer', body: compact(body)));

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

  // ------------------------------------------------------------- more of the wallet

  Future<Map<String, dynamic>> balanceInfo() async => unwrapMap(await _api.get('/wallet/balance'));

  Future<void> freeze() => _api.put('/wallet/freeze');

  Future<void> unfreeze() => _api.put('/wallet/unfreeze');

  Future<void> updateMpesaPhone(String phone) => _api.put('/wallet/mpesa-phone', body: <String, dynamic>{'mpesaPhoneNumber': phone});

  Future<void> updatePochiPhone(String phone) => _api.put('/wallet/pochi-phone', body: <String, dynamic>{'pochiPhoneNumber': phone});

  Future<void> updatePaypalEmail(String email) => _api.put('/wallet/paypal-email', body: <String, dynamic>{'paypalEmail': email});

  /// Any deposit. The body holds amount and provider (MPESA, STRIPE, PAYPAL, FLUTTERWAVE or NOWPAYMENTS) and whatever
  /// that provider needs. The answer tells what to do next, for example a link to open.
  Future<Map<String, dynamic>> deposit(Map<String, dynamic> body) async => asMap(await _api.post('/wallet/deposit', body: body));

  /// Any withdrawal. The body holds amount and provider, and whatever that provider needs.
  Future<Map<String, dynamic>> disburse(Map<String, dynamic> body) async => asMap(await _api.post('/disbursements', body: body));

  Future<Map<String, dynamic>> disburseToPochi(Map<String, dynamic> body) async =>
      asMap(await _api.post('/disbursements/b2pochi', body: body));

  Future<Map<String, dynamic>> verifyNowPaymentsWithdrawal(String disbursementId, String code) async => asMap(await _api.post(
      '/disbursements/nowpayments/${Uri.encodeComponent(disbursementId)}/verify',
      body: <String, dynamic>{'verificationCode': code}));

  /// After the person pays on the provider's page, these credit the wallet.
  Future<Map<String, dynamic>> confirmStripeDeposit(String paymentIntentId) async =>
      asMap(await _api.post('/wallet/deposit/stripe/confirm', body: <String, dynamic>{'paymentIntentId': paymentIntentId}));

  Future<Map<String, dynamic>> confirmPaypalDeposit(String orderId) async =>
      asMap(await _api.post('/wallet/deposit/paypal/confirm', body: <String, dynamic>{'orderId': orderId}));

  Future<Map<String, dynamic>> confirmFlutterwaveDeposit(String txRef) async =>
      asMap(await _api.post('/wallet/deposit/flutterwave/confirm', body: <String, dynamic>{'txRef': txRef}));

  Map<String, dynamic> _dates(String? status, String? provider, DateTime? from, DateTime? to) => compact(<String, dynamic>{
        'status': status,
        'provider': provider,
        'fromDate': from == null ? null : isoDate(from),
        'toDate': to == null ? null : isoDate(to),
      });

  Future<List<Map<String, dynamic>>> depositRows({String? status, String? provider, DateTime? from, DateTime? to}) async =>
      rows(await _api.get('/deposits/history', query: _dates(status, provider, from, to)));

  Future<List<Map<String, dynamic>>> withdrawalRows({String? status, String? provider, DateTime? from, DateTime? to}) async =>
      rows(await _api.get('/disbursements/history', query: _dates(status, provider, from, to)));

  Future<List<Map<String, dynamic>>> transferRows({String? status, String? direction, DateTime? from, DateTime? to}) async =>
      rows(await _api.get('/wallet/transfer/history', query: compact(<String, dynamic>{
        'status': status,
        'direction': direction,
        'fromDate': from == null ? null : isoDate(from),
        'toDate': to == null ? null : isoDate(to),
      })));

  Future<List<Map<String, dynamic>>> transactionRows() async => rows(await _api.get('/transactions/history'));

  /// Payments the wallet made for other services, such as a booking or rent.
  Future<List<Map<String, dynamic>>> paymentRows({String? status, String? service, DateTime? from, DateTime? to}) async =>
      rows(await _api.get('/payments/history', query: compact(<String, dynamic>{
        'status': status,
        'service': service,
        'fromDate': from == null ? null : isoDate(from),
        'toDate': to == null ? null : isoDate(to),
      })));

  Future<Map<String, dynamic>> statementData(Map<String, dynamic> body) async => unwrapMap(await _api.post('/wallet/statement', body: body));

  // Linked accounts

  Future<Map<String, dynamic>> paypalAccount() async => unwrapMap(await _api.get('/wallet/paypal/account'));

  /// Starts linking PayPal. The answer holds the link to open and the setup token to confirm with.
  Future<Map<String, dynamic>> paypalLink() async => unwrapMap(await _api.post('/wallet/paypal/link'));

  Future<void> paypalLinkConfirm(String setupTokenId) =>
      _api.post('/wallet/paypal/link/confirm', body: <String, dynamic>{'setupTokenId': setupTokenId});

  Future<void> paypalDisconnect() => _api.put('/wallet/paypal/disconnect');

  Future<Map<String, dynamic>> flutterwaveAccount() async => unwrapMap(await _api.get('/wallet/flutterwave/account'));

  Future<Map<String, dynamic>> flutterwaveLink() async => unwrapMap(await _api.post('/wallet/flutterwave/link'));

  Future<void> flutterwaveLinkConfirm(Map<String, dynamic> body) => _api.post('/wallet/flutterwave/link/confirm', body: body);

  Future<void> flutterwaveUnlink() => _api.delete('/wallet/flutterwave/link');

  Future<List<Map<String, dynamic>>> stripeCards() async => rows(await _api.get('/wallet/stripe/cards'), key: 'cards');

  Future<void> removeStripeCard(String paymentMethodId) => _api.delete('/wallet/stripe/cards/${Uri.encodeComponent(paymentMethodId)}');

  Future<void> setDefaultStripeCard(String paymentMethodId) =>
      _api.put('/wallet/stripe/cards/${Uri.encodeComponent(paymentMethodId)}/default');

  /// Starts saving a card. The answer holds the client secret and the setup intent id.
  Future<Map<String, dynamic>> stripeSetupIntent() async => unwrapMap(await _api.post('/wallet/stripe/setup-intent'));

  Future<void> confirmStripeSetupIntent(String setupIntentId) =>
      _api.post('/wallet/stripe/setup-intent/confirm', body: <String, dynamic>{'setupIntentId': setupIntentId});

  Future<Map<String, dynamic>> stripeConnectAccount() async => unwrapMap(await _api.get('/wallet/stripe/connect/account'));

  /// Starts bank linking with Stripe. The answer holds a single use link to open.
  Future<Map<String, dynamic>> stripeConnectLink() async => unwrapMap(await _api.post('/wallet/stripe/connect/link'));

  Future<Map<String, dynamic>> stripeConnectRefresh() async => unwrapMap(await _api.post('/wallet/stripe/connect/refresh'));

  Future<void> stripeConnectUnlink() => _api.delete('/wallet/stripe/connect/link');

  // Consents: other people or businesses asking to use the wallet.

  Future<List<Map<String, dynamic>>> consents() async => rows(await _api.get('/wallet/consents'));

  Future<void> approveConsent(String id) => _api.post('/wallet/consents/${Uri.encodeComponent(id)}/approve');

  Future<void> declineConsent(String id) => _api.post('/wallet/consents/${Uri.encodeComponent(id)}/decline');

  Future<void> revokeConsent(String id) => _api.post('/wallet/consents/${Uri.encodeComponent(id)}/revoke');

  // Merchant applications made through the developer portal that name this wallet.

  Future<List<Map<String, dynamic>>> merchantApplications() async => rows(await _api.get('/wallet/merchant-applications'));

  Future<Map<String, dynamic>> merchantApplication(String id) async =>
      unwrapMap(await _api.get('/wallet/merchant-applications/${Uri.encodeComponent(id)}'));

  Future<List<Map<String, dynamic>>> merchantNumbers() async => rows(await _api.get('/wallet/merchant-numbers'));

  // ---------------------------------------------------------------- administration
  // Open to the Admin, Finance and Operations roles.

  Future<Map<String, dynamic>> adminSummary() async => unwrapMap(await _api.get('/admin/wallet/reports/summary'));

  Future<Map<String, dynamic>> adminDaily(DateTime day) async =>
      unwrapMap(await _api.get('/admin/wallet/reports/daily', query: <String, dynamic>{'date': isoDate(day)}));

  Future<Map<String, dynamic>> adminBalanceOverview() async => unwrapMap(await _api.get('/admin/wallet/reports/balance-overview'));

  Future<Map<String, dynamic>> financeSummary() async => unwrapMap(await _api.get('/admin/finance/reports/summary'));

  Future<List<Map<String, dynamic>>> adminWallets() async => rows(await _api.get('/admin/wallet/wallets', query: <String, dynamic>{'size': 50}));

  Future<List<Map<String, dynamic>>> searchWallets(String query) async =>
      rows(await _api.get('/admin/wallet/wallets/search', query: <String, dynamic>{'query': query}));

  Future<Map<String, dynamic>> adminWallet(String userId) async =>
      unwrapMap(await _api.get('/admin/wallet/wallets/${Uri.encodeComponent(userId)}'));

  Future<void> creditWallet(String userId, Map<String, dynamic> body) =>
      _api.post('/admin/wallet/wallets/${Uri.encodeComponent(userId)}/credit', body: body);

  Future<void> debitWallet(String userId, Map<String, dynamic> body) =>
      _api.post('/admin/wallet/wallets/${Uri.encodeComponent(userId)}/debit', body: body);

  Future<void> adminFreeze(String userId) => _api.put('/admin/wallet/wallets/${Uri.encodeComponent(userId)}/freeze');

  Future<void> adminUnfreeze(String userId) => _api.put('/admin/wallet/wallets/${Uri.encodeComponent(userId)}/unfreeze');

  Future<List<Map<String, dynamic>>> adminTransactions({String? userId, String? type, String? status}) async =>
      rows(await _api.get('/admin/wallet/transactions', query: compact(<String, dynamic>{'userId': userId, 'type': type, 'status': status, 'size': 50})));

  Future<Map<String, dynamic>> adminTransaction(String id) async =>
      unwrapMap(await _api.get('/admin/wallet/transactions/${Uri.encodeComponent(id)}'));

  Future<List<Map<String, dynamic>>> adminAdjustments({String? userId}) async =>
      rows(await _api.get('/admin/wallet/adjustments', query: compact(<String, dynamic>{'userId': userId})));

  Future<List<Map<String, dynamic>>> adminPendingDisbursements() async => rows(await _api.get('/admin/wallet/disbursements/pending'));

  Future<List<Map<String, dynamic>>> financeDeposits({String? userId, String? status, String? provider}) async =>
      rows(await _api.get('/admin/finance/deposits', query: compact(<String, dynamic>{'userId': userId, 'status': status, 'provider': provider, 'size': 50, 'sort': 'createdAt,desc'})));

  Future<List<Map<String, dynamic>>> financeDisbursements({String? userId, String? status, String? provider}) async =>
      rows(await _api.get('/admin/finance/disbursements', query: compact(<String, dynamic>{'userId': userId, 'status': status, 'provider': provider, 'size': 50, 'sort': 'createdAt,desc'})));

  Future<List<Map<String, dynamic>>> financeLedger({String? userId, String? type}) async =>
      rows(await _api.get('/admin/finance/ledger', query: compact(<String, dynamic>{'userId': userId, 'type': type, 'size': 50})));

  Future<List<Map<String, dynamic>>> financePayments() async => rows(await _api.get('/admin/finance/payments', query: <String, dynamic>{'size': 50}));

  Future<List<Map<String, dynamic>>> financeTransfers() async => rows(await _api.get('/admin/finance/transfers', query: <String, dynamic>{'size': 50}));

  Future<List<Map<String, dynamic>>> exchangeRates() async => rows(await _api.get('/admin/exchange-rates'));

  Future<Map<String, dynamic>> fetchExchangeRates(String base) async =>
      unwrapMap(await _api.post('/admin/exchange-rates/fetch', query: <String, dynamic>{'base': base}));

  // Reconciliation: payments that need a person to decide.

  Future<Map<String, dynamic>> pendingReconciliation() async => unwrapMap(await _api.get('/admin/reconciliation/pending'));

  /// Everything waiting for a decision, oldest first. Each row says what kind of thing it is in entityType.
  Future<List<Map<String, dynamic>>> pendingItems() async => rows(await _api.get('/admin/reconciliation/pending'));

  Future<void> approveDeposit(String id) => _api.post('/admin/reconciliation/deposits/${Uri.encodeComponent(id)}/approve');

  Future<void> rejectDeposit(String id, String reason) =>
      _api.post('/admin/reconciliation/deposits/${Uri.encodeComponent(id)}/reject', query: <String, dynamic>{'reason': reason});

  Future<void> approveDisbursement(String id) => _api.post('/admin/reconciliation/disbursements/${Uri.encodeComponent(id)}/approve');

  Future<void> rejectDisbursement(String id, String reason) =>
      _api.post('/admin/reconciliation/disbursements/${Uri.encodeComponent(id)}/reject', query: <String, dynamic>{'reason': reason});

  Future<List<Map<String, dynamic>>> mpesaOperations({String? type, String? status}) async =>
      rows(await _api.get('/admin/reconciliation/mpesa-operations', query: compact(<String, dynamic>{'type': type, 'status': status, 'size': 50})));

  Future<void> approveReversal(String operationId) =>
      _api.post('/admin/reconciliation/mpesa-operations/${Uri.encodeComponent(operationId)}/approve-reversal');

  Future<void> rejectReversal(String operationId, String reason) => _api.post(
      '/admin/reconciliation/mpesa-operations/${Uri.encodeComponent(operationId)}/reject-reversal',
      query: <String, dynamic>{'reason': reason});

  Future<void> closeOperation(String operationId, {String? note}) => _api.post(
      '/admin/reconciliation/mpesa-operations/${Uri.encodeComponent(operationId)}/close',
      query: compact(<String, dynamic>{'note': note}));

  // M-Pesa operations the company runs from its own account.

  Future<Map<String, dynamic>> mpesaOperation(String conversationId) async =>
      unwrapMap(await _api.get('/admin/wallet/mpesa/operations/${Uri.encodeComponent(conversationId)}'));

  Future<Map<String, dynamic>> mpesaBalanceQuery() async => unwrapMap(await _api.post('/admin/wallet/mpesa/balance/query'));

  Future<Map<String, dynamic>> mpesaTransactionStatus(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/admin/wallet/mpesa/transaction-status/query', body: body));

  Future<Map<String, dynamic>> mpesaReversal(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/admin/wallet/mpesa/reversal', body: body));

  /// One time setup: tells Safaricom where to send C2B validation and confirmation calls. Admin and Operations only.
  Future<Map<String, dynamic>> mpesaC2bRegisterUrls() async => unwrapMap(await _api.post('/payments/mpesa/c2b/register-urls'));

  /// Sandbox only: pretends a customer paid the Pay Bill. [body] holds billRefNumber, and optionally amount and msisdn.
  Future<Map<String, dynamic>> mpesaC2bSimulate(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/payments/mpesa/c2b/simulate', body: body));

  Future<Map<String, dynamic>> mpesaPullRegister() async => unwrapMap(await _api.post('/admin/wallet/mpesa/pull/register'));

  Future<Map<String, dynamic>> mpesaPullQuery(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/admin/wallet/mpesa/pull/query', body: body));

  Future<Map<String, dynamic>> adminPayPochi(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/admin/wallet/mpesa/b2pochi/pay', body: body));

  Future<Map<String, dynamic>> adminPayB2B(Map<String, dynamic> body) async => unwrapMap(await _api.post('/admin/wallet/b2b/pay', body: body));

  Future<Map<String, dynamic>> adminQueryOrgInfo(Map<String, dynamic> body) async =>
      unwrapMap(await _api.post('/admin/wallet/b2b/query-org-info', body: body));

  // Gateway balances: what the company holds with each payment provider.

  Future<Map<String, dynamic>> gatewayBalances() async => unwrapMap(await _api.get('/admin/gateway-balances'));

  Future<Map<String, dynamic>> gatewayBalance(String provider) async =>
      unwrapMap(await _api.get('/admin/gateway-balances/${Uri.encodeComponent(provider)}'));

  Future<List<Map<String, dynamic>>> savedGatewayBalances() async => rows(await _api.get('/admin/gateway-balances/saved'));

  Future<List<Map<String, dynamic>>> savedGatewayHistory(String provider) async =>
      rows(await _api.get('/admin/gateway-balances/saved/${Uri.encodeComponent(provider)}'));
}
