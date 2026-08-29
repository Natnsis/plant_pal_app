import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

enum PlantStatus { healthy, thirsty, watch }

extension PlantStatusX on PlantStatus {
  String get label => switch (this) {
        PlantStatus.healthy => 'Healthy',
        PlantStatus.thirsty => 'Thirsty',
        PlantStatus.watch => 'Watch',
      };

  Color get badgeBg => switch (this) {
        PlantStatus.thirsty => PP.lime,
        PlantStatus.watch => PP.amberBg,
        PlantStatus.healthy => PP.card.withValues(alpha: 0.85),
      };

  Color get badgeFg => switch (this) {
        PlantStatus.thirsty => PP.ink,
        PlantStatus.watch => PP.amberFg,
        PlantStatus.healthy => PP.forest,
      };
}

class Plant {
  const Plant({
    required this.name,
    required this.room,
    required this.status,
    required this.water,
    this.dark = false,
    this.health = 90,
  });

  final String name;
  final String room;
  final PlantStatus status;
  final String water;
  final bool dark;
  final int health;
}

const demoPlants = <Plant>[
  Plant(name: 'Snake Plant', room: 'Living Room', status: PlantStatus.healthy, water: 'Water in 2 days', health: 88),
  Plant(name: 'Peace Lily', room: 'Home Office', status: PlantStatus.thirsty, water: 'Water today', dark: true, health: 61),
  Plant(name: 'Aloe Vera', room: 'Kitchen', status: PlantStatus.healthy, water: 'Water in 6 days', health: 91),
  Plant(name: 'Golden Pothos', room: 'Living Room', status: PlantStatus.watch, water: 'Leaf spots seen', health: 74),
  Plant(name: 'ZZ Plant', room: 'Home Office', status: PlantStatus.healthy, water: 'Water in 9 days', health: 86),
  Plant(name: 'Basil', room: 'Kitchen', status: PlantStatus.thirsty, water: 'Water today', health: 70),
];

const demoRooms = <String>['All', 'Living Room', 'Home Office', 'Kitchen'];

class CareTask {
  const CareTask({
    required this.key,
    required this.title,
    required this.sub,
    required this.chip,
    required this.chipBg,
    required this.chipFg,
    this.initiallyDone = false,
  });

  final String key;
  final String title;
  final String sub;
  final String chip;
  final Color chipBg;
  final Color chipFg;
  final bool initiallyDone;
}

final demoTasks = <CareTask>[
  const CareTask(
    key: 'water',
    title: 'Water Peace Lily',
    sub: 'Home Office · every 5 days',
    chip: 'Due',
    chipBg: PP.lime,
    chipFg: PP.ink,
  ),
  const CareTask(
    key: 'feed',
    title: 'Fertilize Monstera',
    sub: 'Living Room · monthly',
    chip: 'Today',
    chipBg: PP.pale2,
    chipFg: PP.forest,
  ),
  const CareTask(
    key: 'prune',
    title: 'Prune Snake Plant',
    sub: 'Living Room · seasonal',
    chip: 'Done',
    chipBg: PP.pale4,
    chipFg: Color(0x8016180F),
    initiallyDone: true,
  ),
];

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.initials,
    required this.meta,
    required this.category,
    required this.likes,
    required this.comments,
    required this.text,
  });

  final String id;
  final String author;
  final String initials;
  final String meta;
  final String category;
  final int likes;
  final int comments;
  final String text;
}

const demoPosts = <CommunityPost>[
  CommunityPost(
    id: 'p1',
    author: 'Hana M.',
    initials: 'HM',
    meta: 'Addis Ababa · 2h',
    category: 'Tips',
    likes: 84,
    comments: 12,
    text:
        'Rainy season trick: cut watering by half and check the top 3 cm with your finger, not the calendar. Saved three of my pothos from root rot.',
  ),
  CommunityPost(
    id: 'p2',
    author: 'Dawit K.',
    initials: 'DK',
    meta: 'Bole · 5h',
    category: 'Showcase',
    likes: 156,
    comments: 31,
    text:
        'Six months of consistent misting and my fiddle leaf finally pushed out four new leaves.',
  ),
  CommunityPost(
    id: 'p3',
    author: 'Sara T.',
    initials: 'ST',
    meta: 'Kazanchis · 1d',
    category: 'Q&A',
    likes: 23,
    comments: 18,
    text:
        'Yellow lower leaves on a monstera — overwatering or just old growth? Diagnosis says moderate, curious what people see in practice.',
  ),
];

/// Home "garden health" mini bar chart values.
const healthBarValues = <int>[42, 55, 48, 66, 60, 72, 68, 80, 74, 86, 79, 90, 84, 92];
