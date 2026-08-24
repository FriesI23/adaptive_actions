import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

const openDocumentDialogKey = ValueKey('open-document-dialog');
const projectProposalDialogOptionKey = ValueKey(
  'project-proposal-dialog-option',
);
const meetingNotesDialogOptionKey = ValueKey('meeting-notes-dialog-option');
const cancelOpenDocumentDialogKey = ValueKey('cancel-open-document-dialog');

Future<String?> showOpenDocumentDemoDialog(
  BuildContext context, {
  required bool useCupertino,
}) => useCupertino
    ? _showCupertinoOpenDocumentDialog(context)
    : _showMaterialOpenDocumentDialog(context);

Future<String?> _showMaterialOpenDocumentDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: openDocumentDialogKey,
        icon: const Icon(Icons.folder_open),
        title: const Text('Open document'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Choose a sample document to continue.'),
              const SizedBox(height: 16),
              _MaterialDocumentOption(
                key: projectProposalDialogOptionKey,
                title: 'Project proposal',
                subtitle: 'Edited 5 minutes ago',
                onPressed: () => Navigator.pop(context, 'Project proposal'),
              ),
              const SizedBox(height: 8),
              _MaterialDocumentOption(
                key: meetingNotesDialogOptionKey,
                title: 'Meeting notes',
                subtitle: 'Edited yesterday',
                onPressed: () => Navigator.pop(context, 'Meeting notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: cancelOpenDocumentDialogKey,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

Future<String?> _showCupertinoOpenDocumentDialog(BuildContext context) =>
    cupertino.showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => cupertino.CupertinoTheme(
        data: cupertino.CupertinoThemeData(
          brightness: Theme.of(context).brightness,
        ),
        child: cupertino.CupertinoAlertDialog(
          key: openDocumentDialogKey,
          title: const Text('Open document'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Choose a sample document to continue.'),
          ),
          actions: [
            cupertino.CupertinoDialogAction(
              key: projectProposalDialogOptionKey,
              onPressed: () => Navigator.pop(dialogContext, 'Project proposal'),
              child: const Text('Project proposal'),
            ),
            cupertino.CupertinoDialogAction(
              key: meetingNotesDialogOptionKey,
              onPressed: () => Navigator.pop(dialogContext, 'Meeting notes'),
              child: const Text('Meeting notes'),
            ),
            cupertino.CupertinoDialogAction(
              key: cancelOpenDocumentDialogKey,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

final class _MaterialDocumentOption extends StatelessWidget {
  const _MaterialDocumentOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    ),
  );
}
