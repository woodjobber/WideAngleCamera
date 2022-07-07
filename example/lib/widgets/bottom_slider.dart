import 'package:flutter/material.dart';

class BottomSlider extends StatefulWidget {
  const BottomSlider({Key key, this.onZoomTap}) : super(key: key);
  final Function(double) onZoomTap;
  @override
  State<BottomSlider> createState() => _BottomSliderState();
}

class _BottomSliderState extends State<BottomSlider> {
  double _value = 0.0;
  @override
  Widget build(BuildContext context) {
    return Slider(
        value: _value,
        min: 0.0,
        max: 5.0,
        onChanged: (value) {
          setState(() {
            _value = value;
          });
          widget.onZoomTap?.call(value);
        });
  }
}
