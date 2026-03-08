import 'package:flutter/material.dart';

class RenewalState {
  static final RenewalState _instance = RenewalState._internal();
  factory RenewalState() => _instance;
  RenewalState._internal();

  final ValueNotifier<bool> refreshNotifier = ValueNotifier<bool>(false);
  
  void triggerRefresh() {
    refreshNotifier.value = !refreshNotifier.value;
  }
}

final renewalState = RenewalState();