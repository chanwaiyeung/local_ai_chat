path = 'test/controllers/wealth_controller_test.dart'
text = open(path, 'r', encoding='utf-8').read()
text = text.replace('WealthController.collectionName', 'WealthController.kWealthCollection')
text = text.replace('kDefaultCollection', "'default'")
open(path, 'w', encoding='utf-8').write(text)
