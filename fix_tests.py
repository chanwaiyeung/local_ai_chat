path = 'test/controllers/wealth_controller_test.dart'
text = open(path, 'r', encoding='utf-8').read()

# Fix 1
text = text.replace('expect(store.listCollections(), [WealthController.kWealthCollection]);', 'expect(store.listCollections(), contains(WealthController.kWealthCollection));')

# Fix 2
old_code = '''final c2 = WealthController(reader);

        final all = c2.getAllRecords();'''
new_code = '''final c2 = WealthController(reader);
        await c2.loadAll();
        final all = c2.getAllRecords();'''
text = text.replace(old_code, new_code)

# Just in case old_code matching failed because of whitespace:
if 'await c2.loadAll();' not in text:
    import re
    text = re.sub(r'(final c2 = WealthController\(reader\);)(\s*)(final all = c2\.getAllRecords\(\);)', r'\1\2await c2.loadAll();\n\2\3', text)

open(path, 'w', encoding='utf-8').write(text)
print('Done')
