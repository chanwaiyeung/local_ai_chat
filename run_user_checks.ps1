Write-Host "--- 1. 三檔行數 + 關鍵常數檢查 ---"
Get-Content lib\controllers\wealth_controller.dart | Measure-Object -Line | Select-Object -ExpandProperty Lines
Select-String -Path pubspec.yaml -Pattern '^version:'
Select-String -Path lib\controllers\wealth_controller.dart -Pattern "kWealthCollection"

Write-Host "--- 2. 確保沒有 cache 污染後跑 analyze ---"
C:\src\flutter\flutter\bin\flutter.bat clean
C:\src\flutter\flutter\bin\flutter.bat pub get
C:\src\flutter\flutter\bin\flutter.bat analyze 2>&1 | Tee-Object analyze_output.txt; Get-Content analyze_output.txt | Select-Object -Last 5

Write-Host "--- 3. 跑 test ---"
C:\src\flutter\flutter\bin\flutter.bat test --reporter=expanded 2>&1 | Tee-Object test_output.txt; Get-Content test_output.txt | Select-Object -Last 5
