import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starter_app/services/nws_weather_service.dart';

void main() {
  test(
    'fetches hourly NWS weather summary from official API endpoints',
    () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/GRR/40,44/forecast/hourly',
              },
            }),
            200,
          );
        }

        expect(
          request.url.toString(),
          'https://api.weather.gov/gridpoints/GRR/40,44/forecast/hourly',
        );
        return http.Response(
          jsonEncode({
            'properties': {
              'periods': [
                {
                  'startTime': '2026-07-11T12:00:00Z',
                  'temperature': 72,
                  'windSpeed': '10 mph',
                  'windDirection': 'WNW',
                  'shortForecast': 'Mostly Sunny',
                },
              ],
            },
          }),
          200,
        );
      });

      final service = NwsWeatherService(client: client);
      final summary = await service.fetchHourlySummary(
        latitude: 42.5,
        longitude: -86.4,
      );

      expect(requestCount, 2);
      expect(summary, isNotNull);
      expect(summary!.temperatureF, 72);
      expect(summary.windSpeedMph, 10);
      expect(summary.windDirection, 'WNW');
      expect(summary.shortForecast, 'Mostly Sunny');
    },
  );
}
