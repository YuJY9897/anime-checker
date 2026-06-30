import 'package:flutter/services.dart';

class ExternalLinks {
  const ExternalLinks._();

  static const _channel = MethodChannel('anime_checker/external_links');

  static Future<void> open(String url) async {
    final value = url.trim();
    if (value.isEmpty) return;
    await _channel.invokeMethod<void>('open', value);
  }
}
