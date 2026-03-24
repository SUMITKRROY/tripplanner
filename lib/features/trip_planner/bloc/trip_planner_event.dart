import 'package:equatable/equatable.dart';

import '../models/generate_trip_request_model.dart';

abstract class TripPlannerEvent extends Equatable {
  const TripPlannerEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted the form; start generating the trip.
class TripPlannerGenerateTrip extends TripPlannerEvent {
  const TripPlannerGenerateTrip(this.request);

  final GenerateTripRequestModel request;

  @override
  List<Object?> get props => [request];
}

/// User dismissed the success modal and we should navigate to result (state stays success).
class TripPlannerNavigateToResult extends TripPlannerEvent {
  const TripPlannerNavigateToResult();
}

/// Reset to initial (e.g. when leaving result screen).
class TripPlannerReset extends TripPlannerEvent {
  const TripPlannerReset();
}
