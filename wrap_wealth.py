import re

path = 'test/screens/wealth_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()

# Pattern to find blocks like:
# await controller.saveRecord(
#   ...
# );
pattern = re.compile(r'( {6}await controller\.saveRecord\([^;]+;\n)', re.MULTILINE)

def replacer(match):
    block = match.group(1)
    # Indent the block by 2 spaces
    indented = '\n'.join('  ' + line if line.strip() else line for line in block.split('\n'))
    return f'      await tester.runAsync(() async {{\n{indented}      }});\n'

text = pattern.sub(replacer, text)
open(path, 'w', encoding='utf-8').write(text)
print('Wrapped all saves in wealth')
