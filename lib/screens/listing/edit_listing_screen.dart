import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedCategory;
  late double _lat;
  late double _lng;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.listing.name);
    _addressCtrl = TextEditingController(text: widget.listing.address);
    _contactCtrl = TextEditingController(text: widget.listing.contactNumber);
    _descCtrl = TextEditingController(text: widget.listing.description);
    _selectedCategory = widget.listing.category;
    _lat = widget.listing.latitude;
    _lng = widget.listing.longitude;
  }

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

    final updated = widget.listing.copyWith(
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      address: _addressCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
    );

    final success = await ref
        .read(listingNotifierProvider.notifier)
        .updateListing(updated);

    if (mounted) {
      if (success) {
        AppUtils.showSnackBar(context, 'Listing updated!');
        Navigator.pop(context);
      } else {
        AppUtils.showSnackBar(context, 'Update failed', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(listingNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category
              const Text('Category',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppConstants.cardColor,
                style: const TextStyle(color: AppConstants.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppConstants.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: AppConstants.categories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? _selectedCategory),
              ),
              const SizedBox(height: 14),

              _buildField(
                  controller: _nameCtrl,
                  label: 'Place Name',
                  icon: Icons.store_outlined),
              const SizedBox(height: 14),
              _buildField(
                  controller: _addressCtrl,
                  label: 'Address',
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 14),
              _buildField(
                  controller: _contactCtrl,
                  label: 'Contact',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField(
                  controller: _descCtrl,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  maxLines: 4),
              const SizedBox(height: 20),

              // Map pin
              const Text('Update Location',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.surfaceColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_lat, _lng),
                      zoom: 14,
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
                    }),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
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
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
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
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
