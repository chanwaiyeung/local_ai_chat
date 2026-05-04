import os
base = r'C:\Users\Albert Chan\AppData\Roaming\Claude\local-agent-mode-sessions\946d354c-b95f-4ec3-b49e-9593c916e07f\5a82c4bc-192a-44d0-b75f-bd66de1bacf3\local_98727912-beb1-4e29-b9cf-c9038277739c\outputs'
dest = r'c:\dev\local_ai_chat'
files = {
    'wealth_controller.dart': r'lib\controllers\wealth_controller.dart',
    'wealth_record.dart': r'lib\models\wealth_record.dart',
    'wealth_screen.dart': r'lib\screens\wealth_screen.dart',
    'wealth_controller_test.dart': r'test\controllers\wealth_controller_test.dart',
    'wealth_screen_test.dart': r'test\screens\wealth_screen_test.dart',
}
for src_name, dst_rel in files.items():
    src_path = os.path.join(base, src_name)
    dst_path = os.path.join(dest, dst_rel)
    text = open(src_path, 'r', encoding='utf-8').read()
    text = text.replace('\r\n', '\n').replace('\n', '\r\n')
    open(dst_path, 'w', encoding='utf-8').write(text)
print('Done')
