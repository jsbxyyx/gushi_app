import 'package:flutter/services.dart';

class NumberTextInputFormatter extends TextInputFormatter {
  NumberTextInputFormatter({
    this.inputScope = "-.0123456789",
    this.digit,
    this.min,
    this.max,
    this.isNegative = true,
  });

  String inputScope;
  final double? min;
  final double? max;
  final int? digit;
  final bool isNegative;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    TextEditingValue _newValue = sanitize(newValue);
    String text = _newValue.text;

    // 处理保留0位小数时移除小数点（原有逻辑）
    if (digit == 0) {
      text = text.replaceAll('.', '');
      _newValue = _newValue.copyWith(text: text);
    }

    // 处理单独的小数点输入（原有逻辑）
    if (text == '.') {
      return TextEditingValue(
        text: '0.',
        selection: const TextSelection.collapsed(offset: 2),
        composing: TextRange.empty,
      );
    }

    // 有效性检查（新增中间状态处理）
    if (!isValid(text)) {
      return oldValue;
    }

    // 数值范围处理（优化中间状态保留）
    if (text.isNotEmpty && text != '-') {
      final parsedValue = double.tryParse(text);
      if (parsedValue == null) return oldValue;

      // 范围修正
      double adjustedValue = parsedValue;
      if (min != null && adjustedValue < min!) adjustedValue = min!;
      if (max != null && adjustedValue > max!) adjustedValue = max!;

      // 判断是否需要保留输入状态
      final shouldPreserveInput = _shouldPreserveInputState(
        originalText: text,
        parsedValue: parsedValue,
        adjustedValue: adjustedValue,
      );

      // 生成最终文本
      String adjustedText = shouldPreserveInput
          ? text // 保留原始输入
          : _formatNumber(adjustedValue); // 应用格式

      // 处理文本差异
      if (adjustedText != text) {
        return TextEditingValue(
          text: adjustedText,
          selection: TextSelection.collapsed(offset: adjustedText.length),
          composing: TextRange.empty,
        );
      }
    }

    return _newValue;
  }

  bool _shouldPreserveInputState({
    required String originalText,
    required double parsedValue,
    required double adjustedValue,
  }) {
    // 值未修正且处于中间状态时保留输入
    if (parsedValue == adjustedValue) {
      final hasDecimal = originalText.contains('.');
      if (hasDecimal) {
        final decimalPart = originalText.split('.')[1];
        // 允许小数位数未满的情况（如输入0.0时保留）
        return decimalPart.length < (digit ?? 0) || originalText.endsWith('.');
      }
    }
    return false;
  }

  String _formatNumber(double value) {
    if (digit == 0) {
      return value.toInt().toString();
    }
    // 使用智能补零策略
    final formatted = value.toStringAsFixed(digit!);
    // 移除多余的小数点（当digit=0时）
    return digit! > 0 ? formatted : formatted.split('.').first;
  }

  bool isValid(String text) {
    // 允许空输入
    if (text.isEmpty) return true;

    // 检查字符合法性
    for (int i = 0; i < text.length; i++) {
      if (!inputScope.contains(text[i])) return false;
    }

    // 处理负号检查
    if (text.contains('-')) {
      if (!isNegative || text.indexOf('-') != 0 || text.lastIndexOf('-') != 0) {
        return false;
      }
    }

    // 处理小数检查
    List<String> parts = text.split('.');
    if (parts.length > 2) return false;

    // 当限制0位小数时
    if (digit == 0) {
      if (parts.length > 1) return false;
    }
    // 限制小数位数
    else if (parts.length == 2 && parts[1].length > (digit ?? 0)) {
      return false;
    }

    return true;
  }

  TextEditingValue sanitize(TextEditingValue value) {
    String text = value.text;

    // 处理负号
    if (isNegative) {
      bool hasNegative = text.startsWith('-');
      text = text.replaceAll('-', '');
      if (hasNegative) text = '-$text';
    } else {
      text = text.replaceAll('-', '');
    }

    return TextEditingValue(
      text: text,
      selection: value.selection,
      composing: TextRange.empty,
    );
  }
}