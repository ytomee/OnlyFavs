import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final int sessionUserId;
  final ProfileService profileService;
  final ValueChanged<int> onTabSelected;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.sessionUserId,
    required this.profileService,
    required this.onTabSelected,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  bool get _isOwnProfile => widget.userId == widget.sessionUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _profile = null;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final userId = widget.userId;
    final result = await widget.profileService.getProfile(userId);
    if (!mounted || widget.userId != userId) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _profile = result['profile'] as UserProfile;
      } else {
        _error = result['message'] as String;
      }
    });
  }

  Future<void> _editProfile() async {
    if (!_isOwnProfile) return;
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userId: widget.userId,
          sessionUserId: widget.sessionUserId,
          profileService: widget.profileService,
          onTabSelected: widget.onTabSelected,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    // Mostra os valores confirmados pelo servidor depois de guardar.
    setState(() => _profile = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadProfile,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    final profile = _profile!;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFFF1F2),
      foregroundColor: AppTheme.primaryRed,
      disabledBackgroundColor: const Color(0xFFFFF1F2),
      disabledForegroundColor: AppTheme.primaryRed,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    return SingleChildScrollView(
      key: const PageStorageKey('profile-scroll'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 3,
                  child: Image.asset(
                    'assets/images/banner.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/user.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.username.startsWith('@')
                              ? profile.username
                              : '@${profile.username}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Chip(
                label: Text(
                  profile.isPublic ? 'Perfil público' : 'Perfil privado',
                ),
                labelStyle: const TextStyle(color: Color(0xFF147D59)),
                backgroundColor: AppTheme.fieldBackground,
                side: BorderSide.none,
                shape: const StadiumBorder(),
              ),
              const SizedBox(height: 16),
              Text(
                profile.biography.isEmpty
                    ? 'Ainda não há biografia.'
                    : profile.biography,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  Text('${profile.publicationCount} publicações'),
                  Text(
                    '${profile.photoCount} fotografias',
                    style: const TextStyle(color: AppTheme.grey),
                  ),
                  Text(
                    '${profile.videoCount} vídeos',
                    style: const TextStyle(color: AppTheme.grey),
                  ),
                ],
              ),
              if (_isOwnProfile) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: _editProfile,
                      style: buttonStyle,
                      child: const Text('Editar perfil'),
                    ),
                    FilledButton(
                      onPressed: null,
                      style: buttonStyle,
                      child: const Text('Partilhar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: null,
                  style: TextButton.styleFrom(
                    disabledForegroundColor: AppTheme.primaryRed,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Configurar acesso e preços →'),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                _isOwnProfile ? 'As minhas publicações' : 'Publicações',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.fieldBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.lightGrey),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 36,
                      color: AppTheme.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.publicationCount == 0
                          ? 'Ainda não há publicações.'
                          : 'As publicações vão aparecer aqui.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
