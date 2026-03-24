import 'package:equatable/equatable.dart';

class GenerateTripRequestModel extends Equatable {
  const GenerateTripRequestModel({
    required this.city,
    required this.days,
    required this.persons,
    this.budget,
  });

  final String city;
  final int days;
  final int persons;
  final int? budget;

  Map<String, dynamic> toJson() => {
        'city': city,
        'days': days,
        'persons': persons,
        if (budget != null) 'budget': budget,
      };

  @override
  List<Object?> get props => [city, days, persons, budget];
}
