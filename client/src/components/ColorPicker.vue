<template>
  <div class="color-picker">
    <!-- 预览 -->
    <div class="cp-preview-row">
      <span class="cp-swatch" :style="{ background: hex }"></span>
      <input
        class="cp-input"
        :value="hex"
        spellcheck="false"
        @change="onHexInput"
        @keydown.enter.prevent="$event.target.blur()"
        aria-label="颜色值（十六进制）"
      />
    </div>

    <!-- 色调图：色相条 -->
    <div class="cp-bar-wrap">
      <div
        ref="hueBar"
        class="cp-bar cp-hue"
        @pointerdown="onBarDown('hue', $event)"
      >
        <span class="cp-thumb" :style="{ left: huePct() + '%' }"></span>
      </div>
    </div>

    <!-- 饱和度滑块 -->
    <div class="cp-bar-wrap">
      <div
        ref="satBar"
        class="cp-bar cp-sat"
        :style="{ background: satGradient() }"
        @pointerdown="onBarDown('sat', $event)"
      >
        <span class="cp-thumb" :style="{ left: satPct() + '%' }"></span>
      </div>
    </div>

    <!-- 亮度滑块 -->
    <div class="cp-bar-wrap">
      <div
        ref="lightBar"
        class="cp-bar cp-light"
        :style="{ background: lightGradient() }"
        @pointerdown="onBarDown('light', $event)"
      >
        <span class="cp-thumb" :style="{ left: lightPct() + '%' }"></span>
      </div>
    </div>

    <div class="cp-hints">
      <span>色调·饱和度·亮度</span>
      <span>可拖动或输入 #RRGGBB</span>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import { normalizeColor } from '@/utils/theme';

const props = defineProps({
  modelValue: { type: String, default: '#E7DFCA' },
});
const emit = defineEmits(['update:modelValue']);

// ---- HSL 状态（初始 = 默认米色 #E7DFCA 的精确 HSL）----
const DEFAULT_HEX = '#E7DFCA';
const h = ref(0.121);  // 0-1
const s = ref(0.377);  // 0-1
const l = ref(0.849);  // 0-1
const hex = ref(DEFAULT_HEX);

const hueBar = ref(null);
const satBar = ref(null);
const lightBar = ref(null);

// ---------- HSL / HEX 互转（h,s,l 均 0-1） ----------
function hexToHsl(hexColor) {
  const c = normalizeColor(hexColor);
  if (!c) return { h: 0.121, s: 0.377, l: 0.849 };
  const r = parseInt(c.slice(1, 3), 16) / 255;
  const g = parseInt(c.slice(3, 5), 16) / 255;
  const b = parseInt(c.slice(5, 7), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  let hh = 0;
  if (d !== 0) {
    if (max === r) hh = ((g - b) / d) % 6;
    else if (max === g) hh = (b - r) / d + 2;
    else hh = (r - g) / d + 4;
    hh /= 6;
    if (hh < 0) hh += 1;
  }
  const ll = (max + min) / 2;
  const ss = d === 0 ? 0 : d / (1 - Math.abs(2 * ll - 1));
  return { h: hh, s: ss, l: ll };
}

function hslToHex(hh, ss, ll) {
  const c = (1 - Math.abs(2 * ll - 1)) * ss;
  const x = c * (1 - Math.abs(((hh * 6) % 2) - 1));
  const m = ll - c / 2;
  let r = 0, g = 0, b = 0;
  const seg = Math.floor(hh * 6) % 6;
  if (seg === 0) { r = c; g = x; b = 0; }
  else if (seg === 1) { r = x; g = c; b = 0; }
  else if (seg === 2) { r = 0; g = c; b = x; }
  else if (seg === 3) { r = 0; g = x; b = c; }
  else if (seg === 4) { r = x; g = 0; b = c; }
  else { r = c; g = 0; b = x; }
  const toHex = v => Math.round((v + m) * 255).toString(16).padStart(2, '0');
  return '#' + (toHex(r) + toHex(g) + toHex(b)).toUpperCase();
}

// ---------- 渐变背景（函数化，随 HSL 实时更新） ----------
function satGradient() {
  const hh = Math.round(h.value * 360);
  const ll = Math.round(l.value * 100);
  return `linear-gradient(to right, hsl(${hh}, 0%, ${ll}%), hsl(${hh}, 100%, ${ll}%))`;
}

function lightGradient() {
  const hh = Math.round(h.value * 360);
  const ss = Math.round(s.value * 100);
  return `linear-gradient(to right, #000, hsl(${hh}, ${ss}%, 50%), #fff)`;
}

// ---------- 百分比（滑块位置） ----------
const huePct = () => Math.round(h.value * 100);
const satPct = () => Math.round(s.value * 100);
const lightPct = () => Math.round(l.value * 100);

// ---------- 指针拖动 ----------
function onBarDown(kind, e) {
  e.preventDefault();
  setFromEvent(kind, e);
  const move = ev => setFromEvent(kind, ev);
  const up = () => {
    window.removeEventListener('pointermove', move);
    window.removeEventListener('pointerup', up);
  };
  window.addEventListener('pointermove', move);
  window.addEventListener('pointerup', up);
}

function setFromEvent(kind, e) {
  const barMap = { hue: hueBar, sat: satBar, light: lightBar };
  const el = barMap[kind].value;
  if (!el) return;
  const rect = el.getBoundingClientRect();
  let ratio = (e.clientX - rect.left) / rect.width;
  ratio = Math.max(0, Math.min(1, ratio));
  if (kind === 'hue') h.value = ratio;
  else if (kind === 'sat') s.value = ratio;
  else l.value = ratio;
  syncHex();
}

// ---------- 输入框 ----------
function onHexInput(e) {
  const v = normalizeColor(e.target.value);
  if (!v) {
    e.target.value = hex.value; // 非法输入回退
    return;
  }
  const hsl = hexToHsl(v);
  h.value = hsl.h;
  s.value = hsl.s;
  l.value = hsl.l;
  syncHex();
}

// ---------- 同步 ----------
function syncHex() {
  hex.value = hslToHex(h.value, s.value, l.value);
  emit('update:modelValue', hex.value);
}

// 外部值变化（打开面板 / 恢复默认 / 传入已存值）时同步内部；
// immediate：挂载即按传入值初始化，保证色块与滑块位置与真实颜色一致。
watch(() => props.modelValue, val => {
  const v = normalizeColor(val);
  if (!v || v === hex.value) return;
  const hsl = hexToHsl(v);
  h.value = hsl.h;
  s.value = hsl.s;
  l.value = hsl.l;
  hex.value = v;
}, { immediate: true });
</script>

<style scoped>
.color-picker {
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
}

.cp-preview-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}
.cp-swatch {
  width: 2.2rem;
  height: 2.2rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  flex-shrink: 0;
}
.cp-input {
  flex: 1;
  padding: 0.5rem 0.7rem;
  font-size: var(--fs-sm);
  font-family: ui-monospace, 'SF Mono', Consolas, monospace;
  letter-spacing: 0.04em;
  color: var(--text-strong);
  background: var(--bg-sunken);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  outline: none;
  transition: border-color var(--dur) var(--ease);
}
.cp-input:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}

.cp-bar-wrap { position: relative; }
.cp-bar {
  position: relative;
  height: 1.1rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  touch-action: none;
  user-select: none;
}
.cp-hue { background: linear-gradient(to right, #f00 0%, #ff0 17%, #0f0 33%, #0ff 50%, #00f 67%, #f0f 83%, #f00 100%); }

.cp-thumb {
  position: absolute;
  top: 50%;
  width: 0.9rem;
  height: 0.9rem;
  border-radius: 50%;
  background: var(--bg-surface);
  border: 2px solid var(--text-strong);
  box-shadow: var(--shadow-1);
  transform: translate(-50%, -50%);
  pointer-events: none;
}

.cp-hints {
  display: flex;
  justify-content: space-between;
  font-size: 0.7rem;
  color: var(--text-faint);
}
</style>