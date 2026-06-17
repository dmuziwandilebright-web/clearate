import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class RemoteFlagsState {
  const RemoteFlagsState({
    required this.towns,
    required this.goodsCategories,
    required this.exchangeLocationTypes,
    required this.complaintDisclaimer,
    required this.reportFeatureActive,
    required this.maintenanceMode,
    required this.minAppVersion,
    required this.announcementMessage,
    required this.announcementActive,
  });

  final List<String> towns;
  final List<String> goodsCategories;
  final List<String> exchangeLocationTypes;
  final String complaintDisclaimer;
  final bool reportFeatureActive;
  final bool maintenanceMode;
  final String minAppVersion;
  final String announcementMessage;
  final bool announcementActive;

  factory RemoteFlagsState.fallback() {
    return RemoteFlagsState(
      towns: List<String>.unmodifiable(fallbackZimbabweTowns),
      goodsCategories: List<String>.unmodifiable(fallbackGoodsCategories),
      exchangeLocationTypes:
          List<String>.unmodifiable(fallbackExchangeLocationTypes),
      complaintDisclaimer:
          'Your report has been recorded. Clearate is working to establish a formal partnership with Zimbabwe\'s Consumer Protection Commission.',
      reportFeatureActive: false,
      maintenanceMode: false,
      minAppVersion: '',
      announcementMessage: '',
      announcementActive: false,
    );
  }

  factory RemoteFlagsState.fromJson(Map<String, Object?> json) {
    return RemoteFlagsState(
      towns: _readList(json['towns'], fallbackZimbabweTowns),
      goodsCategories:
          _readList(json['goods_categories'], fallbackGoodsCategories),
      exchangeLocationTypes: _readList(
        json['exchange_location_types'],
        fallbackExchangeLocationTypes,
      ),
      complaintDisclaimer: _readString(json['complaint_disclaimer']).isNotEmpty
          ? _readString(json['complaint_disclaimer'])
          : RemoteFlagsState.fallback().complaintDisclaimer,
      reportFeatureActive: json['report_feature_active'] == true,
      maintenanceMode: json['maintenance_mode'] == true,
      minAppVersion: _readString(json['min_app_version']),
      announcementMessage: _readString(json['announcement_message']),
      announcementActive: json['announcement_active'] == true,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'towns': towns,
        'goods_categories': goodsCategories,
        'exchange_location_types': exchangeLocationTypes,
        'complaint_disclaimer': complaintDisclaimer,
        'report_feature_active': reportFeatureActive,
        'maintenance_mode': maintenanceMode,
        'min_app_version': minAppVersion,
        'announcement_message': announcementMessage,
        'announcement_active': announcementActive,
      };
}

class RemoteFlagsController extends ChangeNotifier {
  RemoteFlagsController(this._prefs) {
    _state = _loadCached() ?? RemoteFlagsState.fallback();
  }

  static const _prefsKey = 'clearate_remote_flags_v1';

  final SharedPreferences _prefs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  late RemoteFlagsState _state;

  RemoteFlagsState get state => _state;

  RemoteFlagsState? _loadCached() {
    try {
      final raw = _prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return RemoteFlagsState.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshFromFirestore() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('flags')
          .get();
      final data = doc.data();
      if (data == null || data.isEmpty) return;
      final updated = RemoteFlagsState.fromJson(data);
      await _applyRemoteState(updated);
    } catch (_) {
      // Keep cached or fallback values if Firestore is unavailable.
    }
  }

  void startFirestoreListener() {
    if (Firebase.apps.isEmpty) return;
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('config')
        .doc('flags')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null || data.isEmpty) return;
      _applyRemoteState(RemoteFlagsState.fromJson(data));
    }, onError: (_) {
      // Keep cached or fallback values if Firestore is unavailable.
    });
  }

  Future<void> _applyRemoteState(RemoteFlagsState updated) async {
    _state = updated;
    await _prefs.setString(_prefsKey, json.encode(updated.toJson()));
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

String _readString(Object? value) => value?.toString().trim() ?? '';

List<String> _readList(Object? value, List<String> fallback) {
  if (value is List) {
    final list = value
        .map(_readListEntry)
        .where((entry) => entry.isNotEmpty)
        .toList();
    if (list.isNotEmpty) return list;
  }
  return List<String>.unmodifiable(fallback);
}

String _readListEntry(Object? entry) {
  if (entry == null) return '';
  if (entry is Map) {
    final map = entry.cast<Object?, Object?>();
    for (final key in const [
      'name',
      'label',
      'title',
      'value',
      'item_name',
      'town',
      'type',
    ]) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  final text = entry.toString().trim();
  if (text.startsWith('{') && text.endsWith('}')) {
    try {
      final decoded = json.decode(text);
      return _readListEntry(decoded);
    } catch (_) {
      return text;
    }
  }
  return text;
}

final List<String> fallbackZimbabweTowns = <String>[
  'Beitbridge',
  'Binga',
  'Bindura',
  'Bikita',
  'Bulawayo',
  'Bubi',
  'Centenary',
  'Chegutu',
  'Chimanimani',
  'Chinhoyi',
  'Chipinge',
  'Chiredzi',
  'Chivhu',
  'Concession',
  'Darwendale',
  'Esigodini',
  'Gokwe',
  'Gwanda',
  'Gweru',
  'Harare',
  'Hwange',
  'Insiza',
  'Kadoma',
  'Kariba',
  'Karoi',
  'Kezi',
  'Kwekwe',
  'Lupane',
  'Lundi',
  'Macheke',
  'Makaha',
  'Mberengwa',
  'Marondera',
  'Masvingo',
  'Matobo',
  'Mazowe',
  'Mhangura',
  'Mt Darwin',
  'Mvurwi',
  'Mutare',
  'Murehwa',
  'Mushumbi Pools',
  'Mutoko',
  'Mvuma',
  'Nkayi',
  'Norton',
  'Nyanga',
  'Nyamandlovu',
  'Plumtree',
  'Redcliff',
  'Rushinga',
  'Rusape',
  'Ruwa',
  'Seke',
  'Shamva',
  'Shurugwi',
  'St Alberts',
  'Tsholotsho',
  'Victoria Falls',
  'Wedza',
  'West Nicholson',
  'Zaka',
  'Zhombe',
  'Zvishavane',
]..sort();

final List<String> fallbackGoodsCategories = <String>[
  'Airtime',
  'Apples',
  'Avocados',
  'Baby formula',
  'Bananas',
  'Batteries',
  'Beans',
  'Beef',
  'Biscuits',
  'Bread',
  'Butter',
  'Cabbage',
  'Cement',
  'Chicken',
  'Cooking gas',
  'Cooking oil',
  'Cooking salt',
  'Cornflakes',
  'Cookies',
  'Cups',
  'Detergent',
  'Diapers',
  'Dishwashing liquid',
  'Eggs',
  'Face soap',
  'Fish',
  'Flour',
  'Fuel',
  'Fuel coupon',
  'Fruits',
  'Garlic',
  'Garri',
  'Grapes',
  'Groceries',
  'Groundnuts',
  'Ice cream',
  'Instant coffee',
  'Iron sheets',
  'Jam',
  'Laundry soap',
  'Laptop',
  'Lemons',
  'Maize',
  'Maize meal',
  'Matches',
  'Milk',
  'Mop',
  'Nappies',
  'Onions',
  'Orange juice',
  'Oranges',
  'Peanut butter',
  'Petrol',
  'Phone',
  'Phone charger',
  'Pork',
  'Potatoes',
  'Rice',
  'Sacks',
  'Salt',
  'School shoes',
  'School uniform',
  'Soap',
  'Soda',
  'Stationery',
  'Sugar',
  'Sweets',
  'Toilet paper',
  'Tomatoes',
  'Toothpaste',
  'Vegetable oil',
  'Vegetables',
  'Water',
  'Yoghurt',
]..sort();

final List<String> fallbackExchangeLocationTypes = <String>[
  'Bank',
  'Bureau de change',
  'Fuel station',
  'Mobile money agent',
  'Other',
  'Shop or supermarket',
  'Street money changer',
]..sort();
