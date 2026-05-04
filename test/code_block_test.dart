import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/core/locator.dart';
import 'package:local_ai_chat/widgets/code_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Locator.resetForTest();
    _clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _clipboardText = args['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': _clipboardText};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('CodeBlock renders language label and copy button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeBlock(
            language: 'dart',
            code: 'final answer = 42;',
          ),
        ),
      ),
    );

    expect(find.text('dart'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(_richTextContains('final answer = 42'), isTrue);
  });

  testWidgets('CodeBlock copy button writes code to clipboard', (tester) async {
    const code = 'print("hello");';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeBlock(
            language: 'dart',
            code: code,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('copy-code-button')));
    await tester.pump();

    expect(find.text('已複製 code'), findsOneWidget);
    expect(_clipboardText, code);
  });

  testWidgets('Markdown code block builder does not break links',
      (tester) async {
    String? tappedHref;
    final codeBlockBuilder = CodeBlockBuilder();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            data: '''
[Citation](chunk:?doc=report.pdf&i=3)

```dart
final value = 1;
```
''',
            builders: {
              'pre': codeBlockBuilder,
              'code': codeBlockBuilder,
            },
            onTapLink: (text, href, title) {
              tappedHref = href;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.copy), findsOneWidget);
    await tester.tap(find.text('Citation'));

    expect(tappedHref, 'chunk:?doc=report.pdf&i=3');
  });

  testWidgets('Markdown builder supports plain fenced blocks and inline code',
      (tester) async {
    final codeBlockBuilder = CodeBlockBuilder();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            selectable: true,
            data: '''
Use `inline` here.

```
plain code
```
''',
            builders: {
              'pre': codeBlockBuilder,
              'code': codeBlockBuilder,
            },
          ),
        ),
      ),
    );

    expect(find.text('text'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(_richTextContains('plain code'), isTrue);
    expect(find.byKey(const Key('copy-code-button')), findsOneWidget);
  });

  testWidgets('CodeBlock supports dark theme and unknown languages',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: CodeBlock(
            language: 'madeuplang',
            code: 'plain fallback',
          ),
        ),
      ),
    );

    expect(find.text('madeuplang'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(_richTextContains('plain fallback'), isTrue);
  });
}

String? _clipboardText;

bool _richTextContains(String text) {
  return find
      .byType(RichText)
      .evaluate()
      .map((element) => element.widget)
      .whereType<RichText>()
      .any((widget) => widget.text.toPlainText().contains(text));
}
