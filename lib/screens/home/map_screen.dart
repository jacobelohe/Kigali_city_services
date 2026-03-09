import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../providers/location_service_provider.dart';
import '../../services/location_service.dart';
import '../listing/listing_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  ListingModel? _selectedListing;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos != null && mounted) {
      ref.read(userPositionProvider.notifier).state =
          UserPosition(pos.latitude, pos.longitude);
    }
  }

  Set<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((l) {
      final color = AppConstants.categoryColors[l.category] ?? AppConstants.accentColor;
      return Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.latitude, l.longitude),
        infoWindow: InfoWindow(title: l.name, snippet: l.category),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _colorToHue(color),
        ),
        onTap: () => setState(() => _selectedListing = l),
      );
    }).toSet();
  }

  double _colorToHue(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.hue;
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(allListingsProvider);
    final filter = ref.watch(listingFilterProvider);
    final userPos = ref.watch(userPositionProvider);

    final initialCamera = CameraPosition(
      target: LatLng(
        userPos?.lat ?? AppConstants.kigaliLat,
        userPos?.lng ?? AppConstants.kigaliLng,
      ),
      zoom: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await _fetchLocation();
              final pos = ref.read(userPositionProvider);
              if (pos != null) {
                final ctrl = await _controller.future;
                ctrl.animateCamera(CameraUpdate.newLatLng(
                    LatLng(pos.lat, pos.lng)));
              }
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: initialCamera,
                markers: _buildMarkers(listings),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (ctrl) => _controller.complete(ctrl),
                onTap: (_) => setState(() => _selectedListing = null),
              ),

              // Category filter overlay
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppConstants.categories.length,
                    itemBuilder: (_, i) {
                      final cat = AppConstants.categories[i];
                      final isSelected = cat == filter.selectedCategory;
                      return GestureDetector(
                        onTap: () => ref
                            .read(listingFilterProvider.notifier)
                            .updateCategory(cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.accentColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppConstants.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Selected listing bottom card
              if (_selectedListing != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(
                              listing: _selectedListing!)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (AppConstants.categoryColors[_selectedListing!.category] ??
                                      AppConstants.accentColor)
                                  .withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              AppConstants.categoryIcons[_selectedListing!.category] ??
                                  Icons.place,
                              color: AppConstants.categoryColors[_selectedListing!.category] ??
                                  AppConstants.accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedListing!.name,
                                  style: const TextStyle(
                                    color: AppConstants.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _selectedListing!.address,
                                  style: const TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: AppConstants.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
