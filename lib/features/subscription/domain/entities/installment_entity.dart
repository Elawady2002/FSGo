import 'package:equatable/equatable.dart';

/// Installment status enumeration
enum InstallmentStatus {
  pending,
  paid,
  overdue;

  String toJson() => name;

  static InstallmentStatus fromJson(String value) {
    return InstallmentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => InstallmentStatus.pending,
    );
  }
}

/// Installment entity - represents a payment installment
class InstallmentEntity extends Equatable {
  final String id;
  final String subscriptionId;
  final double amount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime? paymentDate;
  final DateTime createdAt;

  const InstallmentEntity({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    subscriptionId,
    amount,
    dueDate,
    status,
    paymentDate,
    createdAt,
  ];

  bool get isPaid => status == InstallmentStatus.paid;
  bool get isOverdue => status == InstallmentStatus.overdue;
}
