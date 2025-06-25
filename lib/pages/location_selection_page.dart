import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/pages/home_page.dart';
import 'package:kreisel_frontend/widgets/snow_fall_widget.dart'; // Add this import

class LocationSelectionPage extends StatelessWidget {
  final List<Map<String, dynamic>> locations = [
    {
      'name': 'PASING',
      'displayName': 'Campus Pasing',
      'icon': CupertinoIcons.building_2_fill,
      'color': Color(0xFF007AFF),
    },
    {
      'name': 'LOTHSTRASSE',
      'displayName': 'Campus Lothstraße',
      'icon': CupertinoIcons.location_fill,
      'color': Color(0xFF32D74B),
    },
    {
      'name': 'KARLSTRASSE',
      'displayName': 'Campus Karlstraße',
      'icon': CupertinoIcons.map_fill,
      'color': Color(0xFFFF9500),
    },
  ];

  LocationSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Snow effect background
          SnowFallWidget(),

          // Main content
          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Text(
                        'Standort wählen',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Wähle deinen Campus aus',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 48),
                      Expanded(
                        child: ListView.builder(
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder:
                                          (context) => HomePage(
                                            selectedLocation: location['name'],
                                            locationDisplayName:
                                                location['displayName'],
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: location['color'].withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: location['color'].withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          location['icon'],
                                          color: location['color'],
                                          size: 30,
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          location['displayName'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
