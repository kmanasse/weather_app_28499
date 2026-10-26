import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  City city = cities.first;
  Weather? weather;
  bool loading = true;
  String? error;
  bool offline = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('city');
    final matches = cities.where((c) => c.name == saved);
    if (!mounted) return;
    if (matches.isNotEmpty) {
      setState(() => city = matches.first);
    }
    await load();
  }

  Future<void> load() async {
    final requested = city;
    try {
      final result = await fetchWeather(requested);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'weather_${requested.name}',
        jsonEncode(result.toJson()),
      );
      if (!mounted || city.name != requested.name) return;
      setState(() {
        weather = result;
        loading = false;
        error = null;
        offline = false;
      });
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('weather_${requested.name}');
      if (!mounted || city.name != requested.name) return;
      if (saved != null) {
        setState(() {
          weather = Weather.fromJson(jsonDecode(saved) as Map<String, dynamic>);
          loading = false;
          error = null;
          offline = true;
        });
      } else {
        setState(() {
          loading = false;
          offline = false;
          error = 'Could not load the weather. Check your internet connection.';
        });
      }
    }
  }

  Future<void> choose(City newCity) async {
    setState(() {
      city = newCity;
      loading = true;
      error = null;
      offline = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', newCity.name);
    await load();
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
      offline = false;
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${city.name} Weather')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final c in cities) ...[
                  ChoiceChip(
                    label: Text(c.name),
                    selected: c.name == city.name,
                    onSelected: (_) => choose(c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        if (offline)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFE08A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Offline: showing the weather saved at ${weather!.time.substring(11)}',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [WeatherCard(weather: weather!)],
            ),
          ),
        ),
      ],
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(iconFor(weather.code), size: 72),
            const SizedBox(height: 8),
            Text(
              '${weather.temperature.round()}°C',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Text(
              describe(weather.code),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Humidity ${weather.humidity}%'),
            Text('Wind ${weather.wind} km/h'),
            const SizedBox(height: 12),
            Text('Updated at ${weather.time.substring(11)}'),
          ],
        ),
      ),
    );
  }
}

IconData iconFor(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 95) return Icons.thunderstorm;
  if (code >= 51) return Icons.water_drop;
  return Icons.help_outline;
}
