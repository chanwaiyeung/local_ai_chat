import re

def wrap_in_file(path):
    text = open(path, 'r', encoding='utf-8').read()
    
    # We will just replace specific blocks manually to be safe.
    
    text = text.replace("""    await contactController.saveContact(
      Contact(id: 'c1', name: 'Albert', scannedAt: DateTime(2026, 5, 1)),
    );
    await contactController.saveContact(
      Contact(id: 'c2', name: 'Wang', scannedAt: DateTime(2026, 5, 2)),
    );""", """    await tester.runAsync(() async {
      await contactController.saveContact(
        Contact(id: 'c1', name: 'Albert', scannedAt: DateTime(2026, 5, 1)),
      );
      await contactController.saveContact(
        Contact(id: 'c2', name: 'Wang', scannedAt: DateTime(2026, 5, 2)),
      );
    });""")
    
    open(path, 'w', encoding='utf-8').write(text)

wrap_in_file('test/screens/personal_hub_screen_test.dart')
print('Wrapped contacts')
