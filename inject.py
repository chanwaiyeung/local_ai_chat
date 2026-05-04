path = 'test/screens/personal_hub_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace("await expenseController.saveExpense(Expense(", "print('1'); await expenseController.saveExpense(Expense(")
text = text.replace("await tester.pumpWidget(hostFor());", "print('2'); await tester.pumpWidget(hostFor()); print('3');")
open(path, 'w', encoding='utf-8').write(text)
print('Injected')
