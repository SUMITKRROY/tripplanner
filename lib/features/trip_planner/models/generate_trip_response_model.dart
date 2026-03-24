import 'package:equatable/equatable.dart';

/// Response model for POST /api/generate-trip.
class GenerateTripResponseModel extends Equatable {
  const GenerateTripResponseModel({
    this.status,
    this.tripId,
    this.city,
    this.days,
    this.persons,
    this.summary,
    this.tripPlan = const [],
    this.expenses,
    this.totalDistanceKm,
    this.generatedAt,
  });

  final bool? status;
  final String? tripId;
  final String? city;
  final int? days;
  final int? persons;
  final String? summary;
  final List<TripDayPlanModel> tripPlan;
  final TripExpensesModel? expenses;
  final double? totalDistanceKm;
  final String? generatedAt;

  factory GenerateTripResponseModel.fromJson(Map<String, dynamic> json) {
    return GenerateTripResponseModel(
      status: json['status'] as bool?,
      tripId: json['tripId'] as String?,
      city: json['city'] as String?,
      days: json['days'] as int?,
      persons: json['persons'] as int?,
      summary: json['summary'] as String?,
      tripPlan: (json['tripPlan'] as List<dynamic>?)
              ?.map((e) =>
                  TripDayPlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: json['expenses'] != null
          ? TripExpensesModel.fromJson(
              json['expenses'] as Map<String, dynamic>)
          : null,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble(),
      generatedAt: json['generatedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tripId,
        city,
        days,
        persons,
        summary,
        tripPlan,
        expenses,
        totalDistanceKm,
        generatedAt,
      ];
}

class TripDayPlanModel extends Equatable {
  const TripDayPlanModel({
    this.day,
    this.theme,
    this.description,
    this.places = const [],
    this.totalTimeMin,
  });

  final int? day;
  final String? theme;
  final String? description;
  final List<PlaceModel> places;
  final int? totalTimeMin;

  factory TripDayPlanModel.fromJson(Map<String, dynamic> json) {
    return TripDayPlanModel(
      day: json['day'] as int?,
      theme: json['theme'] as String?,
      description: json['description'] as String?,
      places: (json['places'] as List<dynamic>?)
              ?.map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalTimeMin: json['totalTimeMin'] as int?,
    );
  }

  @override
  List<Object?> get props => [day, theme, description, places, totalTimeMin];
}

class PlaceModel extends Equatable {
  const PlaceModel({
    this.name,
    this.description,
    this.lat,
    this.lng,
    this.duration,
    this.category,
    this.entryFee,
    this.bestTime,
    this.tips,
    this.imageUrl,
    this.openingHours,
    this.rating,
    this.googlePlaceId,
  });

  final String? name;
  final String? description;
  final double? lat;
  final double? lng;
  final int? duration;
  final String? category;
  final int? entryFee;
  final String? bestTime;
  final String? tips;
  final String? imageUrl;
  final String? openingHours;
  final double? rating;
  final String? googlePlaceId;

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      name: json['name'] as String?,
      description: json['description'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      duration: json['duration'] as int?,
      category: json['category'] as String?,
      entryFee: json['entryFee'] as int?,
      bestTime: json['bestTime'] as String?,
      tips: json['tips'] as String?,
      imageUrl: json['imageUrl'] as String?,
      openingHours: json['openingHours'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      googlePlaceId: json['googlePlaceId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        name,
        description,
        lat,
        lng,
        duration,
        category,
        entryFee,
        bestTime,
        tips,
        imageUrl,
        openingHours,
        rating,
        googlePlaceId,
      ];
}

class TripExpensesModel extends Equatable {
  const TripExpensesModel({
    this.hotel,
    this.food,
    this.travel,
    this.tickets,
    this.total,
    this.perPerson,
    this.breakdown,
    this.withinBudget,
    this.budgetDifference,
  });

  final int? hotel;
  final int? food;
  final int? travel;
  final int? tickets;
  final int? total;
  final int? perPerson;
  final ExpenseBreakdownModel? breakdown;
  final bool? withinBudget;
  final int? budgetDifference;

  factory TripExpensesModel.fromJson(Map<String, dynamic> json) {
    return TripExpensesModel(
      hotel: json['hotel'] as int?,
      food: json['food'] as int?,
      travel: json['travel'] as int?,
      tickets: json['tickets'] as int?,
      total: json['total'] as int?,
      perPerson: json['perPerson'] as int?,
      breakdown: json['breakdown'] != null
          ? ExpenseBreakdownModel.fromJson(
              json['breakdown'] as Map<String, dynamic>)
          : null,
      withinBudget: json['withinBudget'] as bool?,
      budgetDifference: json['budgetDifference'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        hotel,
        food,
        travel,
        tickets,
        total,
        perPerson,
        breakdown,
        withinBudget,
        budgetDifference,
      ];
}

class ExpenseBreakdownModel extends Equatable {
  const ExpenseBreakdownModel({
    this.rooms,
    this.distanceKm,
    this.ratesUsed,
  });

  final int? rooms;
  final double? distanceKm;
  final Map<String, dynamic>? ratesUsed;

  factory ExpenseBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ExpenseBreakdownModel(
      rooms: json['rooms'] as int?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      ratesUsed: json['ratesUsed'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [rooms, distanceKm, ratesUsed];
}
