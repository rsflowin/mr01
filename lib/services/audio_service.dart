import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  final ValueNotifier<bool> bgmEnabled = ValueNotifier<bool>(true);

  void setBgmEnabled(bool enabled) {
    bgmEnabled.value = enabled;
  }
}
