import '../i18n.dart';

/// Simplified Chinese implementation of [FormixMessages].
class ChineseFormixMessages extends FormixMessages {
  const ChineseFormixMessages();

  @override
  String required(String label) => '$label是必填项';

  @override
  String invalidFormat() => '格式无效';

  @override
  String minLength(int minLength) => '最小长度为$minLength个字符';

  @override
  String maxLength(int maxLength) => '最大长度为$maxLength个字符';

  @override
  String minValue(num min) => '最小值为$min';

  @override
  String maxValue(num max) => '最大值为$max';

  @override
  String minDate(DateTime minDate) => '日期必须在${_formatDate(minDate)}之后';

  @override
  String maxDate(DateTime maxDate) => '日期必须在${_formatDate(maxDate)}之前';

  @override
  String invalidSelection() => '选择无效';

  @override
  String validationFailed(String error) => '验证失败：$error';

  @override
  String validating() => '正在验证...';

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
  }
}
