import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/app_settings_service.dart';
import '../../services/book_vision_service.dart';
import 'book_metadata_section.dart';

/// Cover vision scan flow; parent dialog invokes this after picker returns.
Future<void> bookFormScanCover(
  BuildContext context, {
  required TextEditingController titleCtrl,
  required TextEditingController authorCtrl,
  required TextEditingController publisherCtrl,
  required TextEditingController yearCtrl,
  required TextEditingController coverUrlCtrl,
  required TextEditingController isbnCtrl,
  required void Function(bool) setScanning,
  required VoidCallback notify,
}) async {
  final image = await BookCoverSection.pickCoverImage(context);
  if (image == null) return;
  final apiKey = (await AppSettingsService().load()).geminiApiKey?.trim();
  if (apiKey == null || apiKey.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請先前往 Settings 設定 Gemini API Key')),
    );
    return;
  }
  setScanning(true);
  notify();
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('AI 正在辨識封面...\n這可能需要幾秒鐘'),
        ],
      ),
    ),
  );
  try {
    final book = await BookVisionService.scanFromImage(
      image.path,
      apiKey: apiKey,
    ).timeout(const Duration(seconds: 35));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法從圖片辨識書籍資料')),
      );
      return;
    }
    final n = fillEmptyMetadataFromBook(
      book,
      titleCtrl: titleCtrl,
      authorCtrl: authorCtrl,
      publisherCtrl: publisherCtrl,
      yearCtrl: yearCtrl,
      coverUrlCtrl: coverUrlCtrl,
      isbnCtrl: isbnCtrl,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n == 0
          ? '找不到可填入的欄位（可能都已手動填寫）'
          : '已從封面圖自動填入 $n 個欄位'),
    ));
    notify();
  } catch (e) {
    if (context.mounted) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('辨識失敗: $e')),
      );
    }
  } finally {
    setScanning(false);
    if (context.mounted) notify();
  }
}

/// Cover URL field, scan/OCR trigger, and Windows-safe image picker flow.
class BookCoverSection extends StatelessWidget {
  const BookCoverSection({
    super.key,
    required this.coverUrlCtrl,
    required this.scanningCover,
    required this.onScanCover,
  });

  final TextEditingController coverUrlCtrl;
  final bool scanningCover;
  final VoidCallback onScanCover;

  /// Returns a picked image file, or null if cancelled / failed.
  static Future<XFile?> pickCoverImage(BuildContext context) async {
    final picker = ImagePicker();
    return showDialog<XFile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('掃描封面'),
        content: const Text('請選擇圖片來源'),
        actions: [
          if (!Platform.isWindows)
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('拍照'),
              onPressed: () async {
                try {
                  final img = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 90,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, img);
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx, null);
                }
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('從相簿選擇'),
            onPressed: () async {
              try {
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 90,
                );
                if (ctx.mounted) Navigator.pop(ctx, img);
              } catch (_) {
                if (ctx.mounted) Navigator.pop(ctx, null);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            icon: scanningCover
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(scanningCover ? '辨識中...' : '拍照/選圖辨識封面'),
            onPressed: scanningCover ? null : onScanCover,
          ),
        ),
        TextFormField(
          controller: coverUrlCtrl,
          decoration: const InputDecoration(labelText: 'Cover image URL'),
        ),
      ],
    );
  }
}


