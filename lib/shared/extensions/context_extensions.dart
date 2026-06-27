import 'package:flutter/material.dart';
import '../theme/responsive_breakpoints.dart';
import '../theme/responsive_typography.dart';
import '../theme/responsive_tokens.dart';

extension ContextExtensions on BuildContext {
  // =========================
  // BREAKPOINTS
  // =========================

  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isLargeTablet => ResponsiveBreakpoints.isLargeTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
  bool get isPortrait => ResponsiveBreakpoints.isPortrait(this);
  bool get isLandscape => ResponsiveBreakpoints.isLandscape(this);

  // =========================
  // TYPOGRAPHY
  // =========================

  TextStyle get displayStyle => ResponsiveTypography.display(this);
  TextStyle get headlineStyle => ResponsiveTypography.headline(this);
  TextStyle get titleStyle => ResponsiveTypography.title(this);
  TextStyle get subtitleStyle => ResponsiveTypography.subtitle(this);
  TextStyle get bodyStyle => ResponsiveTypography.body(this);
  TextStyle get bodyMediumStyle => bodyStyle;
  TextStyle get bodySmallStyle => ResponsiveTypography.bodySmall(this);
  TextStyle get captionStyle => ResponsiveTypography.caption(this);
  TextStyle get labelStyle => ResponsiveTypography.label(this);
  TextStyle get labelMediumStyle => labelStyle;
  TextStyle get buttonStyle => ResponsiveTypography.button(this);

  // =========================
  // ICONS
  // =========================

  double get iconSmall => ResponsiveTokens.iconSmall(this);
  double get iconMedium => ResponsiveTokens.iconMedium(this);
  double get iconLarge => ResponsiveTokens.iconLarge(this);
  double get iconXL => ResponsiveTokens.iconXL(this);

  // =========================
  // SPACING & MARGINS
  // =========================

  double get spacingXS => ResponsiveTokens.spacingXS(this);
  double get spacingS => ResponsiveTokens.spacingS(this);
  double get spacingM => ResponsiveTokens.spacingM(this);
  double get spacingL => ResponsiveTokens.spacingL(this);
  double get spacingXL => ResponsiveTokens.spacingXL(this);

  // =========================
  // PADDING
  // =========================

  EdgeInsets get pagePadding => ResponsiveTokens.pagePadding(this);
  EdgeInsets get cardPadding => ResponsiveTokens.cardPadding(this);
  EdgeInsets get sheetPadding => ResponsiveTokens.sheetPadding(this);
  EdgeInsets get dialogPadding => ResponsiveTokens.dialogPadding(this);

  // =========================
  // RADIUS
  // =========================

  double get radiusS => ResponsiveTokens.radiusS(this);
  double get radiusM => ResponsiveTokens.radiusM(this);
  double get radiusL => ResponsiveTokens.radiusL(this);
  double get radiusPill => ResponsiveTokens.radiusPill(this);

  BorderRadius get borderRadiusS => ResponsiveTokens.borderRadiusS(this);
  BorderRadius get borderRadiusM => ResponsiveTokens.borderRadiusM(this);
  BorderRadius get borderRadiusL => ResponsiveTokens.borderRadiusL(this);
  BorderRadius get borderRadiusPill => ResponsiveTokens.borderRadiusPill(this);

  // =========================
  // DIMENSIONS & ASPECT RATIOS
  // =========================

  double get dashboardCardHeight => ResponsiveTokens.dashboardCardHeight(this);
  double get roomCardWidth => ResponsiveTokens.roomCardWidth(this);
  double get imageHeight => ResponsiveTokens.imageHeight(this);
  double get listTileHeight => ResponsiveTokens.listTileHeight(this);

  int get columns => ResponsiveTokens.getColumns(this);
  double get roomCardAspectRatio => ResponsiveTokens.roomCardAspectRatio(this);
  double get itemCardAspectRatio => ResponsiveTokens.itemCardAspectRatio(this);
  double get photoCardAspectRatio => ResponsiveTokens.photoCardAspectRatio(this);
}
