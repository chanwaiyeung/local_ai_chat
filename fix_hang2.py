def patch_file(path):
    text = open(path, 'r', encoding='utf-8').read()
    text = text.replace('if (await tempDir.exists()) // await tempDir.delete(recursive: true);', '// if (await tempDir.exists()) await tempDir.delete(recursive: true);')
    open(path, 'w', encoding='utf-8').write(text)

patch_file('test/screens/wealth_screen_test.dart')
print('Fixed syntax error')
