import 'package:equatable/equatable.dart';

import 'expense_model.dart';

class TripPlanModel extends Equatable {
  const TripPlanModel({
    this.id,
    this.destination,
    this.itinerary = const [],
    this.expenses = const [],
  });

  final String? id;
  final String? destination;
  final List<ItineraryItemModel> itinerary;
  final List<ExpenseModel> expenses;

  factory TripPlanModel.fromJson(Map<String, dynamic> json) {
    return TripPlanModel(
      id: json['id'] as String?,
      destination: json['destination'] as String?,
      itinerary: (json['itinerary'] as List<dynamic>?)
              ?.map((e) => ItineraryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, destination, itinerary, expenses];
}

class ItineraryItemModel extends Equatable {
  const ItineraryItemModel({
    this.id,
    this.title,
    this.date,
    this.location,
  });

  final String? id;
  final String? title;
  final String? date;
  final String? location;

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    return ItineraryItemModel(
      id: json['id'] as String?,
      title: json['title'] as String?,
      date: json['date'] as String?,
      location: json['location'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, date, location];
}
