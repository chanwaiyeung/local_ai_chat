import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/core/locator.dart';
import 'package:local_ai_chat/screens/doc_viewer_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await Locator.resetForTest();
    tempDir = Directory.systemTemp.createTempSync('doc_viewer_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('DocViewer opens with initial chunk index and highlights it',
      (tester) async {
    final store = VectorStore()
      ..add(_chunk('Intro content.', index: 0))
      ..add(_chunk('Important cited content here.', index: 5));

    await tester.pumpWidget(
      MaterialApp(
        home: DocViewerScreen(
          store: store,
          docName: 'test.pdf',
          initialChunkIndex: 5,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('片段 #5'), findsOneWidget);

    final highlightedTile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('片段 #5'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(highlightedTile.tileColor, const Color(0xFFFFF3B0));
  });
}

DocChunk _chunk(String text, {required int index}) {
  return DocChunk(
    id: 'test_$index',
    docName: 'test.pdf',
    chunkIndex: index,
    text: text,
    embedding: const [1, 0, 0],
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}
