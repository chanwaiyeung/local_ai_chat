"--- A ---"
Get-Content lib\controllers\wealth_controller.dart | Measure-Object -Line
Get-Content lib\models\wealth_record.dart | Measure-Object -Line
Get-Content lib\screens\wealth_screen.dart | Measure-Object -Line
Get-Content test\controllers\wealth_controller_test.dart | Measure-Object -Line
Get-Content test\screens\wealth_screen_test.dart | Measure-Object -Line

"--- B ---"
Select-String -Path pubspec.yaml -Pattern '^version:'

"--- C ---"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "kWealthCollection"

"--- D ---"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "loadAll\("
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "getCurrentTotalByCurrency"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "getNetWorthHistory"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "getStats"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "getCurrencies"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "count "
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "latestPerAsset"
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "deleteAllRecords"

"--- E ---"
C:\src\flutter\flutter\bin\flutter.bat analyze > analyze_output.txt 2>&1
Get-Content analyze_output.txt -Tail 5

"--- F ---"
C:\src\flutter\flutter\bin\flutter.bat test --reporter=expanded > test_output.txt 2>&1
Get-Content test_output.txt -Tail 8
