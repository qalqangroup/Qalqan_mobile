import 'package:flutter/material.dart';
import 'package:qalqan_dsm/l10n/app_localizations.dart';
import 'package:qalqan_dsm/routes/app_router.dart';
import '../../../core/key_access.dart';

class StartScreen extends StatefulWidget {
  final ValueChanged<Locale>? onLocaleChanged;

  const StartScreen({
    Key? key,
    this.onLocaleChanged,
  }) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _selectedKeyType;
  int _currentNavIndex = 0;

  static const _bottomNavHeight = 56.0;
  static const _spinnerWidth = 280.0;
  static const _spinnerHeight = 60.0;

  @override
  void initState() {
    super.initState();

    _selectedKeyType = KeyAccess.selected;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final keyTypes = [loc.all, loc.session];

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BottomNavigationBar(
          elevation: 8,
          backgroundColor: const Color(0x808A9AFF),
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF5869E5),
          unselectedItemColor: Colors.grey,
          onTap: _onNavTap,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.main),
            BottomNavigationBarItem(icon: const Icon(Icons.lock), label: loc.encrypt),
            BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble), label: loc.chat),
            BottomNavigationBarItem(icon: const Icon(Icons.lock_open), label: loc.decrypt),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: loc.profile),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _bottomNavHeight),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8A9AFF),
                  Color(0xFF3B4DFF),
                  Color(0xFF8A9AFF),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Выпадающий список
                Align(
                  alignment: Alignment.center,
                  child: _buildKeyPicker(keyTypes, loc.selectkeytype),
                ),

                // Кнопка Start — именно она "подтверждает" выбор
                Align(
                  alignment: const Alignment(0, 0.6),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: _spinnerWidth,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5869E5),
                          elevation: 8,
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'MontserratRegular',
                            fontSize: 20,
                          ),
                        ),
                        onPressed: () {
                          if (_selectedKeyType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.pleaseselectkeytype)),
                            );
                            return;
                          }
                          // Подтверждаем выбор глобально — теперь доступ в Encrypt разрешён
                          KeyAccess.completeSelection(_selectedKeyType!);

                          // Переходим в Encrypt, передаём выбранный тип
                          Navigator.of(context).pushNamed(
                            AppRouter.encrypt,
                            arguments: _selectedKeyType,
                          );
                        },
                        child: Text(
                          loc.start,
                          style: const TextStyle(
                            color: Color(0xBFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentNavIndex = 0);
        Navigator.of(context).pushNamed(AppRouter.start);
        break;

      case 1: // Encrypt — разрешаем только после Start
        if (!KeyAccess.isReady) {
          // остаёмся на текущей вкладке
          return;
        }
        setState(() => _currentNavIndex = 1);
        Navigator.of(context).pushNamed(
          AppRouter.encrypt,
          arguments: KeyAccess.selected,
        );
        break;

      case 2:
        setState(() => _currentNavIndex = 2);
        Navigator.of(context).pushNamed(AppRouter.login);
        break;

      case 3:
        setState(() => _currentNavIndex = 3);
        Navigator.of(context).pushNamed(AppRouter.decrypt);
        break;

      case 4:
        setState(() => _currentNavIndex = 4);
        Navigator.of(context).pushNamed(AppRouter.init);
        break;
    }
  }

  Widget _buildKeyPicker(List<String> options, String hint) {
    return SizedBox(
      width: _spinnerWidth,
      height: _spinnerHeight,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.3),
        child: PopupMenuButton<String>(
          initialValue: _selectedKeyType,
          padding: EdgeInsets.zero,
          offset: const Offset(0, _spinnerHeight),
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          onSelected: (value) => setState(() => _selectedKeyType = value),
          itemBuilder: (_) => options.map<PopupMenuEntry<String>>((option) {
            return PopupMenuItem<String>(
              value: option,
              height: 48,
              child: SizedBox(
                width: 300,
                child: Center(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: _spinnerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  _selectedKeyType ?? hint,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0x80FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


