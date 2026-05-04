import re

path = 'test/screens/personal_hub_screen_test.dart'
text = open(path, 'r', encoding='utf-8').read()

# First revert the file to a clean state
import os
os.system('git checkout test/screens/personal_hub_screen_test.dart')
text = open(path, 'r', encoding='utf-8').read()

# Pattern to find blocks like:
# await somethingController.saveSomething(
#   ...
# );
pattern = re.compile(r'( {4}await \w+Controller\.save[A-Za-z]+\([^;]+;\n)', re.MULTILINE)

def replacer(match):
    block = match.group(1)
    # Indent the block by 2 spaces
    indented = '\n'.join('  ' + line if line.strip() else line for line in block.split('\n'))
    return f'    await tester.runAsync(() async {{\n{indented}    }});\n'

text = pattern.sub(replacer, text)
open(path, 'w', encoding='utf-8').write(text)
print('Wrapped all saves')
