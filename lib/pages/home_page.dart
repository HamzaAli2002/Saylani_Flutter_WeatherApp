import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:wheatherapp/pages/const.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  final TextEditingController _searchController = TextEditingController();

  Weather? _weather;
  bool _isLoading = false;
  String _errorMessage = "";
  String _currentCity = "Karachi";
  final List<String> _recentSearches = ["Karachi"];

  @override
  void initState() {
    super.initState();
    _fetchWeather(_currentCity);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchWeather(String city) {
    if (city.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    _wf.currentWeatherByCityName(city.trim()).then((w) {
      setState(() {
        _weather = w;
        _isLoading = false;
        _currentCity = city.trim();
        // Add to recent — no duplicates, newest on top, max 10
        _recentSearches.remove(city.trim());
        _recentSearches.insert(0, city.trim());
        if (_recentSearches.length > 10) _recentSearches.removeLast();
        _searchController.clear();
      });
    }).catchError((e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "City not found. Please try again.";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
            _searchAndRecentRow(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            if (_isLoading)
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.8,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_weather != null) ...[
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
              _locationHeader(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
              _dateTimeInfo(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
              _weatherIcon(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
              _currentTemp(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
              _extraInfo(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
            ],
          ],
        ),
      ),
    );
  }

  /// Search TextField + Recent Searches dropdown side by side
  Widget _searchAndRecentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // ── Search field ──────────────────────────────────────
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _fetchWeather(value),
              decoration: InputDecoration(
                hintText: "Enter city name...",
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.deepPurpleAccent),
                  onPressed: () => _fetchWeather(_searchController.text),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Recent searches dropdown ───────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurpleAccent, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Row(
                  children: [
                    Icon(Icons.history, color: Colors.deepPurpleAccent, size: 20),
                    SizedBox(width: 4),
                    Text(
                      "Recent",
                      style: TextStyle(
                          color: Colors.deepPurpleAccent, fontSize: 14),
                    ),
                  ],
                ),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.deepPurpleAccent),
                // Always show hint — don't highlight a selected value
                value: null,
                items: _recentSearches.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.deepPurpleAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(city, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? selected) {
                  if (selected != null) _fetchWeather(selected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = _weather!.date!;
    return Column(
      children: [
        Text(
          DateFormat("h:mm a").format(now),
          style: const TextStyle(fontSize: 35),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat("EEEE").format(now),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat("d.M.y").format(now),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        )
      ],
    );
  }

  Widget _weatherIcon() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.20,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  "http://openweathermap.org/img/wn/${_weather?.weatherIcon}@4x.png"),
            ),
          ),
        ),
        Text(
          _weather?.weatherDescription ?? "",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0)}° C",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 90,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _extraInfo() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.15,
      width: MediaQuery.sizeOf(context).width * 0.80,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Max: ${_weather?.tempMax?.celsius?.toStringAsFixed(0)}° C",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                "Min: ${_weather?.tempMin?.celsius?.toStringAsFixed(0)}° C",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Wind: ${_weather?.windSpeed?.toStringAsFixed(0)}m/s",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                "Humidity: ${_weather?.humidity?.toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            ],
          )
        ],
      ),
    );
  }
}