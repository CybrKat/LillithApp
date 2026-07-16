/// LillithApp - data ownership, sharing and consent.
///
/// This screen is where LillithApp's promise becomes tangible: your cycle data
/// is *yours*. It explains — in plain language a non-technical user can follow
/// — three things:
///
///  1. **Ownership & encryption.** Everything is stored encrypted on your own
///     Solid POD. LillithApp has no server and keeps no copy.
///  2. **Data minimisation.** The app only stores what you actually log, and
///     empty days are dropped rather than kept.
///  3. **Consent & access control (WAC/ACP).** You can grant a specific person
///     (say, your doctor) read-only access to your encrypted cycle file, see
///     who currently has access, and revoke it at any time — each behind an
///     explicit consent step.
///
/// The sharing actions call the Solid server's access-control APIs directly
/// (`grantPermission` / `readPermission` / `revokePermission`) so this is a
/// real WAC/ACP interaction, not a mock-up.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        AccessMode,
        RecipientType,
        SolidFunctionCallStatus,
        getWebId,
        grantPermission,
        readPermission,
        revokePermission;

import 'package:lillith_app/constants/app.dart';

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  State<Privacy> createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  final _recipientController = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _myWebId;
  String? _status;
  Map<dynamic, dynamic> _shares = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final id = await getWebId();
      if (!mounted) return;
      setState(() => _myWebId = id);
      await _refreshShares();
    } catch (e) {
      if (mounted) setState(() => _status = 'Could not read your WebID: $e');
    }
  }

  Future<void> _refreshShares() async {
    try {
      final perms =
          await readPermission(fileName: healthDataFile, isFile: true);
      if (!mounted) return;
      setState(() => _shares = perms);
    } catch (e) {
      // A brand-new file may have no ACL yet — that is fine, just show none.
      if (mounted) setState(() => _shares = {});
    }
  }

  Future<void> _share() async {
    final recipient = _recipientController.text.trim();
    final me = _myWebId;
    if (recipient.isEmpty || me == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await grantPermission(
        fileName: healthDataFile,
        permissionList: [AccessMode.read],
        recipientType: RecipientType.individual,
        recipientWebIdList: [recipient],
        ownerWebId: me,
        granterWebId: me,
        isFile: true,
      );
      final ok = result == SolidFunctionCallStatus.success;
      setState(() {
        _status = ok
            ? 'Shared read-only with $recipient. You can revoke this anytime.'
            : 'Sharing did not complete (status: $result).';
        if (ok) {
          _recipientController.clear();
          _consent = false;
        }
      });
      await _refreshShares();
    } catch (e) {
      setState(() => _status = 'Could not share: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String recipient) async {
    final me = _myWebId;
    if (me == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await revokePermission(
        fileName: healthDataFile,
        permissionList: [AccessMode.read],
        recipientIndOrGroupWebId: recipient,
        ownerWebId: me,
        granterWebId: me,
        recipientType: RecipientType.individual,
        isFile: true,
      );
      setState(() => _status = 'Access revoked for $recipient.');
      await _refreshShares();
    } catch (e) {
      setState(() => _status = 'Could not revoke: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Extract WebIDs other than the owner from the permission map, defensively
  /// (the map shape can vary by server).
  List<String> get _sharedWith {
    final result = <String>[];
    _shares.forEach((key, value) {
      final id = key.toString();
      if (id.startsWith('http') && id != _myWebId) result.add(id);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Your data, your rules',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'LillithApp is different from most cycle apps: it never keeps your '
          'data. Here is exactly what that means.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        const _OwnershipCard(
          icon: Icons.lock_rounded,
          title: 'Locked with a key only you hold',
          body:
              'Every reading, symptom and note is scrambled (encrypted) before '
              'it is saved. It lives in your own private online locker — your '
              'Solid POD. LillithApp has no server and keeps no copy, so nobody '
              '— not even us — can read your cycle.',
        ),
        const _OwnershipCard(
          icon: Icons.spa_rounded,
          title: 'We only keep what you choose to log',
          body:
              'No hidden tracking, no selling your data, no ads. If you clear a '
              'day, it is gone. That is called data minimisation: the app holds '
              'the least it can.',
        ),
        const _OwnershipCard(
          icon: Icons.handshake_rounded,
          title: 'Sharing only ever happens with your say-so',
          body: 'You can let one trusted person — like your doctor — read your '
              'cycle file. You choose who, it is read-only, and you can take it '
              'back whenever you like.',
        ),
        const SizedBox(height: 16),
        if (_myWebId != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_rounded),
              title: const Text('Your WebID'),
              subtitle: Text(_myWebId!),
            ),
          ),
        const SizedBox(height: 16),
        _ShareCard(
          controller: _recipientController,
          consent: _consent,
          busy: _busy,
          onConsentChanged: (v) => setState(() => _consent = v ?? false),
          onShare: (_consent && !_busy) ? _share : null,
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status!),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Currently shared with',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_sharedWith.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nobody. Your cycle data is visible only to you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          for (final id in _sharedWith)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(id),
                subtitle: const Text('Read-only'),
                trailing: TextButton.icon(
                  onPressed: _busy ? null : () => _revoke(id),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Revoke'),
                ),
              ),
            ),
      ],
    );
  }
}

class _OwnershipCard extends StatelessWidget {
  const _OwnershipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.controller,
    required this.consent,
    required this.busy,
    required this.onConsentChanged,
    required this.onShare,
  });

  final TextEditingController controller;
  final bool consent;
  final bool busy;
  final ValueChanged<bool?> onConsentChanged;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share with someone you trust',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Enter their Solid WebID (it looks like a web address). They will '
              'get read-only access to your encrypted cycle file.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Recipient WebID',
                hintText: 'https://their-pod.example/profile/card#me',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: consent,
              onChanged: busy ? null : onConsentChanged,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I understand and consent to giving this person read access to '
                'my cycle data.',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Grant read access'),
            ),
          ],
        ),
      ),
    );
  }
}
