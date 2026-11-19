import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import 'cover.dart';

/// 顶栏（可带字标 / 标题）
class LpAppBar extends StatelessWidget {
  final String? title;
  final bool logo;
  final Widget? leading;
  final List<Widget> actions;

  const LpAppBar({
    super.key,
    this.title,
    this.logo = false,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 20, right: 10),
      color: c.bg,
      child: Row(
        children: [
          ?leading,
          Expanded(
            child: logo
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '良扑',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: c.brand,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4, bottom: 12),
                        decoration: BoxDecoration(
                          color: c.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  )
                : Text(
                    title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: c.text1,
                    ),
                  ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class IconBtn extends StatelessWidget {
  final String svg;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  const IconBtn(
    this.svg, {
    super.key,
    this.onTap,
    this.size = 21,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SvgIcon(svg, size: size, color: color ?? c.text1),
        ),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return IconBtn(
      app.dark ? Ui.sun : Ui.moon,
      onTap: app.toggleTheme,
    );
  }
}

/// 横向滚动筛选 chips
class ChipBar extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final EdgeInsets padding;

  const ChipBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                  decoration: BoxDecoration(
                    color: o == value ? c.brand : c.surface,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: o == value
                        ? [
                            BoxShadow(
                              color: c.brand.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : kShadowLight,
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          o == value ? FontWeight.w700 : FontWeight.w500,
                      color: o == value ? Colors.white : c.text2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHead extends StatelessWidget {
  final String title;
  final String? more;
  final VoidCallback? onTapMore;
  final EdgeInsets padding;

  const SectionHead({
    super.key,
    required this.title,
    this.more,
    this.onTapMore,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: c.text1,
            ),
          ),
          const Spacer(),
          if (more != null)
            GestureDetector(
              onTap: onTapMore,
              behavior: HitTestBehavior.opaque,
              child: Text(
                more!,
                style: TextStyle(fontSize: 12, color: c.text3),
              ),
            ),
        ],
      ),
    );
  }
}

/// 详情页小节标题：红竖条 + 标题
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 15,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: c.text1,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String text;
  final bool red;

  const TagChip(this.text, {super.key, this.red = false});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: red ? c.brandSoft : c.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: red ? Colors.transparent : c.line,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: red ? FontWeight.w600 : FontWeight.w500,
          color: red ? c.brand : c.text2,
        ),
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  final String text;

  const PillTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.brand,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool pill;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.pill = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(pill ? 999 : 14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const EmptyView({
    super.key,
    this.icon = '💬',
    required this.title,
    this.desc = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 70),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: kShadowLight,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.text1,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.7, color: c.text3),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 70),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: kShadowLight,
            ),
            alignment: Alignment.center,
            child: const Text('📡', style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.7, color: c.text2),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.line),
                ),
                child: Text(
                  '重新加载',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class FootNote extends StatelessWidget {
  final String text;

  const FootNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: c.text3),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;

  const MenuRow({
    super.key,
    required this.label,
    this.trailing,
    this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: c.text1),
            ),
            const Spacer(),
            trailing ?? SvgIcon(Ui.chevronRight, size: 14, color: c.text3),
          ],
        ),
      ),
    );
  }
}

class LpSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LpSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? c.brand : c.line,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 快捷 toast
void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// 编辑服务器地址（保存后清空登录态并重新拉取图标）
Future<bool> showServerDialog(BuildContext context) async {
  final app = AppScope.of(context);
  final c = LpColors.of(context);
  final ctrl = TextEditingController(text: app.serverUrl);
  String? err;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: const Text('服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: c.text1),
              decoration: const InputDecoration(
                hintText: '服务器地址请向运维获取',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                err ?? '修改地址会退出当前账号',
                style: TextStyle(
                  fontSize: 12,
                  color: err != null ? c.brand : c.text3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await app.setServer(ctrl.text);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              } on ApiException catch (e) {
                setDlg(() => err = e.message);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  if (ok == true) {
    app.loadIcons(force: true);
  }
  return ok == true;
}

/// 统一错误文案
String errText(Object e) => e is ApiException ? e.message : '$e';
