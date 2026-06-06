
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
  bool toolboxVisible = false;

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
      backgroundColor: const Color(0xFF1A2530),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A3A4A), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 0,
                offset: const Offset(-5, -5),
              ),
              BoxShadow(
                color: const Color(0xFF1A2A3A),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                _ScreenWithHousing(),
                Positioned(
                  right: 0,
                  top: 40,
                  bottom: 40,
                  width: 80,
                  child: _DataBezel(),
                ),
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
                Positioned(
                  left: 20,
                  top: 20,
                  child: _MenuButton(
                    onTap: () {
                      setState(() {
                        toolboxVisible = !toolboxVisible;
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 80,
                  right: 100,
                  child: _TopInfoBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenWithHousing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1520), Color(0xFF07131A), Color(0xFF05101A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.03),
            blurRadius: 100,
            offset: const Offset(-50, -50),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            _ChartContent(),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
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

class _ChartContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(),
      child: Container(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1A25), Color(0xFF07131A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final contourPaint = Paint()
      ..color = const Color(0xFF2A5060)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(size.width * 0.2, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.25, size.width * 0.6, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.55, size.width * 0.9, size.height * 0.5);
    canvas.drawPath(path1, contourPaint);

    final path2 = Path();
    path2.moveTo(size.width * 0.15, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.35, size.height * 0.6, size.width * 0.5, size.height * 0.55);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.5, size.width * 0.85, size.height * 0.65);
    canvas.drawPath(path2, contourPaint..color = const Color(0xFF1A4050));

    final depthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x000A1520), Color(0x30103020)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4), depthPaint);

    final boatPaint = Paint()..color = const Color(0xFFD7A84A)..style = PaintingStyle.fill;
    final boatPath = Path()
      ..moveTo(size.width / 2, size.height / 2 - 20)
      ..lineTo(size.width / 2 - 10, size.height / 2 + 10)
      ..lineTo(size.width / 2, size.height / 2 + 5)
      ..lineTo(size.width / 2 + 10, size.height / 2 + 10)
      ..close();
    canvas.drawPath(boatPath, boatPaint);

    final headingPaint = Paint()
      ..color = const Color(0xFFD7A84A).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width / 2 + 80, size.height / 2 - 60), headingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A3A4A), Color(0xFF1A2A3A)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A4A5A)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(2, 2)),
          ],
        ),
        child: const Icon(Icons.menu, color: Color(0xFFD7A84A), size: 28),
      ),
    );
  }
}

class _TopInfoBar extends StatelessWidget {
  const _TopInfoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1520).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.anchor, color: Color(0xFFD7A84A), size: 18),
              SizedBox(width: 8),
              Text('LAKE COMMAND IN DEPTH',
                style: TextStyle(color: Color(0xFFD7A84A), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
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

class _DataBezel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A2530), Color(0xFF0D1520)],
        ),
        border: Border(left: BorderSide(color: Color(0xFF2A3A4A), width: 2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _BezelGauge(label: 'TEMP', value: '58°F', unit: 'WATER'),
          _BezelGauge(label: 'SPD', value: '5.2', unit: 'KNOTS'),
          _BezelGauge(label: 'DEPTH', value: '42ft', unit: 'BELOW'),
          _BezelGauge(label: 'TIME', value: '14:32', unit: 'LOCAL'),
        ],
      ),
    );
  }
}

class _BezelGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _BezelGauge({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1520),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      child: Column(
        children: [
          Text(label,
            style: const TextStyle(color: Color(0xFF6A8090), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(value,
            style: const TextStyle(color: Color(0xFF70C4D4), fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w800),
          ),
          Text(unit,
            style: const TextStyle(color: Color(0xFF4A5A6A), fontSize: 7, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ToolboxMenu extends StatelessWidget {
  final VoidCallback onClose;
  const _ToolboxMenu({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2530), Color(0xFF0D1520)],
        ),
        border: const Border(right: BorderSide(color: Color(0xFF3A4A5A), width: 2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(5, 0)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2A3A4A)))),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFFD7A84A), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('TOOLBOX',
                    style: TextStyle(color: Color(0xFFD7A84A), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF2A3A4A), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.close, color: Color(0xFF70C4D4), size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
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
                Divider(color: Color(0xFF2A3A4A)),
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
    final color = isDestructive ? const Color(0xFFE46353) : const Color(0xFFE8F1F3);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1520),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A3A4A)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color.withValues(alpha: 0.8), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}