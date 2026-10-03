import 'package:flutter/material.dart';
import '../message_colors.dart';

/// モーダルのトップハンドル（ドラッグバー）
class ModalHandle extends StatelessWidget {
  const ModalHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 3,
      decoration: BoxDecoration(
        color: MessageColors.subtitle.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

/// アイコン付きバッジ（チェック、アナウンス、削除など）
class IconBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const IconBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: MessageColors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: MessageTextStyles.badgeText,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// カプセル型バッジ（遅延中、共有など）
class CapsuleBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const CapsuleBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: MessageTextStyles.badgeText,
      ),
    );
  }
}

/// プロフィール画像プレースホルダー
class ProfilePlaceholder extends StatelessWidget {
  final double size;

  const ProfilePlaceholder({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MessageColors.subtitle.withOpacity(0.2),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: MessageColors.subtitle,
      ),
    );
  }
}

/// 数値+単位を表示するウィジェット
class UnitText extends StatelessWidget {
  final String number;
  final String unit;
  final TextStyle? numberStyle;
  final TextStyle? unitStyle;
  final MainAxisAlignment alignment;

  const UnitText({
    super.key,
    required this.number,
    required this.unit,
    this.numberStyle,
    this.unitStyle,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          number,
          style: numberStyle ?? MessageTextStyles.numberMedium,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          unit,
          style: unitStyle ?? MessageTextStyles.unitTextSmall,
        ),
      ],
    );
  }
}

/// 水平divider
class HorizontalDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const HorizontalDivider({
    super.key,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
      ),
      decoration: BoxDecoration(
        color: MessageColors.subtitle.withOpacity(0.2),
      ),
    );
  }
}

/// カメラアイコン付きサークル（アクション表示用）
class CameraIconCircle extends StatelessWidget {
  final double size;

  const CameraIconCircle({
    super.key,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MessageColors.subtitle.withOpacity(0.1),
      ),
      child: Icon(
        Icons.camera_alt,
        size: size * 0.45,
        color: MessageColors.checkOrange,
      ),
    );
  }
}
