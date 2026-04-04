import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/public_url.dart';
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

  Future<void> _fetchArtists() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiClient.getAllArtists(page: _currentPage, perPage: 20);
      debugPrint('Artists API Full Response: $data');
      
      if (data != null) {
        List<dynamic> newArtists = [];
        bool more = false;
        
        if (data is List) {
          newArtists = data;
          more = false; // If it's a simple list, maybe no pagination info?
        } else if (data is Map) {
          // Check for 'artists' key which might contain pagination
          final artistsData = data['artists'];
          if (artistsData is Map) {
            newArtists = (artistsData['data'] as List?) ?? [];
            more = artistsData['next_page_url'] != null;
          } else if (artistsData is List) {
            newArtists = artistsData;
            more = false;
          } else {
            // Check if 'data' key exists directly in the root
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
        child: _artists.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _artists.clear();
                    _currentPage = 1;
                    _hasMore = true;
                  });
                  await _fetchArtists();
                },
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
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
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.lightGrey,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.lightGrey,
                    child: const Icon(Icons.person, color: AppColors.grey, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
