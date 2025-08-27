/// Простая "память" подтверждённого выбора ключа.
/// Становится true только после нажатия на кнопку Start.
class KeyAccess {
  static String? _selectedKeyType;

  static bool get isReady => _selectedKeyType != null;
  static String? get selected => _selectedKeyType;

  static void completeSelection(String type) {
    _selectedKeyType = type;
  }

  static void reset() {
    _selectedKeyType = null;
  }
}