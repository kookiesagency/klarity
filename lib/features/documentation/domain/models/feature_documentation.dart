import 'package:flutter/material.dart';

/// Represents a step in using a feature
class FeatureStep {
  final String title;
  final String description;
  final IconData? icon;

  const FeatureStep({
    required this.title,
    required this.description,
    this.icon,
  });
}

/// Represents a real-life example of using a feature
class FeatureExample {
  final String title;
  final String description;
  final String? scenario;

  const FeatureExample({
    required this.title,
    required this.description,
    this.scenario,
  });
}

/// Represents a feature with its documentation
class FeatureDocumentation {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final List<FeatureStep> steps;
  final List<FeatureExample> examples;
  final List<String>? tips;

  const FeatureDocumentation({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.steps,
    required this.examples,
    this.tips,
  });
}
