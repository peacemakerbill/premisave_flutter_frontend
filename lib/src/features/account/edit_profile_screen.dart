import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _first;
  late final TextEditingController _middle;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _country;

  bool _saving = false;
  bool _uploading = false;
  String? _error;
  Map<String, String> _fieldErrors = <String, String>{};

  @override
  void initState() {
    super.initState();
    final u = ref.read(sessionProvider).user;
    _username = TextEditingController(text: u?.username);
    _first = TextEditingController(text: u?.firstName);
    _middle = TextEditingController(text: u?.middleName);
    _last = TextEditingController(text: u?.lastName);
    _phone = TextEditingController(text: u?.phoneNumber);
    _address1 = TextEditingController(text: u?.address1);
    _address2 = TextEditingController(text: u?.address2);
    _country = TextEditingController(text: u?.country);
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[_username, _first, _middle, _last, _phone, _address1, _address2, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 88);
      if (picked == null) return;
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      await ref.read(profileRepositoryProvider).uploadPicture(bytes: bytes, fileName: picked.name);
      await ref.read(sessionProvider.notifier).refreshUser();
      if (mounted) showToast(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = <String, String>{};
    });
    try {
      final msg = await ref.read(profileRepositoryProvider).update(
            username: _username.text.trim().isEmpty ? user.username : _username.text,
            firstName: _first.text,
            middleName: _middle.text,
            lastName: _last.text,
            phoneNumber: _phone.text,
            address1: _address1.text,
            address2: _address2.text,
            country: _country.text,
            language: user.language,
          );
      await ref.read(sessionProvider.notifier).refreshUser();
      if (!mounted) return;
      showToast(context, msg);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account/profile');
      }
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _error = err.fieldErrors.isEmpty ? err.message : 'Please fix the highlighted fields.';
          _fieldErrors = err.fieldErrors;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).user;
    return SubPage(
      title: 'Edit profile',
      fallbackRoute: '/account',
      body: user == null
          ? const LoadingState()
          : PageBody(
              maxWidth: 640,
              children: <Widget>[
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      UserAvatar(initials: user.initials, imageUrl: user.profilePictureUrl, size: 96, ring: true),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: Brand.gold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploading ? null : _pickPhoto,
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: _uploading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Brand.ink))
                                  : const Icon(Icons.photo_camera_outlined, size: 18, color: Brand.ink),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 16)],
                      PTextField(
                        label: 'Username',
                        controller: _username,
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: Validators.username,
                        errorText: _fieldErrors['username'],
                        helper: user.usernameGenerated ? 'We picked this for you. You can change it.' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: PTextField(
                              label: 'First name',
                              controller: _first,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => Validators.required(v, 'First name'),
                              errorText: _fieldErrors['firstName'],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PTextField(
                              label: 'Last name',
                              controller: _last,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => Validators.required(v, 'Last name'),
                              errorText: _fieldErrors['lastName'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PTextField(label: 'Middle name', controller: _middle, optional: true, textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 16),
                      PTextField(
                        label: 'Phone number',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: Validators.phone,
                        errorText: _fieldErrors['phoneNumber'],
                      ),
                      const SizedBox(height: 16),
                      PTextField(label: 'Address line 1', controller: _address1, optional: true, prefixIcon: Icons.home_outlined),
                      const SizedBox(height: 16),
                      PTextField(label: 'Address line 2', controller: _address2, optional: true),
                      const SizedBox(height: 16),
                      PTextField(label: 'Country', controller: _country, optional: true, prefixIcon: Icons.public_rounded, textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 14),
                      InfoRow('Email', user.email, icon: Icons.lock_outline_rounded),
                      Text('Your email cannot be changed here.', style: TextStyle(fontSize: 12, color: context.mutedColor)),
                      const SizedBox(height: 22),
                      PButton(label: 'Save changes', expand: true, loading: _saving, onPressed: _saving ? null : _save),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
