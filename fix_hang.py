def patch_file(path):
    text = open(path, 'r', encoding='utf-8').read()
    text = text.replace('await tempDir.delete(recursive: true);', '// await tempDir.delete(recursive: true);')
    open(path, 'w', encoding='utf-8').write(text)

patch_file('test/screens/personal_hub_screen_test.dart')
patch_file('test/screens/wealth_screen_test.dart')
print('Fixed hangs')
