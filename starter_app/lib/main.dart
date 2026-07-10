import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vmt;
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

void main() {
  runApp(const LakeIntelligenceProApp());
}

class LakeIntelligenceProApp extends StatelessWidget {
  const LakeIntelligenceProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lake Intelligence Pro',
      theme: ThemeData.dark(),
      home: const LakeGuardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LakeGuardScreen extends StatefulWidget {
  const LakeGuardScreen({super.key});

  @override
  State<LakeGuardScreen> createState() => _LakeGuardScreenState();
}

class _LakeGuardScreenState extends State<LakeGuardScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<Polygon> _shorelinePolygons = const [];
  List<Polyline> _bathymetryContours = const [];
  vtr.Theme? _noaaBathymetryTheme;
  late final Timer _radarRefreshTimer;
  late final AnimationController _currentAnimationController;
  int _radarRefreshKey = DateTime.now().millisecondsSinceEpoch;
  bool _animateCurrents = true;
  String? _middleMouseModule;
  final vmt.TileProviders _noaaBathymetryProviders = vmt.TileProviders({
    'esri': vmt.NetworkVectorTileProvider(
      urlTemplate:
          'https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/csb_vector_tiles/VectorTileServer/tile/{z}/{y}/{x}.pbf',
      minimumZoom: 0,
      maximumZoom: 19,
    ),
  });

  // Module states
  final Map<String, bool> _moduleStates = {
    'Species Density': true,
    'Bait Density': true,
    'Current': true,
    'Current @ Depth': false,
    'Surface Temp': true,
    'Thermocline': true,
    'Waypoints / Marked Fish': true,
    'Weather Radar': false,
  };

  final Map<String, double> _moduleOpacity = {
    'Species Density': 1.0,
    'Bait Density': 0.85,
    'Current': 0.7,
    'Current @ Depth': 0.6,
    'Surface Temp': 0.9,
    'Thermocline': 0.75,
    'Waypoints / Marked Fish': 0.95,
    'Weather Radar': 0.5,
  };

  double _plotterZoom = 7.0;

  // Fake GPS data (will be replaced with real)
  String _gpsStatus = "3D Fix";
  String _time = "2:34 PM";
  double _speed = 2.8;
  final double _depth = 47.0;
  final double _waterTemp = 68.4;

  LatLng _currentPosition = const LatLng(43.4, -86.7);

  @override
  void initState() {
    super.initState();
    _currentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _loadShorelinePolygons();
    _loadBathymetryContours();
    _loadNoaaBathymetryStyle();
    _updateRealTimeData();
    _radarRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      setState(() => _radarRefreshKey = DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    _radarRefreshTimer.cancel();
    _currentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadNoaaBathymetryStyle() async {
    final source = await rootBundle.loadString(
      'assets/noaa_crowdsourced_bathymetry_style.json',
    );
    final style = jsonDecode(source) as Map<String, dynamic>;
    final theme = vtr.ThemeReader().read(style);

    if (!mounted) return;
    setState(() => _noaaBathymetryTheme = theme);
  }

  Future<void> _loadBathymetryContours() async {
    final source = await rootBundle.loadString(
      'assets/noaa_lake_michigan_bathymetry_contours.geojson',
    );
    final geoJson = jsonDecode(source) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;
    final contours = <Polyline>[];

    for (final feature in features.cast<Map<String, dynamic>>()) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      final type = geometry['type'] as String?;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final lines = type == 'LineString'
          ? <dynamic>[coordinates]
          : type == 'MultiLineString'
          ? coordinates
          : const <dynamic>[];
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final depth = (properties['depth'] as num?)?.toDouble() ?? 0;
      final isMajorContour = depth.remainder(50).abs() < 0.01;

      for (final line in lines) {
        final points = (line as List<dynamic>).map((point) {
          final coordinate = point as List<dynamic>;
          return LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          );
        }).toList();
        if (points.length < 2) continue;

        contours.add(
          Polyline(
            points: points,
            strokeWidth: isMajorContour ? 1.35 : 0.7,
            color: isMajorContour
                ? const Color(0xCC183A4D)
                : const Color(0x7A294D5E),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _bathymetryContours = contours);
  }

  Future<void> _loadShorelinePolygons() async {
    final source = await rootBundle.loadString(
      'assets/lake_michigan_shoreline.geojson',
    );
    final geoJson = jsonDecode(source) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;
    final polygons = <Polygon>[];

    for (final feature in features.cast<Map<String, dynamic>>()) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      final type = geometry['type'] as String?;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final polygonCoordinates = type == 'Polygon'
          ? <dynamic>[coordinates]
          : type == 'MultiPolygon'
          ? coordinates
          : const <dynamic>[];

      for (final polygon in polygonCoordinates) {
        final rings = (polygon as List<dynamic>)
            .map(
              (ring) => (ring as List<dynamic>).map((point) {
                final coordinate = point as List<dynamic>;
                return LatLng(
                  (coordinate[1] as num).toDouble(),
                  (coordinate[0] as num).toDouble(),
                );
              }).toList(),
            )
            .toList();

        if (rings.isEmpty) continue;
        polygons.add(
          Polygon(
            points: rings.first,
            holePointsList: rings.length > 1 ? rings.sublist(1) : null,
            color: const Color(0x3329B6F6),
            borderColor: const Color(0xFF29B6F6),
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _shorelinePolygons = polygons);
  }

  void _updateRealTimeData() async {
    // Time
    setState(() {
      _time = TimeOfDay.now().format(context);
    });

    // GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _speed = position.speed * 2.23694; // m/s → mph
        _gpsStatus = "3D Fix";
      });
    }
  }

  void _toggleModule(String module) {
    setState(() {
      _moduleStates[module] = !(_moduleStates[module] ?? false);
    });
  }

  void _updateOpacity(String module, double delta) {
    setState(() {
      final currentOpacity = _moduleOpacity[module] ?? 1.0;
      _moduleOpacity[module] = (currentOpacity - delta * 0.01).clamp(0.0, 1.0);
    });
  }

  void _setCurrentAnimation(bool enabled) {
    setState(() => _animateCurrents = enabled);
    if (enabled) {
      _currentAnimationController.repeat();
    } else {
      _currentAnimationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050607),
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1168,
              height: 760,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF44494D),
                      Color(0xFF191C1F),
                      Color(0xFF080A0C),
                      Color(0xFF202428),
                    ],
                    stops: [0, 0.08, 0.72, 1],
                  ),
                  border: Border.all(color: const Color(0xFF686E72), width: 3),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF000000),
                      blurRadius: 34,
                      spreadRadius: 4,
                      offset: Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Color(0x557D8790),
                      blurRadius: 3,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(color: const Color(0x44000000), width: 7),
                ),
                child: CustomPaint(
                  painter: const _PlasticTexturePainter(),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 58,
                        child: Center(
                          child: Text(
                            'LakeGuard Pro',
                            style: TextStyle(
                              color: Color(0xFFB9BDC1),
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1.2,
                              shadows: [
                                Shadow(
                                  color: Color(0xCC000000),
                                  blurRadius: 3,
                                  offset: Offset(2, 3),
                                ),
                                Shadow(
                                  color: Color(0x557E8990),
                                  offset: Offset(-1, -1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF080A0C),
                                      Color(0xFF3F4549),
                                      Color(0xFF0A0C0E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black,
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                      offset: Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: Color(0x557E878D),
                                      blurRadius: 2,
                                      offset: Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: _buildLakeGuardDisplay(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(width: 104, child: _buildHardwareRail()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLakeGuardDisplay() {
    return Column(
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07111B), Color(0xFF003B64), Color(0xFF07111B)],
            ),
          ),
          child: const Row(
            children: [
              Text(
                'AquaPlotter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 18),
              Icon(Icons.signal_cellular_alt, color: Colors.white, size: 27),
              Spacer(),
              Icon(Icons.navigation, color: Colors.white, size: 32),
              Spacer(),
              Icon(Icons.usb, color: Color(0xFF15F04B), size: 23),
              SizedBox(width: 18),
              Icon(Icons.battery_full, color: Color(0xFF55F15B), size: 30),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildChartArea()),
              SizedBox(width: 142, child: _buildTelemetryRail()),
            ],
          ),
        ),
        SizedBox(height: 154, child: _buildModuleStrip()),
      ],
    );
  }

  Widget _buildChartArea() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(44.0, -87.0),
            initialZoom: _plotterZoom,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) setState(() => _plotterZoom = position.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.starter_app',
            ),
            if (_moduleStates['Surface Temp'] ?? false)
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: LatLngBounds(
                      const LatLng(41.5, -88.7),
                      const LatLng(46.5, -84.3),
                    ),
                    imageProvider: const AssetImage(
                      'assets/noaa_glsea_lake_michigan_sst.png',
                    ),
                    opacity: _moduleOpacity['Surface Temp'] ?? 0.9,
                  ),
                ],
              ),
            PolylineLayer(polylines: _bathymetryContours),
            PolygonLayer(polygons: _shorelinePolygons),
            if (_noaaBathymetryTheme case final theme?)
              vmt.VectorTileLayer(
                theme: theme,
                tileProviders: _noaaBathymetryProviders,
              ),
            if (_moduleStates['Weather Radar'] ?? false)
              Opacity(
                opacity: _moduleOpacity['Weather Radar'] ?? 0.5,
                child: TileLayer(
                  key: ValueKey(_radarRefreshKey),
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl:
                        'https://mapservices.weather.noaa.gov/eventdriven/services/radar/radar_base_reflectivity/MapServer/WMSServer?',
                    layers: const ['1'],
                    styles: const ['default'],
                    version: '1.3.0',
                    transparent: true,
                    otherParameters: {'refresh': _radarRefreshKey.toString()},
                  ),
                  userAgentPackageName: 'com.example.starter_app',
                ),
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition,
                  child: const Icon(
                    Icons.directions_boat,
                    color: Color(0xFF17272B),
                    size: 38,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_moduleStates['Species Density'] ?? false)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _moduleOpacity['Species Density']!,
                child: Container(color: const Color(0x332400FF)),
              ),
            ),
          ),
        if ((_moduleStates['Current'] ?? false) && _animateCurrents)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _moduleOpacity['Current'] ?? 0.7,
                child: AnimatedBuilder(
                  animation: _currentAnimationController,
                  builder: (context, child) => CustomPaint(
                    painter: _CurrentFlowPainter(
                      progress: _currentAnimationController.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Positioned(
          left: 10,
          bottom: 10,
          child: _MapSquareButton(icon: Icons.home),
        ),
        const Positioned(
          right: 10,
          top: 10,
          child: _MapSquareButton(icon: Icons.gps_fixed),
        ),
      ],
    );
  }

  Widget _buildTelemetryRail() {
    return Container(
      color: const Color(0xFF07090A),
      child: Column(
        children: [
          _buildTelemetryCard(
            'Depth:',
            _depth.toStringAsFixed(0),
            suffix: 'ft',
            flex: 6,
          ),
          _buildTelemetryCard(
            'Water Temp:',
            _waterTemp.toStringAsFixed(1),
            suffix: '°F',
            flex: 5,
          ),
          _buildTelemetryCard(
            'Speed:',
            _speed.toStringAsFixed(1),
            suffix: 'mph',
            flex: 5,
          ),
          _buildTelemetryCard('Time', _time, flex: 4),
          _buildTelemetryCard('GPS', _gpsStatus, flex: 4),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(
    String label,
    String value, {
    String? suffix,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF25292C), Color(0xFF090B0D), Color(0xFF020303)],
          ),
          border: Border.all(color: const Color(0xFF555B5F), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 5,
              offset: Offset(2, 3),
            ),
            BoxShadow(color: Color(0x334F575D), offset: Offset(0, -1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (suffix != null)
                      TextSpan(
                        text: suffix,
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleStrip() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _moduleStates.keys
          .map((module) => Expanded(child: _buildModuleControl(module)))
          .toList(),
    );
  }

  Widget _buildModuleControl(String module) {
    final isOn = _moduleStates[module] ?? false;
    final opacity = _moduleOpacity[module] ?? 1;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons & kMiddleMouseButton != 0) {
          _middleMouseModule = module;
        }
      },
      onPointerUp: (_) {
        if (_middleMouseModule == module) _middleMouseModule = null;
      },
      onPointerCancel: (_) {
        if (_middleMouseModule == module) _middleMouseModule = null;
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && _middleMouseModule == module) {
          _updateOpacity(module, event.scrollDelta.dy.sign * 5);
        }
      },
      child: GestureDetector(
        onTap: () => _toggleModule(module),
        onVerticalDragUpdate: (details) =>
            _updateOpacity(module, details.delta.dy),
        child: Tooltip(
          message: 'Left-click: ON/OFF\nHold mouse wheel + scroll: opacity',
          child: Container(
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isOn
                    ? const [
                        Color(0xFF46FF4A),
                        Color(0xFF12A91A),
                        Color(0xFF063A09),
                      ]
                    : const [
                        Color(0xFF353A3E),
                        Color(0xFF15181A),
                        Color(0xFF070809),
                      ],
              ),
              border: Border.all(color: const Color(0xFF666C70), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6,
                  offset: Offset(2, 4),
                ),
                BoxShadow(
                  color: Color(0x445F686F),
                  blurRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        module
                            .replaceAll(' / ', ' /\n')
                            .replaceAll(' @ ', ' @\n'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 58,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CustomPaint(
                          painter: _OrangeKnobPainter(
                            value: opacity,
                            active: isOn,
                          ),
                        ),
                      ),
                      Text(
                        '${(opacity * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: double.infinity,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF3A3E41),
                        Color(0xFF111315),
                        Color(0xFF050607),
                      ],
                    ),
                    border: Border.all(color: const Color(0xFF363A3D)),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: isOn
                          ? const Color(0xFFD9FFDA)
                          : const Color(0xFFFF9A36),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      shadows: isOn
                          ? const [
                              Shadow(color: Color(0xFF40FF48), blurRadius: 8),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareRail() {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF373C40),
            Color(0xFF15181A),
            Color(0xFF08090A),
            Color(0xFF25292C),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4C5256), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(4, 7),
          ),
          BoxShadow(
            color: Color(0x555E666B),
            blurRadius: 2,
            offset: Offset(-1, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRoundHardwareButton(Icons.arrow_drop_up),
          const SizedBox(height: 12),
          _buildRoundHardwareButton(Icons.add, onTap: () => _zoomBy(1)),
          const SizedBox(height: 12),
          _buildRoundHardwareButton(Icons.remove, onTap: () => _zoomBy(-1)),
          const SizedBox(height: 18),
          SizedBox(width: 88, height: 88, child: _buildBlueKnob()),
          const Spacer(),
          Container(
            width: 84,
            height: 112,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF454A4D),
                  Color(0xFF141719),
                  Color(0xFF050607),
                ],
              ),
              border: Border.all(color: const Color(0xFF0A0B0C), width: 4),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 7,
                  offset: Offset(3, 5),
                ),
                BoxShadow(color: Color(0x555C6469), offset: Offset(-1, -1)),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.arrow_drop_up,
                  color: Color(0xFFFFA044),
                  size: 38,
                  shadows: [Shadow(color: Color(0xFFFF5A00), blurRadius: 12)],
                ),
                Icon(
                  Icons.arrow_drop_up,
                  color: Color(0xFFFF6A28),
                  size: 30,
                  shadows: [Shadow(color: Color(0xFFFF3D00), blurRadius: 11)],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 92,
            height: 68,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FF3D00),
                    blurRadius: 24,
                    spreadRadius: 5.6,
                  ),
                  BoxShadow(
                    color: Color(0xDDFF6A00),
                    blurRadius: 12,
                    spreadRadius: 2.4,
                  ),
                  BoxShadow(
                    color: Color(0xFFFFC36A),
                    blurRadius: 3.2,
                    spreadRadius: 0.8,
                  ),
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(3, 6),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: _showMenu,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFE0A8),
                  backgroundColor: const Color(0xFF111315),
                  side: const BorderSide(color: Color(0xFFFFB64D), width: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xFFFFF0C8), blurRadius: 2),
                      Shadow(color: Color(0xFFFF8A1F), blurRadius: 6.4),
                      Shadow(color: Color(0xFFFF3D00), blurRadius: 14.4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundHardwareButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(0.42, -0.5),
            radius: 1.05,
            colors: [
              Color(0xFF858B8F),
              Color(0xFF303437),
              Color(0xFF08090A),
              Color(0xFF020303),
            ],
            stops: [0, 0.3, 0.76, 1],
          ),
          border: Border.all(color: const Color(0xFFFFA43B), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FF3D00),
              blurRadius: 22.4,
              spreadRadius: 5.6,
            ),
            BoxShadow(
              color: Color(0xCCFF6A00),
              blurRadius: 11.2,
              spreadRadius: 2.4,
            ),
            BoxShadow(
              color: Color(0xFFFFC36A),
              blurRadius: 3.2,
              spreadRadius: 0.4,
            ),
            BoxShadow(
              color: Colors.black,
              blurRadius: 9,
              spreadRadius: 1,
              offset: Offset(3, 6),
            ),
            BoxShadow(
              color: Color(0x665F686D),
              blurRadius: 2,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment(0.55, -1),
              end: Alignment(-0.15, 1),
              colors: [Color(0x447F8A90), Color(0x00121517), Color(0xAA000000)],
              stops: [0, 0.45, 1],
            ),
            border: Border.all(color: const Color(0xFFFFE0A8), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0xCCFF8A1F), blurRadius: 5.6),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFE8BE),
            size: 36,
            shadows: const [
              Shadow(color: Color(0xFFFFFFFF), blurRadius: 2),
              Shadow(color: Color(0xFFFF8A1F), blurRadius: 6.4),
              Shadow(color: Color(0xFFFF3D00), blurRadius: 12.8),
              Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 2)),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLegacyLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Screen Bezel
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700, width: 18),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "AquaPlotter",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Icon(
                            Icons.signal_cellular_4_bar,
                            color: Colors.white,
                          ),
                          const Text(
                            "Lake Intelligence Pro",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Icon(Icons.battery_full, color: Colors.green),
                        ],
                      ),
                    ),

                    // Map Area
                    Expanded(
                      child: CustomPaint(
                        painter: const _DeviceBezelPainter(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      width * 0.07,
                                      height * 0.08,
                                      width * 0.17,
                                      height * 0.10,
                                    ),
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          mapController: _mapController,
                                          options: MapOptions(
                                            initialCenter: _currentPosition,
                                            initialZoom: _plotterZoom,
                                            onPositionChanged:
                                                (position, hasGesture) {
                                                  if (hasGesture) {
                                                    setState(
                                                      () => _plotterZoom =
                                                          position.zoom,
                                                    );
                                                  }
                                                },
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.example.starter_app',
                                              // Replace with Navionics/Garmin tiles when ready
                                            ),
                                            PolygonLayer(
                                              polygons: _shorelinePolygons,
                                            ),
                                            if (_noaaBathymetryTheme
                                                case final theme?)
                                              vmt.VectorTileLayer(
                                                theme: theme,
                                                tileProviders:
                                                    _noaaBathymetryProviders,
                                              ),
                                            // Boat marker
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: _currentPosition,
                                                  child: const Icon(
                                                    Icons.directions_boat,
                                                    color: Colors.white,
                                                    size: 32,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Overlay data (opacity controlled by dials)
                                        if (_moduleStates['Species Density'] ??
                                            false)
                                          Positioned.fill(
                                            child: Opacity(
                                              opacity:
                                                  _moduleOpacity['Species Density']!,
                                              child: Container(
                                                color: Colors.purple.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Add more layers for other modules...

                                        // Right Panel Readings (White as requested)
                                        Positioned(
                                          right: 12,
                                          top: 12,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              _buildReading(
                                                "Depth:",
                                                "${_depth.toStringAsFixed(0)} ft",
                                              ),
                                              _buildReading(
                                                "Water Temp:",
                                                "${_waterTemp.toStringAsFixed(1)}°F",
                                              ),
                                              _buildReading(
                                                "Speed:",
                                                "${_speed.toStringAsFixed(1)} mph",
                                              ),
                                              _buildReading("Time:", _time),
                                              _buildReading("GPS:", _gpsStatus),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: width * 0.875,
                                  top: height * 0.045,
                                  width: width * 0.035,
                                  height: width * 0.035,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF080808),
                                      border: Border.all(
                                        color: const Color(0xFF73787B),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: width * 0.845,
                                  top: height * 0.13,
                                  width: width * 0.10,
                                  height: width * 0.10,
                                  child: _buildBlueKnob(),
                                ),
                                Positioned(
                                  left: width * 0.84,
                                  top: height * 0.35,
                                  width: width * 0.11,
                                  height: height * 0.38,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _buildBezelButton(
                                          icon: Icons.add,
                                          label: 'ZOOM IN',
                                          onPressed: () => _zoomBy(1),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Expanded(
                                        child: _buildBezelButton(
                                          icon: Icons.remove,
                                          label: 'ZOOM OUT',
                                          onPressed: () => _zoomBy(-1),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Expanded(
                                        flex: 2,
                                        child: _buildBezelButton(
                                          icon: Icons.menu,
                                          label: 'MENU',
                                          onPressed: _showMenu,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Bottom Controls
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _moduleStates.keys.map((module) {
                          bool isOn = _moduleStates[module] ?? false;
                          return GestureDetector(
                            onTap: () => _toggleModule(module),
                            onVerticalDragUpdate: (details) =>
                                _updateOpacity(module, details.delta.dy),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CustomPaint(
                                    painter: _OrangeKnobPainter(
                                      value: _moduleOpacity[module] ?? 1.0,
                                      active: isOn,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  module,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  isOn
                                      ? "ON • ${((_moduleOpacity[module] ?? 1.0) * 100).round()}%"
                                      : "OFF",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isOn ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomBy(double amount) {
    setState(() {
      _plotterZoom = (_plotterZoom + amount).clamp(5.0, 20.0);
    });
    _mapController.move(_mapController.camera.center, _plotterZoom);
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MenuPanel(
        animateCurrents: _animateCurrents,
        onAnimateCurrentsChanged: _setCurrentAnimation,
      ),
    );
  }

  Widget _buildBlueKnob() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _plotterZoom += details.delta.dy * -0.05;
          _plotterZoom = _plotterZoom.clamp(5.0, 20.0);
        });
        _mapController.move(_mapController.camera.center, _plotterZoom);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(0.42, -0.5),
            radius: 1.05,
            colors: [
              Color(0xFF71818B),
              Color(0xFF1C2D36),
              Color(0xFF05090B),
              Color(0xFF010203),
            ],
            stops: [0, 0.32, 0.77, 1],
          ),
          border: Border.all(color: const Color(0xFF050708), width: 6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x550087FF),
              blurRadius: 28.8,
              spreadRadius: 7.2,
            ),
            BoxShadow(
              color: Color(0xDD00D9FF),
              blurRadius: 17.6,
              spreadRadius: 3.2,
            ),
            BoxShadow(
              color: Color(0xFFB8F8FF),
              blurRadius: 4,
              spreadRadius: 0.8,
            ),
            BoxShadow(color: Colors.black, blurRadius: 9, offset: Offset(4, 7)),
            BoxShadow(
              color: Color(0x8879858B),
              blurRadius: 2,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment(0.55, -1),
              end: Alignment(-0.15, 1),
              colors: [Color(0x555C7683), Color(0x00121D22), Color(0xB8000000)],
              stops: [0, 0.45, 1],
            ),
            border: Border.all(color: const Color(0xFFC8FBFF), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF00E5FF),
                blurRadius: 10.4,
                spreadRadius: 1.6,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.zoom_in,
              color: Color(0xFF9CF5FF),
              size: 30,
              shadows: [
                Shadow(color: Colors.white, blurRadius: 2),
                Shadow(color: Color(0xFF00E5FF), blurRadius: 7.2),
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBezelButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.orange,
          shape: const RoundedRectangleBorder(),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReading(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label $value",
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PlasticTexturePainter extends CustomPainter {
  const _PlasticTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grain = Paint()
      ..color = const Color(0x0CFFFFFF)
      ..strokeWidth = 0.7;
    final shadowGrain = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 0.8;

    for (double y = 4; y < size.height; y += 7) {
      final offset = (y ~/ 7).isEven ? 0.0 : 3.5;
      for (double x = offset; x < size.width; x += 11) {
        canvas.drawLine(Offset(x, y), Offset(x + 2.5, y + 0.8), grain);
        canvas.drawLine(
          Offset(x + 1, y + 1.8),
          Offset(x + 3.2, y + 2.4),
          shadowGrain,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlasticTexturePainter oldDelegate) => false;
}

class _MapSquareButton extends StatelessWidget {
  const _MapSquareButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xDD0B0D0E),
        border: Border.all(color: const Color(0xFF777C80)),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _CurrentFlowPainter extends CustomPainter {
  const _CurrentFlowPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0x6600E5FF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final streamPaint = Paint()
      ..color = const Color(0xCCB8FBFF)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final headPaint = Paint()
      ..color = const Color(0xFFF2FFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    const columns = 11;
    const rows = 7;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final phase = (progress + column * 0.071 + row * 0.113) % 1.0;
        final baseX = (column + 0.35) * size.width / columns;
        final baseY = (row + 0.4) * size.height / rows;
        final drift = phase * size.width * 0.09;
        final wave = math.sin((phase + row * 0.17) * math.pi * 2);
        final start = Offset(
          (baseX + drift) % (size.width + 30) - 15,
          baseY + wave * 10,
        );
        final direction = -0.30 + math.sin(row * 0.8 + column * 0.32) * 0.24;
        final length = size.width * (0.030 + (column % 3) * 0.006);
        final control = Offset(
          start.dx + length * 0.52,
          start.dy + math.sin(phase * math.pi * 2 + column) * 7,
        );
        final end = Offset(start.dx + length, start.dy + length * direction);
        final path = ui.Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

        final fade = math.sin(phase * math.pi).clamp(0.0, 1.0);
        glowPaint.color = Color.fromRGBO(0, 229, 255, 0.30 * fade);
        streamPaint.color = Color.fromRGBO(184, 251, 255, 0.78 * fade);
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, streamPaint);
        canvas.drawCircle(
          end,
          2.2,
          headPaint..color = Colors.white.withValues(alpha: fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurrentFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DeviceBezelPainter extends CustomPainter {
  const _DeviceBezelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(size.width * 0.025, size.height * 0.05)
      ..lineTo(size.width * 0.09, 0)
      ..lineTo(size.width * 0.80, 0)
      ..lineTo(size.width * 0.84, size.height * 0.035)
      ..lineTo(size.width * 0.96, size.height * 0.055)
      ..lineTo(size.width, size.height * 0.20)
      ..lineTo(size.width, size.height * 0.82)
      ..lineTo(size.width * 0.96, size.height * 0.96)
      ..lineTo(size.width * 0.84, size.height)
      ..lineTo(size.width * 0.80, size.height * 0.97)
      ..lineTo(size.width * 0.08, size.height)
      ..lineTo(size.width * 0.025, size.height * 0.93)
      ..lineTo(0, size.height * 0.78)
      ..lineTo(0, size.height * 0.18)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6062), Color(0xFF26292B), Color(0xFF4A4E50)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF777C7F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.06),
      Offset(size.width * 0.82, size.height * 0.93),
      Paint()
        ..color = const Color(0xFF111315)
        ..strokeWidth = 2,
    );

    final ventPaint = Paint()
      ..color = const Color(0xFF17191A)
      ..strokeWidth = 1;
    for (var index = 0; index < 8; index++) {
      final y = size.height * (0.80 + index * 0.012);
      canvas.drawLine(
        Offset(size.width * 0.88, y),
        Offset(size.width * 0.94, y),
        ventPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DeviceBezelPainter oldDelegate) => false;
}

class _OrangeKnobPainter extends CustomPainter {
  const _OrangeKnobPainter({required this.value, required this.active});

  final double value;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;

    canvas.drawCircle(
      center + const Offset(2.5, 3.5),
      radius + 2,
      Paint()
        ..color = const Color(0xCC000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    if (active) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = const Color(0x33FF3D00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = const Color(0x77FF6A00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.2),
      );
      canvas.drawCircle(
        center,
        radius + 1,
        Paint()
          ..color = const Color(0xCCFFC36A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    }

    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment(-0.18, 1),
          colors: [Color(0xFF8A8F91), Color(0xFF17191A), Color(0xFF020303)],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 2)),
    );

    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.45, -0.5),
          radius: 1.05,
          colors: [
            Color(0xFF666A6D),
            Color(0xFF252728),
            Color(0xFF090A0A),
            Color(0xFF010101),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = active ? const Color(0xFFFF8A1A) : const Color(0xFF5A3B17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -math.pi * 0.45,
      math.pi * 0.40,
      false,
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    for (var index = 0; index < 9; index++) {
      final tickAngle = -math.pi * 0.75 + index * (math.pi * 1.5 / 8);
      final tickStart = Offset(
        center.dx + (radius + 1) * math.cos(tickAngle),
        center.dy + (radius + 1) * math.sin(tickAngle),
      );
      final tickEnd = Offset(
        center.dx + (radius + 4) * math.cos(tickAngle),
        center.dy + (radius + 4) * math.sin(tickAngle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = active ? const Color(0xFFFFB15A) : const Color(0xFF5C5F61)
          ..strokeWidth = 1.2,
      );
    }

    final angle = -math.pi * 0.75 + value * math.pi * 1.5;
    final end = Offset(
      center.dx + (radius - 12) * math.cos(angle),
      center.dy + (radius - 12) * math.sin(angle),
    );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = active ? const Color(0xFFFFD28C) : const Color(0xFF8A6A40)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFF5D6163), Color(0xFF050505)],
        ).createShader(Rect.fromCircle(center: center, radius: 5)),
    );
  }

  @override
  bool shouldRepaint(covariant _OrangeKnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.active != active;
}

class MenuPanel extends StatefulWidget {
  const MenuPanel({
    super.key,
    required this.animateCurrents,
    required this.onAnimateCurrentsChanged,
  });

  final bool animateCurrents;
  final ValueChanged<bool> onAnimateCurrentsChanged;

  @override
  State<MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<MenuPanel> {
  late bool _animateCurrents;

  @override
  void initState() {
    super.initState();
    _animateCurrents = widget.animateCurrents;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1114),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: Color(0xFF42E84B), width: 2)),
        boxShadow: [BoxShadow(color: Color(0x6600FF33), blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF536068),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF53FF5A), size: 27),
              SizedBox(width: 10),
              Text(
                'MAIN MENU  /  SETTINGS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF17311E), Color(0xFF101719)],
              ),
              border: Border.all(
                color: _animateCurrents
                    ? const Color(0xFF48F253)
                    : const Color(0xFF3D484D),
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _animateCurrents
                  ? const [BoxShadow(color: Color(0x443CFF48), blurRadius: 16)]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF082C34),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.air,
                    color: Color(0xFF72F4FF),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Animated currents',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Smooth particle flow over the Current data layer',
                        style: TextStyle(
                          color: Color(0xFF9DAEB5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _animateCurrents,
                  activeThumbColor: const Color(0xFFE8FFEA),
                  activeTrackColor: const Color(0xFF25C92D),
                  onChanged: (enabled) {
                    setState(() => _animateCurrents = enabled);
                    widget.onAnimateCurrentsChanged(enabled);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.mouse_outlined, color: Color(0xFFFFA24B), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Overlay controls: left-click toggles ON/OFF. '
                  'Hold the mouse wheel and scroll to adjust opacity.',
                  style: TextStyle(color: Color(0xFFABB7BC), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
