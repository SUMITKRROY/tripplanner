import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  const ExpenseModel({
    this.id,
    this.category,
    this.amount,
    this.currency,
    this.description,
  });

  final String? id;
  final String? category;
  final double? amount;
  final String? currency;
  final String? description;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String?,
      category: json['category'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, category, amount, currency, description];
}
