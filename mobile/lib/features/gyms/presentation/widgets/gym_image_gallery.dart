import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A premium image gallery with glassmorphic buttons and full-screen zoom support.
class GymImageGallery extends StatefulWidget {
  final List<String> images;
  final String fallbackLogo;
  final AppColors colors;

  const GymImageGallery({
    super.key,
    required this.images,
    required this.fallbackLogo,
    required this.colors,
  });

  @override
  State<GymImageGallery> createState() => _GymImageGalleryState();
}

class _GymImageGalleryState extends State<GymImageGallery> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isFavorite = false; // Mock state for favorite toggle

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Opens a full-screen overlay to view and zoom the image.
  void _openFullScreenImage(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: Dimensions.spacingMedium,
                left: Dimensions.spacingMedium,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> displayImages = widget.images.isNotEmpty
        ? widget.images
        : (widget.fallbackLogo.isNotEmpty ? [widget.fallbackLogo] : []);

    final double expandedHeight = Dimensions.heightPercent(
      40.0,
    ).clamp(300.0, 450.0);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: widget.colors.background,
      automaticallyImplyLeading: false,

      // Glassmorphic Back Button
      leading: Padding(
        padding: EdgeInsets.all(Dimensions.spacingSmall),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ),

      // Glassmorphic Favorite & Share Actions
      actions: [
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? widget.colors.error : Colors.white,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ),
        SizedBox(width: Dimensions.spacingSmall),
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {}, // TODO: Implement Share logic
          ),
        ),
        SizedBox(width: Dimensions.spacingMedium),
      ],

      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (displayImages.isEmpty)
              Container(
                color: widget.colors.surface,
                child: Icon(
                  Icons.fitness_center,
                  size: Dimensions.iconLarge * 2,
                  color: widget.colors.iconGrey,
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: displayImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        _openFullScreenImage(context, displayImages[index]),
                    child: Image.network(
                      displayImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: widget.colors.surface,
                        child: Icon(
                          Icons.broken_image,
                          color: widget.colors.iconGrey,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // CORRECTED: Positioned must be the direct child of Stack
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (displayImages.length > 1)
              Positioned(
                bottom: Dimensions.spacingExtraLarge + Dimensions.spacingSmall,
                right: Dimensions.spacingLarge,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingMedium,
                      vertical: Dimensions.spacingTiny,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${displayImages.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.fontBodyMedium,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // The overlapping rounded corner effect
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Container(
          height: 32.0,
          decoration: BoxDecoration(
            color: widget.colors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32.0),
            ),
          ),
        ),
      ),
    );
  }
}
