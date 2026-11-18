import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/c2b_models.dart';
import '../../state/c2b_session.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';

/// M-Pesa name lookup for staff. It asks the C2B Hakikisha service who owns an M-Pesa number, the same question
/// Safaricom asks it before a customer pays. The service has its own username and password: they are typed here and
/// traded for a token. They are saved in the system keychain only when the person ticks "Remember on this device".
class NameLookupScreen extends ConsumerWidget {
  const NameLookupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(c2bSessionProvider);
    return PageBody(
      maxWidth: 640,
      children: <Widget>[
        const PageTitle('M-Pesa name lookup', subtitle: 'Check who an M-Pesa number belongs to before money moves.'),
        const SizedBox(height: 12),
        if (!session.active) const _ConnectCard() else const _LookupCard(),
        ServiceDownHint('C2B Hakikisha service', AppConfig.c2bUrl),
        if (session.active) ...<Widget>[
          const SectionHeader('Accounts the service knows'),
          const _SavedAccounts(),
        ],
      ],
    );
  }
}

class _ConnectCard extends ConsumerStatefulWidget {
  const _ConnectCard();

  @override
  ConsumerState<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends ConsumerState<_ConnectCard> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _busy = false;
  bool _remember = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadSaved();
  }

  /// Fills in the credentials the person chose to keep on this device, and connects with them.
  Future<void> _loadSaved() async {
    final saved = await ref.read(c2bCredentialStoreProvider).read();
    if (saved == null || !mounted) return;
    setState(() {
      _user.text = saved.$1;
      _pass.text = saved.$2;
      _remember = true;
      _saved = true;
    });
    await _connect();
  }

  Future<void> _forget() async {
    await ref.read(c2bSessionProvider.notifier).forget();
    if (!mounted) return;
    setState(() {
      _user.clear();
      _pass.clear();
      _remember = false;
      _saved = false;
    });
    showToast(context, 'The saved credentials were removed from this device.');
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Enter the service username and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(c2bSessionProvider.notifier).connect(username: _user.text.trim(), password: _pass.text, remember: _remember);
      if (mounted) _pass.clear();
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const InlineMessage(kIsWeb
              ? 'Connect with the C2B service credentials. They are used once to get an access token and are not saved.'
              : 'Connect with the C2B service credentials. They are used to get an access token, and are saved only if you tick the box below.'),
          const SizedBox(height: 14),
          PTextField(label: 'Service username', controller: _user, prefixIcon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          PTextField(label: 'Service password', controller: _pass, obscure: true, prefixIcon: Icons.lock_outline_rounded, onSubmitted: (_) => _connect()),
          if (!kIsWeb)
            CheckboxListTile(
              value: _remember,
              onChanged: _busy ? null : (v) => setState(() => _remember = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Remember on this device', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              subtitle: const Text('Kept in the system keychain, and removed with Forget.', style: TextStyle(fontSize: 12.5)),
            ),
          if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
          const SizedBox(height: 18),
          PButton(label: 'Connect', icon: Icons.link_rounded, expand: true, loading: _busy, onPressed: _connect),
          if (_saved) ...<Widget>[
            const SizedBox(height: 8),
            Center(child: TextButton(onPressed: _busy ? null : _forget, child: const Text('Forget the saved credentials'))),
          ],
        ],
      ),
    );
  }
}

class _LookupCard extends ConsumerStatefulWidget {
  const _LookupCard();

  @override
  ConsumerState<_LookupCard> createState() => _LookupCardState();
}

class _LookupCardState extends ConsumerState<_LookupCard> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _shortcode = TextEditingController(text: '600992');
  bool _busy = false;
  String? _error;
  NameLookupResult? _result;

  @override
  void dispose() {
    _number.dispose();
    _shortcode.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _number.text.trim();
    if (number.length < 9) {
      setState(() => _error = 'Enter the M-Pesa number, for example 254712345678.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await ref.read(c2bRepositoryProvider).lookup(accountNumber: number, shortcode: _shortcode.text.trim());
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PTextField(label: 'M-Pesa number', controller: _number, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_iphone_rounded, autofocus: true, onSubmitted: (_) => _lookup()),
              const SizedBox(height: 14),
              PTextField(label: 'Paybill shortcode', controller: _shortcode, keyboardType: TextInputType.number, prefixIcon: Icons.pin_outlined),
              if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
              const SizedBox(height: 18),
              PButton(label: 'Look up name', icon: Icons.search_rounded, expand: true, loading: _busy, onPressed: _lookup),
              const SizedBox(height: 6),
              Center(
                child: PButton(
                  label: 'Disconnect',
                  kind: PButtonKind.text,
                  small: true,
                  onPressed: () => ref.read(c2bSessionProvider.notifier).disconnect(),
                ),
              ),
            ],
          ),
        ),
        if (r != null) ...<Widget>[
          const SizedBox(height: 12),
          PCard(
            borderColor: Brand.success,
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Brand.success.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
                  child: const Icon(Icons.verified_rounded, color: Brand.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(r.accountName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(r.accountNumber, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedAccounts extends ConsumerWidget {
  const _SavedAccounts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBodyShrink(
      value: ref.watch(savedAccountsProvider),
      onRetry: () => ref.invalidate(savedAccountsProvider),
      builder: (List<SavedAccount> items) {
        if (items.isEmpty) return const InlineMessage('No accounts saved yet. The wallet sync fills this list.');
        return Column(
          children: <Widget>[
            for (final a in items)
              PCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(a.fullName.isEmpty ? a.accountNumber : a.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(<String?>[a.mpesaPhoneNumber, a.lastSyncedAt == null ? null : 'synced ${timeAgo(a.lastSyncedAt)}'].whereType<String>().join('  ·  '), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                        ],
                      ),
                    ),
                    if (a.frozen) const StatusPill('Frozen', color: Brand.danger, dense: true),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// [AsyncBody] for content that sits inside a page that already scrolls: a small loader, no full screen skeleton.
class AsyncBodyShrink<T> extends StatelessWidget {
  const AsyncBodyShrink({super.key, required this.value, required this.builder, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const SkeletonList(count: 2, height: 64, shrink: true, padding: EdgeInsets.zero),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
    );
  }
}
