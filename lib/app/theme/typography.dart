import 'package:flutter/material.dart';

/// Centralizovana tipografska skala — SVI Text widgeti u app-u treba da
/// koriste jedan od ovih stilova umjesto ad-hoc TextStyle(...) na licu mjesta.
///
/// Pravilo: samo naslovi/section title-ovi su bold. Sve ostalo (labele, body
/// tekst, placeholder tekst, chip tekst) koristi istu težinu (w500) i sličnu
/// veličinu, razlikuju se samo po boji (context.textPrimary vs .textSecondary).
///
/// Ovi stilovi NE uključuju boju — kombinuj sa .copyWith(color: context.textPrimary)
/// ili sličnim na mjestu upotrebe, pošto boja zavisi od light/dark moda i
/// da li je tekst primary/secondary/na accent pozadini.
class AppTypography {
  AppTypography._();

  /// Hero naslov (AppHeroSection) — najveći, bold.
  static const TextStyle heroTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Naslov sekcije (npr. "Interests", "Days" kad je kao card header) — bold.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// Naslov unutar kartice (npr. dan naslov u ResultView) — semibold, manji od sectionTitle.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Standardni body tekst — SVE regularne labele, placeholder tekst
  /// ("Select country"), toggle labele ("Travelling with kids"), itd.
  /// Ovo je DEFAULT stil za 95% teksta u app-u.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  /// Manji, sekundarni tekst — caption, helper tekst, lokacija ispod naslova.
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Sitna labela iznad polja (npr. "Country" iznad "Select country" dugmeta).
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Tekst na dugmadima (PrimaryButton, itd.).
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Tekst u chip-ovima (PillChip, trip pace selektor). Malo manji od body.
  static const TextStyle chip = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
