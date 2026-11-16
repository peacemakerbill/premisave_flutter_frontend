import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/application_models.dart';

Color statusTint(String? hex) => colorFromHex(hex, fallback: Brand.muted);

/// Where the application stands, in words the applicant can act on.
class ApplicationStatusPanel extends StatelessWidget {
  const ApplicationStatusPanel({super.key, required this.app});

  final ApplicationDetail app;

  @override
  Widget build(BuildContext context) {
    final c = statusTint(app.statusColor);
    return PCard(
      borderColor: c.op(0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusPill(app.statusLabel, color: c),
              const Spacer(),
              if (app.applicationNumber.isNotEmpty)
                Text(app.applicationNumber, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
            ],
          ),
          if (app.statusDescription != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(app.statusDescription!, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600)),
          ],
          if (app.latestMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            InlineMessage(app.latestMessage!, kind: app.status == 'INFO_REQUESTED' || app.status == 'REJECTED' ? MessageKind.warning : MessageKind.info),
          ],
          if (app.decisionReason != null && app.decisionReason != app.latestMessage) ...<Widget>[
            const SizedBox(height: 10),
            InlineMessage(app.decisionReason!, kind: MessageKind.error),
          ],
          if (app.nextStep != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.arrow_circle_right_outlined, size: 18, color: context.mutedColor),
                const SizedBox(width: 8),
                Expanded(child: Text(app.nextStep!, style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedColor))),
              ],
            ),
          ],
          if (app.reviewTimeHint != null && (app.status == 'SUBMITTED' || app.status == 'PROCESSING')) ...<Widget>[
            const SizedBox(height: 8),
            Text(app.reviewTimeHint!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
          ],
          if (!app.isFinal) ...<Widget>[
            const SizedBox(height: 16),
            _Progress(percent: app.readiness.percent),
          ],
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Application complete', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.mutedColor)),
            const Spacer(),
            Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percent.clamp(0, 100)) / 100,
            minHeight: 7,
            backgroundColor: context.borderColor,
            color: Brand.gold,
          ),
        ),
      ],
    );
  }
}

class ApplicationTimeline extends StatelessWidget {
  const ApplicationTimeline({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return Text('Nothing has happened yet.', style: TextStyle(color: context.mutedColor));
    final list = events.reversed.toList();
    return PCard(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < list.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(color: i == 0 ? Brand.gold : context.borderColor, shape: BoxShape.circle),
                        ),
                        if (i != list.length - 1) Expanded(child: Container(width: 2, color: context.borderColor)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            list[i].toStatus != null ? sentence(list[i].toStatus) : sentence(list[i].type),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          if (list[i].message != null) Text(list[i].message!, style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedColor)),
                          Text(
                            <String>[if (list[i].actor != null) list[i].actor!, whenLabel(list[i].at)].join(' · '),
                            style: TextStyle(fontSize: 12, color: context.mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Documents on an application. Pass [onDelete] to let the applicant remove files,
/// [onReview] for staff to verify or reject them, and [onPreview] to open images.
class DocumentList extends StatelessWidget {
  const DocumentList({super.key, required this.documents, this.onDelete, this.onReview, this.onPreview});

  final List<DocumentView> documents;
  final void Function(DocumentView doc)? onDelete;
  final void Function(DocumentView doc)? onReview;
  final void Function(DocumentView doc)? onPreview;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Text('No documents uploaded yet.', style: TextStyle(color: context.mutedColor));
    }
    return Column(
      children: <Widget>[
        for (final d in documents) ...<Widget>[
          PCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _docColor(d).op(0.12), borderRadius: BorderRadius.circular(11)),
                      child: Icon(d.isImage ? Icons.image_outlined : Icons.description_outlined, color: _docColor(d), size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(d.typeLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('${d.fileName} · ${formatBytes(d.sizeBytes)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                        ],
                      ),
                    ),
                    StatusPill(d.statusLabel, color: _docColor(d), dense: true),
                  ],
                ),
                if (d.reviewReason != null && d.rejected) ...<Widget>[
                  const SizedBox(height: 10),
                  InlineMessage(d.reviewReason!, kind: MessageKind.error),
                ],
                if (onPreview != null || onDelete != null || onReview != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 4,
                      children: <Widget>[
                        if (onPreview != null && d.isImage)
                          TextButton.icon(onPressed: () => onPreview!(d), icon: const Icon(Icons.visibility_outlined, size: 17), label: const Text('Preview')),
                        if (onReview != null)
                          TextButton.icon(onPressed: () => onReview!(d), icon: const Icon(Icons.rule_rounded, size: 17), label: const Text('Review')),
                        if (onDelete != null && !d.verified)
                          TextButton.icon(
                            onPressed: () => onDelete!(d),
                            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Brand.danger),
                            label: const Text('Remove', style: TextStyle(color: Brand.danger)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Color _docColor(DocumentView d) => d.verified ? Brand.success : (d.rejected ? Brand.danger : Brand.warning);
}

/// Shows an image document full screen.
Future<void> showImagePreview(BuildContext context, String title, Future<Uint8List> Function() load) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 240, minWidth: 240),
            child: FutureBuilder<Uint8List>(
              future: load(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator(color: Brand.gold)));
                }
                if (snap.hasError) {
                  return SizedBox(
                    height: 280,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(ApiException.from(snap.error!).message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }
                return InteractiveViewer(child: Image.memory(snap.data!, fit: BoxFit.contain));
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
