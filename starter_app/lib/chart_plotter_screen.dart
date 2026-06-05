import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  
  final Map<String, LayerControl> layerControls = {
    'CONTOURS': LayerControl(enabled: true, gain: 0.8),
    'DEPTH SHADING': LayerControl(enabled: true, gain: 0.4),
    'BAIT DENSITY': LayerControl(enabled: false, gain: 0.6),
    'SPECIES': LayerControl(enabled: true, gain: 0.7),
    'CURRENT': LayerControl(enabled: false, gain: 0.5),
    'WATER TEMP': LayerControl(enabled: false, gain: 0.6),
    'WEATHER': LayerControl(enabled: false, gain: 0.5),
  };
  
  bool toolboxVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07131A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main chart area
            Positioned.fill(
              child: _ChartView(
                boatHeading: boatHeading,
                lat: lat,
                lon: lon,
                layerControls: layerControls,
              ),
            ),
            
            // Overlay toolbox (slides in from left)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: toolboxVisible ? 0 : -280,
              top: 60,
              bottom: 20,
              child: _ToolboxPanel(
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
            
            // Top bezel
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBezel(
                onMenuTap: () {
                  setState(() {
                    toolboxVisible = !toolboxVisible;
                  });
                },
                toolboxVisible: toolboxVisible,
              ),
            ),
            
            // Compass overlay
            Positioned(
              right: 20,
              top: 80,
              child: const _CompassWidget(),
            ),
            
            // Boat position indicator (smaller as requested)
            Center(
              child: _BoatIndicator(heading: boatHeading),
            ),
            
            // Data readouts bottom left
            Positioned(
              left: 20,
              bottom: 100,
              child: _DataReadouts(
                speed: boatSpeed,
                lat: lat,
                lon: lon,
              ),
            ),
            
            // Toggle button for toolbox
            if (!toolboxVisible)
              Positioned(
                left: 10,
                top: 80,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      toolboxVisible = true;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF284451)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, color: Color(0xFF70C4D4), size: 20),
                        SizedBox(height: 4),
                        Text('OVL', style: TextStyle(color: Color(0xFF70C4D4), fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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

class _ChartView extends StatelessWidget {
  const _ChartView({
    required this.boatHeading,
    required this.lat,
    required this.lon,
    required this.layerControls,
  });

  final double boatHeading;
  final double lat;
  final double lon;
  final Map<String, LayerControl> layerControls;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(
        boatHeading: boatHeading,
        lat: lat,
        lon: lon,
        layerControls: layerControls,
      ),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.boatHeading,
    required this.lat,
    required this.lon,
    required this.layerControls,
  });

  final double boatHeading;
  final double lat;
  final double lon;

  final Map<String, LayerControl> layerControls;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw grid
    _drawGrid(canvas, size, center);
    
    // Draw depth shading
    if (layerControls['Depth Shading']!.enabled) {
      _drawDepthShading(canvas, size, center, layerControls['Depth Shading']!.gain);
    }
    
    // Draw contours
    if (layerControls['Contours']!.enabled) {
      _drawContours(canvas, size, center, layerControls['Contours']!.gain);
    }
    
    // Draw bait density
    if (layerControls['Bait Density']!.enabled) {
      _drawBaitDensity(canvas, size, center, layerControls['Bait Density']!.gain);
    }
    
    // Draw species locations
    if (layerControls['Species']!.enabled) {
      _drawSpecies(canvas, size, center, layerControls['Species']!.gain);
    }
    
    // Draw current overlay
    if (layerControls['Current']!.enabled) {
      _drawCurrents(canvas, size, center, layerControls['Current']!.gain);
    }
    
    // Draw water temp
    if (layerControls['Water Temp']!.enabled) {
      _drawWaterTemp(canvas, size, center, layerControls['Water Temp']!.gain);
    }
    
    // Draw weather
    if (layerControls['Weather']!.enabled) {
      _drawWeather(canvas, size, center, layerControls['Weather']!.gain);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.5;
    
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDepthShading(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.3;
    
    // Create depth gradient zones
    final colors = [
      const Color(0xFF0A2535).withOpacity(opacity),
      const Color(0xFF0D3040).withOpacity(opacity),
      const Color(0xFF0F3D50).withOpacity(opacity),
      const Color(0xFF124A60).withOpacity(opacity),
      const Color(0xFF155570).withOpacity(opacity),
    ];
    
    for (int i = 0; i < 5; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * (0.2 + i * 0.15),
        height: size.height * (0.2 + i * 0.15),
      );
      
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawOval(rect, paint);
    }
  }

  void _drawContours(Canvas canvas, Size size, Offset center, double gain) {
    final paint = Paint()
      ..color = const Color(0xFF70C4D4).withOpacity(gain * 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw contour lines (irregular shapes like depth contours)
    for (int ring = 1; ring <= 6; ring++) {
      final radius = ring * 80.0;
      final path = Path();
      
      for (double angle = 0; angle < 360; angle += 5) {
        final rad = angle * math.pi / 180;
        // Add some irregularity
        final variance = math.sin(angle * 0.1) * 15 + math.cos(angle * 0.15) * 10;
        final r = radius + variance;
        
        final x = center.dx + r * math.cos(rad);
        final y = center.dy + r * math.sin(rad);
        
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      canvas.drawPath(path, paint);
      
      // Depth labels
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${100 - ring * 15}F',
          style: TextStyle(
            color: const Color(0xFF70C4D4).withOpacity(gain * 0.5),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      labelPainter.paint(
        canvas,
        Offset(center.dx + radius * 0.7, center.dy + radius * 0.3),
      );
    }
  }

  void _drawBaitDensity(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.4;
    final random = math.Random(42);
    
    // Draw bait concentration zones
    for (int i = 0; i < 5; i++) {
      final x = center.dx + (random.nextDouble() - 0.5) * size.width * 0.6;
      final y = center.dy + (random.nextDouble() - 0.5) * size.height * 0.6;
      final radius = 30 + random.nextDouble() * 50;
      
      final paint = Paint()
        ..color = const Color(0xFF90EE90).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Draw cluster of small dots
      for (int j = 0; j < 8; j++) {
        final dotX = x + (random.nextDouble() - 0.5) * radius;
        final dotY = y + (random.nextDouble() - 0.5) * radius;
        canvas.drawCircle(Offset(dotX, dotY), 3 + random.nextDouble() * 4, paint);
      }
    }
  }

  void _drawSpecies(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.7;
    final random = math.Random(42);
    
    final speciesColors = {
      'King': const Color(0xFFD7A84A),
      'Steel': const Color(0xFF87CEEB),
      'Coho': const Color(0xFF98FB98),
      'Trout': const Color(0xFF9370DB),
    };
    
    for (int i = 0; i < 4; i++) {
      final x = center.dx + (random.nextDouble() - 0.5) * size.width * 0.5;
      final y = center.dy + (random.nextDouble() - 0.5) * size.height * 0.5;
      final color = speciesColors.values.toList()[i % speciesColors.length];
      
      // Fish icon representation
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), 8, paint);
      
      // Label
      final label = speciesColors.keys.toList()[i % speciesColors.length];
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color.withOpacity(opacity),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      labelPainter.paint(canvas, Offset(x + 12, y - 6));
    }
  }

  void _drawCurrents(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.5;
    final paint = Paint()
      ..color = const Color(0xFF00CED1).withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw current arrows
    for (int i = 0; i < 8; i++) {
      final startX = center.dx - size.width * 0.3 + i * 100;
      final startY = center.dy - size.height * 0.3 + (i % 3) * 80;
      
      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(startX + 40, startY)
        ..moveTo(startX + 35, startY - 5)
        ..lineTo(startX + 40, startY)
        ..lineTo(startX + 35, startY + 5);
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawWaterTemp(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.35;
    
    // Draw temperature gradient overlay
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFF6B6B).withOpacity(opacity * 0.3),
        const Color(0xFF4ECDC4).withOpacity(opacity * 0.3),
        const Color(0xFF3498DB).withOpacity(opacity * 0.3),
      ],
    );
    
    final rect = Rect.fromCenter(
      center: Offset(center.dx + 50, center.dy + 30),
      width: 200,
      height: 150,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(rect, paint);
  }

  void _drawWeather(Canvas canvas, Size size, Offset center, double gain) {
    final opacity = gain * 0.3;
    
    // Draw wind direction indicator
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final windX = size.width - 80;
    final windY = size.height * 0.3;
    
    final path = Path()
      ..moveTo(windX, windY)
      ..lineTo(windX + 60, windY)
      ..moveTo(windX + 50, windY - 8)
      ..lineTo(windX + 60, windY)
      ..lineTo(windX + 50, windY + 8);
    
    canvas.drawPath(path, paint);
    
    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'SW 12kt',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    labelPainter.paint(canvas, Offset(windX, windY + 10));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

class _TopBezel extends StatelessWidget {
  const _TopBezel({required this.onMenuTap, required this.toolboxVisible});

  final VoidCallback onMenuTap;
  final bool toolboxVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F28),
        border: Border(
          bottom: BorderSide(color: Color(0xFF284451), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3040),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(24, 24),
                  painter: _LogoPainter(),
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAKE COMMAND',
                      style: TextStyle(
                        color: Color(0xFFD7A84A),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'IN DEPTH',
                      style: TextStyle(
                        color: Color(0xFF70C4D4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // GPS coordinates
          const Text(
            '42.4851° N  86.4152° W',
            style: TextStyle(
              color: Color(0xFF8FB3BE),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Menu toggle
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: toolboxVisible ? const Color(0xFF173545) : const Color(0xFF10212A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: toolboxVisible ? const Color(0xFFD7A84A) : const Color(0xFF284451),
                ),
              ),
              child: Icon(
                toolboxVisible ? Icons.close : Icons.menu,
                color: toolboxVisible ? const Color(0xFFD7A84A) : const Color(0xFF8FB3BE),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw compass-like logo
    final paint = Paint()
      ..color = const Color(0xFFD7A84A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Outer circle
    canvas.drawCircle(center, size.width * 0.45, paint);
    
    // Inner fill
    final fillPaint = Paint()
      ..color = const Color(0xFF10212A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.35, fillPaint);
    
    // Compass points
    final pointPaint = Paint()
      ..color = const Color(0xFF70C4D4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // North point (triangle)
    final path = Path()
      ..moveTo(center.dx, center.dy - size.width * 0.3)
      ..lineTo(center.dx - 4, center.dy - size.width * 0.15)
      ..lineTo(center.dx + 4, center.dy - size.width * 0.15)
      ..close();
    
    final fill = Paint()
      ..color = const Color(0xFFD7A84A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
    
    // Wave lines
    final wavePaint = Paint()
      ..color = const Color(0xFF70C4D4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 3; i++) {
      final y = center.dy + size.width * 0.05 + i * 4;
      final path = Path()
        ..moveTo(center.dx - 8, y)
        ..quadraticBezierTo(center.dx - 4, y - 3, center.dx, y)
        ..quadraticBezierTo(center.dx + 4, y + 3, center.dx + 8, y);
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolboxPanel extends StatelessWidget {
  const _ToolboxPanel({
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
      width: 240,
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3D4A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1E28),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(bottom: BorderSide(color: Color(0xFF2A3D4A))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7A84A),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x80D7A84A), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'DATA LAYERS',
                  style: TextStyle(
                    color: Color(0xFFD7A84A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Layer controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: layerControls.entries.map((entry) {
                return _LayerControlWidget(
                  name: entry.key,
                  control: entry.value,
                  onToggle: (enabled) => onToggle(entry.key, enabled),
                  onGainChanged: (gain) => onGainChanged(entry.key, gain),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerControlWidget extends StatelessWidget {
  const _LayerControlWidget({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row with soft rubber look rectangular switch + LED
          Row(
            children: [
              // Soft rubber rectangular toggle with LED
              Column(
                children: [
                  // LED indicator (small red glow)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: control.enabled 
                          ? const Color(0xFFFF3333) 
                          : const Color(0xFF3A1515),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: control.enabled
                          ? const [
                              BoxShadow(
                                color: Color(0xFFFF3333),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rectangular rubber toggle
                  GestureDetector(
                    onTap: () => onToggle(!control.enabled),
                    child: Container(
                      width: 38,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: control.enabled
                              ? [const Color(0xFF4A5D6A), const Color(0xFF2A3A45)]
                              : [const Color(0xFF2A3540), const Color(0xFF1A2530)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: control.enabled 
                              ? const Color(0xFF5A6D7A) 
                              : const Color(0xFF1A2530),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x20000000),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          // Soft rubber effect
                          BoxShadow(
                            color: const Color(0x0AFFFFFF),
                            blurRadius: 1,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Sliding knob
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            left: control.enabled ? 18 : 2,
                            top: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: control.enabled
                                      ? [const Color(0xFF6A7D8A), const Color(0xFF4A5D6A)]
                                      : [const Color(0xFF3A4550), const Color(0xFF2A3540)],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 10),
              
              // Layer name
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: control.enabled ? const Color(0xFFE8F1F3) : const Color(0xFF5A6A75),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Gain knob row
          Row(
            children: [
              const SizedBox(width: 44),
              
              // GAIN label
              const Text(
                'GAIN',
                style: TextStyle(
                  color: Color(0xFF5A6A75),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Rotary knob
              GestureDetector(
                onPanUpdate: (details) {
                  final change = -details.delta.dy * 0.008;
                  final newGain = (control.gain + change).clamp(0.0, 1.0);
                  onGainChanged(newGain);
                },
                child: _RotaryKnob(
                  value: control.gain,
                  enabled: control.enabled,
                ),
              ),
              
              const SizedBox(width: 6),
              
              // Value display
              Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A22),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF1A2A35)),
                ),
                child: Text(
                  '${(control.gain * 100).round()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: control.enabled ? const Color(0xFF70C4D4) : const Color(0xFF3A4A55),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RotaryKnob extends StatelessWidget {
  const _RotaryKnob({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
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
    final radius = size.width / 2 - 2;

    // Outer ring
    final outerPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Knob body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3A5060),
          const Color(0xFF1A2530),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 4, bodyPaint);

    // Indicator line
    final angle = -math.pi * 0.75 + value * math.pi * 1.5;
    final indicatorStart = center;
    final indicatorEnd = Offset(
      center.dx + (radius - 8) * math.cos(angle),
      center.dy + (radius - 8) * math.sin(angle),
    );

    final indicatorPaint = Paint()
      ..color = enabled ? const Color(0xFFD7A84A) : const Color(0xFF4A6070)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);

    // Center dot
    final centerPaint = Paint()
      ..color = const Color(0xFF0D1F28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.enabled != enabled;
}

class _CompassWidget extends StatelessWidget {
  const _CompassWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xCC0D1F28),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF40606D), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass rose
          CustomPaint(
            size: const Size(64, 64),
            painter: _CompassPainter(),
          ),
          
          // Center heading
          const Text(
            '045°',
            style: TextStyle(
              color: Color(0xFFD7A84A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Cardinal directions
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
      
      canvas.drawLine(
        Offset(inner, innerY),
        Offset(outer, outerY),
        paint..strokeWidth = i % 2 == 0 ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoatIndicator extends StatelessWidget {
  const _BoatIndicator({required this.heading});

  final double heading;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * math.pi / 180,
      child: CustomPaint(
        size: const Size(30, 40),
        painter: _BoatPainter(),
      ),
    );
  }
}

class _BoatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Boat body (smaller)
    final path = Path()
      ..moveTo(center.dx, center.dy - 14)  // Bow
      ..lineTo(center.dx + 8, center.dy + 12)  // Starboard stern
      ..lineTo(center.dx, center.dy + 8)  // Stern center
      ..lineTo(center.dx - 8, center.dy + 12)  // Port stern
      ..close();

    final bodyPaint = Paint()
      ..color = const Color(0xFFD7A84A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFE8C66A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, outlinePaint);

    // Heading line
    final linePaint = Paint()
      ..color = const Color(0xFFFF6B6B).withOpacity(0.8)
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(center.dx, center.dy - 14),
      Offset(center.dx, center.dy - 25),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DataReadouts extends StatelessWidget {
  const _DataReadouts({
    required this.speed,
    required this.lat,
    required this.lon,
  });

  final double speed;
  final double lat;
  final double lon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE60D1F28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF284451)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DataRow(label: 'SPD', value: '${speed.toStringAsFixed(1)} kt'),
          const SizedBox(height: 4),
          _DataRow(label: 'HDG', value: '045°'),
          const SizedBox(height: 4),
          _DataRow(label: 'DEPTH', value: '52 ft'),
          const SizedBox(height: 4),
          _DataRow(label: 'TEMP', value: '54°F'),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A8090),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF70C4D4),
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}