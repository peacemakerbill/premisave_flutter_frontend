import '../../core/utils/money.dart';
import 'json_utils.dart';

/// The signed in person's wallet, from GET /wallet on the wallet service.
class WalletModel {
  WalletModel.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        accountNumber = strOr(j['accountNumber']),
        balance = doubleOrNull(j['balance']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        frozen = boolOr(j['frozen'] ?? j['isFrozen']),
        mpesaPhoneNumber = str(j['mpesaPhoneNumber']),
        pochiPhoneNumber = str(j['pochiPhoneNumber']),
        paypalEmail = str(j['paypalConnectedEmail'] ?? j['paypalEmail']),
        paypalPayoutEmail = str(j['paypalEmail']),
        defaultCurrency = strOr(j['defaultCurrency'], platformCurrency),
        defaultCurrencyBalance = doubleOrNull(j['defaultCurrencyBalance']),
        hasSavedCard = boolOr(j['hasSavedCard']),
        cardBrand = str(j['cardBrand']),
        cardLast4 = str(j['cardLast4']);

  final String id;

  /// The email address other people send money to.
  final String accountNumber;
  final double balance;
  final String currency;
  final bool frozen;
  final String? mpesaPhoneNumber;
  final String? pochiPhoneNumber;
  final String? paypalEmail;

  /// The PayPal address withdrawals are sent to, as saved under Settings.
  final String? paypalPayoutEmail;

  /// The currency the person chose to deal in. USD until they change it.
  final String defaultCurrency;

  /// The balance in [defaultCurrency] at today's rate. Null when the default is USD or no rate is known.
  final double? defaultCurrencyBalance;
  final bool hasSavedCard;
  final String? cardBrand;
  final String? cardLast4;
}

/// One line of activity: a deposit, withdrawal, transfer or payment.
class WalletTransaction {
  WalletTransaction.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        type = strOr(j['type'], 'PAYMENT'),
        status = strOr(j['status'], 'PENDING'),
        amount = doubleOrNull(j['amount']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        description = str(j['description']),
        createdAt = dateOrNull(j['createdAt']),
        direction = str(j['direction']),
        provider = str(j['provider']),
        counterpartyId = str(j['counterpartyId']),
        counterpartyEmail = str(j['counterpartyEmail']),
        counterpartyName = str(j['counterpartyName']),
        account = str(j['account']),
        reference = str(j['reference']),
        failureReason = str(j['failureReason']);

  final String id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String? description;
  final DateTime? createdAt;

  /// IN when money came into the wallet, OUT when it left. Empty on older answers, which fall back to the kind.
  final String? direction;
  final String? provider;

  /// The other side of a transfer, when this line is one.
  final String? counterpartyId;
  final String? counterpartyEmail;
  final String? counterpartyName;

  /// Where the money came from or went to outside the wallet, such as a phone number or a PayPal email.
  final String? account;
  final String? reference;
  final String? failureReason;

  /// Money coming in. Everything else is money going out.
  bool get isCredit => direction != null ? direction == 'IN' : (type == 'DEPOSIT' || type == 'REFUND');
}

/// A statement for a date range, from POST /wallet/statement.
class WalletStatement {
  WalletStatement.fromJson(Map<String, dynamic> j)
      : openingBalance = doubleOrNull(j['openingBalance']) ?? 0,
        closingBalance = doubleOrNull(j['closingBalance']) ?? 0,
        totalCredits = doubleOrNull(j['totalCredits']) ?? 0,
        totalDebits = doubleOrNull(j['totalDebits']) ?? 0,
        fromDate = dateOrNull(j['fromDate']),
        toDate = dateOrNull(j['toDate']),
        transactions = mapList(j['transactions']).map(WalletTransaction.fromJson).toList();

  final double openingBalance;
  final double closingBalance;
  final double totalCredits;
  final double totalDebits;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<WalletTransaction> transactions;
}

/// A transfer between two wallets. [direction] is SENT or RECEIVED, from the point of view of the caller.
class TransferRecord {
  TransferRecord.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        direction = strOr(j['direction'], 'SENT'),
        senderEmail = str(j['senderEmail']),
        recipientEmail = str(j['recipientEmail']),
        amount = doubleOrNull(j['amount']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        description = str(j['description']),
        status = strOr(j['status'], 'PENDING'),
        failureReason = str(j['failureReason']),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final String direction;
  final String? senderEmail;
  final String? recipientEmail;
  final double amount;
  final String currency;
  final String? description;
  final String status;
  final String? failureReason;
  final DateTime? createdAt;

  bool get received => direction == 'RECEIVED';
}

/// A deposit into the wallet from M-Pesa, a card, PayPal, Flutterwave or NOWPayments.
class DepositRecord {
  DepositRecord.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        amount = doubleOrNull(j['amount']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        provider = strOr(j['provider']),
        status = strOr(j['status'], 'PENDING'),
        reference = str(j['reference']),
        failureReason = str(j['failureReason']),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final double amount;
  final String currency;
  final String provider;
  final String status;
  final String? reference;
  final String? failureReason;
  final DateTime? createdAt;
}

/// A withdrawal from the wallet to M-Pesa, PayPal, a card account and so on.
class DisbursementRecord {
  DisbursementRecord.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        amount = doubleOrNull(j['amount']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        provider = strOr(j['provider']),
        status = strOr(j['status'], 'PENDING'),
        destination = str(j['destination']),
        failureReason = str(j['failureReason']),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final double amount;
  final String currency;
  final String provider;
  final String status;
  final String? destination;
  final String? failureReason;
  final DateTime? createdAt;
}

/// What the wallet service answers to a deposit, transfer or payment.
class PaymentResult {
  PaymentResult.fromJson(Map<String, dynamic> j, String fallbackMessage)
      : success = boolOr(j['success'], strOr(j['status']).toUpperCase() != 'FAILED'),
        transactionId = str(j['transactionId'] ?? j['disbursementId']),
        message = strOr(j['message'], fallbackMessage);

  final bool success;
  final String? transactionId;
  final String message;
}

// ------------------------------------------------------------ finance reports
// The models below come from the wallet service's admin finance reports (GET /admin/finance/...), open to the Admin,
// Finance and Operations roles.

/// One day's money movement, from GET /admin/finance/reports/daily.
class DailyFinance {
  DailyFinance.fromJson(Map<String, dynamic> j)
      : date = dateOrNull(j['date']),
        depositCount = intOr(j['depositCount']),
        depositTotal = doubleOrNull(j['totalDepositAmount']) ?? 0,
        pendingDeposits = intOr(asMap(j['depositCountByStatus'])['PENDING']),
        failedDeposits = intOr(asMap(j['depositCountByStatus'])['FAILED']),
        disbursementCount = intOr(j['disbursementCount']),
        disbursementTotal = doubleOrNull(j['totalDisbursementAmount']) ?? 0,
        pendingDisbursements = intOr(asMap(j['disbursementCountByStatus'])['PENDING']),
        failedDisbursements = intOr(asMap(j['disbursementCountByStatus'])['FAILED']),
        transferCount = intOr(j['transferCount']),
        transferTotal = doubleOrNull(j['totalTransferAmount']) ?? 0,
        paymentCount = intOr(j['paymentCount']),
        paymentTotal = doubleOrNull(j['totalPaymentAmount']) ?? 0,
        revenue = doubleOrNull(j['totalCommissionRevenue']) ?? 0;

  final DateTime? date;
  final int depositCount;
  final double depositTotal;
  final int pendingDeposits;
  final int failedDeposits;
  final int disbursementCount;
  final double disbursementTotal;
  final int pendingDisbursements;
  final int failedDisbursements;
  final int transferCount;
  final double transferTotal;
  final int paymentCount;
  final double paymentTotal;

  /// What the company earned that day: commission on transfers and withdrawals plus payments made to the platform.
  final double revenue;

  int get transactionCount => depositCount + disbursementCount + transferCount + paymentCount;
  int get pending => pendingDeposits + pendingDisbursements;
  int get failed => failedDeposits + failedDisbursements;
}

/// Where the platform stands right now, from GET /admin/finance/reports/balance-overview.
class BalanceOverview {
  BalanceOverview.fromJson(Map<String, dynamic> j)
      : walletCount = intOr(j['totalWalletCount']),
        activeWalletCount = intOr(j['activeWalletCount']),
        frozenWalletCount = intOr(j['frozenWalletCount']),
        platformBalance = doubleOrNull(j['totalPlatformBalance']) ?? 0,
        escrowHeld = doubleOrNull(j['totalEscrowHeld']) ?? 0,
        liability = doubleOrNull(j['totalPlatformLiability']) ?? 0,
        frozenBalance = doubleOrNull(j['frozenBalance']) ?? 0,
        averageBalance = doubleOrNull(j['averageBalance']) ?? 0,
        commissionAllTime = doubleOrNull(j['totalCommissionRevenueAllTime']) ?? 0,
        topWallets = mapList(j['topWalletsByBalance']).map(TopWallet.fromJson).toList();

  final int walletCount;
  final int activeWalletCount;
  final int frozenWalletCount;
  final double platformBalance;

  /// Money in open escrow holds. It belongs to no wallet.
  final double escrowHeld;

  /// Wallet balances plus escrow: everything the platform owes its users.
  final double liability;
  final double frozenBalance;
  final double averageBalance;
  final double commissionAllTime;
  final List<TopWallet> topWallets;
}

class TopWallet {
  TopWallet.fromJson(Map<String, dynamic> j)
      : accountNumber = strOr(j['accountNumber'], 'Wallet'),
        balance = doubleOrNull(j['balance']) ?? 0;

  final String accountNumber;
  final double balance;
}

/// A deposit as finance staff see it: the same record a person sees in their own history, with the owner's id.
class AdminDeposit {
  AdminDeposit.fromJson(Map<String, dynamic> j)
      : id = strOr(j['id']),
        userId = str(j['userId']),
        amount = doubleOrNull(j['amount']) ?? 0,
        currency = strOr(j['currency'], platformCurrency),
        provider = strOr(j['provider']),
        status = strOr(j['status'], 'PENDING'),
        createdAt = dateOrNull(j['createdAt']);

  final String id;
  final String? userId;
  final double amount;
  final String currency;
  final String provider;

  /// PENDING, SUCCESS or FAILED.
  final String status;
  final DateTime? createdAt;
}
