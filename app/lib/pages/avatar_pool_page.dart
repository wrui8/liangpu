import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';

class AvatarPoolPage extends StatefulWidget {
  const AvatarPoolPage({super.key});

  @override
  State<AvatarPoolPage> createState() => _AvatarPoolPageState();
}

class _AvatarPoolPageState extends State<AvatarPoolPage> {
  bool _requested = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadIcons();
    });
  }

  Future<void> _pick(String key) async {
    if (_busy) return;
    final app = AppScope.of(context);
    if (app.user?.avatarIcon == key) return;
    setState(() => _busy = true);
    try {
      await app.setAvatar(key);
      if (mounted) showToast(context, '头像已更换');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final icons = app.iconsOfKind('user');
    final current = app.user?.avatarIcon ?? '';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '选择头像',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            '从图标池里挑一个会动的人像，作为你在良扑的形象。',
            style: TextStyle(fontSize: 13, color: c.text2, height: 1.6),
          ),
          const SizedBox(height: 18),
          if (icons.isEmpty)
            const LoadingView()
          else
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                for (final LpIcon icon in icons)
                  _avatarCell(context, icon, current == icon.key),
              ],
            ),
        ],
      ),
    );
  }

  Widget _avatarCell(BuildContext context, LpIcon icon, bool selected) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: _busy ? null : () => _pick(icon.key),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(
                color: selected ? c.brand : c.line,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.brand.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: SvgPicture.string(icon.svg),
            ),
          ),
          if (selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.bg, width: 2),
                ),
                alignment: Alignment.center,
                child: SvgIcon(Ui.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
