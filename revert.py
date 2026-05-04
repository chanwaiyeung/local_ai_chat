path = 'test/screens/personal_hub_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('await tester.pumpWidget(hostFor()); await tester.pumpAndSettle();', 'await tester.pumpWidget(hostFor());')
open(path, 'w', encoding='utf-8').write(text)
print('Reverted hub test')
