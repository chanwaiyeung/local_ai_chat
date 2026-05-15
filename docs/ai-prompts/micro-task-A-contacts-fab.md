# Micro Task A: Add FAB to _ContactListScreen (minimal stub)

## File location (exact)
- File: lib/screens/personal_hub_screen.dart
- Target class: _ContactListScreen (StatelessWidget)
- Line range: 769-795 (verify before editing)

## Current code (verified 2026-05-15)
```dart
class _ContactListScreen extends StatelessWidget {
  const _ContactListScreen({required this.controller});

  final ContactController controller;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final contacts = controller.contacts;
    return Scaffold(
      appBar: AppBar(title: Text(loc.moduleContacts)),
      body: contacts.isEmpty
          ? Center(child: Text(loc.noContactsYet))
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final subtitle = [contact.title, contact.company]
                    .where((value) => value.trim().isNotEmpty)
                    .join(' · ');
                return ListTile(
                  leading: const Icon(Icons.contacts_outlined),
                  title: Text(contact.name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                );
              },
            ),
    );
  }
}
```

## Goal
Add ONE FloatingActionButton.extended to the Scaffold.
On press: show SnackBar with text 新增名片功能建設中.
NOTHING else.

## Required change (only this)
Add a single `floatingActionButton:` parameter to the Scaffold, AFTER `body:`.

Expected diff shape (something like this):
```dart
return Scaffold(
  appBar: AppBar(title: Text(loc.moduleContacts)),
  body: contacts.isEmpty
      ? Center(child: Text(loc.noContactsYet))
      : ListView.builder(...),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(新增名片功能建設中)),
      );
    },
    icon: const Icon(Icons.add),
    label: const Text(新增名片),
  ),
);
```

## Hard constraints

1. Modify ONLY: lib/screens/personal_hub_screen.dart
2. Modify ONLY inside _ContactListScreen.build() method
3. Diff: add 8-12 lines, delete 0 lines (only modify the trailing `,` if needed)
4. NO new imports (ScaffoldMessenger, SnackBar, FloatingActionButton are all
   already available via material.dart which is imported)
5. NO new methods or classes
6. NO converting _ContactListScreen to StatefulWidget
7. NO touching any other class in this file (PersonalHubScreen, _ModuleCardGrid, etc.)
8. NO modifying ARB / l10n files (hardcoded Chinese is OK for now)

## Required deliverables (paste raw output in your reply)

1. Output of: git diff lib/screens/personal_hub_screen.dart
2. Output of: git diff --stat
3. Output of: flutter analyze
4. Output of: flutter test 2>&1 | Select-Object -Last 3
5. Confirmation that Contacts screen visually shows "+ 新增名片" FAB
   (you can describe what you saw, or paste flutter run output)

## Acceptance criteria (ALL must be true)

1. git diff --stat shows ONLY lib/screens/personal_hub_screen.dart
2. flutter analyze: "No issues found!"
3. flutter test: 409+ passed, 4 skipped, 0 failed
4. Contacts screen shows "+ 新增名片" FloatingActionButton at bottom-right
5. Tap FAB → SnackBar appears with text 新增名片功能建設中

## Do NOT

- Do not create new files
- Do not modify imports
- Do not write a form dialog (next task, not this one)
- Do not add controller methods
- Do not commit
- Do not run dart fix --apply
- Do not modify windows/flutter/generated_*
- Do not "improve" any other code in the file

## If you violate any constraint
Stop, revert your changes (git restore .), report the violation, and ask
for clarification. Do not commit partial work.
