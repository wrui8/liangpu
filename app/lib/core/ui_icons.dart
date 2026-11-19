/// 界面线性图标（与原型一致的 SVG 路径）
class Ui {
  static String _s(String inner, {double width = 1.8}) =>
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="$width" stroke-linecap="round" stroke-linejoin="round">'
      '$inner</svg>';

  static final home = _s(
    '<path d="M3 10.8 12 3l9 7.8V20a1 1 0 0 1-1 1h-5v-6.5H9V21H4a1 1 0 0 1-1-1z"/>',
  );

  static final teams = _s(
    '<path d="M4 21V5a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v16"/>'
    '<path d="M11 9h6a1 1 0 0 1 1 1v11"/>'
    '<path d="M2.5 21h19"/>'
    '<path d="M7 8h1M7 12h1M7 16h1M14 13h1M14 17h1"/>',
  );

  static final needs = _s(
    '<path d="M9 4h6a1 1 0 0 1 1 1v1H8V5a1 1 0 0 1 1-1z"/>'
    '<path d="M8 6H6a1 1 0 0 0-1 1v13a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V7a1 1 0 0 0-1-1h-2"/>'
    '<path d="M9 12h6M9 16h4"/>',
  );

  static final community = _s(
    '<path d="M21 11.5a8 8 0 0 1-8 8H6l-3 2.5V11.5a8 8 0 0 1 8-8h2a8 8 0 0 1 8 8z"/>'
    '<path d="M8.5 11.5h.01M12 11.5h.01M15.5 11.5h.01"/>',
  );

  static final me = _s(
    '<circle cx="12" cy="8" r="4"/>'
    '<path d="M4.5 21c0-4 3.4-6.5 7.5-6.5s7.5 2.5 7.5 6.5"/>',
  );

  static final moon = _s(
    '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>',
  );

  static final sun = _s(
    '<circle cx="12" cy="12" r="4"/>'
    '<path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  );

  static final search = _s(
    '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/>',
  );

  static final bell = _s(
    '<path d="M18 8a6 6 0 1 0-12 0c0 7-3 8-3 8h18s-3-1-3-8"/>'
    '<path d="M13.7 21a2 2 0 0 1-3.4 0"/>',
  );

  static final back = _s(
    '<path d="m15 18-6-6 6-6"/>',
    width: 2,
  );

  static final more =
      '<svg viewBox="0 0 24 24" fill="currentColor">'
      '<circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/>'
      '<circle cx="19" cy="12" r="1.8"/></svg>';

  static final share = _s(
    '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/>'
    '<circle cx="18" cy="19" r="3"/>'
    '<path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4"/>',
  );

  static final heart = _s(
    '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1.1 1L12 21l7.7-7.6 1.1-1a5.5 5.5 0 0 0 0-7.8z"/>',
  );

  /* 已点赞：实心爱心（与原型一致） */
  static const heartFilled =
      '<svg viewBox="0 0 24 24" fill="currentColor" stroke="none">'
      '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1.1 1L12 21l7.7-7.6 1.1-1a5.5 5.5 0 0 0 0-7.8z"/>'
      '</svg>';

  static final plus = _s(
    '<path d="M12 5v14M5 12h14"/>',
    width: 2,
  );

  static final chevronRight = _s(
    '<path d="m9 6 6 6-6 6"/>',
    width: 2,
  );

  static final server = _s(
    '<rect x="3" y="4" width="18" height="7" rx="2"/>'
    '<rect x="3" y="13" width="18" height="7" rx="2"/>'
    '<path d="M7 7.5h.01M7 16.5h.01"/>',
  );

  static final logout = _s(
    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>'
    '<path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
  );

  static final image = _s(
    '<rect x="3" y="3" width="18" height="18" rx="3"/>'
    '<circle cx="9" cy="9" r="2"/><path d="m21 15-4.5-4.5L7 20"/>',
  );

  static final info = _s(
    '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  );

  static final close = _s('<path d="M18 6 6 18M6 6l12 12"/>', width: 2);

  static final check = _s('<path d="m5 12.5 4.5 4.5L19 7.5"/>', width: 2.2);

  static final star = _s(
    '<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-2.9-5.6 2.9 1.1-6.2L3 9.6l6.2-.9z"/>',
  );
}
