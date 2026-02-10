import 'package:flutter/material.dart';

class Responsive {
  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static double _blockWidth = 0;
  static double _blockHeight = 0;

  static bool _isInitialized = false;

  static void init(BuildContext context) {
    // Always update to handle rotation/resize
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _blockWidth = _screenWidth / 100;
    _blockHeight = _screenHeight / 100;
    _isInitialized = true;
  }

  // Use these for responsive sizing
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;

  // Scale based on width (good for text size, horizontal padding)
  static double w(double percentage) => _blockWidth * percentage;

  // Scale based on height (good for vertical padding, heights)
  static double h(double percentage) => _blockHeight * percentage;

  // Standard sizes that adapt
  static double get padding => w(5); // 5% of width
  static double get iconSize => w(6); // 6% of width
  static double get titleSize => w(5); // 5% of width
  static double get bodySize => w(3.5); // 3.5% of width

  // Max width constraint for tablets/desktop
  static double get maxContentWidth => 600.0;
}
