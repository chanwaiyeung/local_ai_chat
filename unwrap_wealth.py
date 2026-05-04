import re

path = 'test/screens/wealth_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()

# Pattern to find blocks like:
#       await tester.runAsync(() async {
#         await controller.saveRecord(
#           ...
#         );
#       });
pattern = re.compile(r' {6}await tester\.runAsync\(\(\) async \{\n( {8}await controller\.saveRecord\([^;]+;\n) {6}\}\);\n', re.MULTILINE)

def replacer(match):
    block = match.group(1)
    # Dedent the block by 2 spaces
    dedented = '\n'.join(line[2:] if line.startswith('  ') else line for line in block.split('\n'))
    return dedented

text = pattern.sub(replacer, text)
open(path, 'w', encoding='utf-8').write(text)
print('Unwrapped all saves in wealth')
