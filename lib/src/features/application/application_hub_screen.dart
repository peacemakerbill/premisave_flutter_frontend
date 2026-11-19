import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/application_models.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'application_widgets.dart';

/// Entry point for becoming a home owner: start, continue, track, withdraw or reapply.
class ApplicationHubScreen extends ConsumerStatefulWidget {
  const ApplicationHubScreen({super.key});

  @override
  ConsumerState<ApplicationHubScreen> createState() => _ApplicationHubScreenState();
}

class _ApplicationHubScreenState extends ConsumerState<ApplicationHubScreen> {
  bool _busy = false;

  Future<void> _reload() async {
    ref.invalidate(myApplicationProvider);
    ref.invalidate(eligibilityProvider);
    ref.invalidate(myApplicationsProvider);
    try {
      await ref.read(sessionProvider.notifier).refreshUser();
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
      if (mounted && done != null) showToast(context, done);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(AppMeta meta) async {
    final picked = await showCenteredSheet<_StartChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StartSheet(meta: meta),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final app = await ref.read(applicationRepositoryProvider).start(ownerType: picked.ownerType, country: picked.country);
      await _reload();
      if (mounted) context.push('/application/${app.id}');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(ApplicationDetail a) async {
    final reason = await promptDialog(
      context,
      title: 'Withdraw application',
      message: 'Your application will be closed. You can apply again later.',
      label: 'Reason (optional)',
      confirmLabel: 'Withdraw',
    );
    if (reason == null) return;
    await _run(() => ref.read(applicationRepositoryProvider).withdraw(a.id, reason: reason), done: 'Application withdrawn');
  }

  Future<void> _deleteDraft(ApplicationDetail a) async {
    final ok = await confirmDialog(context, title: 'Delete this draft?', message: 'Everything you entered will be removed.', confirmLabel: 'Delete', danger: true);
    if (!ok) return;
    await _run(() => ref.read(applicationRepositoryProvider).deleteDraft(a.id), done: 'Draft deleted');
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myApplicationProvider);
    final meta = ref.watch(appMetaProvider);
    final eligibility = ref.watch(eligibilityProvider);
    final history = ref.watch(myApplicationsProvider);

    return SubPage(
      title: 'Home owner application',
      fallbackRoute: '/home',
      body: AsyncBody<ApplicationDetail?>(
        value: mine,
        onRetry: _reload,
        builder: (app) => PageBody(
          maxWidth: 760,
          onRefresh: _reload,
          children: <Widget>[
            if (app == null) ..._intro(context, meta, eligibility) else ..._existing(context, app),
            history.maybeWhen(
              data: (items) {
                final others = items.where((i) => i.id != app?.id).toList();
                if (others.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader('Earlier applications'),
                    MenuGroup(
                      children: <Widget>[
                        for (final i in others)
                          MenuTile(
                            icon: Icons.history_rounded,
                            title: i.applicationNumber,
                            subtitle: '${i.statusLabel} · ${timeAgo(i.updatedAt)}',
                            onTap: () => context.push('/application/${i.id}'),
                          ),
                      ],
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _intro(BuildContext context, AsyncValue<AppMeta> meta, AsyncValue<Eligibility> eligibility) {
    final elig = eligibility.valueOrNull;
    final blocked = elig != null && !elig.canApply;
    final openId = elig?.openApplicationId;
    return <Widget>[
      HeroPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.home_work_outlined, size: 34, color: Brand.gold),
            const SizedBox(height: 14),
            const Text('List your property on Premisave', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.7, height: 1.15)),
            const SizedBox(height: 8),
            Text(
              'Tell us about yourself and your properties, upload a few documents and we will review your application.',
              style: TextStyle(fontSize: 14.5, height: 1.5, color: Brand.cream.op(0.8)),
            ),
          ],
        ),
      ),
      const SectionHeader('How it works'),
      const _Step(number: 1, title: 'Fill in your details', text: 'Identity, contact, properties and how you want to be paid.'),
      const _Step(number: 2, title: 'Upload documents', text: 'An ID and proof that you own or manage the property.'),
      const _Step(number: 3, title: 'We review', text: 'A reviewer checks everything and may ask for more information.'),
      const _Step(number: 4, title: 'Start hosting', text: 'Once approved your account becomes a Home Owner account.'),
      if (meta.valueOrNull?.reviewTimeHint != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(meta.valueOrNull!.reviewTimeHint!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
      ],
      const SizedBox(height: 20),
      if (blocked) InlineMessage(elig.reason ?? 'You cannot apply right now.', kind: MessageKind.warning),
      if (blocked && openId != null) ...<Widget>[
        const SizedBox(height: 12),
        PButton(label: 'Open my application', expand: true, onPressed: () => context.push('/application/$openId')),
      ],
      if (!blocked)
        PButton(
          label: 'Start application',
          icon: Icons.arrow_forward_rounded,
          expand: true,
          loading: _busy,
          onPressed: (_busy || meta.valueOrNull == null) ? null : () => _start(meta.valueOrNull!),
        ),
      if (meta.hasError)
        const Padding(padding: EdgeInsets.only(top: 12), child: InlineMessage('Could not load the form options. Pull down to retry.', kind: MessageKind.error)),
    ];
  }

  List<Widget> _existing(BuildContext context, ApplicationDetail app) {
    return <Widget>[
      ApplicationStatusPanel(app: app),
      const SizedBox(height: 14),
      if (app.editable)
        PButton(
          label: app.isDraft ? 'Continue application' : 'Update application',
          icon: Icons.edit_note_rounded,
          expand: true,
          onPressed: () => context.push('/application/${app.id}'),
        )
      else
        PButton(label: 'View details', kind: PButtonKind.outline, expand: true, onPressed: () => context.push('/application/${app.id}')),
      if (app.canReapply) ...<Widget>[
        const SizedBox(height: 10),
        PButton(
          label: 'Fix and reapply',
          icon: Icons.refresh_rounded,
          kind: PButtonKind.accent,
          expand: true,
          loading: _busy,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    final a = await ref.read(applicationRepositoryProvider).reapply(app.id);
                    if (context.mounted) context.push('/application/${a.id}');
                  }),
        ),
      ],
      if (app.status == 'SUBMITTED' || app.status == 'PROCESSING' || app.status == 'INFO_REQUESTED' || app.status == 'VERIFIED') ...<Widget>[
        const SizedBox(height: 10),
        PButton(label: 'Withdraw application', kind: PButtonKind.text, expand: true, onPressed: _busy ? null : () => _withdraw(app)),
      ],
      if (app.isDraft) ...<Widget>[
        const SizedBox(height: 6),
        PButton(label: 'Delete draft', kind: PButtonKind.text, expand: true, onPressed: _busy ? null : () => _deleteDraft(app)),
      ],
      const SectionHeader('Timeline'),
      ApplicationTimeline(events: app.timeline),
    ];
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text});

  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Brand.gold.op(0.18), shape: BoxShape.circle),
            child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.goldDeep)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartChoice {
  const _StartChoice(this.ownerType, this.country);

  final String ownerType;
  final String? country;
}

class _StartSheet extends StatefulWidget {
  const _StartSheet({required this.meta});

  final AppMeta meta;

  @override
  State<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends State<_StartSheet> {
  String? _owner;
  String? _country;

  @override
  Widget build(BuildContext context) {
    final m = widget.meta;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Start your application', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            PSelectField<String>(
              label: 'I am applying as',
              options: <PChoice<String>>[for (final o in m.ownerTypes) PChoice<String>(o.value, o.label, description: o.description)],
              value: _owner,
              onChanged: (v) => setState(() => _owner = v),
            ),
            const SizedBox(height: 14),
            PSelectField<String>(
              label: 'Country you operate in',
              optional: true,
              searchable: true,
              options: <PChoice<String>>[for (final c in m.countries) PChoice<String>(c.value, c.label)],
              value: _country,
              onChanged: (v) => setState(() => _country = v),
            ),
            const SizedBox(height: 20),
            PButton(
              label: 'Continue',
              expand: true,
              onPressed: _owner == null ? null : () => Navigator.of(context).pop(_StartChoice(_owner!, _country)),
            ),
          ],
        ),
      ),
    );
  }
}
