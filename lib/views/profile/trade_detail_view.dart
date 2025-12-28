import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../models/trade_detail_model.dart';

class TradeDetailView extends StatelessWidget {
  final int offerId;

  const TradeDetailView({Key? key, required this.offerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradeViewModel(),
      child: _TradeDetailViewContent(offerId: offerId),
    );
  }
}

class _TradeDetailViewContent extends StatefulWidget {
  final int offerId;

  const _TradeDetailViewContent({Key? key, required this.offerId})
    : super(key: key);

  @override
  _TradeDetailViewContentState createState() => _TradeDetailViewContentState();
}

class _TradeDetailViewContentState extends State<_TradeDetailViewContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _topSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.8, curve: Curves.easeOutBack),
          ),
        );

    _bottomSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.8, curve: Curves.easeOutBack),
          ),
        );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutExpo),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final tradeViewModel = Provider.of<TradeViewModel>(
        context,
        listen: false,
      );
      if (authViewModel.user?.token != null) {
        tradeViewModel.getTradeDetail(
          widget.offerId,
          authViewModel.user!.token,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Takas Detayı"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            );
          }
          if (model.errorMessage != null) {
            return _buildErrorState(model.errorMessage!);
          }
          if (model.currentTradeDetail == null) {
            return const Center(child: Text("Detay bulunamadı"));
          }
          final detail = model.currentTradeDetail!;

          if (!_hasAnimated) {
            _hasAnimated = true;
            _animationController.forward();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStatusBanner(detail),
                ),
                const SizedBox(height: 16),
                _buildSwapCard(detail),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInformationCard(detail),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(TradeDetailData detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sizin Durumunuz",
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              _buildStatusBadge(detail.senderStatusTitle ?? "Beklemede"),
            ],
          ),
          if (detail.receiverStatusTitle != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Karşı Taraf",
                  style: AppTheme.safePoppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                _buildStatusBadge(detail.receiverStatusTitle!, isMe: false),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwapCard(TradeDetailData detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SlideTransition(
            position: _topSlideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserProductRow(
                detail.sender,
                label: "Karşı Tarafın Ürünü",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
              ],
            ),
          ),
          SlideTransition(
            position: _bottomSlideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserProductRow(
                detail.receiver,
                label: "Sizin Ürününüz",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProductRow(TradeUser? user, {required String label}) {
    if (user == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: user.product?.productImage != null
                ? Image.network(
                    user.product!.productImage!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF8FAFC),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.product?.productTitle ?? "Ürün Belirtilmemiş",
                style: AppTheme.safePoppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage:
                        (user.profilePhoto != null &&
                            user.profilePhoto!.isNotEmpty)
                        ? NetworkImage(user.profilePhoto!)
                        : null,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child:
                        (user.profilePhoto == null ||
                            user.profilePhoto!.isEmpty)
                        ? Text(
                            user.userName?.substring(0, 1).toUpperCase() ?? "?",
                            style: const TextStyle(fontSize: 8),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.userName ?? "Bilinmeyen Kullanıcı",
                      style: AppTheme.safePoppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard(TradeDetailData detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Takas Bilgileri",
            style: AppTheme.safePoppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.local_shipping_outlined,
            "Teslimat Türü",
            detail.deliveryTypeTitle,
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            "Buluşma Yeri",
            detail.meetingLocation,
          ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            "Oluşturulma",
            detail.createdAt?.split(' ').first,
          ),
          if (detail.completedAt != null && detail.completedAt!.isNotEmpty)
            _buildInfoRow(
              Icons.check_circle_outline_rounded,
              "Tamamlanma",
              detail.completedAt?.split(' ').first,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.safePoppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTheme.safePoppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool isMe = true}) {
    Color color = AppTheme.primary;
    Color bgColor = AppTheme.primary.withOpacity(0.1);

    final lower = status.toLowerCase();
    if (lower.contains('bekle')) {
      color = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
    } else if (lower.contains('red') || lower.contains('iptal')) {
      color = AppTheme.error;
      bgColor = AppTheme.error.withOpacity(0.1);
    } else if (lower.contains('tamam')) {
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: AppTheme.safePoppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
