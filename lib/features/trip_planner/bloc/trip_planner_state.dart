import 'package:equatable/equatable.dart';

import '../models/generate_trip_response_model.dart';

abstract class TripPlannerState extends Equatable {
  const TripPlannerState();

  @override
  List<Object?> get props => [];
}

class TripPlannerInitial extends TripPlannerState {
  const TripPlannerInitial();
}

class TripPlannerLoading extends TripPlannerState {
  const TripPlannerLoading();
}

class TripPlannerSuccess extends TripPlannerState {
  const TripPlannerSuccess(this.data);

  final GenerateTripResponseModel data;

  @override
  List<Object?> get props => [data];
}

class TripPlannerFailure extends TripPlannerState {
  const TripPlannerFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
