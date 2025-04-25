import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  DecimalTextInputFormatter({required this.decimalDigits}) : assert(decimalDigits >= 0);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String newText = newValue.text;

    // Step 1: 过滤非法字符
    final allowedChars = decimalDigits > 0 ? r'[\d.-]' : r'[\d-]';
    newText = newText.replaceAll(RegExp('[^$allowedChars]'), '');

    // Step 2: 处理负号
    bool hasNegative = newText.contains('-');
    newText = newText.replaceAll('-', '');
    if (hasNegative) {
      newText = '-$newText'; // 负号只能出现在开头
      if (newText.startsWith('--')) newText = '-${newText.substring(2)}'; // 处理多个负号
    }

    // Step 3: 处理小数点逻辑（关键修复部分）
    if (decimalDigits > 0) {
      final dotIndex = newText.indexOf('.');
      if (dotIndex != -1) {
        // 保留第一个小数点并移除多余的点
        final beforeDot = newText.substring(0, dotIndex);
        final afterDot = newText.substring(dotIndex + 1).replaceAll('.', '');
        newText = '$beforeDot.${afterDot.isEmpty ? '' : afterDot}'; // 允许单独的小数点

        // 处理前导零
        if (newText.startsWith('.') && newText.length > 1) {
          newText = '0$newText';
        } else if (newText.startsWith('-.')) {
          newText = '-0${newText.substring(1)}';
        }
      }
    }

    // Step 4: 分割整数和小数部分
    List<String> parts = newText.split('.');

    // Step 5: 小数位数处理（修复核心问题）
    String integerPart = parts[0].replaceAll(RegExp(r'[^-\d]'), '');
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalDigits > 0) {
      decimalPart = decimalPart.length > decimalDigits
          ? decimalPart.substring(0, decimalDigits)
          : decimalPart;

      // 关键修改：允许保留单独的小数点
      newText = parts.length > 1
          ? '$integerPart.$decimalPart'
          : integerPart;
    } else {
      newText = integerPart;
    }

    // Step 6: 处理无效状态
    if (newText == '-' || newText.isEmpty) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    // Step 7: 优化前导零和负号
    if (newText.startsWith('-0') &&
        !newText.startsWith('-0.') &&
        newText.length > 2) {
      newText = '-${newText.substring(2)}';
    } else if (newText.startsWith('0') &&
        newText.length > 1 &&
        !newText.startsWith('0.')) {
      newText = newText.substring(1);
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}