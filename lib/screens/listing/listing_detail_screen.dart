import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import 'edit_listing_screen.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final _reviewCtrl = TextEditingController();
  double _reviewRating = 4.0;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${widget.listing.latitude},${widget.listing.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callContact() async {
    final uri = Uri.parse('tel:${widget.listing.contactNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submitReview() async {
    final user = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (user == null || _reviewCtrl.text.trim().isEmpty) return;

    final review = ReviewModel(
      id: '',
      listingId: widget.listing.id,
      userId: user.uid,
      userName: profile?.name ?? 'Anonymous',
      comment: _reviewCtrl.text.trim(),
      rating: _reviewRating,
      createdAt: DateTime.now(),
    );

    final success =
        await ref.read(listingNotifierProvider.notifier).addReview(review);
    if (mounted) {
      _reviewCtrl.clear();
      AppUtils.showSnackBar(
        context,
        success ? 'Review submitted!' : 'Failed to submit review',
        isError: !success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final userProfile = ref.watch(userProfileProvider).value;
    final isOwner = currentUser?.uid == widget.listing.createdBy;
    final isBookmarked =
        userProfile?.bookmarks.contains(widget.listing.id) ?? false;
    final reviewsAsync = ref.watch(reviewsProvider(widget.listing.id));
    final categoryColor =
        AppConstants.categoryColors[widget.listing.category] ??
            AppConstants.accentColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with map
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppConstants.accentColor : Colors.white,
                ),
                onPressed: () => ref
                    .read(authNotifierProvider.notifier)
                    .toggleBookmark(widget.listing.id),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: AppConstants.cardColor,
                  onSelected: (v) async {
                    if (v == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditListingScreen(listing: widget.listing),
                          ),
                        );
                        // Refresh the listing from Firestore after editing
                        if (context.mounted) {
                          final updated = await ref
                              .read(firestoreServiceProvider)
                              .getListing(widget.listing.id);
                          if (updated != null && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listing: updated),
                              ),
                            );
                          }
                        }
                      } else if (v == 'delete') {
                      final confirm = await AppUtils.showConfirmDialog(
                        context,
                        title: 'Delete Listing',
                        message:
                            'Delete "${widget.listing.name}"? This cannot be undone.',
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(listingNotifierProvider.notifier)
                            .deleteListing(widget.listing.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red))
                        ])),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      widget.listing.latitude, widget.listing.longitude),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('listing'),
                    position: LatLng(
                        widget.listing.latitude, widget.listing.longitude),
                  ),
                },
                onMapCreated: (c) => _mapController.complete(c),
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & category badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.name,
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: categoryColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppConstants.categoryIcons[
                                      widget.listing.category] ??
                                  Icons.place,
                              size: 14,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.listing.category,
                              style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        if (i < widget.listing.rating.floor()) {
                          return const Icon(Icons.star,
                              color: AppConstants.starColor, size: 20);
                        } else if (i < widget.listing.rating) {
                          return const Icon(Icons.star_half,
                              color: AppConstants.starColor, size: 20);
                        } else {
                          return const Icon(Icons.star_border,
                              color: AppConstants.starColor, size: 20);
                        }
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.listing.rating.toStringAsFixed(1)}  •  ${widget.listing.reviewCount} reviews',
                        style: const TextStyle(
                            color: AppConstants.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info tiles
                  _InfoTile(
                      icon: Icons.location_on,
                      text: widget.listing.address,
                      color: AppConstants.accentColor),
                  if (widget.listing.contactNumber.isNotEmpty)
                    _InfoTile(
                        icon: Icons.phone,
                        text: widget.listing.contactNumber,
                        color: AppConstants.successColor,
                        onTap: _callContact),
                  _InfoTile(
                      icon: Icons.person,
                      text: 'Added by ${widget.listing.createdByName}',
                      color: AppConstants.textSecondary),
                  const SizedBox(height: 16),

                  // Description
                  if (widget.listing.description.isNotEmpty) ...[
                    const Text('About',
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.listing.description,
                        style: const TextStyle(
                            color: AppConstants.textSecondary,
                            height: 1.6,
                            fontSize: 14)),
                    const SizedBox(height: 20),
                  ],

                  // Navigate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Open in Google Maps'),
                      onPressed: _openInMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Reviews section
                  const Text('Reviews',
                      style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Write a review
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Write a Review',
                            style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        // Star picker
                        Row(
                          children: List.generate(5, (i) {
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _reviewRating = i + 1.0),
                              child: Icon(
                                i < _reviewRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppConstants.starColor,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reviewCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                              color: AppConstants.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Share your experience…',
                            hintStyle: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13),
                            filled: true,
                            fillColor: AppConstants.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _submitReview,
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews list
                  reviewsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading reviews',
                        style: TextStyle(color: AppConstants.errorColor)),
                    data: (reviews) {
                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('No reviews yet — be the first!',
                                style: TextStyle(
                                    color: AppConstants.textSecondary)),
                          ),
                        );
                      }
                      return Column(
                        children: reviews
                            .map((r) => _ReviewCard(review: r))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null ? color : AppConstants.textSecondary,
                  fontSize: 14,
                  decoration: onTap != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppConstants.accentColor.withOpacity(0.2),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(AppUtils.formatDate(review.createdAt),
                        style: const TextStyle(
                            color: AppConstants.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: AppConstants.starColor,
                          size: 14,
                        )),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
                style: const TextStyle(
                    color: AppConstants.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
