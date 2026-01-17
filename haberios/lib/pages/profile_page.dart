import 'package:flutter/material.dart';
import '../models/yorum.dart';
import '../services/profile_service.dart';
import '../main.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;

  ProfilePage({required this.userEmail});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService profileService = ProfileService();
  
  Map<String, dynamic>? profileData;
  List<Yorum> userComments = [];
  List<Map<String, dynamic>> likedNews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    
    final profile = await profileService.getProfile(widget.userEmail);
    final comments = await profileService.getUserComments(widget.userEmail);
    final likes = await profileService.getLikedNews(widget.userEmail);
    
    setState(() {
      profileData = profile;
      userComments = comments;
      likedNews = likes;
      isLoading = false;
    });
  }

  String get userName {
    if (widget.userEmail.contains('@')) {
      return widget.userEmail.split('@')[0];
    }
    return widget.userEmail;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.backgroundDark, Color(0xFF1E1B4B)]
                : [AppColors.backgroundLight, Color(0xFFEEF2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(isDark)),
                    SliverToBoxAdapter(child: _buildStats(isDark)),
                    SliverToBoxAdapter(child: _buildLikedNewsSection(isDark)),
                    SliverToBoxAdapter(child: _buildCommentsSection(isDark)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              Spacer(),
              Text('Profilim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              Spacer(),
              SizedBox(width: 44),
            ],
          ),
          SizedBox(height: 32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primaryLight.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Center(
              child: Text(
                userName[0].toUpperCase(),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          SizedBox(height: 4),
          Text(widget.userEmail, style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
          SizedBox(height: 8),
          if (profileData != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.primaryLight),
                  SizedBox(width: 6),
                  Text('Katılım: ${_formatDate(profileData!['created_at'])}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    final stats = profileData?['stats'] ?? {};
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard('Okunan', stats['history_count']?.toString() ?? '0', Icons.menu_book, isDark),
          SizedBox(width: 12),
          _buildStatCard('Yorum', stats['comment_count']?.toString() ?? '0', Icons.chat_bubble, isDark),
          SizedBox(width: 12),
          _buildStatCard('Beğeni', stats['total_likes']?.toString() ?? '0', Icons.favorite, isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedNewsSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red, Colors.pink]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.favorite, color: Colors.white, size: 18),
              ),
              SizedBox(width: 12),
              Text('Beğendiğim Haberler (${likedNews.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ],
          ),
          SizedBox(height: 16),
          if (likedNews.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite_border, size: 48, color: AppColors.textSecondaryLight),
                  SizedBox(height: 12),
                  Text('Henüz haber beğenmediniz', style: TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ),
            )
          else
            Container(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: likedNews.length,
                itemBuilder: (context, index) {
                  final news = likedNews[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: news['news_image'] != null
                                ? Image.network(
                                    (news['news_image'] as String).replaceFirst('http://', 'https://'),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: Center(child: Icon(Icons.newspaper))),
                                  )
                                : Container(color: Colors.grey[300], child: Center(child: Icon(Icons.newspaper))),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              news['news_title'] ?? 'Başlık yok',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
              ),
              SizedBox(width: 12),
              Text('Yorumlarım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ],
          ),
          SizedBox(height: 16),
          if (userComments.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondaryLight),
                  SizedBox(height: 12),
                  Text('Henüz yorum yapmadınız', style: TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ),
            )
          else
            ...userComments.map((yorum) => _buildCommentCard(yorum, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Yorum yorum, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(yorum.commentText, style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: AppColors.textSecondaryLight),
              SizedBox(width: 4),
              Text(yorum.timeAgo, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              Spacer(),
              Icon(Icons.favorite, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text('${yorum.likeCount}', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }
}
