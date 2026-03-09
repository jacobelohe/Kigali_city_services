import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart';
import '../screens/listing/listing_detail_screen.dart';

class ListingCard extends ConsumerWidget {
  final ListingModel listing;
  final double? distanceKm;
  final bool showBookmark;

  const ListingCard({
    super.key,
    required this.listing,
    this.distanceKm,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isBookmarked = userProfile?.bookmarks.contains(listing.id) ?? false;
    final categoryColor =
        AppConstants.categoryColors[listing.category] ?? AppConstants.accentColor;
    final categoryIcon =
        AppConstants.categoryIcons[listing.category] ?? Icons.place;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListingDetailScreen(listing: listing),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 28),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.name,
                            style: const TextStyle(
                              color: AppConstants.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _CategoryBadge(
                          label: listing.category,
                          color: categoryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppConstants.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.address,
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StarRating(rating: listing.rating),
                        const SizedBox(width: 6),
                        Text(
                          '${listing.rating.toStringAsFixed(1)} (${listing.reviewCount})',
                          style: const TextStyle(
                              color: AppConstants.textSecondary, fontSize: 12),
                        ),
                        const Spacer(),
                        if (distanceKm != null)
                          Row(
                            children: [
                              const Icon(Icons.directions_walk,
                                  size: 13, color: AppConstants.accentColor),
                              const SizedBox(width: 2),
                              Text(
                                distanceKm! < 1
                                    ? '${(distanceKm! * 1000).toStringAsFixed(0)} m'
                                    : '${distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: AppConstants.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bookmark
              if (showBookmark) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(authNotifierProvider.notifier)
                      .toggleBookmark(listing.id),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? AppConstants.accentColor
                        : AppConstants.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, color: AppConstants.starColor, size: 14);
        } else if (i < rating) {
          return const Icon(Icons.star_half,
              color: AppConstants.starColor, size: 14);
        } else {
          return const Icon(Icons.star_border,
              color: AppConstants.starColor, size: 14);
        }
      }),
    );
  }
}
