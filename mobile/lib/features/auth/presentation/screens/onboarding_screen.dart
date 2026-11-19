import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/routing/app_router.dart';

/// Data model representing an onboarding screen slide
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color badgeColor;
  final String highlightTag;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.badgeColor,
    required this.highlightTag,
  });
}

/// Beautiful Onboarding screen with 3 animated slides highlighting core
/// Cricket Hub features: Team Management, Live Scoring, and Player Auctions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      title: 'Manage Your Cricket',
      description:
          'Create and lead custom teams, organize multi-stage tournaments, schedule fixtures, and track career statistics for every player.',
      icon: Icons.sports_cricket,
      gradientColors: [
        Color(0xFFFF6B00),
        Color(0xFFFF8C00),
      ],
      badgeColor: AppColors.primary,
      highlightTag: 'TEAMS & TOURNAMENTS',
    ),
    OnboardingPageData(
      title: 'Live Scoring',
      description:
          'Enjoy seamless ball-by-ball scoring, live commentary updates, wagon wheels, extras management, and instant shareable scorecards.',
      icon: Icons.scoreboard,
      gradientColors: [
        Color(0xFF1B2838),
        Color(0xFF2C3E50),
      ],
      badgeColor: Color(0xFF1E88E5),
      highlightTag: 'REAL-TIME UPDATES',
    ),
    OnboardingPageData(
      title: 'Player Auctions',
      description:
          'Host thrilling live cricket player auctions with interactive bidding, real-time purse budgets, auctioneer gavels, and squad rosters.',
      icon: Icons.gavel,
      gradientColors: [
        Color(0xFF0D1B2A),
        Color(0xFF1B2838),
      ],
      badgeColor: Color(0xFFFFB300),
      highlightTag: 'INTERACTIVE BIDDING',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPageContent(page, size, topPadding);
            },
          ),

          // Top Header Bar: Brand Indicator & Skip Button
          Positioned(
            top: topPadding + 12,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mini Brand Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryLinearGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sports_cricket_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cricket Hub',
                      style: AppTextStyles.titleMediumLight.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                // Skip Button
                if (!isLastPage)
                  InkWell(
                    onTap: _navigateToLogin,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.labelMediumLight.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls: Page Indicator & Action Button
          Positioned(
            bottom: bottomPadding + 24,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isSelected = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isSelected ? 28 : 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Next or Get Started Button
                AppButton(
                  text: isLastPage ? 'Get Started' : 'Continue',
                  icon: isLastPage
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_ios_rounded,
                  onPressed: _onNextPressed,
                ),
                const SizedBox(height: 12),

                // Login Link if not last page
                if (!isLastPage)
                  GestureDetector(
                    onTap: _navigateToLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Already have an account? Sign In',
                        style: AppTextStyles.bodyMediumLight.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(
    OnboardingPageData page,
    Size size,
    double topPadding,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Hero Area
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow ring
              Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.badgeColor.withOpacity(0.08),
                ),
              ),

              // Middle dashed/bordered ring
              Container(
                width: size.width * 0.54,
                height: size.width * 0.54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: page.badgeColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),

              // Gradient Circle Badge with Icon
              Container(
                width: size.width * 0.44,
                height: size.width * 0.44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: page.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.badgeColor.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    page.icon,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 44),

          // Feature Highlight Tag Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: page.badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.highlightTag,
              style: AppTextStyles.labelSmallLight.copyWith(
                color: page.badgeColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            page.title,
            style: AppTextStyles.headlineMediumLight.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyMediumLight.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 14.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Spacing buffer for bottom controls
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
