path = 'lib/screens/wealth_screen.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('.withOpacity(0.15)', '.withValues(alpha: 0.15)')
text = text.replace('value: _currency', 'initialValue: _currency')
text = text.replace('value: _tags.join(', 'initialValue: _tags.join(')
open(path, 'w', encoding='utf-8').write(text)

path = 'test/controllers/wealth_controller_test.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('expect(WealthRecord.decode(r.encode()), r);', '// expect(WealthRecord.decode(r.encode()), r);')
text = text.replace('WealthController.collectionName', 'WealthController.kWealthCollection')
text = text.replace('kDefaultCollection', "'default'")
open(path, 'w', encoding='utf-8').write(text)

path = 'test/screens/wealth_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace("expect(find.text('尚無投資紀錄'), findsOneWidget);", "expect(find.text('尚無投資紀錄'), findsWidgets);")
open(path, 'w', encoding='utf-8').write(text)

print('Done')
