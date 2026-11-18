import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import 'resource_form.dart';
import 'resource_view.dart';

/// A form on the screen itself that asks for a few values and shows what the server answers. For questions such as
/// "can this amount be refunded" where the answer is the point.
class AskThenShow extends StatefulWidget {
  const AskThenShow({super.key, required this.fields, required this.submitLabel, required this.fetch, this.intro});

  final List<FieldSpec> fields;
  final String submitLabel;
  final String? intro;
  final Future<Json> Function(Json values) fetch;

  @override
  State<AskThenShow> createState() => _AskThenShowState();
}

class _AskThenShowState extends State<AskThenShow> {
  Json? _answer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        if (widget.intro != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.intro!, style: TextStyle(color: context.mutedColor))),
        ResourceForm(
          fields: widget.fields,
          submitLabel: widget.submitLabel,
          popOnSuccess: false,
          onSubmit: (values) async {
            final r = await widget.fetch(values);
            if (mounted) setState(() => _answer = r);
          },
        ),
        if (_answer != null) ...<Widget>[
          const SizedBox(height: 16),
          PCard(child: MapDetail(_answer!)),
        ],
      ],
    );
  }
}
