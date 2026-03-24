import 'package:equatable/equatable.dart';

class TripRequestModel extends Equatable {
  const TripRequestModel({
    this.destination,
    this.startDate,
    this.endDate,
    this.budget,
  });

  final String? destination;
  final String? startDate;
  final String? endDate;
  final double? budget;

  Map<String, dynamic> toJson() => {
        if (destination != null) 'destination': destination,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (budget != null) 'budget': budget,
      };

  @override
  List<Object?> get props => [destination, startDate, endDate, budget];
}
