// Riverpod providers expose Firestore streams to the UI
// No screen should import FirestoreService directly
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

// ─── Service providers ─────────────────────────────────────────────────────
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// ─── All listings stream ───────────────────────────────────────────────────
final allListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).listingsStream();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── User listings stream ──────────────────────────────────────────────────
final userListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).userListingsStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── Reviews stream ────────────────────────────────────────────────────────
final reviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, listingId) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).reviewsStream(listingId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── Filter state ──────────────────────────────────────────────────────────
class ListingFilter {
  final String searchQuery;
  final String selectedCategory;

  const ListingFilter({
    this.searchQuery = '',
    this.selectedCategory = 'All',
  });

  ListingFilter copyWith({String? searchQuery, String? selectedCategory}) {
    return ListingFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

final listingFilterProvider =
    StateNotifierProvider<ListingFilterNotifier, ListingFilter>(
  (ref) => ListingFilterNotifier(),
);

class ListingFilterNotifier extends StateNotifier<ListingFilter> {
  ListingFilterNotifier() : super(const ListingFilter());

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void updateCategory(String category) =>
      state = state.copyWith(selectedCategory: category);

  void reset() => state = const ListingFilter();
}

// ─── Filtered listings ─────────────────────────────────────────────────────
final filteredListingsProvider = Provider<List<ListingModel>>((ref) {
  final allListings = ref.watch(allListingsProvider).value ?? [];
  final filter = ref.watch(listingFilterProvider);

  return allListings.where((listing) {
    final matchesSearch = filter.searchQuery.isEmpty ||
        listing.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
        listing.address
            .toLowerCase()
            .contains(filter.searchQuery.toLowerCase());

    final matchesCategory = filter.selectedCategory == 'All' ||
        listing.category == filter.selectedCategory;

    return matchesSearch && matchesCategory;
  }).toList();
});

// ─── Listing CRUD notifier ─────────────────────────────────────────────────
class ListingNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _service;

  ListingNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> createListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _service.createListing(listing);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateListing(listing);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteListing(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    try {
      await _service.addReview(review);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final listingNotifierProvider =
    StateNotifierProvider<ListingNotifier, AsyncValue<void>>(
  (ref) => ListingNotifier(ref.watch(firestoreServiceProvider)),
);