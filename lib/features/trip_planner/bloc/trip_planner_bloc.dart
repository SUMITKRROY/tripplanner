import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/trip_api_service.dart';
import 'trip_planner_event.dart';
import 'trip_planner_state.dart';

class TripPlannerBloc extends Bloc<TripPlannerEvent, TripPlannerState> {
  TripPlannerBloc({TripApiService? apiService})
      : _apiService = apiService ?? TripApiService(),
        super(const TripPlannerInitial()) {
    on<TripPlannerGenerateTrip>(_onGenerateTrip);
    on<TripPlannerNavigateToResult>(_onNavigateToResult);
    on<TripPlannerReset>(_onReset);
  }

  final TripApiService _apiService;

  Future<void> _onGenerateTrip(
    TripPlannerGenerateTrip event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(const TripPlannerLoading());
    try {
      final data = await _apiService.generateTrip(event.request);
      emit(TripPlannerSuccess(data));
    } catch (e, st) {
      // ignore: avoid_print
      print('TripPlannerBloc generateTrip error: $e $st');
      emit(TripPlannerFailure(
        e.toString().replaceFirst('DioException: ', ''),
      ));
    }
  }

  void _onNavigateToResult(
    TripPlannerNavigateToResult event,
    Emitter<TripPlannerState> emit,
  ) {
    // State remains success; UI uses it to navigate and show result.
    // No state change needed unless we want a "modal dismissed" flag.
  }

  void _onReset(TripPlannerReset event, Emitter<TripPlannerState> emit) {
    emit(const TripPlannerInitial());
  }
}
