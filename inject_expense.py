path = 'lib/controllers/expense_controller.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('Future<void> saveExpense(Expense expense) async {', 'Future<void> saveExpense(Expense expense) async { print("save1");')
text = text.replace('_setLoading(true);', '_setLoading(true); print("save2");')
text = text.replace('try {', 'try { print("save3");')
text = text.replace('await _vectorStore.addToCollection(', 'print("save4"); await _vectorStore.addToCollection(')
text = text.replace('await loadAll();', 'print("save5"); await loadAll(); print("save6");')
open(path, 'w', encoding='utf-8').write(text)
print('Injected expense')
