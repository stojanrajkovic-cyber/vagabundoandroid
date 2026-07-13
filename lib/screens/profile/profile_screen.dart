import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/plan_document.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/profile_controller.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../services/profile/delete_account_service.dart';
import '../../services/profile/profile_avatar_service.dart';
import '../../widgets/profile/achievement_definitions.dart';
import '../../widgets/profile/journey_map_view.dart';
import '../../widgets/profile/section_card.dart';
import '../../widgets/settings/feedback_sheet.dart';

/// Ekvivalent ProfileView.swift + ProfileStore.swift — travel stats,
/// achievements, journey map, account akcije.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileDerivedStats _derivedStats = const ProfileDerivedStats.empty();
  File? _avatarFile;
  bool _isRefreshing = false;
  bool _isCheckingVerification = false;
  bool? _isEmailVerifiedOverride;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final file = await ref.read(profileAvatarServiceProvider).loadIfExists(uid);
    if (mounted) setState(() => _avatarFile = file);
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    final stats = await ref.read(profileControllerProvider).refresh();
    if (!mounted) return;
    setState(() {
      _derivedStats = stats;
      _isRefreshing = false;
    });
  }

  Future<void> _pickAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final saved = await ref
        .read(profileAvatarServiceProvider)
        .save(uid, File(picked.path));
    if (mounted) setState(() => _avatarFile = saved);
  }

  Future<void> _editDisplayName(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await ref
        .read(firestoreServiceProvider)
        .updateDisplayName(uid: uid, displayName: result.trim());
  }

  Future<void> _resendVerification() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent.')),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _isCheckingVerification = true);
    await FirebaseAuth.instance.currentUser?.reload();
    // authStateChanges() (koji authStateProvider koristi) NE emituje novi event
    // na reload() — samo userChanges() stream to radi. Bez ovog lokalnog
    // override-a, `user.emailVerified` bi ostao zaglavljen na starom snapshot-u
    // zauvijek, bez obzira što je verifikacija stvarno uspjela.
    final refreshed = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _isCheckingVerification = false;
      _isEmailVerifiedOverride = refreshed?.emailVerified;
    });
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/plan');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final success =
        await ref.read(deleteAccountServiceProvider).deleteAccount(context);
    if (!mounted) return;
    if (success) {
      context.go('/plan');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not delete account. Please try again.')),
      );
    }
  }

  ImageProvider? _avatarImage(User? user) {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    if (user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final user = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final visits =
        ref.watch(userVisitsProvider).asData?.value ?? const <VisitedCity>[];
    final achievements = profile?.achievements ?? const <String>[];

    // Prikazani travel stats su DERIVED (svježe računati na refresh()), ne
    // profile.stats iz Firestore-a — isto ponašanje kao iOS refreshPlans().
    final displayStats = UserStats(
      plansCount: _derivedStats.plansCount,
      completedPlans: _derivedStats.completedPlansCount,
      totalKm: _derivedStats.totalKm,
      citiesCount: profile?.stats.citiesCount ?? 0,
      freePlansRemaining: profile?.stats.freePlansRemaining ?? 0,
      paidPlansCount: profile?.stats.paidPlansCount ?? 0,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          children: [
            if (isOffline) ...[
              const _OfflineBadge(),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Profile',
                style: AppTypography.heroTitle
                    .copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: context.accent.withValues(alpha: 0.12),
                      backgroundImage: _avatarImage(user),
                      child: _avatarImage(user) == null
                          ? Icon(Icons.account_circle,
                              size: 40, color: context.accent)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (profile?.displayName?.isNotEmpty ?? false)
                                    ? profile!.displayName!
                                    : (user?.displayName ?? 'Traveler'),
                                style: AppTypography.cardTitle
                                    .copyWith(color: context.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  size: 18, color: context.textSecondary),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _editDisplayName(
                                  profile?.displayName ?? user?.displayName),
                            ),
                          ],
                        ),
                        Text(
                          user?.email ?? '',
                          style: AppTypography.bodySecondary
                              .copyWith(color: context.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.refresh, color: context.textSecondary),
                    onPressed: _isRefreshing ? null : _refresh,
                  ),
                ],
              ),
            ),
            if (user != null &&
                !(_isEmailVerifiedOverride ?? user.emailVerified)) ...[
              const SizedBox(height: AppSpacing.lg),
              _EmailVerificationBanner(
                email: user.email ?? '',
                isChecking: _isCheckingVerification,
                onResend: _resendVerification,
                onCheckVerified: _checkVerified,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _TravelStatsCard(stats: displayStats),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievements',
                      style: AppTypography.cardTitle
                          .copyWith(color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  if (achievements.isEmpty)
                    Text('No achievements yet',
                        style: AppTypography.bodySecondary
                            .copyWith(color: context.textSecondary))
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final key in achievements)
                          _AchievementChip(achievementKey: key),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                    child: Text('Journey Map',
                        style: AppTypography.cardTitle
                            .copyWith(color: context.textPrimary)),
                  ),
                  SizedBox(
                    height: 220,
                    child: visits.isEmpty
                        ? Center(
                            child: Text('No trips yet',
                                style: AppTypography.bodySecondary
                                    .copyWith(color: context.textSecondary)))
                        : JourneyMapView(visits: visits),
                  ),
                  if (visits.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (final visit in visits.take(15))
                      _VisitedCityRow(visit: visit),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileActionRow(
                    icon: Icons.feedback_outlined,
                    label: 'Send feedback',
                    onTap: () => showFeedbackSheet(context),
                  ),
                  const Divider(height: 1),
                  _ProfileActionRow(
                    icon: Icons.logout,
                    label: 'Sign out',
                    onTap: _signOut,
                  ),
                  const Divider(height: 1),
                  _ProfileActionRow(
                    icon: Icons.delete_outline,
                    label: 'Delete account',
                    isDestructive: true,
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: context.cardStroke),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 16, color: context.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('You are offline',
              style: AppTypography.bodySecondary
                  .copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}

class _EmailVerificationBanner extends StatelessWidget {
  const _EmailVerificationBanner({
    required this.email,
    required this.isChecking,
    required this.onResend,
    required this.onCheckVerified,
  });

  final String email;
  final bool isChecking;
  final VoidCallback onResend;
  final VoidCallback onCheckVerified;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your email',
              style:
                  AppTypography.cardTitle.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We sent a verification link to $email. Verify your email to unlock the verified email achievement.',
            style: AppTypography.bodySecondary
                .copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              TextButton(onPressed: onResend, child: const Text('Resend')),
              const SizedBox(width: AppSpacing.sm),
              isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: onCheckVerified,
                      child: const Text("I've verified")),
            ],
          ),
        ],
      ),
    );
  }
}

class _TravelStatsCard extends StatelessWidget {
  const _TravelStatsCard({required this.stats});

  final UserStats stats;

  static const _levelLabels = {
    'level_one_step': 'One small step',
    'level_baby_footsteps': 'Baby footsteps',
    'level_aspiring_traveler': 'Aspiring traveler',
    'level_experienced_explorer': 'Experienced explorer',
    'level_citizen_world': 'Citizen of the world',
    'level_global_nomad': 'Global nomad',
  };

  @override
  Widget build(BuildContext context) {
    final percent =
        stats.usesEarthScale ? stats.earthPercent : stats.moonPercent;
    final levelLabel =
        _levelLabels[stats.travelerLevelKey] ?? stats.travelerLevelKey;
    final remaining = stats.nextLevelRemaining;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travel Stats',
              style:
                  AppTypography.cardTitle.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 10,
                      color: context.cardStroke,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: (percent / 100).clamp(0, 1),
                      strokeWidth: 10,
                      color: context.accent,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stats.usesEarthScale
                            ? Icons.public
                            : Icons.nightlight_round,
                        color: context.accent,
                        size: 28,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${stats.totalKm.toStringAsFixed(0)} km',
                        style: AppTypography.body
                            .copyWith(color: context.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              stats.usesEarthScale
                  ? '${stats.earthPercent.toStringAsFixed(1)}% around the Earth'
                  : '${stats.moonPercent.toStringAsFixed(2)}% of the way to the Moon',
              style: AppTypography.bodySecondary
                  .copyWith(color: context.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(levelLabel,
              style: AppTypography.body.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: stats.travelerLevelProgress.clamp(0, 1),
              minHeight: 8,
              color: context.accent,
              backgroundColor: context.cardStroke,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            remaining != null
                ? '$remaining completed ${remaining == 1 ? 'trip' : 'trips'} until next level'
                : 'Maximum level reached',
            style: AppTypography.bodySecondary
                .copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievementKey});

  final String achievementKey;

  @override
  Widget build(BuildContext context) {
    final definition = achievementDefinitionFor(achievementKey);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: context.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(definition.icon, size: 16, color: context.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(definition.title,
              style: AppTypography.chip.copyWith(color: context.accent)),
        ],
      ),
    );
  }
}

class _VisitedCityRow extends StatelessWidget {
  const _VisitedCityRow({required this.visit});

  final VisitedCity visit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 16, color: context.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${visit.name}, ${visit.country}',
              style: AppTypography.body.copyWith(color: context.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            DateFormat.yMMMd().format(visit.visitedAt),
            style: AppTypography.bodySecondary
                .copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : context.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTypography.body.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
