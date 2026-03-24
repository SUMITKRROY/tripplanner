import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/expense_model.dart';
import '../models/generate_trip_request_model.dart';
import '../models/generate_trip_response_model.dart';
import '../models/trip_plan_model.dart';
import '../models/trip_request_model.dart';

/// All trip-related API calls go through [DioClient.instance],
/// so every request/response is logged and errors handled in one place.
class TripApiService {
  TripApiService({DioClient? client}) : _client = client ?? DioClient.instance;

  final DioClient _client;

  /// Analyze trip request and return a plan (example endpoint).
  Future<TripPlanModel> analyzeTrip(TripRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/trips/analyze',
      data: request.toJson(),
    );
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return TripPlanModel.fromJson(response.data!);
  }

  /// Load trip plan by id.
  Future<TripPlanModel> loadTripPlan(String tripId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/trips/$tripId',
    );
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return TripPlanModel.fromJson(response.data!);
  }

  /// Generate trip plan (POST /generate-trip).
  Future<GenerateTripResponseModel> generateTrip(
    GenerateTripRequestModel request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/generate-trip',
      data: request.toJson(),
    );
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return GenerateTripResponseModel.fromJson(response.data!);
  }

  /// Fetch expenses for a trip.
  Future<List<ExpenseModel>> getTripExpenses(String tripId) async {
    final response = await _client.get<List<dynamic>>(
      '/trips/$tripId/expenses',
    );
    if (response.data == null) return [];
    return (response.data!)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
