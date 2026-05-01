# 智讀館 — Namespace Alignment Sprint Archive

| Field | Value |
|---|---|
| Status | Completed (2026-04-30) |
| Companion docs | `docs/v2_schema_v3_spec.md`、`docs/v2_test_rename_sprint.md`、`docs/v2_migration_to_d_drive.md` |
| Trigger | v2.0 promotion 後發現 `pubspec.yaml` `name:` 仍掛舊 ai_library_server，但 v2.0 派代碼全部 `import 'package:local_ai_chat/...'`，導致 `flutter pub get` 後所有 v2.0 派 test 在 import 階段就 fail |

## 1. 背景

`local_ai_chat` 專案有兩條歷史線：

| 來源 | 命名 | 狀態 |
|---|---|---|
| 早期 ai_library_server lite | `package:ai_library_server/...` | 已被 v2.0 promotion 取代，但 6 個舊 test + 2 個 bin 入口仍用此 prefix |
| v2.0 source（從 handoff_exports 整檔 promote） | `package:local_ai_chat/...` | 主流，含所有 controllers/screens/services/v2.0 派 tests |

`pubspec.yaml line 14` 早期是 `name: ai_library_server`，跟 v2.0 派代碼的 import prefix 對不上。Dart package resolution 用的是 pubspec.yaml 的 `name:` 欄位——所以 `package:local_ai_chat/...` 全部解不到，編譯紅燈。

## 2. 落地動作

### 2.1 `pubspec.yaml`（2 處改動）

| Line | 舊 | 新 |
|---|---|---|
| 14 | `name: ai_library_server` | `name: local_ai_chat` |
| 36（新增） | （不存在） | `path_provider: ^2.1.0` |

`path_provider` 是 promotion 之後 6 個 lib/ 檔案開始引用的（含 `vector_store.dart`），但 pubspec 一直沒有顯式宣告，靠 `flutter_tts` 的 transitive resolution 偶然能 build。**顯式化是技術債清理**——確保依賴契約穩定。

### 2.2 12 個 Dart 檔案的 import rewrite

以 `sed -i 's|package:ai_library_server/|package:local_ai_chat/|g'` 批量處理：

| 檔案 | 改動 import 數 |
|---|---|
| `bin/index.dart` | 4 |
| `bin/server.dart` | 5 |
| `test/api_client_test.dart` | 1 |
| `test/api_server_test.dart` | 5 |
| `test/document_loader_test.dart` | 1 |
| `test/library_screen_test.dart` | 3 |
| `test/reader_controller_test.dart` | 3 |
| `test/reader_screen_test.dart` | 3 |
| `test/reading_mode_screen_test.dart` | 3 |
| `test/text_chunker_test.dart` | 1 |
| `test/vector_store_test.dart` | 1 |
| `test/widget_test.dart` | 1 |
| **Total** | **31 imports across 12 files** |

## 3. 驗證結果

### 3.1 全 repo Dart import sweep（執行於 2026-04-30）

```
$ grep -rn "package:ai_library_server" --include='*.dart' .
(empty — clean ✓)

$ grep -rn "package:local_ai_chat" --include='*.dart' . | wc -l
80+ across lib/ + test/ + bin/
```

所有 Dart `import 'package:...'` 統一為 `local_ai_chat`，0 個殘留 `ai_library_server`。

### 3.2 pubspec 驗證

```
$ grep -nE "^name:|^  path_provider:" pubspec.yaml
14:name: local_ai_chat
36:  path_provider: ^2.1.0
```

### 3.3 非 Dart 檔案中殘留的 `ai_library_server` 字串（**非 blocker**）

| 檔案 | 內容 | 處置 |
|---|---|---|
| `lib/main.dart` line 86, 88 | `debugPrint('[ai_library_server] startup ...')` log 字串 | v2.1 brand sprint 順手清 |
| `pubspec.yaml` line 5 | bootstrap comment（`flutter create --project-name ai_library_server`） | cosmetic |
| `windows/CMakeLists.txt` line 3 | `project(ai_library_server LANGUAGES CXX)` | 影響 Windows .exe 名稱；下次 `flutter build windows` 前再處理 |
| `docs/v2_schema_v3_spec.md` line 158, 262 | 規格書中正確的歷史術語（描述被淘汰的舊架構） | **保留**——不要改 |
| `README.md`、`AI_HANDOFF.md`、`release_v2.0.0/README.md` | 專案介紹 / handoff 文件 | 文件更新 sprint |

## 4. Forbidden Changes（防退化清單）

| 規則 | 為什麼 |
|---|---|
| **不得**將 pubspec.yaml 的 `name:` 改回 `ai_library_server` | 會立即把 80+ 條 v2.0 派 import 全部打破 |
| **不得**移除 pubspec.yaml 的 `path_provider: ^2.1.0` 顯式宣告 | 會讓持久化邏輯重新依賴 transitive luck |
| **不得**在新增 import 時使用 `package:ai_library_server/...` | 整個專案的 namespace 已對齊到 `local_ai_chat`，新進的 mixed-namespace 會破壞一致性 |
| **不得**保留 `lib/services/text_chunker.dart` 的引用（已刪檔） | 任何嘗試「復活」此檔的 import 應改為呼叫 `RagService.chunk()` 靜態方法 |

## 5. 為什麼選擇對齊到 `local_ai_chat` 而不是 `ai_library_server`

當時的決策因素：

1. **代碼量**：v2.0 派的 import 80+ 條 vs 舊派 31 條。對齊到主流方向改動最少。
2. **release 名稱**：`release_notes.md` 與打包輸出已經是 `local_ai_chat.exe`（Windows release at `build/windows/x64/runner/Release/local_ai_chat.exe`）。`ai_library_server` 是早期 bootstrap 殘留。
3. **資料夾名稱**：`C:\dev\local_ai_chat` 與 `D:\dev\local_ai_chat`。
4. **使用者偏好**：「智讀館」對應 `local_ai_chat`，更貼近產品 brand。

## 6. References

- 此次 sprint 的執行對話：2026-04-30 session（含 12 檔 import diff、pre-flight grep、post-fix sweep）
- Schema v3 規格（為何需要 path_provider）：`docs/v2_schema_v3_spec.md` §2
- Test rename sprint（namespace 對齊後仍待修的 test 檔案）：`docs/v2_test_rename_sprint.md`
- 搬家後重新 `flutter pub get` 流程：`docs/v2_migration_to_d_drive.md` §4
