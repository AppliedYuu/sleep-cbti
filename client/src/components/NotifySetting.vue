<template>
  <div class="notify-overlay" v-if="visible" @click.self="visible = false">
    <div class="notify-card">
      <h3>🔔 睡眠提醒</h3>
      <p class="notify-desc">每天固定时间提醒你准备睡觉</p>

      <div class="time-picker">
        <select v-model.number="hour" class="tp-select">
          <option v-for="h in 24" :key="h" :value="h - 1">{{ String(h - 1).padStart(2, '0') }}</option>
        </select>
        <span class="tp-colon">:</span>
        <select v-model.number="minute" class="tp-select">
          <option :value="0">00</option>
          <option :value="15">15</option>
          <option :value="30">30</option>
          <option :value="45">45</option>
        </select>
      </div>

      <div class="notify-actions">
        <button class="btn-save" @click="saveNotify">✅ 开启提醒</button>
        <button v-if="active" class="btn-cancel" @click="cancelNotify">关闭提醒</button>
      </div>

      <p v-if="active" class="notify-status">✅ 已设置 · 每天 {{ pad(hour) }}:{{ pad(minute) }} 提醒</p>
      <p v-if="msg" class="notify-msg">{{ msg }}</p>
      <button class="btn-close" @click="visible = false">关闭</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const visible = ref(false);
const hour = ref(22);
const minute = ref(0);
const active = ref(false);
const msg = ref('');

function pad(n) { return String(n).padStart(2, '0'); }

function open() {
  visible.value = true;
  active.value = !!(localStorage.getItem('notify_time'));
  const saved = localStorage.getItem('notify_time');
  if (saved) {
    const [h, m] = saved.split(':').map(Number);
    hour.value = h; minute.value = m;
  }
}

function saveNotify() {
  const time = `${pad(hour.value)}:${pad(minute.value)}`;
  localStorage.setItem('notify_time', time);
  active.value = true;
  msg.value = '提醒已设置';

  // 调用 Android 原生接口
  if (window.NativeBridge) {
    window.NativeBridge.setNotification(hour.value, minute.value);
  }

  setTimeout(() => { msg.value = ''; }, 2000);
}

function cancelNotify() {
  localStorage.removeItem('notify_time');
  active.value = false;
  msg.value = '提醒已关闭';
  if (window.NativeBridge) window.NativeBridge.cancelNotification();
  setTimeout(() => { msg.value = ''; }, 2000);
}

defineExpose({ open });
</script>

<style scoped>
.notify-overlay {
  position: fixed; inset: 0;
  background: rgba(11, 16, 32, 0.6);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  display: flex; align-items: center; justify-content: center; z-index: 999;
  animation: notify-fade var(--dur-base) var(--ease-out) both;
}
@keyframes notify-fade {
  from { opacity: 0; }
  to   { opacity: 1; }
}

.notify-card {
  background: var(--bg-glass-strong);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-float);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: var(--space-4);
  width: min(300px, calc(100vw - 2.4rem));
  text-align: center;
  animation: notify-rise var(--dur-slow) var(--ease-spring) both;
}
@keyframes notify-rise {
  from { opacity: 0; transform: translateY(16px) scale(0.98); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

.notify-card h3 {
  font-size: var(--fs-lg);
  color: var(--text-strong);
  margin-bottom: var(--space-1);
  font-weight: 700;
}
.notify-desc {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: var(--space-3);
}

.time-picker {
  display: flex; align-items: center; justify-content: center;
  gap: var(--space-2); margin-bottom: var(--space-3);
}
.tp-select {
  padding: 0.5rem 1rem;
  font-size: var(--fs-xl);
  font-weight: 700;
  background: var(--bg-soft);
  color: var(--text-strong);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  text-align: center;
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.tp-select:focus {
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}
.tp-colon {
  font-size: var(--fs-xl);
  font-weight: 700;
  color: var(--text-base);
}

.notify-actions {
  display: flex; flex-direction: column; gap: var(--space-2);
}
.btn-save {
  padding: 0.6rem;
  background: var(--accent-amber);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-weight: 600;
  cursor: pointer;
  box-shadow: var(--glow-amber);
  transition: transform var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.btn-save:hover {
  box-shadow: 0 0 28px rgba(255, 210, 138, 0.40);
}
.btn-save:active {
  transform: scale(0.98);
}
.btn-cancel {
  padding: 0.5rem;
  background: transparent;
  color: var(--danger);
  border: 1px solid var(--danger);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  cursor: pointer;
  transition: background var(--dur-fast) var(--ease-out),
              transform var(--dur-fast) var(--ease-out);
}
.btn-cancel:hover {
  background: rgba(255, 138, 155, 0.10);
}
.btn-cancel:active {
  transform: scale(0.98);
}

.notify-status {
  font-size: var(--fs-sm);
  color: var(--success);
  margin-top: var(--space-2);
}
.notify-msg {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-top: var(--space-1);
}

.btn-close {
  margin-top: var(--space-3);
  padding: 0.3rem 1.2rem;
  background: var(--bg-soft);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  color: var(--text-muted);
  cursor: pointer;
  transition: background var(--dur-fast) var(--ease-out),
              color var(--dur-fast) var(--ease-out),
              transform var(--dur-fast) var(--ease-out);
}
.btn-close:hover {
  background: var(--bg-hover);
  color: var(--text-base);
}
.btn-close:active {
  transform: scale(0.98);
}

@media (prefers-reduced-motion: reduce) {
  .notify-overlay,
  .notify-card { animation: none; }
}
</style>
