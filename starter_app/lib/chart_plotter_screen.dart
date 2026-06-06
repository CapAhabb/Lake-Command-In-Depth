import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChartPlotterScreen extends StatefulWidget {
  const ChartPlotterScreen({super.key});

  @override
  State<ChartPlotterScreen> createState() => _ChartPlotterScreenState();
}

class _ChartPlotterScreenState extends State<ChartPlotterScreen> {
  double boatHeading = 45.0;
  double boatSpeed = 5.2;
  double lat = 42.485;
  double lon = -86.415;
  bool dataBezelVisible = true;
  bool toolboxVisible = false;

  final Map<String, LayerControl> layerControls = {
    'CONTOURS': LayerControl(enabled: true, gain: 0.8),
    'DEPTH SHADING': LayerControl(enabled: true, gain: 0.4),
    'BAIT DENSITY': LayerControl(enabled: false, gain: 0.6),
    'SPECIES': LayerControl(enabled: true, gain: 0.7),
    'CURRENT': LayerControl(enabled: false, gain: 0.5),
    'WATER TEMP': LayerControl(enabled: false, gain: 0.6),
    'WEATHER': LayerControl(enabled: false, gain: 0.5),
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Stack(
            children: [
              // Outer plastic housing (thick black bezel)
              _PlasticHousing(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Main chart with overlays
                      Positioned(
                        left: dataBezelVisible ? 170 : 0,  // Tighter panel
                        right: 20,  // 10% margin on right
                        top: 0,
                        bottom: 0,
                        child: _ChartArea(layerControls: layerControls),
                      ),
                      
                      // Data Bezel (left panel with toggles/knobs)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: dataBezelVisible ? 0 : -170,  // Tighter panel
                        top: 0,
                        bottom: 0,
                        child: _DataBezelPanel(
                          layerControls: layerControls,
                          onToggle: (name, enabled) {
                            setState(() {
                              layerControls[name]!.enabled = enabled;
                            });
                          },
                          onGainChanged: (name, gain) {
                            setState(() {
                              layerControls[name]!.gain = gain;
                            });
                          },
                        ),
                      ),
                      
                      // Toolbox menu (slides from left over data bezel)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: toolboxVisible ? 0 : -300,
                        top: 0,
                        bottom: 0,
                        child: _ToolboxMenu(
                          onClose: () {
                            setState(() {
                              toolboxVisible = false;
                            });
                          },
                        ),
                      ),
                      
                      // Menu button to toggle toolbox
                      Positioned(
                        left: dataBezelVisible ? 180 : 10,
                        top: 15,
                        child: _MenuButton(
                          onTap: () {
                            setState(() {
                              toolboxVisible = !toolboxVisible;
                            });
                          },
                        ),
                      ),
                      
                      // Top info bar
                      Positioned(
                        top: 15,
                        left: dataBezelVisible ? 230 : 60,
                        right: 80,
                        child: const _TopInfoBar(),
                      ),
                      
                      // Compass
                      Positioned(
                        right: 25,
                        top: 80,
                        child: const _CompassWidget(),
                      ),
                      
                      // Toggle data bezel button
                      Positioned(
                        right: 25,
                        bottom: 15,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              dataBezelVisible = !dataBezelVisible;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF3A3A3A)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  dataBezelVisible ? Icons.chevron_left : Icons.chevron_right,
                                  color: const Color(0xFFD7A84A),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dataBezelVisible ? 'HIDE' : 'SHOW',
                                  style: const TextStyle(
                                    color: Color(0xFFD7A84A),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Plastic housing widget - matching bezelidea.jpeg reference
class _PlasticHousing extends StatelessWidget {
  final Widget child;
  const _PlasticHousing({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252525),  // Top-left highlight
            Color(0xFF1A1A1A),  // Upper
            Color(0xFF101010),  // Middle
            Color(0xFF0A0A0A),  // Bottom-right shadow
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
        border: Border.all(color: const Color(0xFF303030), width: 2),
        boxShadow: [
          // Deep outer shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.95),
            blurRadius: 60,
            offset: const Offset(0, 25),
            spreadRadius: 5,
          ),
          // Top-left bevel highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 0,
            offset: const Offset(-2, -2),
          ),
          // Bottom-right inset shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
              Color(0xFF080808),
            ],
          ),
          border: Border.all(color: const Color(0xFF050505), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

class LayerControl {
  LayerControl({required this.enabled, required this.gain});
  bool enabled;
  double gain;
}

// Data Bezel Panel (left side with toggles, LEDs, and knobs)
class _DataBezelPanel extends StatelessWidget {
  const _DataBezelPanel({
    required this.layerControls,
    required this.onToggle,
    required this.onGainChanged,
  });

  final Map<String, LayerControl> layerControls;
  final void Function(String, bool) onToggle;
  final void Function(String, double) onGainChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,  // Tighter panel
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF101010), Color(0xFF0A0A0A)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: const Border(right: BorderSide(color: Color(0xFF050505), width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2A2A2A).withValues(alpha: 0.5), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.layers, color: Color(0xFFD7A84A), size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text('DATA BEZEL',
                    style: TextStyle(color: Color(0xFFD7A84A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Layer controls - compact grid layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: layerControls.entries.map((entry) {
                  return _CompactLayerControl(
                    name: entry.key,
                    control: entry.value,
                    onToggle: (enabled) => onToggle(entry.key, enabled),
                    onGainChanged: (gain) => onGainChanged(entry.key, gain),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact layer control with button-style toggle
class _CompactLayerControl extends StatelessWidget {
  const _CompactLayerControl({
    required this.name,
    required this.control,
    required this.onToggle,
    required this.onGainChanged,
  });

  final String name;
  final LayerControl control;
  final void Function(bool) onToggle;
  final void Function(double) onGainChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!control.enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        height: 80,
        decoration: BoxDecoration(
          // Button style: white/beige gradient like reference
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: control.enabled
                ? [
                    const Color(0xFFE8E0D8),  // Light cream top
                    const Color(0xFFD8D0C8),  // Cream middle
                    const Color(0xFFC8C0B8),  // Darker cream bottom
                  ]
                : [
                    const Color(0xFFB8B0A8),  // Dimmed top
                    const Color(0xFFA8A098),  // Dimmed middle
                    const Color(0xFF989088),  // Dimmed bottom
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: control.enabled
                ? const Color(0xFFFF6B00).withValues(alpha: 0.8)  // Orange glow border
                : const Color(0xFF505050),
            width: control.enabled ? 2 : 1,
          ),
          boxShadow: control.enabled
              ? [
                  // Orange glow effect
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layer name (vertical text, dark)
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: control.enabled ? const Color(0xFF1A1A1A) : const Color(0xFF606060),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            // Small gain knob
            GestureDetector(
              onPanUpdate: (details) {
                final change = -details.delta.dy * 0.01;
                final newGain = (control.gain + change).clamp(0.0, 1.0);
                onGainChanged(newGain);
              },
              child: _MiniKnob(value: control.gain, enabled: control.enabled),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini knob for compact layout
class _MiniKnob extends StatelessWidget {
  const _MiniKnob({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MiniKnobPainter(value: value, enabled: enabled),
      ),
    );
  }
}

class _MiniKnobPainter extends CustomPainter {
  _MiniKnobPainter({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Knob body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: enabled
            ? [const Color(0xFF606060), const Color(0xFF404040), const Color(0xFF252525)]
            : [const Color(0xFF454545), const Color(0xFF353535), const Color(0xFF202020)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 1, bodyPaint);

    // Indicator
    final angle = -math.pi * 0.75 + value * math.pi * 1.5;
    final indicatorEnd = Offset(
      center.dx + (radius - 4) * math.cos(angle),
      center.dy + (radius - 4) * math.sin(angle),
    );
    final indicatorPaint = Paint()
      ..color = enabled ? const Color(0xFFD7A84A) : const Color(0xFF3A3A3A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, indicatorEnd, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniKnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.enabled != enabled;
}

class _RotaryKnob extends StatelessWidget {
  const _RotaryKnob({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _KnobPainter(value: value, enabled: enabled),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Gradient drop shadow (dark at bottom, fading up)
    final shadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0x60000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 1.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: radius * 1.8, height: radius * 1.2),
      shadowPaint,
    );

    // Outer rim (visible edge of 3D knob)
    final outerRimPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [const Color(0xFF404040), const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 1));
    canvas.drawCircle(center, radius - 2, outerRimPaint);

    // Knob body with 3D perspective (side view - top-left light source)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),  // Off-center for side view
        radius: 1.2,
        colors: [
          enabled ? const Color(0xFF707070) : const Color(0xFF454545),  // Bright top highlight
          enabled ? const Color(0xFF505050) : const Color(0xFF353535),  // Upper portion
          enabled ? const Color(0xFF3A3A3A) : const Color(0xFF2A2A2A),  // Middle
          enabled ? const Color(0xFF252525) : const Color(0xFF1A1A1A),  // Shadow side
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 4));
    canvas.drawCircle(center, radius - 4, bodyPaint);

    // "Hot spot" highlight (bright reflection on top-left)
    final hotSpotPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.7),
        radius: 0.5,
        colors: [
          Colors.white.withValues(alpha: enabled ? 0.4 : 0.2),
          Colors.white.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(center.dx - radius * 0.25, center.dy - radius * 0.25), radius: radius * 0.4));
    canvas.drawCircle(center, radius - 4, hotSpotPaint);

    // Indicator line
    final angle = -math.pi * 0.75 + value * math.pi * 1.5;
    final indicatorEnd = Offset(
      center.dx + (radius - 10) * math.cos(angle),
      center.dy + (radius - 10) * math.sin(angle),
    );

    final indicatorPaint = Paint()
      ..color = enabled ? const Color(0xFFD7A84A) : const Color(0xFF3A3A3A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, indicatorEnd, indicatorPaint);

    // Center recessed dot
    final centerDotPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF151515), const Color(0xFF050505)],
      ).createShader(Rect.fromCircle(center: center, radius: 6));
    canvas.drawCircle(center, 6, centerDotPaint);

    // Top edge highlight bevel
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi * 1.1,
      math.pi * 0.7,
      false,
      bevelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.enabled != enabled;
}

// Chart Area with data overlays (95% width)
class _ChartArea extends StatelessWidget {
  const _ChartArea({required this.layerControls});

  final Map<String, LayerControl> layerControls;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.only(
            left: 8,
            top: 60,  // Space for top bar
            bottom: 40,  // Space for compass
            right: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF060A0E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _ChartPainter(layerControls: layerControls),
              child: Container(),
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.layerControls});

  final Map<String, LayerControl> layerControls;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1A25), Color(0xFF07131A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Depth shading overlay
    if (layerControls['DEPTH SHADING']!.enabled) {
      _drawDepthShading(canvas, size);
    }

    // Contours overlay
    if (layerControls['CONTOURS']!.enabled) {
      _drawContours(canvas, size, layerControls['CONTOURS']!.gain);
    }

    // Bait density overlay
    if (layerControls['BAIT DENSITY']!.enabled) {
      _drawBaitDensity(canvas, size, layerControls['BAIT DENSITY']!.gain);
    }

    // Species overlay
    if (layerControls['SPECIES']!.enabled) {
      _drawSpecies(canvas, size, layerControls['SPECIES']!.gain);
    }

    // Current overlay
    if (layerControls['CURRENT']!.enabled) {
      _drawCurrents(canvas, size, layerControls['CURRENT']!.gain);
    }

    // Water temp overlay
    if (layerControls['WATER TEMP']!.enabled) {
      _drawWaterTemp(canvas, size, layerControls['WATER TEMP']!.gain);
    }

    // Weather overlay
    if (layerControls['WEATHER']!.enabled) {
      _drawWeather(canvas, size, layerControls['WEATHER']!.gain);
    }

    // Boat indicator
    _drawBoat(canvas, center);
  }

  void _drawDepthShading(Canvas canvas, Size size) {
    final depthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x000A1520), Color(0x40103020), Color(0x50204030)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6), depthPaint);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  void _drawContours(Canvas canvas, Size size, double gain) {
    final paint = Paint()
      ..color = const Color(0xFF2A5060).withValues(alpha: gain)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(size.width * 0.1, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.25, size.width * 0.5, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.7, size.height * 0.55, size.width * 0.9, size.height * 0.5);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.15, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.6, size.width * 0.6, size.height * 0.55);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.85, size.height * 0.7);
    canvas.drawPath(path2, paint..color = const Color(0xFF1A4050).withValues(alpha: gain));

    // Depth markers
    _drawText(canvas, '42ft', Offset(size.width * 0.2, size.height * 0.35), const Color(0xFF4A7080).withValues(alpha: gain));
    _drawText(canvas, '58ft', Offset(size.width * 0.5, size.height * 0.45), const Color(0xFF4A7080).withValues(alpha: gain));
    _drawText(canvas, '75ft', Offset(size.width * 0.7, size.height * 0.6), const Color(0xFF4A7080).withValues(alpha: gain));
  }

  void _drawBaitDensity(Canvas canvas, Size size, double gain) {
    final opacity = gain * 0.6;
    
    // Bait fish schools (small circles)
    final baitPaint = Paint()
      ..color = const Color(0xFF80A040).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // School 1
    final center1 = Offset(size.width * 0.35, size.height * 0.4);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = center1.dx + 15 * math.cos(angle);
      final y = center1.dy + 15 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, baitPaint);
    }
    canvas.drawCircle(center1, 5, baitPaint..color = const Color(0xFF90B050).withValues(alpha: opacity));

    // School 2
    final center2 = Offset(size.width * 0.65, size.height * 0.55);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center2.dx + 12 * math.cos(angle);
      final y = center2.dy + 12 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, baitPaint);
    }
  }

  void _drawSpecies(Canvas canvas, Size size, double gain) {
    final opacity = gain * 0.8;
    final speciesPaint = Paint()
      ..color = const Color(0xFFE46353).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Fish markers (trophy size)
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.35), 6, speciesPaint);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.6), 5, speciesPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.45), 7, speciesPaint);

    // Fish icons
    final iconPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawFishIcon(canvas, Offset(size.width * 0.3, size.height * 0.35), 12, iconPaint);
    _drawFishIcon(canvas, Offset(size.width * 0.75, size.height * 0.45), 14, iconPaint);
  }

  void _drawFishIcon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx - size/2, center.dy - size/2, center.dx + size/2, center.dy)
      ..quadraticBezierTo(center.dx + size, center.dy + size/3, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx + size, center.dy - size/3, center.dx + size/2, center.dy)
      ..quadraticBezierTo(center.dx - size/2, center.dy + size/2, center.dx - size, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawCurrents(Canvas canvas, Size size, double gain) {
    final opacity = gain * 0.5;
    final currentPaint = Paint()
      ..color = const Color(0xFF40A0D0).withValues(alpha: opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Current arrows
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        final x = size.width * (0.2 + col * 0.15);
        final y = size.height * (0.3 + row * 0.2);
        final arrowLength = 20 + gain * 15;
        
        // Main line
        canvas.drawLine(
          Offset(x - arrowLength/2, y),
          Offset(x + arrowLength/2, y),
          currentPaint,
        );
        // Arrow head
        canvas.drawLine(
          Offset(x + arrowLength/2, y),
          Offset(x + arrowLength/2 - 6, y - 4),
          currentPaint,
        );
        canvas.drawLine(
          Offset(x + arrowLength/2, y),
          Offset(x + arrowLength/2 - 6, y + 4),
          currentPaint,
        );
      }
    }
  }

  void _drawWaterTemp(Canvas canvas, Size size, double gain) {
    // Temperature gradient overlay
    final tempPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x004080FF), Color(0x0080D0FF), Color(0x00FF8040)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tempPaint);

    // Temperature legend
    final textColor = const Color(0xFF70C4D4).withValues(alpha: gain);
    _drawText(canvas, '58°F', Offset(size.width - 50, size.height - 30), textColor);
    _drawText(canvas, '42°F', Offset(10, 20), textColor);
  }

  void _drawWeather(Canvas canvas, Size size, double gain) {
    final weatherPaint = Paint()
      ..color = const Color(0xFF607080).withValues(alpha: gain)
      ..strokeWidth = 1;

    // Wind direction indicators
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      final y = 30.0;
      
      // Cloud symbol
      canvas.drawCircle(Offset(x, y), 8, weatherPaint..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x + 6, y - 3), 6, weatherPaint);
      canvas.drawCircle(Offset(x + 10, y), 7, weatherPaint);
    }
  }

  void _drawBoat(Canvas canvas, Offset center) {
    // Boat body
    final boatPaint = Paint()
      ..color = const Color(0xFFD7A84A)
      ..style = PaintingStyle.fill;

    final boatPath = Path()
      ..moveTo(center.dx, center.dy - 16)
      ..lineTo(center.dx - 10, center.dy + 10)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx + 10, center.dy + 10)
      ..close();
    canvas.drawPath(boatPath, boatPaint);

    // Heading line
    final headingPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx, center.dy - 16),
      Offset(center.dx + 60, center.dy - 45),
      headingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          // 3D metallic gradient with off-center highlight
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [
              const Color(0xFF454545),  // Bright top-left
              const Color(0xFF353535),  // Upper
              const Color(0xFF252525),  // Middle
              const Color(0xFF151515),  // Shadow side
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF353535), width: 1),
          boxShadow: [
            // 3D floating shadow (gradient)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            // Top edge highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  const Color(0xFF555555),
                  const Color(0xFF353535),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.menu, color: Color(0xFFD7A84A), size: 20),
          ),
        ),
      ),
    );
  }
}

class _CompassWidget extends StatelessWidget {
  const _CompassWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        // 3D metallic beveled ring
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            const Color(0xFF454545),  // Top-left highlight
            const Color(0xFF353535),  // Upper
            const Color(0xFF252525),  // Middle
            const Color(0xFF151515),  // Shadow
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF303030), width: 2),
        boxShadow: [
          // Gradient drop shadow (fading up)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          // Top highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // Inner bezel with depth
          gradient: const RadialGradient(
            colors: [Color(0xFF151515), Color(0xFF0A0A0A)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0A0A0A), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: const Size(56, 56), painter: _CompassPainter()),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
            Text('045°',
              style: TextStyle(
                color: const Color(0xFFD7A84A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(1, 1), blurRadius: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF8FB3BE)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // N indicator
    final nPath = Path()
      ..moveTo(center.dx, center.dy - 26)
      ..lineTo(center.dx - 4, center.dy - 20)
      ..moveTo(center.dx, center.dy - 26)
      ..lineTo(center.dx + 4, center.dy - 20);
    canvas.drawPath(nPath, paint);

    // Degree marks
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = center.dx + 24 * math.cos(angle);
      final innerY = center.dy + 24 * math.sin(angle);
      final outer = center.dx + 28 * math.cos(angle);
      final outerY = center.dy + 28 * math.sin(angle);
      canvas.drawLine(Offset(inner, innerY), Offset(outer, outerY), paint..strokeWidth = i % 2 == 0 ? 2 : 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopInfoBar extends StatelessWidget {
  const _TopInfoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // 3D beveled/embossed gradient
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),  // Top highlight
            Color(0xFF0F0F0F),  // Upper
            Color(0xFF0A0A0A),  // Main
            Color(0xFF050505),  // Bottom shadow
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF252525),  // Top/left bevel
          width: 1,
        ),
        boxShadow: [
          // Bottom shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Top highlight bevel
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 3D anchor icon
              Depth3DIcon(icon: Icons.anchor, size: 20),
              SizedBox(width: 10),
              // 3D text effect for branding
              Depth3DText(text: 'LAKE COMMAND IN DEPTH'),
            ],
          ),
          Row(
            children: [
              _DataChip(label: 'LAT', value: '42.485'),
              SizedBox(width: 12),
              _DataChip(label: 'LON', value: '-86.415'),
              SizedBox(width: 12),
              _DataChip(label: 'SPD', value: '5.2 kn'),
              SizedBox(width: 12),
              _DataChip(label: 'HDG', value: '045°'),
            ],
          ),
        ],
      ),
    );
  }
}

// 3D Icon with bevel effect
class Depth3DIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const Depth3DIcon({super.key, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            const Color(0xFF606060),
            const Color(0xFF404040),
            const Color(0xFF252525),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: Color(0xFFD7A84A), size: size),
    );
  }
}

// 3D Text with embossed effect
class Depth3DText extends StatelessWidget {
  final String text;
  const Depth3DText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow layer
        Text(
          text,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 0),
            ],
          ),
        ),
        // Highlight layer (offset up-left)
        Text(
          text,
          style: TextStyle(
            color: const Color(0xFFD7A84A).withValues(alpha: 0.3),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 0),
            ],
          ),
        ),
        // Main text
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD7A84A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final String value;
  const _DataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
          style: const TextStyle(color: Color(0xFF6A8090), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(value,
          style: const TextStyle(color: Color(0xFF70C4D4), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ToolboxMenu extends StatelessWidget {
  final VoidCallback onClose;
  const _ToolboxMenu({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D), Color(0xFF080808)],
        ),
        border: const Border(right: BorderSide(color: Color(0xFF050505), width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header matching data bezel style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2A2A2A).withValues(alpha: 0.5), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFFD7A84A), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('TOOLBOX',
                    style: TextStyle(color: Color(0xFFD7A84A), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF353535)),
                    ),
                    child: const Icon(Icons.close, color: Color(0xFFD7A84A), size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: const [
                _MenuItem(icon: Icons.speed, label: 'Settings'),
                _MenuItem(icon: Icons.book, label: "Captain's Log"),
                _MenuItem(icon: Icons.history, label: 'Historical Data'),
                _MenuItem(icon: Icons.emoji_events, label: 'Tournaments'),
                _MenuItem(icon: Icons.cloud, label: 'Weather'),
                _MenuItem(icon: Icons.credit_card, label: 'Subscription'),
                _MenuItem(icon: Icons.warning, label: 'Emergency Waypoint Contact'),
                _MenuItem(icon: Icons.link, label: 'API & Data Sources'),
                _MenuItem(icon: Icons.person, label: 'User Settings'),
                SizedBox(height: 8),
                _MenuItem(icon: Icons.logout, label: 'Log Out', isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  const _MenuItem({required this.icon, required this.label, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    // Destructive uses red styling, normal uses white/beige button
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDestructive
                    ? [
                        const Color(0xFFE46353).withValues(alpha: 0.9),
                        const Color(0xFFD45343),
                      ]
                    : [
                        const Color(0xFFE8E0D8),
                        const Color(0xFFD8D0C8),
                      ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDestructive ? const Color(0xFFB84333) : const Color(0xFFB8A898),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1A1A1A).withValues(alpha: 0.9), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                    style: TextStyle(
                      color: isDestructive ? const Color(0xFF1A0A0A) : const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: const Color(0xFF303030).withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}