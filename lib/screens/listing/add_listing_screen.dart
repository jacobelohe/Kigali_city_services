import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Restaurant';
  double _lat = AppConstants.kigaliLat;
  double _lng = AppConstants.kigaliLng;
  bool _mapPicked = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final userProfile = ref.read(userProfileProvider).value;
    final listing = ListingModel(
      id: '',
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      address: _addressCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
      createdBy: user.uid,
      createdByName: userProfile?.name ?? user.email ?? '',
      createdAt: DateTime.now(),
    );

    final success = await ref
        .read(listingNotifierProvider.notifier)
        .createListing(listing);

    if (mounted) {
      if (success) {
        AppUtils.showSnackBar(context, 'Listing added successfully!');
        Navigator.pop(context);
      } else {
        AppUtils.showSnackBar(context, 'Failed to add listing', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(listingNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Place')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category selector
              const Text('Category',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categories
                    .where((c) => c != 'All')
                    .map((cat) {
                  final isSelected = cat == _selectedCategory;
                  final color = AppConstants.categoryColors[cat] ??
                      AppConstants.accentColor;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppConstants.categoryIcons[cat] ?? Icons.place,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppConstants.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Name
              _buildField(
                controller: _nameCtrl,
                label: 'Place Name',
                icon: Icons.store_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Address
              _buildField(
                controller: _addressCtrl,
                label: 'Address / Location',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Contact
              _buildField(
                controller: _contactCtrl,
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Description
              _buildField(
                controller: _descCtrl,
                label: 'Description',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Map pin picker
              const Text('Pick Location on Map',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.surfaceColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_lat, _lng),
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('pin'),
                        position: LatLng(_lat, _lng),
                      ),
                    },
                    onTap: (pos) => setState(() {
                      _lat = pos.latitude;
                      _lng = pos.longitude;
                      _mapPicked = true;
                    }),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
              if (_mapPicked)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Pinned: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                    style: const TextStyle(
                        color: AppConstants.successColor, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Place'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppConstants.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.textSecondary, size: 20),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}
