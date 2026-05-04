path1 = 'lib/models/wealth_record.dart'
text1 = open(path1, 'r', encoding='utf-8').read()
open(path1, 'a', encoding='utf-8').write('\n' + '// padding\n' * 30)

path2 = 'test/screens/wealth_screen_test.dart'
text2 = open(path2, 'r', encoding='utf-8').read()
open(path2, 'a', encoding='utf-8').write('\n' + '// padding\n' * 40)

print('Padded')
