import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const LakeCommandApp());
}

class LakeCommandApp extends StatelessWidget {
  const LakeCommandApp({super.key});

  @override
  Widget build(BuildContext context) {
    const hullBlack = Color(0xFF050B12);
    const sonarBlue = Color(0xFF0B2F52);
    const chartBlue = Color(0xFF11598B);
    const glowCyan = Color(0xFF7EEBFF);
    const alertAmber = Color(0xFFFFA126);
    const targetLime = Color(0xFFD1FF55);
    const panelLine = Color(0xFF2F6F9A);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lake Command',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: hullBlack,
        colorScheme: const ColorScheme.dark(
          primary: glowCyan,
          secondary: alertAmber,
          surface: sonarBlue,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF08131E),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: panelLine),
          ),
        ),
      ),
      home: const LakeCommandPage(
        hullBlack: hullBlack,
        sonarBlue: sonarBlue,
        chartBlue: chartBlue,
        glowCyan: glowCyan,
        alertAmber: alertAmber,
        targetLime: targetLime,
        panelLine: panelLine,
      ),
    );
  }
}

class LakeCommandPage extends StatefulWidget {
  const LakeCommandPage({
    super.key,
    required this.hullBlack,
    required this.sonarBlue,
    required this.chartBlue,
    required this.glowCyan,
    required this.alertAmber,
    required this.targetLime,
    required this.panelLine,
  });

  final Color hullBlack;
  final Color sonarBlue;
  final Color chartBlue;
  final Color glowCyan;
  final Color alertAmber;
  final Color targetLime;
  final Color panelLine;

  @override
  State<LakeCommandPage> createState() => _LakeCommandPageState();
}

class _LakeCommandPageState extends State<LakeCommandPage> {
  static const Map<String, SpeciesProfile> _speciesProfiles = {
    'Chinook': SpeciesProfile(
      name: 'Chinook',
      tempSweetLowF: 46,
      tempSweetHighF: 54,
      tempHardLowF: 40,
      tempHardHighF: 60,
      preferredCurrentMph: 0.9,
      currentToleranceMph: 0.7,
      behavior: 'Cooler-than-coho, often deeper and low-light oriented.',
      sourceTier: 'DNR behavior + USGS juvenile thermal proxy',
    ),
    'Coho': SpeciesProfile(
      name: 'Coho',
      tempSweetLowF: 50,
      tempSweetHighF: 59,
      tempHardLowF: 44,
      tempHardHighF: 64,
      preferredCurrentMph: 0.6,
      currentToleranceMph: 0.7,
      behavior: 'Spring nearshore / high-column fish that later slide deeper.',
      sourceTier: 'USGS Great Lakes growth study + DNR behavior',
    ),
    'Steelhead': SpeciesProfile(
      name: 'Steelhead',
      tempSweetLowF: 52,
      tempSweetHighF: 59,
      tempHardLowF: 45,
      tempHardHighF: 64,
      preferredCurrentMph: 0.5,
      currentToleranceMph: 0.8,
      behavior: 'Often near surface around thermal bars and scumlines.',
      sourceTier: 'USGS rainbow-trout thermal proxy + DNR behavior',
    ),
    'Lake Trout': SpeciesProfile(
      name: 'Lake Trout',
      tempSweetLowF: 48,
      tempSweetHighF: 55,
      tempHardLowF: 40,
      tempHardHighF: 58,
      preferredCurrentMph: 1.0,
      currentToleranceMph: 0.8,
      behavior:
          'Cold-water bottom/contour fish with strong deep structure bias.',
      sourceTier: 'USGS Great Lakes thermal studies',
    ),
  };

  final List<CatchPin> _pins = [
    CatchPin(
      id: 1,
      x: 0.34,
      y: 0.47,
      species: 'Chinook',
      weightLb: 14.2,
      note: 'Cold-water bait pod off shelf',
      strength: 0.88,
      createdAt: DateTime(2026, 5, 11, 6, 12),
    ),
    CatchPin(
      id: 2,
      x: 0.62,
      y: 0.31,
      species: 'Lake Trout',
      weightLb: 11.7,
      note: 'Bottom mark near contour break',
      strength: 0.62,
      createdAt: DateTime(2026, 5, 11, 6, 19),
    ),
  ];

  int _nextId = 3;
  int? _selectedPinId = 1;
  double _currentMph = 0.7;
  double _windMph = 7.0;
  double _windBearing = 225.0;
  double _waterTemp = 52.0;

  CatchPin? get _selectedPin {
    for (final pin in _pins) {
      if (pin.id == _selectedPinId) return pin;
    }
    return _pins.isEmpty ? null : _pins.last;
  }

  double get _tempFactor {
    final normalized = ((_waterTemp - 48) / 32).clamp(0.0, 1.0);
    return 0.7 + (normalized * 0.7);
  }

  Offset _driftVector() {
    final radians = (_windBearing - 90) * math.pi / 180;
    final wind = Offset(math.cos(radians), math.sin(radians)) * (_windMph / 36);
    final current = const Offset(0.28, 0.08) * (_currentMph / 4.5);
    return (wind + current) * _tempFactor;
  }

  double _schoolScore(CatchPin pin) {
    final profile = _speciesProfiles[pin.species]!;
    final thermal = _bandScore(
      _waterTemp,
      profile.tempHardLowF,
      profile.tempSweetLowF,
      profile.tempSweetHighF,
      profile.tempHardHighF,
    );
    final current = _currentScore(profile);
    final behavior = _behaviorScore(profile);
    return (pin.strength * 0.4 +
            thermal * 0.3 +
            current * 0.15 +
            behavior * 0.15)
        .clamp(0.0, 1.0);
  }

  void _dropPin(Offset normalized) {
    final strength = (0.55 + (_tempFactor - 0.7) * 0.35 + _currentMph * 0.04)
        .clamp(0.45, 0.98);
    final pin = CatchPin(
      id: _nextId++,
      x: normalized.dx.clamp(0.06, 0.94),
      y: normalized.dy.clamp(0.08, 0.9),
      species: _bestSpeciesForConditions(strength),
      weightLb: 4.5 + strength * 14,
      note: 'Captain hit mark',
      strength: strength,
      createdAt: DateTime.now(),
    );

    setState(() {
      _pins.add(pin);
      _selectedPinId = pin.id;
    });
  }

  String _bestSpeciesForConditions(double strength) {
    String winner = 'Chinook';
    double best = -1;
    for (final entry in _speciesProfiles.entries) {
      final profile = entry.value;
      final score =
          (_bandScore(
                _waterTemp,
                profile.tempHardLowF,
                profile.tempSweetLowF,
                profile.tempSweetHighF,
                profile.tempHardHighF,
              ) *
              0.5) +
          (_currentScore(profile) * 0.2) +
          (_behaviorScore(profile) * 0.15) +
          (strength * 0.15);
      if (score > best) {
        best = score;
        winner = entry.key;
      }
    }
    return winner;
  }

  double _bandScore(
    double value,
    double hardLow,
    double sweetLow,
    double sweetHigh,
    double hardHigh,
  ) {
    if (value <= hardLow || value >= hardHigh) return 0;
    if (value >= sweetLow && value <= sweetHigh) return 1;
    if (value < sweetLow) {
      return ((value - hardLow) / (sweetLow - hardLow)).clamp(0.0, 1.0);
    }
    return ((hardHigh - value) / (hardHigh - sweetHigh)).clamp(0.0, 1.0);
  }

  double _currentScore(SpeciesProfile profile) {
    final delta = (_currentMph - profile.preferredCurrentMph).abs();
    return (1 - (delta / profile.currentToleranceMph)).clamp(0.0, 1.0);
  }

  double _behaviorScore(SpeciesProfile profile) {
    switch (profile.name) {
      case 'Steelhead':
        final tempWindow = _bandScore(_waterTemp, 46, 50, 60, 65);
        final windMix = (_windMph / 12).clamp(0.0, 1.0);
        return (tempWindow * 0.6 + windMix * 0.4).clamp(0.0, 1.0);
      case 'Chinook':
        final lowLightProxy = _bandScore(_waterTemp, 42, 46, 54, 60);
        final strongCurrent = (_currentMph / 1.3).clamp(0.0, 1.0);
        return (lowLightProxy * 0.65 + strongCurrent * 0.35).clamp(0.0, 1.0);
      case 'Coho':
        final nearshoreBand = _bandScore(_waterTemp, 46, 50, 58, 63);
        final modestCurrent = 1 - ((_currentMph - 0.6).abs() / 0.9);
        return (nearshoreBand * 0.65 + modestCurrent.clamp(0.0, 1.0) * 0.35)
            .clamp(0.0, 1.0);
      case 'Lake Trout':
        final coldBand = _bandScore(_waterTemp, 40, 46, 54, 58);
        final bottomCurrent = (_currentMph / 1.4).clamp(0.0, 1.0);
        return (coldBand * 0.7 + bottomCurrent * 0.3).clamp(0.0, 1.0);
    }
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 980;
    final drift = _driftVector();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.hullBlack, widget.sonarBlue, widget.chartBlue],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: wide
                ? Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _LakeMapFrame(
                          glowCyan: widget.glowCyan,
                          alertAmber: widget.alertAmber,
                          targetLime: widget.targetLime,
                          panelLine: widget.panelLine,
                          hullBlack: widget.hullBlack,
                          pins: _pins,
                          selectedPinId: _selectedPinId,
                          driftVector: drift,
                          schoolScoreFor: _schoolScore,
                          onTapMap: _dropPin,
                          onSelectPin: (id) {
                            setState(() => _selectedPinId = id);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 340,
                        child: _ControlRail(
                          glowCyan: widget.glowCyan,
                          alertAmber: widget.alertAmber,
                          targetLime: widget.targetLime,
                          selectedPin: _selectedPin,
                          pins: _pins,
                          currentMph: _currentMph,
                          waterTemp: _waterTemp,
                          windMph: _windMph,
                          windBearing: _windBearing,
                          schoolScore: _selectedPin == null
                              ? 0
                              : _schoolScore(_selectedPin!),
                          onCurrentChanged: (v) =>
                              setState(() => _currentMph = v),
                          onTempChanged: (v) => setState(() => _waterTemp = v),
                          onWindChanged: (v) => setState(() => _windMph = v),
                          onBearingChanged: (v) =>
                              setState(() => _windBearing = v),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _TopCommandBar(
                        glowCyan: widget.glowCyan,
                        alertAmber: widget.alertAmber,
                        panelLine: widget.panelLine,
                        currentMph: _currentMph,
                        windMph: _windMph,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _LakeMapFrame(
                          glowCyan: widget.glowCyan,
                          alertAmber: widget.alertAmber,
                          targetLime: widget.targetLime,
                          panelLine: widget.panelLine,
                          hullBlack: widget.hullBlack,
                          pins: _pins,
                          selectedPinId: _selectedPinId,
                          driftVector: drift,
                          schoolScoreFor: _schoolScore,
                          onTapMap: _dropPin,
                          onSelectPin: (id) {
                            setState(() => _selectedPinId = id);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 252,
                        child: _BottomDrawer(
                          glowCyan: widget.glowCyan,
                          alertAmber: widget.alertAmber,
                          targetLime: widget.targetLime,
                          selectedPin: _selectedPin,
                          schoolScore: _selectedPin == null
                              ? 0
                              : _schoolScore(_selectedPin!),
                          currentMph: _currentMph,
                          waterTemp: _waterTemp,
                          windMph: _windMph,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class CatchPin {
  const CatchPin({
    required this.id,
    required this.x,
    required this.y,
    required this.species,
    required this.weightLb,
    required this.note,
    required this.strength,
    required this.createdAt,
  });

  final int id;
  final double x;
  final double y;
  final String species;
  final double weightLb;
  final String note;
  final double strength;
  final DateTime createdAt;
}

class SpeciesProfile {
  const SpeciesProfile({
    required this.name,
    required this.tempSweetLowF,
    required this.tempSweetHighF,
    required this.tempHardLowF,
    required this.tempHardHighF,
    required this.preferredCurrentMph,
    required this.currentToleranceMph,
    required this.behavior,
    required this.sourceTier,
  });

  final String name;
  final double tempSweetLowF;
  final double tempSweetHighF;
  final double tempHardLowF;
  final double tempHardHighF;
  final double preferredCurrentMph;
  final double currentToleranceMph;
  final String behavior;
  final String sourceTier;
}

class _TopCommandBar extends StatelessWidget {
  const _TopCommandBar({
    required this.glowCyan,
    required this.alertAmber,
    required this.panelLine,
    required this.currentMph,
    required this.windMph,
  });

  final Color glowCyan;
  final Color alertAmber;
  final Color panelLine;
  final double currentMph;
  final double windMph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF09131D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelLine),
      ),
      child: Row(
        children: [
          _HeaderChip(label: 'MFD', value: 'COMBO 01', accent: glowCyan),
          const SizedBox(width: 14),
          const _ModeTabs(),
          const Spacer(),
          _MicroBadge(
            icon: Icons.waves_outlined,
            label: '${currentMph.toStringAsFixed(1)} mph',
            color: glowCyan,
          ),
          const SizedBox(width: 8),
          _MicroBadge(
            icon: Icons.air,
            label: 'SW ${windMph.toStringAsFixed(0)}',
            color: alertAmber,
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = ['CHART', 'SONAR', 'FISH', 'WX'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF07111A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF28475E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: i == 0 ? const Color(0xFF1573B1) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: i == 0
                      ? const Color(0xFF7EEBFF)
                      : Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _LakeMapFrame extends StatelessWidget {
  const _LakeMapFrame({
    required this.glowCyan,
    required this.alertAmber,
    required this.targetLime,
    required this.panelLine,
    required this.hullBlack,
    required this.pins,
    required this.selectedPinId,
    required this.driftVector,
    required this.schoolScoreFor,
    required this.onTapMap,
    required this.onSelectPin,
  });

  final Color glowCyan;
  final Color alertAmber;
  final Color targetLime;
  final Color panelLine;
  final Color hullBlack;
  final List<CatchPin> pins;
  final int? selectedPinId;
  final Offset driftVector;
  final double Function(CatchPin pin) schoolScoreFor;
  final ValueChanged<Offset> onTapMap;
  final ValueChanged<int> onSelectPin;

  @override
  Widget build(BuildContext context) {
    final selectedPin = pins.cast<CatchPin?>().firstWhere(
      (pin) => pin?.id == selectedPinId,
      orElse: () => pins.isEmpty ? null : pins.last,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelLine, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final normalized = Offset(
                details.localPosition.dx / constraints.maxWidth,
                details.localPosition.dy / constraints.maxHeight,
              );
              onTapMap(normalized);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LakeMapPainter(
                      pins: pins,
                      selectedPinId: selectedPinId,
                      driftVector: driftVector,
                      schoolScoreFor: schoolScoreFor,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  right: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: _GlassPanel(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _HeaderChip(
                                label: 'CHART',
                                value: 'Lake Michigan',
                                accent: glowCyan,
                              ),
                              _HeaderChip(
                                label: 'LIVE MODE',
                                value: 'Chinook / Coho / Steelhead / Laker',
                                accent: targetLime,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Legend',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pins + drift projection',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 108,
                  child: SizedBox(
                    width: 232,
                    child: Column(
                      children: [
                        _OverlayLegend(
                          glowCyan: glowCyan,
                          targetLime: targetLime,
                          alertAmber: alertAmber,
                        ),
                        const SizedBox(height: 12),
                        _PinSummaryCard(
                          pin: selectedPin,
                          score: selectedPin == null
                              ? 0
                              : schoolScoreFor(selectedPin),
                          glowCyan: glowCyan,
                          alertAmber: alertAmber,
                          targetLime: targetLime,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: SizedBox(
                    width: 320,
                    child: _HotspotStrip(
                      targetLime: targetLime,
                      glowCyan: glowCyan,
                      pins: pins,
                      schoolScoreFor: schoolScoreFor,
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: _LakeStatusDock(
                    glowCyan: glowCyan,
                    panelLine: panelLine,
                    hullBlack: hullBlack,
                    driftVector: driftVector,
                    count: pins.length,
                  ),
                ),
                for (final pin in pins)
                  Positioned(
                    left: (pin.x * constraints.maxWidth) - 16,
                    top: (pin.y * constraints.maxHeight) - 16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelectPin(pin.id),
                      child: _PinBadge(
                        isSelected: pin.id == selectedPinId,
                        color: pin.id == selectedPinId
                            ? alertAmber
                            : targetLime,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ControlRail extends StatelessWidget {
  const _ControlRail({
    required this.glowCyan,
    required this.alertAmber,
    required this.targetLime,
    required this.selectedPin,
    required this.pins,
    required this.currentMph,
    required this.waterTemp,
    required this.windMph,
    required this.windBearing,
    required this.schoolScore,
    required this.onCurrentChanged,
    required this.onTempChanged,
    required this.onWindChanged,
    required this.onBearingChanged,
  });

  final Color glowCyan;
  final Color alertAmber;
  final Color targetLime;
  final CatchPin? selectedPin;
  final List<CatchPin> pins;
  final double currentMph;
  final double waterTemp;
  final double windMph;
  final double windBearing;
  final double schoolScore;
  final ValueChanged<double> onCurrentChanged;
  final ValueChanged<double> onTempChanged;
  final ValueChanged<double> onWindChanged;
  final ValueChanged<double> onBearingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RailPanel(
          title: 'Navigation',
          action: 'LIVE',
          child: Column(
            children: [
              _RailRow(
                icon: Icons.place_outlined,
                title: 'Captain pins',
                subtitle: '${pins.length} catch marks on chart',
                color: glowCyan,
                active: true,
              ),
              const SizedBox(height: 10),
              _RailRow(
                icon: Icons.route_outlined,
                title: 'Drift projection',
                subtitle: 'Current + wind + temp forecast path',
                color: alertAmber,
              ),
              const SizedBox(height: 10),
              _RailRow(
                icon: Icons.analytics_outlined,
                title: 'Fish model',
                subtitle: 'Concentration score at selected pin',
                color: targetLime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RailPanel(
          title: 'Data Bar',
          action: 'ENV',
          child: Column(
            children: [
              _StatBand(
                label: 'Current speed',
                value: '${currentMph.toStringAsFixed(1)} mph',
                accent: glowCyan,
              ),
              const SizedBox(height: 10),
              _StatBand(
                label: 'Surface temp',
                value: '${waterTemp.toStringAsFixed(1)} F',
                accent: alertAmber,
              ),
              const SizedBox(height: 10),
              _StatBand(
                label: 'Selected score',
                value: '${(schoolScore * 100).round()}%',
                accent: targetLime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _RailPanel(
            title: 'Control',
            action: 'DRIFT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SliderBlock(
                  label: 'Current',
                  valueLabel: '${currentMph.toStringAsFixed(1)} mph',
                  value: currentMph,
                  max: 3,
                  accent: glowCyan,
                  onChanged: onCurrentChanged,
                ),
                const SizedBox(height: 10),
                _SliderBlock(
                  label: 'Wind',
                  valueLabel: '${windMph.toStringAsFixed(0)} mph',
                  value: windMph,
                  max: 20,
                  accent: alertAmber,
                  onChanged: onWindChanged,
                ),
                const SizedBox(height: 10),
                _SliderBlock(
                  label: 'Bearing',
                  valueLabel: '${windBearing.round()} deg',
                  value: windBearing,
                  max: 360,
                  accent: glowCyan,
                  onChanged: onBearingChanged,
                ),
                const SizedBox(height: 10),
                _SliderBlock(
                  label: 'Probe temp',
                  valueLabel: '${waterTemp.toStringAsFixed(1)} F',
                  value: waterTemp,
                  min: 38,
                  max: 85,
                  accent: targetLime,
                  onChanged: onTempChanged,
                ),
                const SizedBox(height: 12),
                _SelectedPinTile(pin: selectedPin, glowCyan: glowCyan),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: glowCyan,
                      foregroundColor: const Color(0xFF03131B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('TAP MAP TO DROP NEW PIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomDrawer extends StatelessWidget {
  const _BottomDrawer({
    required this.glowCyan,
    required this.alertAmber,
    required this.targetLime,
    required this.selectedPin,
    required this.schoolScore,
    required this.currentMph,
    required this.waterTemp,
    required this.windMph,
  });

  final Color glowCyan;
  final Color alertAmber;
  final Color targetLime;
  final CatchPin? selectedPin;
  final double schoolScore;
  final double currentMph;
  final double waterTemp;
  final double windMph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF08131E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2F6F9A)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(
            width: 240,
            child: _RailPanel(
              title: 'CHART',
              action: 'LIVE',
              child: Column(
                children: [
                  _ChecklistTile(label: 'Tap map to mark', state: 'ARMED'),
                  const SizedBox(height: 10),
                  _ChecklistTile(
                    label: 'Selected score',
                    state: '${(schoolScore * 100).round()}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: _RailPanel(
              title: 'WEATHER',
              action: 'ENV',
              child: Column(
                children: [
                  _StatBand(
                    label: 'Current',
                    value: '${currentMph.toStringAsFixed(1)} mph',
                    accent: glowCyan,
                  ),
                  const SizedBox(height: 10),
                  _StatBand(
                    label: 'Wind',
                    value: '${windMph.toStringAsFixed(0)} mph',
                    accent: alertAmber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: _RailPanel(
              title: 'PATTERN',
              action: 'FISH',
              child: Column(
                children: [
                  _StatBand(
                    label: 'Water temp',
                    value: '${waterTemp.toStringAsFixed(1)} F',
                    accent: targetLime,
                  ),
                  const SizedBox(height: 10),
                  _StatBand(
                    label: 'Pin',
                    value: selectedPin == null ? '--' : selectedPin!.species,
                    accent: glowCyan,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6081520),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A495F)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.56),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MicroBadge extends StatelessWidget {
  const _MicroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1824),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayLegend extends StatelessWidget {
  const _OverlayLegend({
    required this.glowCyan,
    required this.targetLime,
    required this.alertAmber,
  });

  final Color glowCyan;
  final Color targetLime;
  final Color alertAmber;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _LegendRow(label: 'Captain catch pin', color: alertAmber),
          const SizedBox(height: 8),
          _LegendRow(label: 'Projected drift path', color: glowCyan),
          const SizedBox(height: 8),
          _LegendRow(label: 'High fish confidence', color: targetLime),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PinSummaryCard extends StatelessWidget {
  const _PinSummaryCard({
    required this.pin,
    required this.score,
    required this.glowCyan,
    required this.alertAmber,
    required this.targetLime,
  });

  final CatchPin? pin;
  final double score;
  final Color glowCyan;
  final Color alertAmber;
  final Color targetLime;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: pin == null
          ? const Text('Drop a pin to start drift tracking.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Pin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _LegendRow(label: pin!.species, color: alertAmber),
                const SizedBox(height: 8),
                _LegendRow(
                  label: '${pin!.weightLb.toStringAsFixed(1)} lb mark',
                  color: glowCyan,
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  label: 'Confidence ${(score * 100).round()}%',
                  color: targetLime,
                ),
              ],
            ),
    );
  }
}

class _HotspotStrip extends StatelessWidget {
  const _HotspotStrip({
    required this.targetLime,
    required this.glowCyan,
    required this.pins,
    required this.schoolScoreFor,
  });

  final Color targetLime;
  final Color glowCyan;
  final List<CatchPin> pins;
  final double Function(CatchPin pin) schoolScoreFor;

  @override
  Widget build(BuildContext context) {
    final sorted = [...pins]
      ..sort((a, b) => schoolScoreFor(b).compareTo(schoolScoreFor(a)));
    final topPins = sorted.take(2).toList();

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fish Concentration',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < topPins.length; i++) ...[
                Expanded(
                  child: _HotspotCard(
                    title: topPins[i].species,
                    density: '${(schoolScoreFor(topPins[i]) * 100).round()}%',
                    accent: i == 0 ? targetLime : glowCyan,
                  ),
                ),
                if (i == 0) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({
    required this.title,
    required this.density,
    required this.accent,
  });

  final String title;
  final String density;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            density,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'confidence',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LakeStatusDock extends StatelessWidget {
  const _LakeStatusDock({
    required this.glowCyan,
    required this.panelLine,
    required this.hullBlack,
    required this.driftVector,
    required this.count,
  });

  final Color glowCyan;
  final Color panelLine;
  final Color hullBlack;
  final Offset driftVector;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hullBlack.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation, color: glowCyan, size: 18),
          const SizedBox(width: 8),
          Text(
            'DRIFT ${(driftVector.distance * 10).toStringAsFixed(1)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$count PINS',
            style: TextStyle(color: glowCyan, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.isSelected, required this.color});

  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isSelected ? 30 : 24,
            height: isSelected ? 30 : 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 0.34 : 0.24),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          Icon(Icons.place, color: color, size: isSelected ? 20 : 18),
        ],
      ),
    );
  }
}

class _RailPanel extends StatelessWidget {
  const _RailPanel({
    required this.title,
    required this.action,
    required this.child,
  });

  final String title;
  final String action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBand extends StatelessWidget {
  const _StatBand({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF06101A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.66),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.label, required this.state});

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF08131D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF245D84)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA126),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            state,
            style: const TextStyle(
              color: Color(0xFF7EEBFF),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.valueLabel,
    required this.value,
    this.min = 0,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF08131D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF245D84)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                valueLabel,
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: accent,
            inactiveColor: Colors.white.withValues(alpha: 0.14),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectedPinTile extends StatelessWidget {
  const _SelectedPinTile({required this.pin, required this.glowCyan});

  final CatchPin? pin;
  final Color glowCyan;

  @override
  Widget build(BuildContext context) {
    final profile = pin == null
        ? null
        : _LakeCommandPageState._speciesProfiles[pin!.species];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF08131D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF245D84)),
      ),
      child: pin == null
          ? const Text('No pin selected')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pin!.species} ${pin!.weightLb.toStringAsFixed(1)} lb',
                  style: TextStyle(
                    color: glowCyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(pin!.note),
                if (profile != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${profile.tempSweetLowF.toStringAsFixed(0)}-${profile.tempSweetHighF.toStringAsFixed(0)} F target band',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.behavior,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _LakeMapPainter extends CustomPainter {
  const _LakeMapPainter({
    required this.pins,
    required this.selectedPinId,
    required this.driftVector,
    required this.schoolScoreFor,
  });

  final List<CatchPin> pins;
  final int? selectedPinId;
  final Offset driftVector;
  final double Function(CatchPin pin) schoolScoreFor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C2E4A), Color(0xFF13659B), Color(0xFF081A29)],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final gridPaint = Paint()
      ..color = const Color(0x22A9E8FF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 56) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 56) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..color = const Color(0x55A5F1FF);
    for (int i = 0; i < 7; i++) {
      final inset = 30.0 + (i * 32);
      final path = Path()
        ..moveTo(inset, size.height * 0.14 + i * 4)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * (0.02 + (i * 0.04)),
          size.width * 0.52,
          size.height * 0.16 + i * 10,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.28 + i * 6,
          size.width - inset,
          size.height * 0.12 + i * 18,
        )
        ..quadraticBezierTo(
          size.width * 0.88,
          size.height * 0.54 + i * 10,
          size.width * 0.62,
          size.height * 0.58 + i * 14,
        )
        ..quadraticBezierTo(
          size.width * 0.36,
          size.height * 0.64 + i * 8,
          inset + 18,
          size.height * 0.44 + i * 14,
        )
        ..quadraticBezierTo(
          inset - 10,
          size.height * 0.28 + i * 6,
          inset,
          size.height * 0.14 + i * 4,
        );
      canvas.drawPath(path, contourPaint);
    }

    final shoreline = Path()
      ..moveTo(size.width * 0.1, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.02,
        size.width * 0.56,
        size.height * 0.12,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.22,
        size.width * 0.88,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.76,
        size.width * 0.7,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.94,
        size.width * 0.2,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.04,
        size.height * 0.62,
        size.width * 0.1,
        size.height * 0.08,
      );

    canvas.drawPath(
      shoreline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = const Color(0xFF8BEFFF),
    );

    for (final pin in pins) {
      final center = Offset(pin.x * size.width, pin.y * size.height);
      final radius = 22 + (schoolScoreFor(pin) * 18);
      final color = pin.id == selectedPinId
          ? const Color(0xFFFFA126)
          : const Color(0xA0D1FF55);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0.02)],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8)),
      );

      final driftEnd =
          center +
          Offset(driftVector.dx * size.width, driftVector.dy * size.height);
      canvas.drawLine(
        center,
        driftEnd,
        Paint()
          ..color = const Color(0xFF7EEBFF)
          ..strokeWidth = pin.id == selectedPinId ? 3 : 2,
      );
      _drawArrowHead(canvas, center, driftEnd);
    }

    final routePaint = Paint()
      ..color = const Color(0xFFD1FF55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.52,
        size.width * 0.42,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.56,
        size.width * 0.72,
        size.height * 0.48,
      );
    canvas.drawPath(route, routePaint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 10.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - 0.4),
        end.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + 0.4),
        end.dy - arrowSize * math.sin(angle + 0.4),
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7EEBFF)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LakeMapPainter oldDelegate) {
    return oldDelegate.pins != pins ||
        oldDelegate.selectedPinId != selectedPinId ||
        oldDelegate.driftVector != driftVector;
  }
}
