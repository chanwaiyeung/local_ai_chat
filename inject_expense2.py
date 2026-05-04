path = 'lib/controllers/expense_controller.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('await _vectorStore.deleteById(expense.id);', 'print("deleteById"); await _vectorStore.deleteById(expense.id);')
text = text.replace('await _vectorStore.add(chunk, _generateDummyEmbedding(chunk.text));', 'print("addChunk"); await _vectorStore.add(chunk, _generateDummyEmbedding(chunk.text)); print("doneAdd");')
text = text.replace('await getAllExpenses();', 'print("getAll"); await getAllExpenses(); print("doneAll");')
open(path, 'w', encoding='utf-8').write(text)
print('Injected 2')
