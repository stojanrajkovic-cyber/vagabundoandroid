import 'package:flutter/material.dart';

/// Ekvivalent achievementCard(for:)/achievementTitle(_:) switch-eva iz
/// ProfileView.swift.
class AchievementDefinition {
  const AchievementDefinition({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

const Map<String, AchievementDefinition> kAchievementDefinitions = {
  'firstPlan': AchievementDefinition(icon: Icons.star_border, title: 'First plan'),
  'fivePlans': AchievementDefinition(icon: Icons.star_half, title: '5 plans'),
  'tenPlans': AchievementDefinition(icon: Icons.star, title: '10 plans'),
  'firstCompleted':
      AchievementDefinition(icon: Icons.directions_walk, title: 'First completed trip'),
  'citizenWorld': AchievementDefinition(icon: Icons.public, title: 'Citizen of the world'),
  'earthCircled': AchievementDefinition(icon: Icons.language, title: 'Circled the Earth'),
  'moonBound': AchievementDefinition(icon: Icons.nightlight_round, title: 'Moon-bound'),
  'verifiedEmail': AchievementDefinition(icon: Icons.verified, title: 'Verified email'),
};

AchievementDefinition achievementDefinitionFor(String key) =>
    kAchievementDefinitions[key] ??
    const AchievementDefinition(icon: Icons.workspace_premium, title: 'Achievement');
