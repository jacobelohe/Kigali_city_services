// FirestoreService handles all Firestore read/write operations
// No UI widget should call Firebase directly use this service instead
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _listings =>
      _db.collection(AppConstants.listingsCollection);

  // ─── Stream all listings ───────────────────────────────────────────────────
  Stream<List<ListingModel>> listingsStream() {
    return _listings
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // ─── Stream listings by user ───────────────────────────────────────────────
  Stream<List<ListingModel>> userListingsStream(String uid) {
    return _listings
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList());
  }

  // ─── Create listing ────────────────────────────────────────────────────────
  Future<String> createListing(ListingModel listing) async {
    final doc = await _listings.add(listing.toMap());
    return doc.id;
  }

  // ─── Update listing ────────────────────────────────────────────────────────
  Future<void> updateListing(ListingModel listing) async {
    await _listings.doc(listing.id).update(listing.toMap());
  }

  // ─── Delete listing ────────────────────────────────────────────────────────
  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  // ─── Fetch single listing ──────────────────────────────────────────────────
  Future<ListingModel?> getListing(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────
  Stream<List<ReviewModel>> reviewsStream(String listingId) {
    return _db
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  Future<void> addReview(ReviewModel review) async {
    // Add review
    await _db.collection('reviews').add(review.toMap());

    // Recalculate aggregate rating
    final reviews = await _db
        .collection('reviews')
        .where('listingId', isEqualTo: review.listingId)
        .get();
    final totalRating = reviews.docs.fold<double>(
        0, (sum, d) => sum + (d.data()['rating'] as num).toDouble());
    final count = reviews.docs.length;
    final avg = count > 0 ? totalRating / count : 0.0;

    await _listings.doc(review.listingId).update({
      'rating': avg,
      'reviewCount': count,
    });
  }
}
