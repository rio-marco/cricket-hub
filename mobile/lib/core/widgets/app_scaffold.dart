import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard scaffold wrapper ensuring uniform app bar styling, safe areas,
/// background themes, floating action buttons, and bottom navigation.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool showAppBar;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool useSafeArea;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.showAppBar = true,
    this.centerTitle = true,
    this.elevation = 0,
    this.bottom,
    this.useSafeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    PreferredSizeWidget? appBar;
    if (showAppBar) {
      appBar = AppBar(
        title: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: (isDark
                            ? AppTextStyles.titleLargeDark
                            : AppTextStyles.titleLargeLight)
                        .copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null),
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        actions: actions,
        centerTitle: centerTitle,
        elevation: elevation,
        scrolledUnderElevation: 1.5,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        bottom: bottom,
      );
    }

    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
