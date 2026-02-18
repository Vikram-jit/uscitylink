import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class StationDetailScreen extends StatelessWidget {
  final Stations station;

  const StationDetailScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(station.name ?? "Station Details"),
        backgroundColor: TColors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_gas_station,
                          color: Colors.orange[800],
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name ?? "Unnamed Station",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Store #${station.storeNumber}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Address & Contact
                  _buildSection(
                    icon: Icons.location_on,
                    title: 'Location',
                    children: [
                      Text(
                        station.address ?? "Address not available",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${station.city ?? "City not available"}, ${station.state ?? "State not available"} ${station.zipCode ?? "Zip code not available"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          station.interstate ?? "Interstate info not available",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                _launchPhone(station.phoneNumber ?? ""),
                            child: Text(
                              station.phoneNumber ??
                                  "Phone number not available",
                              style: TextStyle(
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price Information
                  if (station.fuelPrice != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          icon: Icons.attach_money,
                          title: 'Fuel Pricing',
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.green[50]!, Colors.blue[50]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Price',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '\$${station.fuelPrice!.yourPrice}/gal',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Retail',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '\$${station.fuelPrice!.retailPrice}/gal',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Save \$${station.fuelPrice!.savingsTotal}',
                                          style: TextStyle(
                                            color: Colors.green[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Effective: ${_formatDate(station.fuelPrice!.effectiveDate)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Facilities
                  _buildSection(
                    icon: Icons.build,
                    title: 'Facilities',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFacilityChip(Icons.local_gas_station,
                              '${station.fuelLaneCount} Fuel Lanes'),
                          _buildFacilityChip(Icons.local_parking,
                              '${station.parkingSpacesCount} Parking'),
                          _buildFacilityChip(
                              Icons.shower, '${station.showerCount} Showers'),
                          _buildFacilityChip(Icons.wifi, 'Premium WiFi'),
                          _buildFacilityChip(
                              Icons.local_laundry_service, 'Public Laundry'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  _buildSection(
                    icon: Icons.emoji_food_beverage,
                    title: 'Amenities',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (station.amenities?.split('|') ?? [])
                            .map((amenity) => Chip(
                                  label: Text(amenity),
                                  backgroundColor: Colors.blue[50],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Restaurants
                  if ((station.restaurants?.length ?? 0) > 0)
                    Column(
                      children: [
                        _buildSection(
                          icon: Icons.restaurant,
                          title: 'Restaurants',
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: station.restaurants
                                      ?.split("|")
                                      .map((restaurant) => Chip(
                                            label: Text(restaurant),
                                            backgroundColor: Colors.orange[50],
                                            avatar: Icon(Icons.restaurant_menu,
                                                color: Colors.orange[700]),
                                          ))
                                      .toList() ??
                                  [],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _launchDirections(context, station.latitude ?? 0.0,
                                station.longitude ?? 0.0);
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _launchPhone(station.phoneNumber ?? ""),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Station'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.grey[100],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    late DateTime date;

    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.parse(value);
    } else {
      throw ArgumentError('Invalid date type: ${value.runtimeType}');
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _launchDirections(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    Uri? uri;

    // 1️⃣ Try Google Maps app
    final googleMapsUri = Uri.parse('comgooglemaps://?daddr=$lat,$lng');
    if (await canLaunchUrl(googleMapsUri)) {
      uri = googleMapsUri;
    }

    // 2️⃣ Try Apple Maps app (iOS only)
    else if (Platform.isIOS) {
      final appleMapsUri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(appleMapsUri)) {
        uri = appleMapsUri;
      }
    }

    // 3️⃣ Fallback to web
    uri ??= Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No maps application available'),
        ),
      );
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final url = 'tel:${phoneNumber.replaceAll(RegExp(r'[^\d+]'), '')}';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
