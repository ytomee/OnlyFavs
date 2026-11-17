import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final int sessionUserId;
  final ProfileService profileService;
  final ValueChanged<int> onTabSelected;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.sessionUserId,
    required this.profileService,
    required this.onTabSelected,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _biography = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.userId != widget.sessionUserId) {
      setState(() {
        _isLoading = false;
        _loadError = 'Só podes editar o teu perfil.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final result = await widget.profileService.getProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        // Os campos vêm sempre do GET, mesmo que a sessão tenha outros valores.
        final profile = result['profile'] as UserProfile;
        _name.text = profile.name;
        _username.text = profile.username.replaceFirst(RegExp(r'^@+'), '');
        _biography.text = profile.biography;
      } else {
        _loadError = result['message'] as String;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _biography.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading || _isSaving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final result = await widget.profileService.updateProfile(
      sessionUserId: widget.sessionUserId,
      userId: widget.userId,
      name: _name.text,
      username: _username.text,
      biography: _biography.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result['success'] == true) {
      Navigator.pop(context, result['profile'] as UserProfile);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'] as String)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.black,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Voltar',
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _loadError != null
                          ? Column(
                              children: [
                                Text(_loadError!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _loadProfile,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: ClipOval(
                                      child: Image(
                                        image: AssetImage(
                                          'assets/images/user.jpg',
                                        ),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _name,
                                    enabled: !_isSaving,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Introduz o teu nome.'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _username,
                                    enabled: !_isSaving,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixText: '@',
                                    ),
                                    validator: (value) {
                                      final username = (value ?? '')
                                          .trim()
                                          .replaceFirst(RegExp(r'^@+'), '');
                                      if (username.isEmpty) {
                                        return 'Introduz o teu username.';
                                      }
                                      if (RegExp(r'\s').hasMatch(username)) {
                                        return 'O username não pode ter espaços.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _biography,
                                    enabled: !_isSaving,
                                    minLines: 3,
                                    maxLines: 5,
                                    keyboardType: TextInputType.multiline,
                                    decoration: const InputDecoration(
                                      labelText: 'Biografia',
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Personaliza a forma como a tua comunidade te vê.',
                                    style: TextStyle(
                                      color: AppTheme.grey,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  PrimaryButton(
                                    text: _isSaving
                                        ? 'A guardar...'
                                        : 'Guardar alterações',
                                    onPressed: _isSaving ? null : _save,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFF1F2),
                                      foregroundColor: AppTheme.primaryRed,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: AppNavBar(
          currentIndex: 3,
          onTap: _isSaving
              ? null
              : (index) {
                  Navigator.pop(context);
                  widget.onTabSelected(index);
                },
        ),
      ),
    );
  }
}
