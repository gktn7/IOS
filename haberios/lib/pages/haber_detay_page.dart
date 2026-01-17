import 'package:flutter/material.dart';
import '../models/haber.dart';
import '../models/yorum.dart';
import '../services/history_service.dart';
import '../services/comment_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../main.dart';

class HaberDetayPage extends StatefulWidget {
  final Haber haber;
  final List<Haber> tumHaberler;
  final String? userEmail;

  HaberDetayPage({
    required this.haber,
    this.tumHaberler = const [],
    this.userEmail,
  });

  @override
  _HaberDetayPageState createState() => _HaberDetayPageState();
}

class _HaberDetayPageState extends State<HaberDetayPage> with SingleTickerProviderStateMixin {
  final HistoryService historyService = HistoryService();
  final CommentService commentService = CommentService();
  final ProfileService profileService = ProfileService();
  final TextEditingController _commentController = TextEditingController();
  
  late Haber aktifHaber;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Yorum> yorumlar = [];
  bool isLoadingComments = false;
  bool isSendingComment = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    aktifHaber = widget.haber;
    _saveHaber(aktifHaber);
    _loadComments();
    _checkLikeStatus();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _cleanContent(String? text) {
    if (text == null || text.isEmpty) return "İçerik mevcut değil.";
    return text.replaceAll(RegExp(r'\[\+\d+ chars\]'), '').trim();
  }

  int _calculateReadTime(String? text) {
    if (text == null || text.isEmpty) return 1;
    final wordCount = text.split(' ').length;
    return (wordCount / 200).ceil().clamp(1, 30);
  }

  void _saveHaber(Haber haber) async {
    try {
      await historyService.saveHistory(haber);
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> _loadComments() async {
    if (aktifHaber.url == null) return;
    
    setState(() => isLoadingComments = true);
    
    try {
      final comments = await commentService.getComments(aktifHaber.url!);
      setState(() {
        yorumlar = comments;
        isLoadingComments = false;
      });
    } catch (e) {
      setState(() => isLoadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (aktifHaber.url == null) return;

    setState(() => isSendingComment = true);

    final success = await commentService.addComment(
      newsUrl: aktifHaber.url!,
      userEmail: widget.userEmail ?? AuthService.loggedInEmail ?? 'anonim@kullanici.com',
      commentText: _commentController.text.trim(),
    );

    setState(() => isSendingComment = false);

    if (success) {
      _commentController.clear();
      _loadComments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorumunuz eklendi!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _likeComment(String commentId) async {
    final success = await commentService.likeComment(commentId);
    if (success) {
      _loadComments();
    }
  }

  Future<void> _checkLikeStatus() async {
    if (aktifHaber.url == null) return;
    final email = widget.userEmail ?? AuthService.loggedInEmail;
    if (email == null) return;

    final liked = await profileService.checkLike(email, aktifHaber.url!);
    setState(() => isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (aktifHaber.url == null) return;
    final email = widget.userEmail ?? AuthService.loggedInEmail ?? 'kullanici@mail.com';

    final newLiked = await profileService.toggleLike(
      email: email,
      newsUrl: aktifHaber.url!,
      newsTitle: aktifHaber.title,
      newsImage: aktifHaber.imageUrl,
    );

    setState(() => isLiked = newLiked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool sagPanelGoster = widget.tumHaberler.isNotEmpty;
    final content = _cleanContent(aktifHaber.content ?? aktifHaber.description);
    final readTime = _calculateReadTime(content);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [

          Expanded(
            flex: 3,
            child: CustomScrollView(
              slivers: [

                _buildSliverAppBar(isDark, readTime),
                
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.8,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 32),

                          if (aktifHaber.url != null) _buildSourceCard(isDark),
                          
                          SizedBox(height: 32),
                          
                          _buildCommentsSection(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (sagPanelGoster) ...[
            Container(width: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
            Expanded(flex: 1, child: _buildRightPanel(isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, int readTime) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.40,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            margin: EdgeInsets.all(8),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'haber_${aktifHaber.title}',
              child: (aktifHaber.imageUrl != null && aktifHaber.imageUrl!.isNotEmpty)
                  ? Image.network(
                      aktifHaber.imageUrl!.replaceFirst('http://', 'https://'),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _buildPlaceholder(isDark),
                    )
                  : _buildPlaceholder(isDark),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.secondaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('$readTime dk', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    aktifHaber.title,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.link, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kaynak', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(aktifHaber.url!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
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
            Text(
              'Yorumlar (${yorumlar.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ],
        ),
        SizedBox(height: 16),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Yorumunuzu yazın...',
                  hintStyle: TextStyle(color: AppColors.textSecondaryLight),
                  border: InputBorder.none,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isSendingComment ? null : _sendComment,
                      icon: isSendingComment 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send, size: 18),
                      label: Text('Gönder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        if (isLoadingComments)
          Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
        else if (yorumlar.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondaryLight),
                  SizedBox(height: 12),
                  Text('Henüz yorum yok', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16)),
                  Text('İlk yorumu sen yaz!', style: TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          )
        else
          ...yorumlar.map((yorum) => _buildCommentCard(yorum, isDark)).toList(),
      ],
    );
  }

  Widget _buildCommentCard(Yorum yorum, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  yorum.userName[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(yorum.userName, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text(yorum.timeAgo, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _likeComment(yorum.id),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text('${yorum.likeCount}', style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            yorum.commentText,
            style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Diğer Haberler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.tumHaberler.length,
              itemBuilder: (context, index) {
                final h = widget.tumHaberler[index];
                final isActive = h.title == aktifHaber.title;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      aktifHaber = h;
                      _saveHaber(h);
                      yorumlar = [];
                    });
                    _loadComments();
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isActive ? Border.all(color: AppColors.primaryLight, width: 2) : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: h.imageUrl != null
                                ? Image.network(h.imageUrl!.replaceFirst('http://', 'https://'), fit: BoxFit.cover, errorBuilder: (a, b, c) => _buildSmallPlaceholder(isDark))
                                : _buildSmallPlaceholder(isDark),
                          ),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            child: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          ),
                        ],
                      ),
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

  Widget _buildPlaceholder(bool isDark) {
    return Container(color: isDark ? AppColors.surfaceDark : Colors.grey[200], child: Center(child: Icon(Icons.newspaper_rounded, size: 80, color: Colors.grey)));
  }

  Widget _buildSmallPlaceholder(bool isDark) {
    return Container(color: isDark ? AppColors.surfaceDark : Colors.grey[200], child: Center(child: Icon(Icons.newspaper_rounded, size: 24, color: Colors.grey)));
  }
}