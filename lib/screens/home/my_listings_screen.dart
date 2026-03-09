import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../listing/add_listing_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListingsAsync = ref.watch(userListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.accentColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddListingScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: userListingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppConstants.errorColor))),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_location_alt_outlined,
                      size: 64, color: AppConstants.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No listings yet',
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first place',
                    style:
                        TextStyle(color: AppConstants.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Listing'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddListingScreen()),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: listings.length,
            itemBuilder: (_, i) {
              final listing = listings[i];
              return Dismissible(
                key: Key(listing.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                confirmDismiss: (_) async {
                  return await AppUtils.showConfirmDialog(
                    context,
                    title: 'Delete Listing',
                    message:
                        'Are you sure you want to delete "${listing.name}"? This cannot be undone.',
                  );
                },
                onDismissed: (_) async {
                  final success = await ref
                      .read(listingNotifierProvider.notifier)
                      .deleteListing(listing.id);
                  if (context.mounted) {
                    AppUtils.showSnackBar(
                      context,
                      success
                          ? '"${listing.name}" deleted'
                          : 'Failed to delete listing',
                      isError: !success,
                    );
                  }
                },
                child: ListingCard(listing: listing, showBookmark: false),
              );
            },
          );
        },
      ),
    );
  }
}
