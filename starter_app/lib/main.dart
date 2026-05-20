import 'package:flutter/material.dart';

import 'models/observation_models.dart';
import 'services/mock_data_repository.dart';
import 'services/scenario_aggregator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepBase = Color(0xFF07131A);
    const Color panel = Color(0xFF10212A);
    const Color panelAlt = Color(0xFF163240);
    const Color gold = Color(0xFFD7A84A);
    const Color aqua = Color(0xFF70C4D4);

    return MaterialApp(
      title: 'Lake Michigan Blueprint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deepBase,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: gold,
          onPrimary: deepBase,
          secondary: aqua,
          onSecondary: deepBase,
          error: Color(0xFFE46353),
          onError: Colors.white,
          surface: panel,
          onSurface: Color(0xFFE8F1F3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: deepBase,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: panel,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF284451)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panelAlt,
          labelStyle: const TextStyle(color: Color(0xFFA7BBC4)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF31505F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF31505F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: gold, width: 1.3),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: gold,
          inactiveTrackColor: Color(0xFF294A59),
          thumbColor: gold,
          overlayColor: Color(0x33D7A84A),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(height: 1.35),
          bodyMedium: TextStyle(height: 1.4),
          labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .5),
        ),
        useMaterial3: true,
      ),
      home: const BlueprintApp(),
    );
  }
}

enum TargetSpecies {
  kingSalmon('King Salmon'),
  cohoSalmon('Coho Salmon'),
  steelhead('Steelhead'),
  lakeTrout('Lake Trout');

  const TargetSpecies(this.label);

  final String label;
}

enum TimeOfDayPeriod {
  firstLight('First light'),
  morning('Morning'),
  midday('Midday'),
  evening('Evening'),
  lowLight('Low light');

  const TimeOfDayPeriod(this.label);

  final String label;
}

enum WaterClarity {
  muddy('Muddy / stained'),
  mixed('Mixed green'),
  clear('Clear'),
  ultraClear('Ultra clear');

  const WaterClarity(this.label);

  final String label;
}

enum WeatherPattern {
  stable('Stable'),
  warming('Warming'),
  cooling('Cooling'),
  strongNorthBlow('Strong North Blow'),
  strongSouthBlow('Strong South Blow');

  const WeatherPattern(this.label);

  final String label;
}

class TripInputs {
  const TripInputs({
    required this.species,
    required this.month,
    required this.timeOfDay,
    required this.waterClarity,
    required this.waterDepth,
    required this.surfaceTemp,
    required this.thermoclineDepth,
    required this.currentSpeed,
    required this.baitLevel,
    required this.reportStrength,
    required this.weatherPattern,
  });

  final TargetSpecies species;
  final int month;
  final TimeOfDayPeriod timeOfDay;
  final WaterClarity waterClarity;
  final double waterDepth;
  final double surfaceTemp;
  final double thermoclineDepth;
  final double currentSpeed;
  final double baitLevel;
  final double reportStrength;
  final WeatherPattern weatherPattern;

  TripInputs copyWith({
    TargetSpecies? species,
    int? month,
    TimeOfDayPeriod? timeOfDay,
    WaterClarity? waterClarity,
    double? waterDepth,
    double? surfaceTemp,
    double? thermoclineDepth,
    double? currentSpeed,
    double? baitLevel,
    double? reportStrength,
    WeatherPattern? weatherPattern,
  }) {
    return TripInputs(
      species: species ?? this.species,
      month: month ?? this.month,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      waterClarity: waterClarity ?? this.waterClarity,
      waterDepth: waterDepth ?? this.waterDepth,
      surfaceTemp: surfaceTemp ?? this.surfaceTemp,
      thermoclineDepth: thermoclineDepth ?? this.thermoclineDepth,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      baitLevel: baitLevel ?? this.baitLevel,
      reportStrength: reportStrength ?? this.reportStrength,
      weatherPattern: weatherPattern ?? this.weatherPattern,
    );
  }
}

class SpeciesProfile {
  const SpeciesProfile({
    required this.species,
    required this.shortTitle,
    required this.generalLocation,
    required this.depthBand,
    required this.seasonWindow,
    required this.idealSpread,
    required this.keySignals,
    required this.menuNotes,
  });

  final TargetSpecies species;
  final String shortTitle;
  final String generalLocation;
  final String depthBand;
  final String seasonWindow;
  final String idealSpread;
  final List<String> keySignals;
  final List<String> menuNotes;
}

class SpeciesMarkerData {
  const SpeciesMarkerData({
    required this.species,
    required this.label,
    required this.note,
    required this.alignment,
    required this.color,
  });

  final TargetSpecies species;
  final String label;
  final String note;
  final Alignment alignment;
  final Color color;
}

class MenuSectionData {
  const MenuSectionData({required this.title, required this.items});

  final String title;
  final List<MenuItemData> items;
}

class MenuItemData {
  const MenuItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class BlueprintApp extends StatefulWidget {
  const BlueprintApp({super.key});

  @override
  State<BlueprintApp> createState() => _BlueprintAppState();
}

class _BlueprintAppState extends State<BlueprintApp> {
  static const List<SpeciesProfile> _speciesProfiles = <SpeciesProfile>[
    SpeciesProfile(
      species: TargetSpecies.kingSalmon,
      shortTitle: 'Offshore thermocline hunters',
      generalLocation: 'West-side bait breaks and suspended offshore lanes',
      depthBand: '35-70 down over 90-180 FOW',
      seasonWindow: 'June through early September',
      idealSpread: 'Deep riggers, wire divers, paddles, meat, and glow starts',
      keySignals: <String>[
        'Defined thermocline',
        'Adult bait pods stacked near the break',
        'Stable overnight water',
      ],
      menuNotes: <String>[
        'Best as the primary tournament weight play when bait and cold water align.',
        'If the morning king lane fades, rotate to lake trout for insurance weight.',
      ],
    ),
    SpeciesProfile(
      species: TargetSpecies.cohoSalmon,
      shortTitle: 'Nearshore seam fish',
      generalLocation:
          'Warm shoreline edges, harbor plume seams, and high bait',
      depthBand: 'Surface to 35 down',
      seasonWindow: 'April to June, then support fish in midsummer',
      idealSpread:
          'Short cores, small spoons, boards, and quick-turn search passes',
      keySignals: <String>[
        'Green water seams',
        'Warmer pockets',
        'Scattered high bait',
      ],
      menuNotes: <String>[
        'Use coho as a speed and search species when kings are not pinned yet.',
        'They fit naturally into shallower menu paths and early-season planning screens.',
      ],
    ),
    SpeciesProfile(
      species: TargetSpecies.steelhead,
      shortTitle: 'Surface-oriented roamers',
      generalLocation:
          'Offshore top-water edges, slicks, and warm current seams',
      depthBand: 'Surface to 20 down over deep water',
      seasonWindow: 'Late spring through late summer',
      idealSpread:
          'Fast spoons, high divers, coppers, and visible surface-line passes',
      keySignals: <String>[
        'Surface temp breaks',
        'Calm-sunrise slicks',
        'High bait on open water',
      ],
      menuNotes: <String>[
        'Steelhead belong in the upper-column submenu because speed and visibility matter more than bottom structure.',
        'Good fallback species for action when mature kings are inactive.',
      ],
    ),
    SpeciesProfile(
      species: TargetSpecies.lakeTrout,
      shortTitle: 'Bottom-control weight insurance',
      generalLocation:
          'Structure edges and deep contour swings near cold water',
      depthBand: 'Bottom to 10 above bottom over 80-160 FOW',
      seasonWindow: 'Most consistent across the broadest part of the season',
      idealSpread:
          'Bottom-hugging attractors, paddles, and repeatable contour trolls',
      keySignals: <String>[
        'Cold stable bottom water',
        'Repeatable contours',
        'Turns that sweep bottom structure',
      ],
      menuNotes: <String>[
        'Lake trout are the most dependable submenu for backup weight and salvage passes.',
        'They pair well with tournament-history screens because historical boxes often lean on them.',
      ],
    ),
  ];

  static const List<SpeciesMarkerData> _markers = <SpeciesMarkerData>[
    SpeciesMarkerData(
      species: TargetSpecies.cohoSalmon,
      label: 'Coho',
      note: 'Nearshore warm seam',
      alignment: Alignment(-0.18, 0.58),
      color: Color(0xFF87D97A),
    ),
    SpeciesMarkerData(
      species: TargetSpecies.kingSalmon,
      label: 'Kings',
      note: 'Offshore thermocline lane',
      alignment: Alignment(0.08, 0.18),
      color: Color(0xFFD7A84A),
    ),
    SpeciesMarkerData(
      species: TargetSpecies.steelhead,
      label: 'Steelhead',
      note: 'High open-water edge',
      alignment: Alignment(0.28, -0.18),
      color: Color(0xFF70C4D4),
    ),
    SpeciesMarkerData(
      species: TargetSpecies.lakeTrout,
      label: 'Lake Trout',
      note: 'Deep contour weight lane',
      alignment: Alignment(0.12, 0.72),
      color: Color(0xFFE36B57),
    ),
  ];

  static const List<MenuSectionData> _menuSections = <MenuSectionData>[
    MenuSectionData(
      title: 'Trip Planning',
      items: <MenuItemData>[
        MenuItemData(
          id: 'planner',
          title: 'Run Blueprint',
          subtitle: 'Interactive setup and scoring',
          icon: Icons.tune_rounded,
        ),
        MenuItemData(
          id: 'departure',
          title: 'Departure Plan',
          subtitle: 'Launch, route, and first pass',
          icon: Icons.route_rounded,
        ),
      ],
    ),
    MenuSectionData(
      title: 'Species Menus',
      items: <MenuItemData>[
        MenuItemData(
          id: 'overview',
          title: 'Lake Overview',
          subtitle: 'General fish locations map',
          icon: Icons.map_rounded,
        ),
        MenuItemData(
          id: 'species_all',
          title: 'Species Index',
          subtitle: 'All four target programs',
          icon: Icons.menu_book_rounded,
        ),
        MenuItemData(
          id: 'species_king',
          title: 'King Salmon',
          subtitle: 'Offshore thermocline submenu',
          icon: Icons.waves_rounded,
        ),
        MenuItemData(
          id: 'species_coho',
          title: 'Coho Salmon',
          subtitle: 'Nearshore seam submenu',
          icon: Icons.water_rounded,
        ),
        MenuItemData(
          id: 'species_steelhead',
          title: 'Steelhead',
          subtitle: 'Upper-column submenu',
          icon: Icons.air_rounded,
        ),
        MenuItemData(
          id: 'species_laker',
          title: 'Lake Trout',
          subtitle: 'Bottom-control submenu',
          icon: Icons.terrain_rounded,
        ),
      ],
    ),
    MenuSectionData(
      title: 'Intel Menus',
      items: <MenuItemData>[
        MenuItemData(
          id: 'observations',
          title: 'Observation Feed',
          subtitle: 'Recent modeled and captain inputs',
          icon: Icons.radar_rounded,
        ),
        MenuItemData(
          id: 'patterns',
          title: 'Pattern Scores',
          subtitle: 'Presence, targetability, weight',
          icon: Icons.analytics_rounded,
        ),
        MenuItemData(
          id: 'tournaments',
          title: 'Tournament History',
          subtitle: 'Historical weight reference',
          icon: Icons.emoji_events_rounded,
        ),
      ],
    ),
    MenuSectionData(
      title: 'Safety Menus',
      items: <MenuItemData>[
        MenuItemData(
          id: 'ports',
          title: 'Ports and Contacts',
          subtitle: 'Launch-side resources',
          icon: Icons.anchor_rounded,
        ),
        MenuItemData(
          id: 'float_plan',
          title: 'Float Plan',
          subtitle: 'Crew brief and return checks',
          icon: Icons.assignment_rounded,
        ),
        MenuItemData(
          id: 'traffic',
          title: 'Traffic and Hazards',
          subtitle: 'Commercial and weather awareness',
          icon: Icons.warning_amber_rounded,
        ),
      ],
    ),
  ];

  final MockDataRepository _repository = const MockDataRepository();
  final ScenarioAggregator _aggregator = const ScenarioAggregator();

  late final List<ObservationEnvelope> _observations;
  late final List<HistoricalTournamentResult> _tournaments;

  bool _showSplash = true;
  String _selectedMenuId = 'planner';
  TripInputs _inputs = const TripInputs(
    species: TargetSpecies.kingSalmon,
    month: 7,
    timeOfDay: TimeOfDayPeriod.firstLight,
    waterClarity: WaterClarity.mixed,
    waterDepth: 125,
    surfaceTemp: 55,
    thermoclineDepth: 46,
    currentSpeed: 1.2,
    baitLevel: 8,
    reportStrength: 7,
    weatherPattern: WeatherPattern.stable,
  );
  late AggregatedScenario _scenario;

  @override
  void initState() {
    super.initState();
    _observations = _repository.lakeMichiganObservations();
    _tournaments = _repository.lakeMichiganTournamentResults();
    _scenario = _buildScenario(_inputs);
  }

  AggregatedScenario _buildScenario(TripInputs inputs) {
    return _aggregator.build(
      request: ScenarioRequest(
        targetSpecies: inputs.species.label,
        month: inputs.month,
        timeOfDay: inputs.timeOfDay.label,
        waterClarity: inputs.waterClarity.label,
        waterDepthFt: inputs.waterDepth,
        surfaceTempF: inputs.surfaceTemp,
        thermoclineDepthFt: inputs.thermoclineDepth,
        currentSpeedKt: inputs.currentSpeed,
        baitLevel: inputs.baitLevel,
        reportStrength: inputs.reportStrength,
        weatherPattern: inputs.weatherPattern.label,
      ),
      observations: _observations,
      tournamentResults: _tournaments,
    );
  }

  void _updateInputs(TripInputs newInputs) {
    setState(() {
      _inputs = newInputs;
      _scenario = _buildScenario(_inputs);
    });
  }

  SpeciesProfile get _activeProfile => _speciesProfiles.firstWhere(
    (SpeciesProfile profile) => profile.species == _inputs.species,
  );

  SpeciesProfile _profileFromMenu(String menuId) {
    if (menuId == 'species_king') {
      return _speciesProfiles[0];
    }
    if (menuId == 'species_coho') {
      return _speciesProfiles[1];
    }
    if (menuId == 'species_steelhead') {
      return _speciesProfiles[2];
    }
    return _speciesProfiles[3];
  }

  MenuItemData get _selectedMenuMeta {
    for (final MenuSectionData section in _menuSections) {
      for (final MenuItemData item in section.items) {
        if (item.id == _selectedMenuId) {
          return item;
        }
      }
    }
    return _menuSections.first.items.first;
  }

  List<String> get _plannerActions => <String>[
    'Run the first pass off ${_scenario.primaryPort} with ${_scenario.averageBaitScore.toStringAsFixed(1)}/10 bait confidence.',
    'Set the first program ${_scenario.averageThermoclineDepthFt.toStringAsFixed(0)} ft down and work the ${_scenario.areaLabel.toLowerCase()}.',
    'Hold ${_scenario.primeTargetSpecies} as the lead menu and ${_scenario.fallbackSpecies} as the backup submenu.',
  ];

  List<String> get _departureChecklist => <String>[
    'Launch from ${_scenario.primaryPort} before ${_inputs.timeOfDay == TimeOfDayPeriod.firstLight ? 'first light' : _inputs.timeOfDay.label.toLowerCase()}.',
    'Initial heading: work the lane that best matches ${_activeProfile.generalLocation.toLowerCase()}.',
    'Start with ${_activeProfile.idealSpread.toLowerCase()}.',
    'Abort to the fallback submenu if current exceeds ${(_scenario.averageCurrentSpeedKt + 0.4).toStringAsFixed(1)} kt or bait breaks apart.',
  ];

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        markers: _markers,
        onEnter: () {
          setState(() {
            _showSplash = false;
            _selectedMenuId = 'overview';
          });
        },
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wideMenu = constraints.maxWidth >= 1080;
        final bool mediumMenu = constraints.maxWidth >= 760;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Lake Michigan Blueprint'),
                Text(
                  _selectedMenuMeta.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF98ADB8),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showSplash = true;
                  });
                },
                icon: const Icon(Icons.photo_size_select_large_rounded),
                label: const Text('Splash'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          drawer: mediumMenu
              ? null
              : Drawer(
                  backgroundColor: const Color(0xFF0C181F),
                  child: SafeArea(
                    child: AppMenu(
                      sections: _menuSections,
                      selectedId: _selectedMenuId,
                      onSelect: (String id) {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedMenuId = id;
                        });
                      },
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: <Widget>[
                if (mediumMenu)
                  SizedBox(
                    width: wideMenu ? 320 : 270,
                    child: AppMenu(
                      sections: _menuSections,
                      selectedId: _selectedMenuId,
                      onSelect: (String id) {
                        setState(() {
                          _selectedMenuId = id;
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey<String>(_selectedMenuId),
                      child: _buildContent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedMenuId) {
      case 'overview':
        return LakeOverviewPage(markers: _markers, scenario: _scenario);
      case 'species_all':
        return SpeciesIndexPage(
          profiles: _speciesProfiles,
          activeSpecies: _inputs.species,
          onOpen: (TargetSpecies species) {
            setState(() {
              _inputs = _inputs.copyWith(species: species);
              _scenario = _buildScenario(_inputs);
              _selectedMenuId = switch (species) {
                TargetSpecies.kingSalmon => 'species_king',
                TargetSpecies.cohoSalmon => 'species_coho',
                TargetSpecies.steelhead => 'species_steelhead',
                TargetSpecies.lakeTrout => 'species_laker',
              };
            });
          },
        );
      case 'species_king':
      case 'species_coho':
      case 'species_steelhead':
      case 'species_laker':
        return SpeciesDetailPage(
          profile: _profileFromMenu(_selectedMenuId),
          scenario: _scenario,
        );
      case 'departure':
        return DeparturePlanPage(
          profile: _activeProfile,
          scenario: _scenario,
          actions: _departureChecklist,
        );
      case 'observations':
        return ObservationFeedPage(observations: _observations);
      case 'patterns':
        return PatternScoresPage(scenario: _scenario);
      case 'tournaments':
        return TournamentHistoryPage(results: _tournaments);
      case 'ports':
        return const PortContactsPage();
      case 'float_plan':
        return FloatPlanPage(
          scenario: _scenario,
          profile: _activeProfile,
          items: _plannerActions,
        );
      case 'traffic':
        return const TrafficHazardsPage();
      case 'planner':
      default:
        return PlannerPage(
          inputs: _inputs,
          scenario: _scenario,
          profile: _activeProfile,
          actions: _plannerActions,
          onChanged: _updateInputs,
        );
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.markers, required this.onEnter});

  final List<SpeciesMarkerData> markers;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF07131A),
              Color(0xFF0D2430),
              Color(0xFF143D4D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stacked = constraints.maxWidth < 920;
                final Widget textColumn = SizedBox(
                  width: stacked ? double.infinity : 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1F70C4D4),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF4BA7BB)),
                        ),
                        child: const Text(
                          'SPLASH / GENERAL FISH LOCATIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFFB0E4EE),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Lake-first splash screen.\nEverything after this is menus and submenus.',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'The lake graphic carries the main idea: where each target species generally lives. Once inside the app, planning, species intel, safety, and historical data all move into structured menu pages.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD3E1E6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _PillRow(
                        items: <String>[
                          'Kings offshore',
                          'Coho nearshore',
                          'Steelhead high',
                          'Lake trout deep',
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onEnter,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Enter Menus'),
                      ),
                    ],
                  ),
                );

                final Widget lakePanel = Container(
                  height: 520,
                  margin: EdgeInsets.only(
                    top: stacked ? 24 : 0,
                    left: stacked ? 0 : 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x10000000),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF2F5160)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(painter: LakeMichiganPainter()),
                      ),
                      for (final SpeciesMarkerData marker in markers)
                        Align(
                          alignment: marker.alignment,
                          child: _LakeMarker(marker: marker),
                        ),
                      const Align(
                        alignment: Alignment(-0.55, -0.86),
                        child: _MiniCompass(),
                      ),
                    ],
                  ),
                );

                return stacked
                    ? SingleChildScrollView(
                        child: Column(
                          children: <Widget>[textColumn, lakePanel],
                        ),
                      )
                    : Row(
                        children: <Widget>[
                          textColumn,
                          Expanded(child: lakePanel),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AppMenu extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  final List<MenuSectionData> sections;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A161D),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12222B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF294550)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Menu Shell',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Splash is the lake graphic. The app itself is now organized into menu-driven sections and submenus.',
                  style: TextStyle(color: Color(0xFFABC2CB), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final MenuSectionData section in sections) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF7F98A3),
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...section.items.map(
              (MenuItemData item) => _MenuTile(
                item: item,
                selected: item.id == selectedId,
                onTap: () => onSelect(item.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class PlannerPage extends StatelessWidget {
  const PlannerPage({
    super.key,
    required this.inputs,
    required this.scenario,
    required this.profile,
    required this.actions,
    required this.onChanged,
  });

  final TripInputs inputs;
  final AggregatedScenario scenario;
  final SpeciesProfile profile;
  final List<String> actions;
  final ValueChanged<TripInputs> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Run Blueprint',
            subtitle:
                'This is the main planning submenu. It keeps the prototype interactive but puts the controls and outputs into menu cards instead of one giant dashboard.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _MetricCard(
                label: 'Probability',
                value: '${scenario.probabilityScore}%',
              ),
              _MetricCard(
                label: 'Prime Species',
                value: scenario.primeTargetSpecies,
              ),
              _MetricCard(label: 'Fallback', value: scenario.fallbackSpecies),
              _MetricCard(
                label: 'Target Water',
                value:
                    '${scenario.averageThermoclineDepthFt.toStringAsFixed(0)} ft',
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool twoColumn = constraints.maxWidth >= 980;
              final Widget controls = _Panel(
                title: 'Trip Controls',
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _EnumDropdown<TargetSpecies>(
                            label: 'Target species',
                            value: inputs.species,
                            values: TargetSpecies.values,
                            labelBuilder: (TargetSpecies value) => value.label,
                            onChanged: (TargetSpecies? value) {
                              if (value != null) {
                                onChanged(inputs.copyWith(species: value));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EnumDropdown<int>(
                            label: 'Month',
                            value: inputs.month,
                            values: List<int>.generate(
                              8,
                              (int index) => index + 4,
                            ),
                            labelBuilder: (int value) => _monthLabel(value),
                            onChanged: (int? value) {
                              if (value != null) {
                                onChanged(inputs.copyWith(month: value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _EnumDropdown<TimeOfDayPeriod>(
                            label: 'Time of day',
                            value: inputs.timeOfDay,
                            values: TimeOfDayPeriod.values,
                            labelBuilder: (TimeOfDayPeriod value) =>
                                value.label,
                            onChanged: (TimeOfDayPeriod? value) {
                              if (value != null) {
                                onChanged(inputs.copyWith(timeOfDay: value));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EnumDropdown<WaterClarity>(
                            label: 'Water clarity',
                            value: inputs.waterClarity,
                            values: WaterClarity.values,
                            labelBuilder: (WaterClarity value) => value.label,
                            onChanged: (WaterClarity? value) {
                              if (value != null) {
                                onChanged(inputs.copyWith(waterClarity: value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EnumDropdown<WeatherPattern>(
                      label: 'Weather pattern',
                      value: inputs.weatherPattern,
                      values: WeatherPattern.values,
                      labelBuilder: (WeatherPattern value) => value.label,
                      onChanged: (WeatherPattern? value) {
                        if (value != null) {
                          onChanged(inputs.copyWith(weatherPattern: value));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _SliderField(
                      label: 'Water depth',
                      suffix: 'FOW',
                      value: inputs.waterDepth,
                      min: 50,
                      max: 220,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(waterDepth: value)),
                    ),
                    _SliderField(
                      label: 'Surface temp',
                      suffix: 'F',
                      value: inputs.surfaceTemp,
                      min: 42,
                      max: 70,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(surfaceTemp: value)),
                    ),
                    _SliderField(
                      label: 'Thermocline',
                      suffix: 'ft',
                      value: inputs.thermoclineDepth,
                      min: 20,
                      max: 90,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(thermoclineDepth: value)),
                    ),
                    _SliderField(
                      label: 'Current speed',
                      suffix: 'kt',
                      value: inputs.currentSpeed,
                      min: 0.4,
                      max: 2.5,
                      divisions: 21,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(currentSpeed: value)),
                    ),
                    _SliderField(
                      label: 'Bait level',
                      suffix: '/10',
                      value: inputs.baitLevel,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(baitLevel: value)),
                    ),
                    _SliderField(
                      label: 'Report strength',
                      suffix: '/10',
                      value: inputs.reportStrength,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (double value) =>
                          onChanged(inputs.copyWith(reportStrength: value)),
                    ),
                  ],
                ),
              );

              final Widget summary = _Panel(
                title: 'Recommended Menu Route',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      scenario.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    _InfoStripe(
                      title: profile.shortTitle,
                      subtitle:
                          '${profile.generalLocation} | ${profile.depthBand}',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'First-pass actions',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...actions.map((String item) => _BulletLine(text: item)),
                    const SizedBox(height: 16),
                    const Text(
                      'Evidence',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...scenario.evidence.map(
                      (String item) => _BulletLine(text: item),
                    ),
                  ],
                ),
              );

              if (twoColumn) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: controls),
                    const SizedBox(width: 18),
                    Expanded(child: summary),
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  controls,
                  const SizedBox(height: 18),
                  summary,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class LakeOverviewPage extends StatelessWidget {
  const LakeOverviewPage({
    super.key,
    required this.markers,
    required this.scenario,
  });

  final List<SpeciesMarkerData> markers;
  final AggregatedScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Lake Overview',
            subtitle:
                'This is the persistent general-location page. It carries the same lake graphic idea from the splash screen but in a reusable submenu panel.',
          ),
          const SizedBox(height: 18),
          _Panel(
            title: 'General Fish Locations',
            child: SizedBox(
              height: 540,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(painter: LakeMichiganPainter()),
                    ),
                  ),
                  for (final SpeciesMarkerData marker in markers)
                    Align(
                      alignment: marker.alignment,
                      child: _LakeMarker(marker: marker),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _MetricCard(label: 'Primary Port', value: scenario.primaryPort),
              _MetricCard(label: 'Area Label', value: scenario.areaLabel),
              _MetricCard(
                label: 'Prime Target',
                value: scenario.primeTargetSpecies,
              ),
              _MetricCard(label: 'Fallback', value: scenario.fallbackSpecies),
            ],
          ),
        ],
      ),
    );
  }
}

class SpeciesIndexPage extends StatelessWidget {
  const SpeciesIndexPage({
    super.key,
    required this.profiles,
    required this.activeSpecies,
    required this.onOpen,
  });

  final List<SpeciesProfile> profiles;
  final TargetSpecies activeSpecies;
  final ValueChanged<TargetSpecies> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Species Index',
            subtitle:
                'Each species now has a submenu lane instead of being buried inside one crowded screen.',
          ),
          const SizedBox(height: 18),
          for (final SpeciesProfile profile in profiles) ...<Widget>[
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onOpen(profile.species),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              profile.species.label,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          if (profile.species == activeSpecies)
                            const Chip(label: Text('Current target')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(profile.shortTitle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _TagChip(text: profile.generalLocation),
                          _TagChip(text: profile.depthBand),
                          _TagChip(text: profile.seasonWindow),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class SpeciesDetailPage extends StatelessWidget {
  const SpeciesDetailPage({
    super.key,
    required this.profile,
    required this.scenario,
  });

  final SpeciesProfile profile;
  final AggregatedScenario scenario;

  @override
  Widget build(BuildContext context) {
    final AggregatedSpeciesOutlook? outlook = scenario.outlooks
        .where(
          (AggregatedSpeciesOutlook item) =>
              item.species == profile.species.label,
        )
        .cast<AggregatedSpeciesOutlook?>()
        .firstWhere(
          (AggregatedSpeciesOutlook? item) => item != null,
          orElse: () => null,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionIntro(
            title: profile.species.label,
            subtitle:
                'This submenu isolates the ${profile.species.label.toLowerCase()} program so the app reads like a set of purpose-built menu paths.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _MetricCard(
                label: 'Presence',
                value: outlook == null
                    ? 'N/A'
                    : '${outlook.presenceScore.toStringAsFixed(1)}/10',
              ),
              _MetricCard(
                label: 'Targetability',
                value: outlook == null
                    ? 'N/A'
                    : '${outlook.targetabilityScore.toStringAsFixed(1)}/10',
              ),
              _MetricCard(
                label: 'Weight',
                value: outlook == null
                    ? 'N/A'
                    : '${outlook.weightPotentialScore.toStringAsFixed(1)}/10',
              ),
              _MetricCard(label: 'Depth Band', value: profile.depthBand),
            ],
          ),
          const SizedBox(height: 18),
          _Panel(
            title: profile.shortTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoStripe(
                  title: 'General location',
                  subtitle: profile.generalLocation,
                ),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Season window',
                  subtitle: profile.seasonWindow,
                ),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Ideal spread',
                  subtitle: profile.idealSpread,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Key signals',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ...profile.keySignals.map(
                  (String item) => _BulletLine(text: item),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Menu notes',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ...profile.menuNotes.map(
                  (String item) => _BulletLine(text: item),
                ),
                if (outlook != null) ...<Widget>[
                  const SizedBox(height: 16),
                  const Text(
                    'Outlook summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(outlook.summary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeparturePlanPage extends StatelessWidget {
  const DeparturePlanPage({
    super.key,
    required this.profile,
    required this.scenario,
    required this.actions,
  });

  final SpeciesProfile profile;
  final AggregatedScenario scenario;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Departure Plan',
            subtitle:
                'This submenu is focused on the first thirty minutes of the trip: launch, heading, spread, and backup move.',
          ),
          const SizedBox(height: 18),
          _Panel(
            title: 'First Pass Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoStripe(title: 'Port', subtitle: scenario.primaryPort),
                const SizedBox(height: 12),
                _InfoStripe(title: 'Target lane', subtitle: scenario.areaLabel),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Primary submenu',
                  subtitle: profile.species.label,
                ),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Fallback',
                  subtitle: scenario.fallbackSpecies,
                ),
                const SizedBox(height: 16),
                ...actions.map((String item) => _BulletLine(text: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ObservationFeedPage extends StatelessWidget {
  const ObservationFeedPage({super.key, required this.observations});

  final List<ObservationEnvelope> observations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (BuildContext context, int index) {
        final ObservationEnvelope observation = observations[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        observation.sourceName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                    Chip(label: Text(observation.sourceType)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${observation.location.port} | ${observation.location.areaLabel}',
                ),
                const SizedBox(height: 12),
                if (observation.surfaceConditions != null)
                  _BulletLine(
                    text:
                        'Surface ${observation.surfaceConditions!.surfaceTempF.toStringAsFixed(0)} F, wind ${observation.surfaceConditions!.windDirection} ${observation.surfaceConditions!.windSpeedKt.toStringAsFixed(0)} kt.',
                  ),
                if (observation.waterColumn != null)
                  _BulletLine(
                    text:
                        'Thermocline ${observation.waterColumn!.thermoclineDepthFt.toStringAsFixed(0)} ft, clarity ${observation.waterColumn!.clarity}.',
                  ),
                if (observation.forage != null)
                  _BulletLine(
                    text:
                        'Bait ${observation.forage!.concentrationScore.toStringAsFixed(1)}/10 at ${observation.forage!.baitDepthFt.toStringAsFixed(0)} ft.',
                  ),
                if (observation.fishActivity != null)
                  _BulletLine(
                    text:
                        'Catch rate ${observation.fishActivity!.catchRate}, best window ${observation.fishActivity!.bestWindow}.',
                  ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 14),
      itemCount: observations.length,
    );
  }
}

class PatternScoresPage extends StatelessWidget {
  const PatternScoresPage({super.key, required this.scenario});

  final AggregatedScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Pattern Scores',
            subtitle:
                'This submenu keeps the analytics in one place: presence, concentration, targetability, and weight potential.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _MetricCard(
                label: 'Presence',
                value: '${scenario.presenceScore}%',
              ),
              _MetricCard(
                label: 'Concentration',
                value: '${scenario.concentrationScore}%',
              ),
              _MetricCard(
                label: 'Targetability',
                value: '${scenario.targetabilityScore}%',
              ),
              _MetricCard(
                label: 'Weight Potential',
                value: '${scenario.weightPotentialScore}%',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Panel(
            title: 'Species Outlooks',
            child: Column(
              children: scenario.outlooks
                  .map(
                    (AggregatedSpeciesOutlook outlook) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132730),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2A4856)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              outlook.species,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _TagChip(
                                  text:
                                      'Presence ${outlook.presenceScore.toStringAsFixed(1)}',
                                ),
                                _TagChip(
                                  text:
                                      'Targetability ${outlook.targetabilityScore.toStringAsFixed(1)}',
                                ),
                                _TagChip(
                                  text:
                                      'Weight ${outlook.weightPotentialScore.toStringAsFixed(1)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(outlook.summary),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class TournamentHistoryPage extends StatelessWidget {
  const TournamentHistoryPage({super.key, required this.results});

  final List<HistoricalTournamentResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 14),
      itemBuilder: (BuildContext context, int index) {
        final HistoricalTournamentResult result = results[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  result.eventName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text('${result.port} | ${result.areaLabel}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _TagChip(text: '${result.teamCount} teams'),
                    _TagChip(
                      text: '${result.totalWeightLb.toStringAsFixed(1)} lb box',
                    ),
                    _TagChip(
                      text:
                          '${result.bigFishLb.toStringAsFixed(1)} lb big fish',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(result.notes),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PortContactsPage extends StatelessWidget {
  const PortContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          _SectionIntro(
            title: 'Ports and Contacts',
            subtitle:
                'This submenu is reserved for launch-day support and quick-access resources rather than fishing logic.',
          ),
          SizedBox(height: 18),
          _StaticChecklistPanel(
            title: 'South Haven',
            items: <String>[
              'Harbor channel check and launch decision',
              'Fuel, ice, and last-minute spread reset',
              'Crew rendezvous point before departure',
            ],
          ),
          SizedBox(height: 14),
          _StaticChecklistPanel(
            title: 'Backup Port Logic',
            items: <String>[
              'Shift north or south only if weather and water placement justify the trailer move.',
              'Keep one nearshore and one offshore backup lane in the plan.',
            ],
          ),
        ],
      ),
    );
  }
}

class FloatPlanPage extends StatelessWidget {
  const FloatPlanPage({
    super.key,
    required this.scenario,
    required this.profile,
    required this.items,
  });

  final AggregatedScenario scenario;
  final SpeciesProfile profile;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionIntro(
            title: 'Float Plan',
            subtitle:
                'This submenu turns the current pattern into a crew brief with a clear lead plan and a fallback move.',
          ),
          const SizedBox(height: 18),
          _Panel(
            title: 'Crew Brief',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoStripe(
                  title: 'Primary',
                  subtitle: scenario.primeTargetSpecies,
                ),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Fallback',
                  subtitle: scenario.fallbackSpecies,
                ),
                const SizedBox(height: 12),
                _InfoStripe(
                  title: 'Spread bias',
                  subtitle: profile.idealSpread,
                ),
                const SizedBox(height: 16),
                ...items.map((String item) => _BulletLine(text: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrafficHazardsPage extends StatelessWidget {
  const TrafficHazardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          _SectionIntro(
            title: 'Traffic and Hazards',
            subtitle:
                'This submenu is intentionally simple right now: it keeps safety awareness separate from fishing choices.',
          ),
          SizedBox(height: 18),
          _StaticChecklistPanel(
            title: 'Commercial Traffic',
            items: <String>[
              'Cross shipping lanes with a deliberate plan, not during spread resets.',
              'Treat large-course vessels as non-negotiable routing constraints.',
            ],
          ),
          SizedBox(height: 14),
          _StaticChecklistPanel(
            title: 'Weather Hazards',
            items: <String>[
              'Re-check wind build before committing farther offshore than your fallback lane.',
              'Keep the return route cleaner than the outbound route if afternoon rollers are forecast.',
            ],
          ),
        ],
      ),
    );
  }
}

class LakeMichiganPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bg = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF08202B),
          Color(0xFF0E3240),
          Color(0xFF165264),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      bg,
    );

    final Path lake = Path()
      ..moveTo(size.width * 0.52, size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.08,
        size.width * 0.42,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.28,
        size.width * 0.39,
        size.height * 0.39,
      )
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.53,
        size.width * 0.41,
        size.height * 0.61,
      )
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.74,
        size.width * 0.45,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.95,
        size.width * 0.56,
        size.height * 0.90,
      )
      ..quadraticBezierTo(
        size.width * 0.63,
        size.height * 0.82,
        size.width * 0.62,
        size.height * 0.67,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.55,
        size.width * 0.65,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.31,
        size.width * 0.61,
        size.height * 0.21,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.09,
        size.width * 0.52,
        size.height * 0.05,
      )
      ..close();

    final Paint lakeFill = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF7CCAD8),
          Color(0xFF3D8FA3),
          Color(0xFF1B566A),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawPath(lake, lakeFill);

    final Paint lakeStroke = Paint()
      ..color = const Color(0xFFB8E8F1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(lake, lakeStroke);

    final Paint contour = Paint()
      ..color = const Color(0x55D4F1F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (int i = 0; i < 6; i++) {
      final double inset = 18 + (i * 20);
      final Path line = Path()
        ..moveTo(size.width * 0.28, inset + size.height * 0.08)
        ..quadraticBezierTo(
          size.width * 0.48,
          size.height * (0.18 + i * 0.08),
          size.width * 0.72,
          inset + size.height * 0.10,
        );
      canvas.drawPath(line, contour);
    }

    final Paint shore = Paint()..color = const Color(0x33183126);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.22, size.height), shore);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.78, 0, size.width * 0.22, size.height),
      shore,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFB7CBD2)),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF132730),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF294A58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF82A0AA),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String suffix;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label)),
              Text(
                '${value.toStringAsFixed(divisions == null ? 0 : 1)} $suffix',
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (T item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MenuItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF173545) : const Color(0xFF101F28),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(
                  item.icon,
                  color: selected
                      ? const Color(0xFFD7A84A)
                      : const Color(0xFF8FB3BE),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF93AAB4),
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: Color(0xFFD7A84A)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF17303B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF325160)),
      ),
      child: Text(text),
    );
  }
}

class _InfoStripe extends StatelessWidget {
  const _InfoStripe({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF132730),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF284653)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF88A1AB),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _LakeMarker extends StatelessWidget {
  const _LakeMarker({required this.marker});

  final SpeciesMarkerData marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE6101F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: marker.color),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: marker.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                marker.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            marker.note,
            style: const TextStyle(color: Color(0xFFC4D6DC), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniCompass extends StatelessWidget {
  const _MiniCompass();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xCC08151B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF40606D)),
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((String item) => _TagChip(text: item)).toList(),
    );
  }
}

class _StaticChecklistPanel extends StatelessWidget {
  const _StaticChecklistPanel({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((String item) => _BulletLine(text: item)).toList(),
      ),
    );
  }
}

String _monthLabel(int month) {
  const List<String> months = <String>[
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month];
}
