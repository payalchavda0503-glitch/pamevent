import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_image.dart';
import '../search/artist_details.screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _artists = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchArtists();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMore) {
        _fetchArtists();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _artists.clear();
        _currentPage = 1;
        _hasMore = true;
      });
      _fetchArtists();
    });
  }

  Future<void> _fetchArtists() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiClient.getAllArtists(
        page: _currentPage,
        perPage: 20,
        search: _searchController.text,
      );
      debugPrint('Artists API Full Response: $data');
      
      if (data != null) {
        List<dynamic> newArtists = [];
        bool more = false;
        
        if (data is List) {
          newArtists = data;
          more = false;
        } else if (data is Map) {
          final artistsData = data['artists'];
          if (artistsData is Map) {
            newArtists = (artistsData['data'] as List?) ?? [];
            more = artistsData['next_page_url'] != null;
          } else if (artistsData is List) {
            newArtists = artistsData;
            more = false;
          } else {
            final rootData = data['data'];
            if (rootData is List) {
              newArtists = rootData;
              more = data['next_page_url'] != null;
            }
          }
        }
        
        setState(() {
          _artists.addAll(newArtists);
          _currentPage++;
          _hasMore = more;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artists: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Artists',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search artists...',
                    hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppColors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading && _artists.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _artists.isEmpty
                      ? const Center(
                          child: Text(
                            'Artist not available',
                            style: TextStyle(color: AppColors.grey, fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _artists.clear();
                          _currentPage = 1;
                          _hasMore = true;
                          _searchController.clear();
                        });
                        await _fetchArtists();
                      },
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Changed to 3 columns
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7, // Adjusted for smaller photos and 3 columns
                        ),
                        itemCount: _artists.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _artists.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final artist = _artists[index];
                          return _buildArtistItem(artist);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(dynamic artist) {
    final name = artist['name'] ?? artist['username'] ?? artist['display_name'] ?? 'Artist';
    final imageUrl = artist['image_url'] ?? 
                    artist['profile_photo_url'] ?? 
                    resolvePublicUrl(artist['photo'] ?? artist['image'] ?? artist['avatar']) ?? 
                    'https://picsum.photos/200/200';
    final slug = artist['slug'] ?? artist['username'] ?? '';

    return GestureDetector(
      onTap: () {
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailsScreen(
                name: name,
                imageUrl: imageUrl,
                artistSlug: slug,
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipOval(
              child: CustomImage(
                imageUrl,
                fit: BoxFit.cover,
                whenEmpty: Container(
                  color: AppColors.lightGrey,
                  child: const Icon(Icons.person, color: AppColors.grey, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12, // Reduced font size for 3 columns
              color: AppColors.black,
            ),
            maxLines: 2, // Allow 2 lines for long names
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
