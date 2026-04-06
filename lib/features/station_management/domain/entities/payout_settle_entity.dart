import 'package:equatable/equatable.dart';

/// Settlement status of a driver payout request.
enum PayoutStatus {
  pending,
  settled;

  String toJson() => name;

  static PayoutStatus fromJson(String value) {
    return PayoutStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PayoutStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case PayoutStatus.pending:
        return 'في الانتظار';
      case PayoutStatus.settled:
        return 'مُسوَّى';
    }
  }
}

/// A driver payout request with optional settlement proof.
class PayoutSettleEntity extends Equatable {
  final String payoutId;
  final String driverId;
  final String driverName;
  final double amount;
  final String? proofUrl;
  final PayoutStatus status;
  final DateTime createdAt;

  const PayoutSettleEntity({
    required this.payoutId,
    required this.driverId,
    required this.driverName,
    required this.amount,
    this.proofUrl,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == PayoutStatus.pending;
  bool get isSettled => status == PayoutStatus.settled;

  factory PayoutSettleEntity.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>? ?? {};
    return PayoutSettleEntity(
      payoutId: json['id'] as String,
      driverId: json['driver_id'] as String,
      driverName: driverJson['full_name'] as String? ?? 'سائق',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      proofUrl: json['proof_url'] as String?,
      status: PayoutStatus.fromJson(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [payoutId, driverId, driverName, amount, proofUrl, status, createdAt];
}
