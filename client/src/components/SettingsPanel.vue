<template>
  <Teleport to="body">
    <Transition name="drawer">
      <div v-if="visible" class="settings-overlay" @click.self="close">
        <aside class="settings-drawer" role="dialog" aria-label="设置">
          <header class="sd-header">
            <h3 class="serif">设置</h3>
            <div class="sd-header-actions">
              <button class="sd-reset" @click="handleReset">重置默认</button>
              <button class="sd-close" @click="close" aria-label="关闭">×</button>
            </div>
          </header>

          <div class="sd-body">
            <transition name="fade">
              <p v-if="resetMsg" class="sd-reset-msg">{{ resetMsg }}</p>
            </transition>

            <!-- 背景色（可折叠） -->
            <section class="sd-group" :class="{ open: bgExpanded }">
              <button class="sd-head" @click="bgExpanded = !bgExpanded" aria-expanded="bgExpanded">
                <span class="sd-head-left">
                  <span class="sd-arrow" aria-hidden="true">▸</span>
                  <span class="sd-group-name">背景色</span>
                </span>
                <span class="sd-save-state" :class="{ ok: savedBg }">
                  {{ savedBg ? '✓ 已保存' : '保存中…' }}
                </span>
              </button>
              <div class="sd-collapse">
                <div class="sd-collapse-inner">
                  <p class="sd-desc">调节整个页面背景，实时预览</p>
                  <ColorPicker v-model="bgColor" />
                </div>
              </div>
            </section>

            <div class="sd-divider"></div>

            <!-- 字体颜色（可折叠） -->
            <section class="sd-group" :class="{ open: textExpanded }">
              <button class="sd-head" @click="textExpanded = !textExpanded" aria-expanded="textExpanded">
                <span class="sd-head-left">
                  <span class="sd-arrow" aria-hidden="true">▸</span>
                  <span class="sd-group-name">字体颜色</span>
                </span>
                <span class="sd-save-state" :class="{ ok: savedText }">
                  {{ savedText ? '✓ 已保存' : '保存中…' }}
                </span>
              </button>
              <div class="sd-collapse">
                <div class="sd-collapse-inner">
                  <p class="sd-desc">调节正文与标题颜色，实时预览</p>
                  <ColorPicker v-model="textColor" />
                </div>
              </div>
            </section>
          </div>

          <!-- 底部：退出登录（红色） -->
          <footer class="sd-footer">
            <button class="sd-logout" @click="handleLogout">退出登录</button>
          </footer>
        </aside>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import { getSettings, updateSettings } from '@/api/auth';
import { applyTheme, DEFAULT_THEME, normalizeColor } from '@/utils/theme';
import ColorPicker from './ColorPicker.vue';

const visible = ref(false);
const bgColor = ref(DEFAULT_THEME.bgColor);
const textColor = ref(DEFAULT_THEME.textColor);
const savedBg = ref(true);
const savedText = ref(true);
const resetMsg = ref('');
const bgExpanded = ref(false);   // 背景色折叠：默认收起
const textExpanded = ref(false); // 字体颜色折叠：默认收起

const router = useRouter();
const authStore = useAuthStore();

let saveBgTimer = null;
let saveTextTimer = null;

/** 打开侧边栏：默认折叠收起；颜色为当前值（数据库已存 或 主题默认） */
async function open() {
  visible.value = true;
  bgExpanded.value = false;
  textExpanded.value = false;
  // 优先读取用户已保存的设置
  try {
    const res = await getSettings();
    const data = res && res.data ? res.data : {};
    bgColor.value = normalizeColor(data.bgColor) || DEFAULT_THEME.bgColor;
    textColor.value = normalizeColor(data.textColor) || DEFAULT_THEME.textColor;
    savedBg.value = true;
    savedText.value = true;
  } catch {
    // 接口不可用时用当前页面生效值
    const root = getComputedStyle(document.documentElement);
    const curBg = normalizeColor(root.getPropertyValue('--bg-base'));
    const curText = normalizeColor(root.getPropertyValue('--text-base'));
    bgColor.value = curBg || DEFAULT_THEME.bgColor;
    textColor.value = curText || DEFAULT_THEME.textColor;
  }
  applyTheme({ bgColor: bgColor.value, textColor: textColor.value });
}

function close() {
  visible.value = false;
}

/** 背景色变化：实时预览 + 防抖保存 */
watch(bgColor, val => {
  if (!visible.value) return;
  applyTheme({ bgColor: val, textColor: textColor.value });
  savedBg.value = false;
  clearTimeout(saveBgTimer);
  saveBgTimer = setTimeout(saveSettings, 600);
});

/** 字体颜色变化：实时预览 + 防抖保存 */
watch(textColor, val => {
  if (!visible.value) return;
  applyTheme({ bgColor: bgColor.value, textColor: val });
  savedText.value = false;
  clearTimeout(saveTextTimer);
  saveTextTimer = setTimeout(saveSettings, 600);
});

async function saveSettings() {
  try {
    await updateSettings({
      bgColor: bgColor.value,
      textColor: textColor.value,
    });
    savedBg.value = true;
    savedText.value = true;
  } catch {
    // 保存失败：提示状态回退（下次再动会重试）
    savedBg.value = false;
    savedText.value = false;
  }
}

/** 重置为默认（米色背景 + 黑色字体），应用并保存 */
function handleReset() {
  bgColor.value = DEFAULT_THEME.bgColor;
  textColor.value = DEFAULT_THEME.textColor;
  applyTheme({
    bgColor: DEFAULT_THEME.bgColor,
    textColor: DEFAULT_THEME.textColor,
  });
  clearTimeout(saveBgTimer);
  clearTimeout(saveTextTimer);
  saveSettings();
  resetMsg.value = '已恢复默认';
  setTimeout(() => { resetMsg.value = ''; }, 2000);
}

function handleLogout() {
  authStore.logout();
  router.push('/login');
}

defineExpose({ open });
</script>

<style scoped>
/* ---- 遮罩 ---- */
.settings-overlay {
  position: fixed;
  inset: 0;
  z-index: 900;
  background: rgba(42, 42, 40, 0.35);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

/* ---- 抽屉 ---- */
.settings-drawer {
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: min(340px, 86vw);
  background: var(--bg-base);
  border-left: 1px solid var(--bg-line);
  box-shadow: var(--shadow-float);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* ---- 头部 ---- */
.sd-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.2rem;
  border-bottom: 1px solid var(--bg-line);
}
.sd-header h3 {
  font-size: var(--fs-lg);
  color: var(--text-strong);
}
.sd-header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.sd-reset {
  border: 1px solid var(--border);
  background: transparent;
  color: var(--text-muted);
  font-size: var(--fs-xs);
  font-family: inherit;
  padding: 0.35rem 0.7rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease),
              background var(--dur) var(--ease);
}
.sd-reset:hover {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-weak);
}
.sd-close {
  width: 2rem;
  height: 2rem;
  border: none;
  background: var(--bg-sunken);
  color: var(--text-muted);
  border-radius: var(--radius-sm);
  font-size: 1.1rem;
  line-height: 1;
  cursor: pointer;
  transition: background var(--dur) var(--ease), color var(--dur) var(--ease);
}
.sd-close:hover {
  background: var(--bg-hover);
  color: var(--text-strong);
}

/* ---- 主体 ---- */
.sd-body {
  flex: 1;
  overflow-y: auto;
  padding: 1.2rem 1.2rem 0.8rem;
}
.sd-group { margin-bottom: 0.4rem; }

/* 重置成功提示 */
.sd-reset-msg {
  margin-bottom: 0.8rem;
  padding: 0.5rem 0.8rem;
  background: var(--primary-weak);
  color: var(--primary-strong);
  border-left: 3px solid var(--primary);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity var(--dur) var(--ease);
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 折叠头部 */
.sd-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0.6rem 0.2rem;
  border: none;
  background: transparent;
  font-family: inherit;
  cursor: pointer;
  text-align: left;
}
.sd-head:hover .sd-group-name { color: var(--primary); }
.sd-head:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
.sd-head-left {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.sd-arrow {
  display: inline-block;
  font-size: 0.8rem;
  color: var(--text-faint);
  transition: transform var(--dur) var(--ease);
}
.sd-group.open .sd-arrow {
  transform: rotate(90deg);
  color: var(--primary);
}

/* 折叠内容：grid-rows 平滑展开 */
.sd-collapse {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 260ms var(--ease);
}
.sd-group.open .sd-collapse {
  grid-template-rows: 1fr;
}
.sd-collapse-inner {
  overflow: hidden;
  min-height: 0;
}
.sd-collapse-inner .sd-desc { margin-top: 0.2rem; }

.sd-group-name {
  font-size: var(--fs-md);
  font-weight: 600;
  color: var(--text-strong);
  transition: color var(--dur) var(--ease);
}
.sd-save-state {
  font-size: var(--fs-xs);
  color: var(--text-faint);
  transition: color var(--dur) var(--ease);
}
.sd-save-state.ok { color: var(--success); }
.sd-desc {
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-bottom: 0.9rem;
}
.sd-divider {
  height: 1px;
  background: var(--bg-line);
  margin: 0.2rem 0;
}

/* ---- 底部：退出登录（红色） ---- */
.sd-footer {
  padding: 0.9rem 1.2rem calc(0.9rem + var(--safe-bottom));
  border-top: 1px solid var(--bg-line);
  background: var(--bg-base);
}
.sd-logout {
  width: 100%;
  padding: 0.8rem;
  background: transparent;
  color: var(--danger);
  border: 1.5px solid var(--danger);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur) var(--ease), color var(--dur) var(--ease);
}
.sd-logout:hover {
  background: var(--danger);
  color: var(--text-on-primary);
}

/* ---- 过渡 ---- */
.drawer-enter-active,
.drawer-leave-active {
  transition: opacity 220ms var(--ease);
}
.drawer-enter-active .settings-drawer,
.drawer-leave-active .settings-drawer {
  transition: transform 220ms var(--ease);
}
.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
}
.drawer-enter-from .settings-drawer,
.drawer-leave-to .settings-drawer {
  transform: translateX(100%);
}

@media (prefers-reduced-motion: reduce) {
  .drawer-enter-active,
  .drawer-leave-active,
  .drawer-enter-active .settings-drawer,
  .drawer-leave-active .settings-drawer,
  .sd-collapse {
    transition: none;
  }
}
</style>