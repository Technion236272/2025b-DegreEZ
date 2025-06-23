
import 'package:flutter/material.dart';
// building_geocode_map.dart
import 'package:latlong2/latlong.dart';

/// Maps raw building names (from schedule) to OpenStreetMap-compatible queries
String getHebrewBuildingQuery(String building) {
  debugPrint('🔍🔍🔍 Building Query: $building');

  if (building.contains('אולמן')) return 'אולמן הטכניון';
  if (building.contains('טאוב')) return 'טאוב הטכניון';
  if (building.contains('מאייר')) return ' מאייר הטכניון';
  if (building.contains('אמדו')) return 'אמדו הטכניון';
  if (building.contains('דייוס')) return 'ליידי דייויס הטכניון';
  if (building.contains('ליידי דייוס - מכונות')) return 'ליידי דייויס מכונות הטכניון';
  if (building.contains('ליידי דייוס - אווירונוטיקה')) return 'אווירונוטיקה הטכניון';
  if (building.contains('בורוביץ')) return 'בורוביץ הטכניון';
  if (building.contains('בריכת הטכניון')) return 'בריכת שחיה הטכניון';
  if (building.contains('מכון להנ\' ביו רפואה')) return 'הפקולטה להנדסה ביו-רפואית טכניון';
  if (building.contains('בלומפילד')) return 'בנין בלומפילד הטכניון';
  if (building.contains('ביולוגיה')) return 'ביולוגיה הטכניון';
  if (building.contains('כימיה')) return 'כימיה הטכניון';
  if (building.contains('בית הסטודנט')) return 'בית הסטודנט טכניון';
  if (building.contains('טכניון')) return building; // fallback

  return '$building טכניון';
}



final Map<String, LatLng> manualBuildingCoordinates = {
  'דשא סינטתי': LatLng(32.779384, 35.018240),
  // Add more as needed
};

