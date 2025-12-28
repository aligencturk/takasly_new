import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/product_detail_viewmodel.dart';
import '../../models/product_detail_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ticket_viewmodel.dart';
import '../../models/profile/profile_detail_model.dart';
import '../profile/user_profile_view.dart';
import '../messages/chat_view.dart';
import '../widgets/product_card.dart';
import '../../models/products/product_models.dart' as prod_models;
import '../../models/tickets/ticket_model.dart';

class ProductDetailView extends StatefulWidget {
  final int productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userToken = context.read<AuthViewModel>().user?.token;
      context.read<ProductDetailViewModel>().getProductDetail(
        widget.productId,
        userToken: userToken,
      );
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    final appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (Platform.isAndroid) {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulaması açılamadı')),
        );
      }
    } else if (Platform.isIOS) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Apple Maps'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await canLaunchUrl(appleMapsUrl)) {
                      await launchUrl(appleMapsUrl);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Google Maps'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(googleMapsUrl);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      }
    }
  }

  void _shareLocation(String title, double lat, double lng) {
    Share.share(
      'Bu ilana göz at: $title\nKonum: https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  }

  void _shareProduct(ProductDetail product) {
    if (product.productTitle == null || product.productCode == null) return;

    String slug = product.productTitle!.toLowerCase();
    const turkishChars = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    turkishChars.forEach((key, value) {
      slug = slug.replaceAll(key, value);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.trim().replaceAll(RegExp(r'\s+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');

    String code = product.productCode!.replaceAll(
      RegExp(r'tks', caseSensitive: false),
      '',
    );

    final url = 'https://www.takasly.tr/ilan/$slug-$code';
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailViewModel>(
      builder: (context, viewModel, child) {
        final product = viewModel.productDetail;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'İlan Detayı',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            backgroundColor: AppTheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: product == null
                    ? null
                    : () => _shareProduct(product),
              ),
            ],
          ),
          body: () {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text(viewModel.errorMessage!));
            }

            if (product == null) {
              return const Center(child: Text("Ürün bulunamadı"));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(product),
                  const SizedBox(height: 16),
                  _buildTitleSection(product),
                  const SizedBox(height: 16),

                  _buildUserInfoCard(product),
                  const SizedBox(height: 16),

                  _buildDescription(product),

                  const SizedBox(height: 56),

                  _buildAdDetailsTable(product),

                  const SizedBox(height: 46),

                  _buildLocationSection(product),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }(),
          bottomNavigationBar: _buildBottomBar(product),
        );
      },
    );
  }

  Widget _buildImageGallery(ProductDetail product) {
    final images =
        product.productGallery != null && product.productGallery!.isNotEmpty
        ? product.productGallery!
        : (product.productImage != null && product.productImage!.isNotEmpty
              ? [product.productImage!]
              : []);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: images.isEmpty
              ? Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                )
              : PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[200]),
                    );
                  },
                ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? AppTheme.primary
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        // Image count badge
        if (images.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productTitle ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.error, size: 16),
              const SizedBox(width: 4),
              Text(
                '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kullanıcı Bilgileri",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                if (product.userID != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ProfileViewModel(),
                        child: UserProfileView(userId: product.userID!),
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (product.profilePhoto != null &&
                            product.profilePhoto!.isNotEmpty)
                        ? NetworkImage(product.profilePhoto!)
                        : null,
                    child:
                        (product.profilePhoto == null ||
                            product.profilePhoto!.isEmpty)
                        ? Text(
                            (product.userFullname ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.userFullname ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${product.averageRating ?? 0.0} (${product.totalReviews ?? 0})",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdDetailsTable(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İlan Bilgileri",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildDetailRow("İlan Sahibi :", product.userFullname ?? '', true),
          _buildDetailRow("Durum :", product.productCondition ?? '', true),
          _buildDetailRow(
            "Kategori :",
            product.categoryList?.map((e) => e.catName).join(' > ') ?? '',
            true,
          ),
          _buildDetailRow("İlan Tarihi :", product.createdAt ?? '', true),
          _buildDetailRow(
            "Görüntülenme :",
            "Bu ilan ${product.proView?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0'} kere görüntülendi",
            true,
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "İlan Kodu :",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Expanded(
                flex: 7,
                child: Row(
                  children: [
                    Text(
                      product.productCode ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (product.productCode != null) {
                          Clipboard.setData(
                            ClipboardData(text: product.productCode!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İlan kodu kopyalandı'),
                            ),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool addSeparator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          if (addSeparator) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Açıklama",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            product.productDesc ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ProductDetail product) {
    // Default coordinates if parsing fails or null
    double lat = 39.9334; // Ankara default
    double lng = 32.8597;

    if (product.productLat != null && product.productLong != null) {
      try {
        lat = double.parse(product.productLat!);
        lng = double.parse(product.productLong!);
      } catch (e) {
        // Fallback to default
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Konum Bilgileri",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_city,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Flutter Map Implementation
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // Static map
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rivorya.takaslyapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMap(lat, lng),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Yol Tarifi Al"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _shareLocation(product.productTitle ?? 'İlan', lat, lng),
                  icon: const Icon(Icons.share_location, size: 18),
                  label: const Text("Konumu Paylaş"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.grey[600],
              ),
              label: Text(
                "Bu ilanı şikayet et",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductDetail? product) {
    if (product == null) return const SizedBox.shrink();

    final showCallButton =
        product.isShowContact == true &&
        product.userPhone != null &&
        product.userPhone!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.cardShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (showCallButton) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(product.userPhone!),
                  icon: const Icon(Icons.phone),
                  label: const Text("Ara"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showOfferBottomSheet(context, product),
                icon: const Icon(Icons.message),
                label: const Text("Mesaj Gönder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferBottomSheet(BuildContext context, ProductDetail product) {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.user?.token;
    final myUserId = authViewModel.user?.userID;

    if (userToken == null || myUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj göndermek için giriş yapmalısınız'),
        ),
      );
      return;
    }

    if (product.userID == myUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanınıza mesaj gönderemezsiniz')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          height: MediaQuery.of(context).size.height * 0.85,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    ProfileViewModel()..getProfileDetail(myUserId, userToken),
              ),
              ChangeNotifierProvider(create: (_) => TicketViewModel()),
            ],
            child: _OfferSheetContent(
              targetProduct: product,
              userToken: userToken,
              myUserId: myUserId,
            ),
          ),
        );
      },
    );
  }
}

class _OfferSheetContent extends StatefulWidget {
  final ProductDetail targetProduct;
  final String userToken;
  final int myUserId;

  const _OfferSheetContent({
    required this.targetProduct,
    required this.userToken,
    required this.myUserId,
  });

  @override
  State<_OfferSheetContent> createState() => _OfferSheetContentState();
}

class _OfferSheetContentState extends State<_OfferSheetContent> {
  int? _selectedProductId;
  final TextEditingController _messageController = TextEditingController();

  final List<String> _quickMessages = [
    "Merhaba, ürün hala satılık mı?",
    "Takas düşünür müsünüz?",
    "Teklifim uygun mu?",
    "Detaylı bilgi alabilir miyim?",
    "Hangi konumdasınız?",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Product Card (Trade Summary)
                    _buildSectionTitle("İlgilendiğiniz Ürün"),
                    const SizedBox(height: 12),
                    _buildTargetProductCard(),

                    const SizedBox(height: 32),

                    // My Products Section
                    _buildSectionTitle("Takas İçin Ürününüzü Seçin"),
                    const SizedBox(height: 16),
                    _buildMyProductsList(),

                    const SizedBox(height: 32),

                    // Message Section
                    _buildSectionTitle("Mesajınız"),
                    const SizedBox(height: 16),
                    _buildQuickReplies(),
                    const SizedBox(height: 12),
                    _buildMessageInputField(),

                    const SizedBox(height: 40),

                    // Send Button
                    _buildSendButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Teklif Gönder',
                  textAlign: TextAlign.center,
                  style: AppTheme.safePoppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.safePoppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  prod_models.Product _mapToProduct(dynamic item) {
    if (item is ProfileProduct) {
      return prod_models.Product(
        productID: item.productID,
        productTitle: item.productTitle,
        productImage: item.productImage,
        productCondition: item.productCondition,
        cityTitle: item.cityTitle,
        districtTitle: item.districtTitle,
        categoryList: item.categoryList
            ?.map(
              (e) => prod_models.Category(catID: e.catID, catName: e.catName),
            )
            .toList(),
        isFavorite: item.isFavorite,
      );
    } else if (item is ProductDetail) {
      return prod_models.Product(
        productID: item.productID,
        productTitle: item.productTitle,
        productImage: item.productImage,
        productCondition: item.productCondition,
        cityTitle: item.cityTitle,
        districtTitle: item.districtTitle,
        categoryList: item.categoryList
            ?.map(
              (e) => prod_models.Category(catID: e.catID, catName: e.catName),
            )
            .toList(),
        isFavorite: item.isFavorite,
        userID: item.userID,
        userFullname: item.userFullname,
      );
    }
    return prod_models.Product();
  }

  Widget _buildTargetProductCard() {
    final product = _mapToProduct(widget.targetProduct);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.productImage != null
                ? Image.network(
                    product.productImage!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.categoryTitle ?? 'Kategori',
                  style: AppTheme.safePoppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.productTitle ?? '',
                  style: AppTheme.safePoppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.cityTitle?.toUpperCase() ?? ''} / ${product.districtTitle?.toUpperCase() ?? ''}',
                      style: AppTheme.safePoppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProductsList() {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.state == ProfileState.busy) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (viewModel.state == ProfileState.error) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ürünler yüklenemedi: ${viewModel.errorMessage}',
              style: TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          );
        }

        final products = viewModel.profileDetail?.products ?? [];
        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Takas teklif edecek aktif bir ürününüz bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final profileProduct = products[index];
              final product = _mapToProduct(profileProduct);
              final isSelected = _selectedProductId == product.productID;

              return Stack(
                children: [
                  SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        setState(() {
                          _selectedProductId = product.productID;
                        });
                      },
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.borderRadius,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                            color: AppTheme.primary.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  if (isSelected)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickMessages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _messageController.text = _quickMessages[index],
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Text(
                _quickMessages[index],
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInputField() {
    return TextField(
      controller: _messageController,
      maxLines: 4,
      style: AppTheme.safePoppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Satıcıya bir mesaj yazın...',
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Consumer<TicketViewModel>(
      builder: (context, ticketViewModel, child) {
        final bool canSend =
            _selectedProductId != null && !ticketViewModel.isSendingMessage;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canSend
                ? () async {
                    if (widget.targetProduct.productID == null) return;

                    final result = await ticketViewModel.createTicket(
                      widget.userToken,
                      widget.targetProduct.productID!,
                      _selectedProductId!,
                      _messageController.text.trim().isEmpty
                          ? "Merhaba, bu ilan için bir takas teklifim var."
                          : _messageController.text,
                    );

                    if (!context.mounted) return;

                    if (result != null) {
                      Navigator.pop(context);

                      final ticket = Ticket(
                        ticketID: result,
                        productID: widget.targetProduct.productID,
                        productTitle: widget.targetProduct.productTitle,
                        productImage: widget.targetProduct.productImage,
                        otherUserID: widget.targetProduct.userID,
                        otherFullname: widget.targetProduct.userFullname,
                        otherProfilePhoto: widget.targetProduct.profilePhoto,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatView(ticket: ticket),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teklif başarıyla gönderildi'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ticketViewModel.errorMessage ?? 'Hata oluştu',
                          ),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: ticketViewModel.isSendingMessage
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Teklifi Gönder',
                    style: AppTheme.safePoppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
