import 'dart:convert';
import '../models/book.dart';
import 'ai_router_service.dart';

class BookAiService {
  final AiRouterService aiRouter;

  BookAiService(this.aiRouter);

  // 1. 書籍分類與標籤生成 (本地端 LLM + JSON 輸出)
  Future<Map<String, dynamic>> classifyBook(Book book) async {
    final description = book.notes.isNotEmpty ? book.notes : (book.metadata['description']?.toString() ?? '');
    final prompt = """
請根據書名、作者、簡介，產生分類與標籤（JSON 格式）。
書名：${book.title}
作者：${book.author}
簡介：$description
""";
    return await aiRouter.localLlmJson(prompt);
  }

  // 2. 篇章摘要 (本地端 LLM)
  Future<String> summarizeChapter(String text) async {
    return await aiRouter.localLlm("請摘要以下內容：$text");
  }

  // 3. 針對書籍內容提問 (本地端 RAG 檢索增強生成)
  Future<String> askBookQuestion(Book book, String question) async {
    return await aiRouter.localRag(question: question, bookId: book.id);
  }

  // 4. 深度解說 (雲端 LLM，處理較複雜的上下文)
  Future<String> deepExplain(String question, List<String> context) async {
    final prompt = """
以下是書籍內容的相關段落：
${context.join("\n\n")}
請提供深入解說：
問題：$question
""";
    return await aiRouter.cloudLlm(prompt);
  }

  /// 自動生成段落註解（特化為語言學習/日語）
  Future<List<Map<String, dynamic>>> generateAutoNotes(String paragraph) async {
    try {
      final prompt = '''
你是一位專業的日語教師。請分析以下日文段落，挑選出 3 到 5 個最重要或進階的單字/文法。
請嚴格以 JSON 陣列格式回傳，不要包含其他說明文字。格式如下：
[
  {"word": "單字/文法", "reading": "平假名讀音", "meaning": "繁體中文解釋", "explanation": "簡單的用法說明"}
]

段落內容：
$paragraph
''';
      // 呼叫雲端模型以獲取最準確的日文解析
      final responseText = await aiRouter.cloudLlm(prompt); 
      
      // 這裡簡單實作 JSON 剝離
      String cleanJson = responseText;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json')[1].split('```')[0].trim();
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
      }
      
      final start = cleanJson.indexOf('[');
      final end = cleanJson.lastIndexOf(']');
      if (start != -1 && end != -1 && end >= start) {
        cleanJson = cleanJson.substring(start, end + 1);
      }
      
      final List<dynamic> parsed = jsonDecode(cleanJson) as List<dynamic>;
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("註解生成失敗: $e");
    }
  }
}


