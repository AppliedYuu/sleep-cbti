/**
 * 界面主题（背景色 / 字体颜色）工具
 * 默认值 = 纸与墨主题的默认外观（与 styles/theme.css 保持一致）：
 *   背景 bgColor    #F7F4ED（奶白纸底）
 *   字体 textColor  #2A2A28（浓墨）
 */

export const DEFAULT_THEME = {
  bgColor: '#F7F4ED',
  textColor: '#2A2A28',
};

/** 校验 #RGB / #RRGGBB，返回统一大写 #RRGGBB，非法返回 null */
export function normalizeColor(color) {
  if (typeof color !== 'string') return null;
  let c = color.trim();
  if (!/^#?[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$/.test(c)) return null;
  c = c.replace(/^#/, '');
  if (c.length === 3) {
    c = c.split('').map(ch => ch + ch).join('');
  }
  return '#' + c.toUpperCase();
}

/** hex → rgb() 带透明度，例如 hexToRgba('#7C9885', 0.6) */
export function hexToRgba(hex, alpha) {
  const c = normalizeColor(hex);
  if (!c) return `rgba(0,0,0,${alpha})`;
  const r = parseInt(c.slice(1, 3), 16);
  const g = parseInt(c.slice(3, 5), 16);
  const b = parseInt(c.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/**
 * 应用主题：把背景色 / 字体颜色写入 CSS 变量。
 * - 字体颜色同时影响 --text-base / --text-strong，并派生 --text-muted / --text-faint。
 * - 不去动 body 的米格噪点纹理（theme.css 中固定叠加，背景色只改 --bg-base，两者独立）。
 */
export function applyTheme(settings = {}) {
  const bg = normalizeColor(settings.bgColor) || DEFAULT_THEME.bgColor;
  const text = normalizeColor(settings.textColor) || DEFAULT_THEME.textColor;

  const root = document.documentElement;
  root.style.setProperty('--bg-base', bg);
  root.style.setProperty('--text-base', text);
  root.style.setProperty('--text-strong', text);
  root.style.setProperty('--text-muted', hexToRgba(text, 0.62));
  root.style.setProperty('--text-faint', hexToRgba(text, 0.42));
}

/** 重置为默认主题 */
export function resetTheme() {
  applyTheme(DEFAULT_THEME);
}