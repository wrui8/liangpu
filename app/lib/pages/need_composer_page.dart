import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/image_compress.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import '../widgets/remote_image.dart';

const _roles = ['提议', '负责', '参与'];
const _categoryHints = ['办公效率', '财务流程', '网络环境', '数据报表'];

class _NeedImage {
  /// 编辑时保留的旧图（/uploads/xxx.jpg）
  final String? url;

  /// 新选择的图片（已压缩）
  final Uint8List? bytes;

  const _NeedImage.url(String this.url) : bytes = null;
  const _NeedImage.bytes(Uint8List this.bytes) : url = null;
}

class _SelMember {
  final int employeeId;
  final String name;
  final String? iconKey;
  final String color1;
  final String color2;
  String role;

  _SelMember({
    required this.employeeId,
    required this.name,
    required this.iconKey,
    required this.color1,
    required this.color2,
    this.role = '参与',
  });
}

/// 发布 / 编辑需求。新需求直接进入「评审中」，评分由全员打分产生。
class NeedComposerPage extends StatefulWidget {
  /// 编辑模式传入原需求（需来自详情接口，members 含完整员工信息）
  final Need? initial;

  const NeedComposerPage({super.key, this.initial});

  @override
  State<NeedComposerPage> createState() => _NeedComposerPageState();
}

class _NeedComposerPageState extends State<NeedComposerPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _tagsCtrl;

  final _picker = ImagePicker();
  final List<_NeedImage> _images = [];
  final List<_SelMember> _members = [];
  int? _teamId;

  List<Employee>? _allEmployees;
  bool _membersLoading = false;
  bool _saving = false;

  /// 进入页面时的内容快照，用于判断是否有未保存的修改
  late final String _initSnapshot;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final n = widget.initial;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _descCtrl = TextEditingController(text: n?.desc ?? '');
    _catCtrl = TextEditingController(text: n?.category ?? '');
    _tagsCtrl = TextEditingController(text: (n?.tags ?? const []).join(' '));
    _teamId = n?.teamId;
    for (final url in n?.images ?? const <String>[]) {
      _images.add(_NeedImage.url(url));
    }
    for (final m in n?.members ?? const <NeedMember>[]) {
      _members.add(
        _SelMember(
          employeeId: m.employeeId,
          name: m.name,
          iconKey: m.iconKey,
          color1: m.color1,
          color2: m.color2,
          role: m.role,
        ),
      );
    }
    _initSnapshot = _snapshot();
  }

  /// 当前编辑内容的快照：标题、描述、分类、标签、团队、成员、配图
  String _snapshot() => [
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
        _catCtrl.text.trim(),
        _tags.join('|'),
        _teamId?.toString() ?? '',
        _members.map((m) => '${m.employeeId}:${m.role}').join(','),
        _images
            .map((i) => i.url ?? '@new')
            .join(','),
      ].join('');

  bool get _dirty => _snapshot() != _initSnapshot;

  /// 离开前确认：有未保存修改时弹窗询问
  Future<void> _askLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = LpColors.of(ctx);
        return AlertDialog(
          title: const Text('放弃本次编辑？'),
          content: const Text('离开后未保存的内容将会丢失。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('继续编辑'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('放弃离开', style: TextStyle(color: c.brand)),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    /* 编辑时团队列表可能尚未加载，补拉一次以正确显示团队名 */
    if (_teamId != null) AppScope.of(context).loadTeams();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  List<String> get _tags => _tagsCtrl.text
      .split(RegExp(r'[,，、\s]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .take(6)
      .toList();

  Future<void> _pickImages() async {
    if (_images.length >= 4) {
      showToast(context, '最多上传 4 张图片');
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      if (raw.length > 25 * 1024 * 1024) {
        if (mounted) showToast(context, '图片过大，请换一张');
        return;
      }
      final small = await compute(compressImage, raw);
      if (!mounted) return;
      setState(() => _images.add(_NeedImage.bytes(small)));
    } catch (_) {
      if (mounted) showToast(context, '选择图片失败，请重试');
    }
  }

  Future<List<Employee>> _ensureEmployees() async {
    if (_allEmployees != null) return _allEmployees!;
    setState(() => _membersLoading = true);
    try {
      final list = await AppScope.of(context).api.employees();
      _allEmployees = list;
      return list;
    } finally {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  Future<void> _addMembers() async {
    if (_membersLoading) return;
    List<Employee> all;
    try {
      all = await _ensureEmployees();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
      return;
    }
    if (!mounted) return;
    if (all.isEmpty) {
      showToast(context, '暂无可选员工，请先联系管理员配置团队');
      return;
    }

    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberPickerSheet(
        employees: all,
        selected: _members.map((m) => m.employeeId).toSet(),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _members.removeWhere((m) => !picked.contains(m.employeeId));
      final existed = _members.map((m) => m.employeeId).toSet();
      for (final e in all) {
        if (picked.contains(e.id) && !existed.contains(e.id)) {
          _members.add(
            _SelMember(
              employeeId: e.id,
              name: e.name,
              iconKey: e.iconKey,
              color1: e.color1,
              color2: e.color2,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickTeam() async {
    final app = AppScope.of(context);
    if (app.teams.isEmpty) {
      await app.loadTeams();
    }
    if (!mounted) return;
    final teams = app.teams;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = LpColors.of(ctx);
        return _SheetShell(
          title: '归属团队',
          child: ListView(
            shrinkWrap: true,
            children: [
              _sheetOption(
                ctx,
                label: '不指定团队',
                selected: _teamId == null,
                onTap: () => Navigator.of(ctx).pop(-1),
              ),
              for (final t in teams)
                _sheetOption(
                  ctx,
                  label: t.name,
                  sub: t.category,
                  selected: _teamId == t.id,
                  onTap: () => Navigator.of(ctx).pop(t.id),
                ),
              if (teams.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '暂无可选团队',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: c.text3),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _teamId = picked == -1 ? null : picked);
  }

  Widget _sheetOption(
    BuildContext ctx, {
    required String label,
    String? sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = LpColors.of(ctx);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text1,
                      ),
                    ),
                    if (sub != null)
                      TextSpan(
                        text: '  $sub',
                        style: TextStyle(fontSize: 11, color: c.text3),
                      ),
                  ],
                ),
              ),
            ),
            if (selected)
              SvgIcon(Ui.check, size: 16, color: c.brand)
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  void _cycleRole(int index) {
    final m = _members[index];
    final next = _roles[(_roles.indexOf(m.role) + 1) % _roles.length];
    setState(() => m.role = next);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final category = _catCtrl.text.trim();
    if (title.isEmpty) {
      showToast(context, '请填写需求标题');
      return;
    }
    if (desc.isEmpty) {
      showToast(context, '请填写需求描述');
      return;
    }
    if (category.isEmpty) {
      showToast(context, '请填写分类');
      return;
    }

    setState(() => _saving = true);
    final app = AppScope.of(context);
    try {
      final images = _images
          .map(
            (img) => img.bytes != null
                ? 'data:image/jpeg;base64,${base64Encode(img.bytes!)}'
                : img.url!,
          )
          .toList();
      final members = _members
          .map((m) => {'employeeId': m.employeeId, 'role': m.role})
          .toList();
      final tags = _tags;

      if (_editing) {
        await app.api.updateNeed(
          widget.initial!.id,
          title: title,
          desc: desc,
          category: category,
          teamId: _teamId,
          tags: tags,
          members: members,
          images: images,
        );
        if (!mounted) return;
        showToast(context, '需求已更新');
      } else {
        await app.api.createNeed(
          title: title,
          desc: desc,
          category: category,
          teamId: _teamId,
          tags: tags,
          members: members,
          images: images,
        );
        if (!mounted) return;
        showToast(context, '已提交，进入评审中');
      }
      app.loadNeeds(force: true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final teams = AppScope.of(context).teams;
    String? teamName;
    for (final t in teams) {
      if (t.id == _teamId) {
        teamName = t.name;
        break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_dirty) {
          Navigator.of(context).pop();
          return;
        }
        _askLeave();
      },
      child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: _editing ? '编辑需求' : '发布需求',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            GestureDetector(
              onTap: _saving ? null : _submit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _editing ? '保存' : '发布',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _card(
            c,
            child: TextField(
              controller: _titleCtrl,
              maxLength: 60,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text1,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '一句话说明你想要什么',
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.text3,
                ),
                counterStyle: TextStyle(fontSize: 10.5, color: c.text3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            c,
            child: TextField(
              controller: _descCtrl,
              maxLength: 1000,
              minLines: 5,
              maxLines: 12,
              style: TextStyle(fontSize: 14, height: 1.7, color: c.text1),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '背景、期望效果、涉及范围…写清楚更容易获得支持',
                hintStyle: TextStyle(fontSize: 14, color: c.text3),
                counterStyle: TextStyle(fontSize: 10.5, color: c.text3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label(c, '分类'),
          _card(
            c,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: TextField(
              controller: _catCtrl,
              maxLength: 16,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14, color: c.text1),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '例如：办公效率',
                hintStyle: TextStyle(fontSize: 14, color: c.text3),
                counterStyle: TextStyle(fontSize: 10.5, color: c.text3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in _categoryHints)
                GestureDetector(
                  onTap: () => setState(() => _catCtrl.text = h),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _catCtrl.text == h ? c.brandSoft : c.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _catCtrl.text == h ? c.brand : c.line,
                      ),
                    ),
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _catCtrl.text == h ? c.brand : c.text2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _label(c, '标签（可选）'),
          _card(
            c,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: TextField(
              controller: _tagsCtrl,
              style: TextStyle(fontSize: 14, color: c.text1),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '空格或逗号分隔，最多 6 个',
                hintStyle: TextStyle(fontSize: 14, color: c.text3),
                counterStyle: TextStyle(fontSize: 10.5, color: c.text3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(c, '归属团队（可选）'),
          GestureDetector(
            onTap: _pickTeam,
            behavior: HitTestBehavior.opaque,
            child: _card(
              c,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      teamName ?? '不指定团队',
                      style: TextStyle(
                        fontSize: 14,
                        color: teamName == null ? c.text3 : c.text1,
                      ),
                    ),
                  ),
                  SvgIcon(Ui.chevronRight, size: 14, color: c.text3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(c, '相关员工（可选）'),
          if (_members.isNotEmpty) ...[
            for (var i = 0; i < _members.length; i++) _memberRow(c, i),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: _membersLoading ? null : _addMembers,
            behavior: HitTestBehavior.opaque,
            child: _card(
              c,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_membersLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.text3,
                      ),
                    )
                  else
                    SvgIcon(Ui.plus, size: 15, color: c.text3),
                  const SizedBox(width: 7),
                  Text(
                    _members.isEmpty ? '添加相关员工' : '调整相关员工',
                    style: TextStyle(fontSize: 13.5, color: c.text2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(c, '配图（可选，最多 4 张，自动压缩）'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _images.length; i++) _thumb(c, i),
              if (_images.length < 4)
                GestureDetector(
                  onTap: _pickImages,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgIcon(Ui.image, size: 22, color: c.text3),
                        const SizedBox(height: 5),
                        Text(
                          '添加',
                          style: TextStyle(fontSize: 10.5, color: c.text3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _editing
                ? '保存后需求内容立即更新；状态与评分由平台统一维护。'
                : '发布后需求进入「评审中」，全员打分决定优先级。请描述真实、可落地的诉求。',
            style: TextStyle(fontSize: 11, height: 1.7, color: c.text3),
          ),
        ],
      ),
      ),
    );
  }

  Widget _card(LpColors c, {required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kShadowLight,
      ),
      child: child,
    );
  }

  Widget _label(LpColors c, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: c.text2,
        ),
      ),
    );
  }

  Widget _memberRow(LpColors c, int i) {
    final m = _members[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kShadowLight,
      ),
      child: Row(
        children: [
          EmployeeAvatar(
            name: m.name,
            iconKey: m.iconKey,
            color1: m.color1,
            color2: m.color2,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m.name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: c.text1,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _cycleRole(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                m.role,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.brand,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _members.removeAt(i)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: SvgIcon(Ui.close, size: 13, color: c.text3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(LpColors c, int i) {
    final img = _images[i];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: img.bytes != null
              ? Image.memory(
                  img.bytes!,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                )
              : RemoteImage(
                  url: img.url!,
                  width: 84,
                  height: 84,
                ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(i)),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgIcon(Ui.close, size: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 通用底部弹层外框：圆角白色面板 + 标题
class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// 选择相关员工：按团队分组，可搜索，多选
class _MemberPickerSheet extends StatefulWidget {
  final List<Employee> employees;
  final Set<int> selected;

  const _MemberPickerSheet({
    required this.employees,
    required this.selected,
  });

  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  late final Set<int> _sel = {...widget.selected};
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final keyword = _searchCtrl.text.trim();
    final list = keyword.isEmpty
        ? widget.employees
        : widget.employees
            .where((e) =>
                e.name.contains(keyword) ||
                (e.teamName ?? '').contains(keyword))
            .toList();

    /* 按团队分组，保持接口返回的团队顺序 */
    final groups = <String, List<Employee>>{};
    for (final e in list) {
      groups.putIfAbsent(e.teamName ?? '未分组', () => []).add(e);
    }

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择相关员工',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.text1,
                      ),
                    ),
                  ),
                  Text(
                    '已选 ${_sel.length} 人',
                    style: TextStyle(fontSize: 11.5, color: c.text3),
                  ),
                  const SizedBox(width: 6),
                  IconBtn(
                    Ui.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SvgIcon(Ui.search, size: 15, color: c.text3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 13.5, color: c.text1),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '搜索姓名或团队',
                          hintStyle:
                              TextStyle(fontSize: 13.5, color: c.text3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        '没有匹配的员工',
                        style: TextStyle(fontSize: 12.5, color: c.text3),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: c.text3,
                              ),
                            ),
                          ),
                          for (final e in entry.value) _row(c, e),
                        ],
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(_sel),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(LpColors c, Employee e) {
    final on = _sel.contains(e.id);
    return InkWell(
      onTap: () => setState(() {
        if (on) {
          _sel.remove(e.id);
        } else {
          _sel.add(e.id);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Row(
          children: [
            EmployeeAvatar(
              name: e.name,
              iconKey: e.iconKey,
              color1: e.color1,
              color2: e.color2,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.text1,
                    ),
                  ),
                  Text(
                    e.title,
                    style: TextStyle(fontSize: 10.5, color: c.text3),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? c.brand : Colors.transparent,
                border: Border.all(color: on ? c.brand : c.line),
              ),
              alignment: Alignment.center,
              child: on ? SvgIcon(Ui.check, size: 13, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}
