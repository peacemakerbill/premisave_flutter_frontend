import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import 'info_parts.dart';

/// How to reach the Premisave team. The form sends the message to the server, which emails the team
/// and confirms to the sender. If the server cannot be reached, the person can still email us instead.
class ContactContent extends StatefulWidget {
  const ContactContent({super.key});

  @override
  State<ContactContent> createState() => _ContactContentState();
}

class _ContactContentState extends State<ContactContent> {
  final GlobalKey _formAnchor = GlobalKey();

  void _scrollToForm() {
    final target = _formAnchor.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        InfoHero(
          eyebrow: 'Contact us',
          title: 'We are here to help',
          message: 'Questions about your account, an application or anything else? Send us a message and the '
              'Premisave team will reply by email.',
          actions: <Widget>[
            HeroAction(
              label: 'Write to us',
              icon: Icons.edit_outlined,
              onPressed: _scrollToForm,
            ),
            HeroAction(
              label: 'Copy email address',
              icon: Icons.content_copy_rounded,
              filled: false,
              onPressed: () => copySupportEmail(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Channels(),
        InfoSection(
          key: _formAnchor,
          title: 'Send us a message',
          subtitle: 'Tell us a little about what you need and we will point you the right way.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              const form = _MessageForm();
              const help = _QuickAnswers();
              if (constraints.maxWidth < 860) {
                return const Column(children: <Widget>[form, SizedBox(height: 16), help]);
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: form),
                  SizedBox(width: 18),
                  Expanded(flex: 2, child: help),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        const _SafetyNote(),
      ],
    );
  }
}

class _Channels extends StatelessWidget {
  const _Channels();

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrap(
      minItemWidth: 250,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[
        _ChannelCard(
          icon: Icons.mail_outline_rounded,
          title: 'Email us',
          highlight: AppConfig.supportEmail,
          text: 'Prefer your own email app? Tap here. If none opens, we copy the address for you.',
          onTap: () => composeSupportEmail(context, subject: 'Premisave support'),
        ),
        _ChannelCard(
          icon: Icons.shield_outlined,
          title: 'Security concern',
          highlight: 'Review your activity',
          text: 'Saw a sign in you do not recognise? Check your activity, then change your password.',
          onTap: () => context.push('/account/security'),
        ),
        _ChannelCard(
          icon: Icons.home_work_outlined,
          title: 'Application status',
          highlight: 'Follow your application',
          text: 'See where your home owner application stands and what the team has asked for.',
          onTap: () => context.push('/application'),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.title,
    required this.highlight,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String highlight;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconBadge(icon),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 20, color: context.mutedColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text(
            highlight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: pal.accent),
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor)),
        ],
      ),
    );
  }
}

class _MessageForm extends ConsumerStatefulWidget {
  const _MessageForm();

  @override
  ConsumerState<_MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends ConsumerState<_MessageForm> {
  /// The value is the code the server expects; the label is what people read.
  static const List<PChoice<String>> _topics = <PChoice<String>>[
    PChoice<String>('GENERAL', 'General question'),
    PChoice<String>('ACCOUNT', 'Account and sign in'),
    PChoice<String>('APPLICATION', 'Home owner application'),
    PChoice<String>('PAYMENTS', 'Bookings and payments'),
    PChoice<String>('SECURITY', 'Security concern'),
    PChoice<String>('FEEDBACK', 'Feedback or an idea'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String _topic = _topics.first.value;
  bool _sending = false;
  String? _error;
  bool _offerEmail = false;
  ContactReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).user;
    if (user != null) {
      _name.text = user.fullName;
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  String get _topicLabel => _topics.firstWhere((t) => t.value == _topic).label;

  Future<void> _send() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
      _offerEmail = false;
    });
    try {
      final receipt = await ref.read(contactRepositoryProvider).send(
            name: _name.text,
            email: _email.text,
            topic: _topic,
            message: _message.text,
          );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _sending = false;
      });
    } catch (e) {
      final err = ApiException.from(e);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = err.message;
        // When the server cannot be reached or is down, the person can still get through by email.
        _offerEmail = err.isNetwork || (err.statusCode ?? 0) >= 500;
      });
    }
  }

  Future<void> _emailInstead() {
    final body = '${_message.text.trim()}\n\nName: ${_name.text.trim()}\nEmail: ${_email.text.trim()}';
    return composeSupportEmail(context, subject: '[$_topicLabel] Premisave', body: body);
  }

  void _another() {
    setState(() {
      _message.clear();
      _receipt = null;
      _error = null;
      _offerEmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt != null) {
      return _SentCard(receipt: receipt, email: _email.text.trim(), onAnother: _another);
    }
    return PCard(
      padding: EdgeInsets.all(context.isCompact ? 18 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ResponsiveWrap(
              minItemWidth: 230,
              spacing: 14,
              maxColumns: 2,
              children: <Widget>[
                PTextField(
                  label: 'Your name',
                  controller: _name,
                  hint: 'Jane Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  enabled: !_sending,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return 'Please enter your name';
                    if (text.length < 2) return 'Your name looks too short';
                    return null;
                  },
                ),
                PTextField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: !_sending,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  helper: 'We reply to this address',
                  validator: Validators.email,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PSelectField<String>(
              label: 'Topic',
              options: _topics,
              value: _topic,
              enabled: !_sending,
              onChanged: (v) => setState(() => _topic = v ?? _topic),
            ),
            const SizedBox(height: 16),
            PTextField(
              label: 'Message',
              controller: _message,
              hint: 'Tell us how we can help',
              maxLines: 7,
              minLines: 5,
              maxLength: 2000,
              enabled: !_sending,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Please write a message';
                if (text.length < 10) return 'Please add a few more details so we can help';
                return null;
              },
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              InlineMessage(
                _error!,
                kind: MessageKind.error,
                actionLabel: _offerEmail ? 'Email us instead' : null,
                onAction: _offerEmail ? _emailInstead : null,
              ),
            ],
            const SizedBox(height: 20),
            PButton(
              label: _sending ? 'Sending' : 'Send message',
              icon: Icons.send_rounded,
              expand: context.isCompact,
              loading: _sending,
              onPressed: _send,
            ),
            const SizedBox(height: 12),
            Text(
              'We reply to the email address above and send you a confirmation straight away.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the form once the server has the message.
class _SentCard extends StatelessWidget {
  const _SentCard({required this.receipt, required this.email, required this.onAnother});

  final ContactReceipt receipt;
  final String email;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      padding: EdgeInsets.all(context.isCompact ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconBadge(Icons.check_circle_outline_rounded, size: 56, color: pal.good),
          const SizedBox(height: 18),
          Text('Message sent', style: context.display(size: 24, weight: FontWeight.w800, spacing: -0.6, height: 1.2)),
          const SizedBox(height: 8),
          Text(receipt.message, style: TextStyle(fontSize: 14.5, height: 1.55, color: context.mutedColor)),
          if (receipt.reference.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
              decoration: BoxDecoration(
                color: pal.accentSoft,
                borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.confirmation_number_outlined, size: 20, color: pal.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Your reference', style: TextStyle(fontSize: 11.5, color: context.mutedColor)),
                        SelectableText(
                          receipt.reference,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy reference',
                    icon: const Icon(Icons.content_copy_rounded, size: 19),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: receipt.reference));
                      if (context.mounted) showToast(context, 'Reference copied');
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'We emailed a confirmation to $email. If it does not arrive within a few minutes, check your spam folder.',
            style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              PButton(label: 'Send another message', kind: PButtonKind.outline, onPressed: onAnother),
              PButton(label: 'Back to home', kind: PButtonKind.text, onPressed: () => context.go('/home')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

class _QuickAnswers extends StatelessWidget {
  const _QuickAnswers();

  static const List<_Faq> _items = <_Faq>[
    _Faq(
      'I did not get my activation email',
      'Check your spam folder first. On the sign in screen, choose "Did not get your activation email? Resend it" '
          'and we will send a fresh link.',
    ),
    _Faq(
      'I forgot my password',
      'Use "Forgot password" on the sign in screen. We email you a link to choose a new one.',
    ),
    _Faq(
      'How do I become a home owner?',
      'Open Applications, fill in your details and upload your documents. Our team reviews them and emails you '
          'whenever the status changes.',
    ),
    _Faq(
      'I see a sign in I do not recognise',
      'Open Account, then Security, to review your devices and activity. Sign out other sessions and change '
          'your password, then contact us.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const IconBadge(Icons.lightbulb_outline_rounded, size: 36),
              const SizedBox(width: 12),
              Text(
                'Quick answers',
                style: context.display(size: 17, weight: FontWeight.w800, spacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < _items.length; i++) ...<Widget>[
                  if (i != 0) Divider(height: 1, color: context.borderColor),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    iconColor: pal.accent,
                    collapsedIconColor: context.mutedColor,
                    title: Text(
                      _items[i].question,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    children: <Widget>[
                      Text(
                        _items[i].answer,
                        style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      color: pal.accentSoft,
      borderColor: pal.accent.op(0.25),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.gpp_good_outlined, color: pal.accent, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Premisave will never ask for your password or a verification code. '
              'Keep them private, even if someone says they work with us.',
              style: TextStyle(fontSize: 13.5, height: 1.55, color: context.inkColor),
            ),
          ),
        ],
      ),
    );
  }
}
