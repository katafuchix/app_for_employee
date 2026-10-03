// utils/image_compress_helper.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCompressHelper {
  /// 画像を圧縮して新しいFileを返す
  /// 圧縮に失敗した場合は元のFileをそのまま返す
  static Future<File> compressImage(File file) async {
    try {
      // 一時ディレクトリのパスを取得
      final dir = await getTemporaryDirectory();
      // 圧縮後の保存先パスを生成（一意なファイル名にする）
      final targetPath =
          '${dir.absolute.path}/${const Uuid().v4()}_compressed.jpg';

      // 圧縮実行
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 画質 (0〜100)。70〜80が容量と見た目のバランスが良いです
        minWidth: 1024, // リサイズ後の最大幅
        minHeight: 1024, // リサイズ後の最大高さ
      );

      // 圧縮成功なら圧縮後のFileを、失敗(null)なら元のFileを返す
      return result != null ? File(result.path) : file;
    } catch (e) {
      // エラー時もとりあえず元のファイルを返してアップロードを継続させる
      return file;
    }
  }
}
