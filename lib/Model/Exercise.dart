import 'dart:core';

class Exercise{
  String label;
  String position;
  List<double> vector;

  Exercise({required this.label,required this.position,required this.vector});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      label: json['label'],
      position: json['position'],
      vector: List<double>.from(json['vector'].map((x) => x.toDouble())),
    );
  }

  // Optional: To JSON
  Map<String, dynamic> toJson() => {
    'label': label,
    'position': position,
    'vector': vector,
  };
}