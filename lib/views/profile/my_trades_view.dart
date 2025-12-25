import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/trade_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/trade_model.dart';
import '../../models/products/product_models.dart';

class MyTradesView extends StatelessWidget {
  final bool showBackButton;

  const MyTradesView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradeViewModel(),
      child: _MyTradesViewContent(showBackButton: showBackButton),
    );
  }
}

class _MyTradesViewContent extends StatefulWidget {
  final bool showBackButton;

  const _MyTradesViewContent({required this.showBackButton});

  @override
  State<_MyTradesViewContent> createState() => _MyTradesViewContentState();
}

class _MyTradesViewContentState extends State<_MyTradesViewContent> {
  bool _isInitDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitDone) return;

    final authVM = context.watch<AuthViewModel>();
    if (authVM.isAuthCheckComplete) {
      _isInitDone = true;
      if (authVM.user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TradeViewModel>().getTrades(authVM.user!.userID);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Takaslarım',
          style: AppTheme.safePoppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.background,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.background,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Consumer<TradeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: AppTheme.safePoppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.error,
                ),
              ),
            );
          }

          if (viewModel.trades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Takas Bulunamadı',
                    style: AppTheme.safePoppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Henüz herhangi bir takas işleminiz bulunmamaktadır.',
                      textAlign: TextAlign.center,
                      style: AppTheme.safePoppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 150,
            ),
            itemCount: viewModel.trades.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final trade = viewModel.trades[index];
              return _TradeItem(trade: trade);
            },
          );
        },
      ),
    );
  }
}

class _TradeItem extends StatelessWidget {
  final Trade trade;

  const _TradeItem({required this.trade});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Date & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trade.createdAt ?? '',
                      style: AppTheme.safePoppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(trade.senderStatusTitle ?? 'İşlemde'),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Main Content: Product Swap
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // My Product
                Expanded(
                  child: _buildProductColumn(
                    title: 'Benim Ürünüm',
                    product: trade.myProduct,
                    isMe: true,
                  ),
                ),

                // Swap Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                ),

                // Their Product
                Expanded(
                  child: _buildProductColumn(
                    title: 'Takaslanan',
                    product: trade.theirProduct,
                    isMe: false,
                  ),
                ),
              ],
            ),
          ),

          // Footer: Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _buildInfoChip(
                  Icons.local_shipping_outlined,
                  trade.deliveryType ?? 'Teslimat Yok',
                ),
                const SizedBox(width: 12),
                if (trade.meetingLocation != null &&
                    trade.meetingLocation!.isNotEmpty)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.location_on_outlined,
                      trade.meetingLocation!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductColumn({
    required String title,
    required Product? product,
    required bool isMe,
  }) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTheme.safePoppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            image: product?.productImage != null
                ? DecorationImage(
                    image: NetworkImage(product!.productImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product?.productImage == null
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Color(0xFFCBD5E1),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          product?.productTitle ?? 'Ürün Silinmiş',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isMe ? TextAlign.start : TextAlign.end,
          style: AppTheme.safePoppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    // Simple heuristic for colors
    final s = status.toLowerCase();
    if (s.contains('tamam') || s.contains('onay')) {
      bgColor = const Color(0xFFDCFCE7); // Green-100
      textColor = const Color(0xFF166534); // Green-800
    } else if (s.contains('red') || s.contains('iptal')) {
      bgColor = const Color(0xFFFEE2E2); // Red-100
      textColor = const Color(0xFF991B1B); // Red-800
    } else if (s.contains('bekle')) {
      bgColor = const Color(0xFFFEF3C7); // Amber-100
      textColor = const Color(0xFF92400E); // Amber-800
    } else {
      bgColor = const Color(0xFFE0F2FE); // Sky-100
      textColor = const Color(0xFF075985); // Sky-800
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTheme.safePoppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTheme.safePoppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
