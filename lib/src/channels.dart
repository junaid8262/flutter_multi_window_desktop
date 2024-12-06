// src/channels.dart

import 'package:flutter/services.dart';

/// The primary method channel for multi-window operations.
/// Ensures a single instance across the entire application.
const MethodChannel multiWindowChannel =
MethodChannel('mixin.one/flutter_multi_window');

/// The event channel for window-specific events and communication.
/// Ensures a single instance across the entire application.
const MethodChannel windowEventChannel =
MethodChannel('mixin.one/flutter_multi_window_channel');
