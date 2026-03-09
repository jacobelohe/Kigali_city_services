import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/listing_provider.dart';
import '../../providers/location_service_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/category_filter.dart';
import '../listing/add_listing_screen.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(listingFilterProvider);
    final listings = ref.watch(filteredListingsProvider);
    final allListingsAsync = ref.watch(allListingsProvider);
    final userPosition = ref.watch(userPositionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali City Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Bookmarks',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.accentColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddListingScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            onChanged: (q) =>
                ref.read(listingFilterProvider.notifier).updateSearch(q),
          ),
          CategoryFilter(
            selected: filter.selectedCategory,
            onChanged: (cat) =>
                ref.read(listingFilterProvider.notifier).updateCategory(cat),
          ),
          const SizedBox(height: 12),

          // Results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${listings.length} places found',
                  style: const TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                if (filter.searchQuery.isNotEmpty ||
                    filter.selectedCategory != 'All')
                  TextButton(
                    onPressed: () =>
                        ref.read(listingFilterProvider.notifier).reset(),
                    child: const Text('Clear filters',
                        style: TextStyle(
                            color: AppConstants.accentColor, fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Listings list
          Expanded(
            child: allListingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppConstants.errorColor)),
              ),
              data: (_) {
                if (listings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 56, color: AppConstants.textSecondary),
                        SizedBox(height: 12),
                        Text('No places found',
                            style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: listings.length,
                  itemBuilder: (_, i) {
                    final listing = listings[i];
                    double? distance;
                    if (userPosition != null) {
                      distance = userPosition.distanceTo(listing.latitude, listing.longitude);
                    }
                    return ListingCard(
                      listing: listing,
                      distanceKm: distance,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
