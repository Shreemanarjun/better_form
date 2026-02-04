import '../i18n.dart';

/// Simplified Chinese implementation of [FormixMessages].
class ChineseFormixMessages extends FormixMessages {
  /// Creates a [ChineseFormixMessages].
  const ChineseFormixMessages();

  @override
  String required(String label) => '$label是必填项';

  @override
  String invalidFormat() => '格式无效';

  @override
  String minLength(String label, int minLength) => '$label最小长度为$minLength个字符';

  @override
  String maxLength(String label, int maxLength) => '$label最大长度为$maxLength个字符';

  @override
  String minValue(String label, num min) => '$label最小值为$min';

  @override
  String maxValue(String label, num max) => '$label最大值为$max';

  @override
  String minDate(String label, DateTime minDate) => '$label日期必须在${_formatDate(minDate)}之后';

  @override
  String maxDate(String label, DateTime maxDate) => '$label日期必须在${_formatDate(maxDate)}之前';

  @override
  String invalidSelection(String label) => '$label选择无效';

  @override
  String validationFailed(String error) => '验证失败：$error';

  @override
  String validating() => '正在验证...';

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }
}
