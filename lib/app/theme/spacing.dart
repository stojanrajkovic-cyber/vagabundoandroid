/// Ekvivalent spacing/radius konstanti iz AppTheme.swift.
///
/// ISPRAVKA (bilo pogrešno u Fazi 1 — pravi AppTheme.swift tad nije bio
/// dostupan pa su vrijednosti bile placeholder nagađanje):
///   md: 16 → 12, lg: 24 → 16, xl: 32 → 24 (usklađeno sa AppTheme.Spacing)
///   dodano: screenPadding = 14 (AppTheme.padding — generički "gap" korišten
///   u CountryCityPickerView/PlanOptionsView kao `let gap = AppTheme.padding`)
///
/// xs, xxl i pillRadius nisu u Swift originalu — ostavljeni kao razumne
/// Flutter-specifične dopune, ne mijenjaj ih bez razloga.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8; // AppTheme.Spacing.sm
  static const double md = 12; // AppTheme.Spacing.md
  static const double lg = 16; // AppTheme.Spacing.lg
  static const double xl = 24; // AppTheme.Spacing.xl
  static const double xxl = 48;

  /// AppTheme.padding — generički "gap" korišten kao padding oko cijelih
  /// card-ova (NIJE isto što i md=12; ovo je zaseban konstanta u Swift-u).
  static const double screenPadding = 14;

  static const double cardRadius = 20; // AppTheme.corner
  static const double pillRadius = 100; // capsule / potpuno zaobljeno
}
