import 'package:flutter/material.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'haber_detay_page.dart';
import 'history_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback temaDegistir;

  HomePage({required this.temaDegistir});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Haber> haberler = [];
  List<Haber> filtreliHaberler = [];
  bool isLoading = true;

  String seciliKategori = 'general';
  final List<Map<String, dynamic>> kategoriler = [
    {'id': 'general', 'icon': Icons.public, 'label': 'Genel'},
    {'id': 'business', 'icon': Icons.business_center, 'label': 'İş'},
    {'id': 'entertainment', 'icon': Icons.movie, 'label': 'Eğlence'},
    {'id': 'health', 'icon': Icons.health_and_safety, 'label': 'Sağlık'},
    {'id': 'science', 'icon': Icons.science, 'label': 'Bilim'},
    {'id': 'sports', 'icon': Icons.sports_soccer, 'label': 'Spor'},
    {'id': 'technology', 'icon': Icons.computer, 'label': 'Teknoloji'},
  ];

  TextEditingController aramaController = TextEditingController();
  final apiService = ApiService();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    api_haber_getir_kategori(seciliKategori);
    aramaController.addListener(() {
      filterHaberler(aramaController.text);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    aramaController.dispose();
    super.dispose();
  }

  Future<void> api_haber_getir_kategori(String kategori) async {
    setState(() {
      isLoading = true;
      seciliKategori = kategori;
    });
    try {
      final fetchedHaberler = await apiService.api_haber_getir(category: kategori);
      setState(() {
        haberler = fetchedHaberler;
        filtreliHaberler = List.from(haberler);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Haberler yüklenemedi'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void filterHaberler(String query) {
    setState(() {
      if (query.isEmpty) {
        filtreliHaberler = List.from(haberler);
      } else {
        filtreliHaberler = haberler
            .where((haber) => haber.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> refreshHaberler() async {
    await api_haber_getir_kategori(seciliKategori);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(isDark),
              SizedBox(height: 8),
              // Arama Çubuğu
              _buildSearchBar(isDark),
              SizedBox(height: 16),
              // Kategori Seçimi
              _buildCategorySelector(isDark),
              SizedBox(height: 16),
              // Haber Grid
              Expanded(
                child: isLoading
                    ? _buildShimmerLoading()
                    : RefreshIndicator(
                        onRefresh: refreshHaberler,
                        color: AppColors.primaryLight,
                        child: filtreliHaberler.isEmpty
                            ? _buildEmptyState()
                            : _buildNewsGrid(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HaberIOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.secondaryLight],
                    ).createShader(Rect.fromLTWH(0, 0, 150, 40)),
                ),
              ),
              Text(
                'Güncel haberler',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                onTap: widget.temaDegistir,
                isDark: isDark,
              ),
              SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.history,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage())),
                isDark: isDark,
              ),
              SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.person,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userEmail: AuthService.loggedInEmail ?? 'kullanici@mail.com'))),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: aramaController,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Haber ara...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryLight, size: 24),
            suffixIcon: aramaController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondaryLight),
                    onPressed: () {
                      aramaController.clear();
                      filterHaberler('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: kategoriler.length,
        itemBuilder: (context, index) {
          final kategori = kategoriler[index];
          final isSelected = seciliKategori == kategori['id'];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => api_haber_getir_kategori(kategori['id']),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [AppColors.primaryLight, AppColors.secondaryLight])
                      : null,
                  color: isSelected ? null : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          )
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      kategori['icon'],
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    SizedBox(width: 6),
                    Text(
                      kategori['label'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtreliHaberler.length,
      itemBuilder: (context, index) {
        return _buildNewsCard(filtreliHaberler[index], index);
      },
    );
  }

  Widget _buildNewsCard(Haber haber, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HaberDetayPage(haber: haber, tumHaberler: filtreliHaberler, userEmail: AuthService.loggedInEmail),
        ),
      ),
      child: Hero(
        tag: 'haber_${haber.title}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [

                haber.imageUrl != null && haber.imageUrl!.isNotEmpty
                    ? Image.network(
                        haber.imageUrl!.replaceFirst('http://', 'https://'),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildPlaceholder(isDark),
                      )
                    : _buildPlaceholder(isDark),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.3, 0.6, 1.0],
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 14,
                  child: Text(
                    haber.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.secondaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kategoriler.firstWhere((k) => k['id'] == seciliKategori)['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: 50,
          color: isDark ? AppColors.textSecondaryDark : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondaryLight),
          SizedBox(height: 16),
          Text(
            'Haber bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                    Colors.grey.shade300,
                  ],
                  stops: [
                    0.0,
                    _shimmerController.value,
                    1.0,
                  ],
                  begin: Alignment(-1.0, -0.3),
                  end: Alignment(1.0, 0.3),
                ),
              ),
            );
          },
        );
      },
    );
  }
}