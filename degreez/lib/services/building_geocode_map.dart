import 'package:flutter/material.dart';
// building_geocode_map.dart
import 'package:latlong2/latlong.dart';

/// Maps raw building names (from schedule) to OpenStreetMap-compatible queries
String getHebrewBuildingQuery(String building) {
  debugPrint('🔍🔍🔍 Building Query: $building');

  if (building.contains('אולמן')) return 'אולמן הטכניון';
  if (building.contains('הומניסטים')) return 'טאוב הטכניון';
  if (building.contains('טאוב')) return 'טאוב הטכניון';
  if (building.contains('מאייר')) return ' מאייר הטכניון';
  if (building.contains('אמדו')) return 'בנין אמאדו הטכניון';
  if (building.contains('דייוס')) return 'ליידי דייויס הטכניון';
  if (building.contains('ליידי דייוס - מכונות'))
    {return 'ליידי דייויס מכונות הטכניון';}
  if (building.contains("הנ' אוירונאוטית") ||
      building.contains("ליידי דייוס - אוירונוטיקה"))
    {return 'בניין הנדסת אווירונוטיקה וחלל הטכניון ';
}  if (building.contains('בורוביץ')) return 'בורוביץ הטכניון';
  if (building.contains('בריכת הטכניון')) return 'בריכת שחיה הטכניון';
  if (building.contains("מכון להנ' ביו רפואה")) return 'הנדסה ביו-רפואית הטכניון';
  if (building.contains('בלומפילד')) return 'בנין בלומפילד הטכניון';
  if (building.contains('ביולוגיה')) return 'ביולוגיה הטכניון';
  if (building.contains('כימיה')) return 'כימיה הטכניון';
  if (building.contains('בית הסטודנט')) return 'בית הסטודנט הטכניון';
  if (building.contains('אולם חורב')||building.contains("חדר כושר")||building.contains("מרכז סקווש")) return 'מרכז הספורט הטכניון';
  if (building.contains('בית צ')) return 'Churchill Auditorium';
  if (building.contains('בלומפילד - מדעי הנתונים'))
    {return 'בלומפילד - מדעי הנתונים הטכניון';}
  if (building.contains('דן קאהן- מכונות')) return 'הנדסת מכונות - בניין קאהן';
  if (building.contains("הנ' מזון וביוטכנולוג")) return 'הנדסת ביוטכנולוגיה ומזון הטכניון';
  if (building.contains('הנדסה אזרחית רבין')) return 'הנדסה אזרחית רבין הטכניון';
  if (building.contains('הנדסה כימית')) return 'הנדסה כימית הטכניון';
  if (building.contains('מועדון מעונות קנדה')) return ' מועדון קהילתי קנדה הטכניון';
  if (building.contains('מידן-חומרים')) return 'הפקולטה להנדסת חומרים הטכניון';
  if (building.contains('ננו-אלקטרוניקה')) return 'המרכז לננו-אלקטרוניקה הטכניון';
  if (building.contains('סגו')) return 'סגו ארכיטקטורה הטכניון';
  if (building.contains('פיזיקה')||building.contains("פיסיקה")) return 'פיסיקה הטכניון';
  if (building.contains('פישבך')) return 'פישבך להנדסת חשמל הטכניון';
  if (building.contains('קופר- מדעי הנתונים')) return 'מדעי הנתונים וההחלטות - בנין קופר הטכניון';
  if (building.contains('רפפורט')) return 'הפקולטה לרפואה הטכניון';
  if (building.contains('')) return '';
  if (building.contains('')) return '';
  if (building.contains('')) return '';
  if (building.contains('טכניון')) return building; // fallback

  return 'הטכניון $building';
}

final Map<String, LatLng> manualBuildingCoordinates = {
  'דשא סינטתי': LatLng(32.779384, 35.018240),
  'ביולוגיה אגף חדש': LatLng(32.776723, 35.025688),
  "טאוב-הומניסטים": LatLng(32.777192, 35.025500),
  'לוינ-פיס': LatLng(32.777416, 35.024972),
   'מגרש טניס טכניון': LatLng(32.779296, 35.017679),
  'מגרש כדורגל חופים': LatLng(32.779705, 35.018229),
  'מרכז ספורט נוה שאנן 47': LatLng(32.788966, 35.010805),
  'שרמן, חינוך למדע וטכנולוגיה': LatLng(32.77627114524274, 35.026361297387375),
  'תחנה לחקר בניה':LatLng(32.779317990070815, 35.02149925157916)
  // Add more as needed
};
