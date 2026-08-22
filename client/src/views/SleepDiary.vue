<template>
  <div class="diary-page">
    <div class="diary-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1>📓 睡眠日记</h1>
      <p class="diary-date">{{ displayDate }}</p>
    </div>

    <!-- 日期选择器 -->
    <div class="date-picker">
      <button class="btn-date" @click="changeDate(-1)">◀ 前一天</button>
      <input type="date" :value="diaryDate" @change="onDateChange" class="input-date" />
      <button class="btn-date" @click="changeDate(1)">后一天 ▶</button>
    </div>

    <!-- 睡眠效率趋势小卡片 -->
    <div class="trend-card" v-if="trend.length > 0">
      <div class="trend-head">
        <h3>📈 近 {{ trend.length }} 次睡眠效率趋势</h3>
        <button class="btn-log" @click="openLog">📋 查看提交日志</button>
      </div>
      <div class="trend-bars">
        <div
          v-for="(item, idx) in trend"
          :key="idx"
          class="trend-bar-item"
          :class="{ today: item.diary_date === diaryDate }"
        >
          <div class="bar-fill-wrapper">
            <div
              class="bar-fill"
              :style="{ height: (item.sleep_efficiency || 0) + '%' }"
              :class="efficiencyClass(item.sleep_efficiency)"
            ></div>
          </div>
          <span class="bar-label">{{ formatShortDate(item.diary_date) }}</span>
          <span class="bar-value">{{ item.sleep_efficiency || '--' }}%</span>
        </div>
      </div>
    </div>

    <!-- 无记录时提示 -->
    <div class="trend-empty" v-else>
      <span>暂无睡眠记录，保存第一条日记后这里会显示近 7 次提交趋势。</span>
    </div>

    <!-- 日记表单 -->
    <div class="diary-form">
      <!-- 上床时间 -->
      <div class="form-group">
        <label>🛌 上床时间</label>
        <div class="time-split">
          <select v-model="form.bedH" class="input-split">
            <option v-for="h in hours" :key="h" :value="h">{{ String(h).padStart(2,'0') }}</option>
          </select>
          <span class="time-colon">:</span>
          <select v-model="form.bedM" class="input-split">
            <option v-for="m in minutes" :key="m" :value="m">{{ String(m).padStart(2,'0') }}</option>
          </select>
        </div>
      </div>

      <!-- 熄灯时间 -->
      <div class="form-group">
        <label>💡 熄灯时间</label>
        <div class="time-split">
          <select v-model="form.lightsOffH" class="input-split">
            <option v-for="h in hours" :key="h" :value="h">{{ String(h).padStart(2,'0') }}</option>
          </select>
          <span class="time-colon">:</span>
          <select v-model="form.lightsOffM" class="input-split">
            <option v-for="m in minutes" :key="m" :value="m">{{ String(m).padStart(2,'0') }}</option>
          </select>
        </div>
        <span class="hint">关灯准备入睡的时间</span>
      </div>

      <!-- 入睡耗时（滑块） -->
      <div class="form-group slider-group">
        <label>⏱️ 入睡耗时</label>
        <div class="slider-value-display">
          <span class="big-value">{{ form.sleepLatency || 0 }}</span>
          <span class="unit">分钟</span>
        </div>
        <input
          type="range"
          v-model.number="form.sleepLatency"
          min="0"
          max="180"
          step="5"
          class="range-input"
        />
        <div class="slider-marks">
          <span>0</span><span>30</span><span>60</span><span>90</span><span>120+</span>
        </div>
        <p class="slider-desc">{{ latencyDesc }}</p>
      </div>

      <!-- 夜醒次数（滑块） -->
      <div class="form-group slider-group">
        <label>🌙 夜醒次数</label>
        <div class="slider-value-display">
          <span class="big-value">{{ form.nightAwakenings || 0 }}</span>
          <span class="unit">次</span>
        </div>
        <input
          type="range"
          v-model.number="form.nightAwakenings"
          min="0"
          max="10"
          step="1"
          class="range-input"
        />
        <div class="slider-marks">
          <span>0</span><span>2</span><span>4</span><span>6</span><span>8</span><span>10</span>
        </div>
      </div>

      <!-- 起床时间 -->
      <div class="form-group">
        <label>⏰ 起床时间</label>
        <div class="time-split">
          <select v-model="form.wakeH" class="input-split">
            <option v-for="h in hours" :key="h" :value="h">{{ String(h).padStart(2,'0') }}</option>
          </select>
          <span class="time-colon">:</span>
          <select v-model="form.wakeM" class="input-split">
            <option v-for="m in minutes" :key="m" :value="m">{{ String(m).padStart(2,'0') }}</option>
          </select>
        </div>
      </div>

      <!-- 日间精力评分（滑块） -->
      <div class="form-group slider-group">
        <label>⚡ 日间精力评分</label>
        <div class="slider-value-display">
          <span class="big-value">{{ form.daytimeEnergy || 5 }}</span>
          <span class="unit">/ 10 分</span>
        </div>
        <input
          type="range"
          v-model.number="form.daytimeEnergy"
          min="1"
          max="10"
          step="1"
          class="range-input energy-range"
        />
        <div class="energy-labels">
          <span>😴 很差</span>
          <span>😐 一般</span>
          <span>😊 很好</span>
        </div>
      </div>

      <!-- 备注 -->
      <div class="form-group">
        <label>📝 备注（选填）</label>
        <textarea
          v-model="form.notes"
          class="input-textarea"
          placeholder="今天有什么影响睡眠的事情？如：咖啡、运动、压力...…"
          rows="2"
        ></textarea>
      </div>
    </div>

    <!-- 保存按钮 -->
    <div class="diary-footer">
      <button class="btn-save" @click="saveDiaryEntry" :disabled="saving">
        {{ saving ? '保存中...' : '💾 保存日记' }}
      </button>
    </div>

    <!-- 保存成功提示 -->
    <div v-if="showSuccess" class="toast-success">✅ 日记保存成功！</div>

    <!-- 提交日志抽屉 -->
    <Teleport to="body">
      <Transition name="drawer">
        <div v-if="logVisible" class="log-overlay" @click.self="logVisible = false">
          <aside class="log-drawer">
            <header class="log-header">
              <h3>📋 提交日志</h3>
              <button class="log-close" @click="logVisible = false" aria-label="关闭">×</button>
            </header>

            <div class="log-body">
              <p v-if="logs.length === 0" class="log-empty">还没有提交记录</p>
              <ul v-else class="log-list">
                <li
                  v-for="(item, idx) in logs"
                  :key="idx"
                  class="log-item"
                  :class="{ current: item.diary_date === diaryDate }"
                >
                  <div class="log-main">
                    <span class="log-date">{{ formatLogDate(item.diary_date) }}</span>
                    <span class="log-eff" :class="efficiencyClass(item.sleep_efficiency)">
                      {{ item.sleep_efficiency != null ? item.sleep_efficiency + '%' : '--' }}
                    </span>
                  </div>
                  <div class="log-meta">
                    <span v-if="item.sleep_latency != null">入睡 {{ item.sleep_latency }} 分钟</span>
                    <span v-if="item.daytime_energy != null">精力 {{ item.daytime_energy }}/10</span>
                    <span v-if="item.wake_up_time">起床 {{ item.wake_up_time.slice(0, 5) }}</span>
                  </div>
                  <p v-if="item.notes" class="log-notes">{{ item.notes }}</p>
                </li>
              </ul>
            </div>

            <footer class="log-footer">
              <button class="btn-close-log" @click="logVisible = false">关闭</button>
            </footer>
          </aside>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { saveDiary, getDiary, getDiaryList, getEfficiencyTrend } from '@/api/diary';

import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);
const diaryDate = ref(todayStr());
const saving = ref(false);
const showSuccess = ref(false);
const trend = ref([]);
const TREND_COUNT = 7; // 显示最近 N 次提交

// 提交日志
const logVisible = ref(false);
const logs = ref([]);

const hours = Array.from({ length: 24 }, (_, i) => i);
const minutes = [0, 15, 30, 45];

const form = reactive({
  bedH: 22, bedM: 0,
  lightsOffH: 22, lightsOffM: 0,
  sleepLatency: 20,
  nightAwakenings: 0,
  wakeH: 8, wakeM: 0,
  daytimeEnergy: 5,
  notes: '',
});

function fmt(h, m) { return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`; }

const displayDate = computed(() => {
  const d = new Date(diaryDate.value);
  return d.toLocaleDateString('zh-CN', {
    year: 'numeric', month: 'long', day: 'numeric', weekday: 'long',
  });
});

const latencyDesc = computed(() => {
  const v = form.sleepLatency;
  if (v <= 15) return '👍 入睡很快，非常好！';
  if (v <= 30) return '✅ 入睡时间正常';
  if (v <= 60) return '⚠️ 入睡偏慢，可尝试放松技巧';
  return '🔴 入睡困难，建议咨询干预方案';
});

function todayStr() {
  return new Date().toISOString().slice(0, 10);
}

function formatShortDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

function efficiencyClass(val) {
  if (!val || val < 65) return 'bad';
  if (val < 75) return 'warn';
  if (val < 85) return 'fair';
  return 'good';
}

function changeDate(delta) {
  const d = new Date(diaryDate.value);
  d.setDate(d.getDate() + delta);
  diaryDate.value = d.toISOString().slice(0, 10);
}

function onDateChange(e) {
  diaryDate.value = e.target.value;
}

function parseTime(timeStr) {
  if (!timeStr) return [22, 0];
  const parts = timeStr.toString().split(':');
  const h = parseInt(parts[0]) || 22;
  const m = Math.round((parseInt(parts[1]) || 0) / 15) * 15;
  return m >= 60 ? [(h + 1) % 24, 0] : [h, m];
}

async function loadDiary() {
  try {
    const res = await getDiary(userId.value, diaryDate.value);
    if (res.data) {
      [form.bedH, form.bedM] = parseTime(res.data.bed_time);
      [form.lightsOffH, form.lightsOffM] = parseTime(res.data.lights_off_time);
      form.sleepLatency = res.data.sleep_latency || 20;
      form.nightAwakenings = res.data.night_awakenings || 0;
      [form.wakeH, form.wakeM] = parseTime(res.data.wake_up_time);
      form.daytimeEnergy = res.data.daytime_energy || 5;
      form.notes = res.data.notes || '';
    } else {
      resetForm();
    }
  } catch {
    resetForm();
  }
}

function resetForm() {
  form.bedH = 22; form.bedM = 0;
  form.lightsOffH = 22; form.lightsOffM = 0;
  form.sleepLatency = 20;
  form.nightAwakenings = 0;
  form.wakeH = 8; form.wakeM = 0;
  form.daytimeEnergy = 5;
  form.notes = '';
}

async function loadTrend() {
  try {
    const res = await getEfficiencyTrend(userId.value, TREND_COUNT);
    trend.value = res.data || [];
  } catch {
    trend.value = [];
  }
}

/* ===================== 提交日志 ===================== */

async function openLog() {
  logVisible.value = true;
  try {
    const res = await getDiaryList(userId.value, { limit: 50 });
    logs.value = res.data || [];
  } catch {
    logs.value = [];
  }
}

function formatLogDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('zh-CN', {
    month: 'long', day: 'numeric', weekday: 'short',
  });
}

/* ===================== 保存 ===================== */

async function saveDiaryEntry() {
  saving.value = true;
  try {
    await saveDiary(userId.value, {
      diaryDate: diaryDate.value,
      bedTime: fmt(form.bedH, form.bedM),
      lightsOffTime: fmt(form.lightsOffH, form.lightsOffM),
      sleepLatency: form.sleepLatency,
      nightAwakenings: form.nightAwakenings,
      wakeUpTime: fmt(form.wakeH, form.wakeM),
      daytimeEnergy: form.daytimeEnergy,
      notes: form.notes || null,
    });
    showSuccess.value = true;
    setTimeout(() => { showSuccess.value = false; }, 2000);
    loadTrend();
  } catch {
    alert('保存失败，请重试');
  } finally {
    saving.value = false;
  }
}

watch(diaryDate, () => {
  loadDiary();
});

onMounted(() => {
  loadDiary();
  loadTrend();
});
</script>

<style scoped>
.diary-page {
  min-height: 100vh;
  padding: 1rem 1.4rem 3rem;
  color: var(--text-base);
}

.diary-header {
  padding: 0.6rem 0 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.2rem;
}
.btn-back-link {
  display: inline-block;
  color: var(--text-muted);
  text-decoration: none;
  font-size: var(--fs-sm);
  margin-bottom: 0.6rem;
  transition: color var(--dur) var(--ease);
}
.btn-back-link:hover { color: var(--text-strong); }

.diary-header h1 {
  font-size: var(--fs-xl);
  font-weight: 500;
  color: var(--text-strong);
  letter-spacing: 0.04em;
}
.diary-date {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-top: 0.2rem;
}

/* 日期选择器：纯白面板 */
.date-picker {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.6rem;
  padding: 0.9rem;
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  margin: 0 0 1.2rem;
}
.btn-date {
  padding: 0.4rem 0.7rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--fs-sm);
  font-family: inherit;
  cursor: pointer;
  color: var(--text-base);
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease);
}
.btn-date:hover {
  border-color: var(--primary);
  color: var(--primary);
}
.input-date {
  padding: 0.4rem 0.7rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-sunken);
  outline: none;
  text-align: center;
  transition: border-color var(--dur) var(--ease);
}
.input-date:focus { border-color: var(--primary); }

/* 趋势 */
.trend-card {
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 1rem;
  margin-bottom: 1rem;
}
.trend-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.8rem;
  gap: 0.6rem;
}
.trend-head h3 {
  font-size: var(--fs-md);
  font-weight: 500;
  color: var(--text-strong);
}
.btn-log {
  flex-shrink: 0;
  padding: 0.35rem 0.7rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--fs-xs);
  font-family: inherit;
  color: var(--text-muted);
  cursor: pointer;
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease),
              background var(--dur) var(--ease);
}
.btn-log:hover {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-weak);
}

.trend-empty {
  background: var(--bg-surface);
  border: 1px dashed var(--border);
  border-radius: var(--radius-sm);
  padding: 1rem;
  margin-bottom: 1rem;
  text-align: center;
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.trend-bars {
  display: flex;
  gap: 0.5rem;
  justify-content: space-around;
  align-items: flex-end;
  height: 110px;
}
.trend-bar-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}
.bar-fill-wrapper {
  width: 100%;
  height: 60px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.bar-fill {
  width: 18px;
  border-radius: 1px 1px 0 0;
  min-height: 4px;
  transition: height var(--dur) var(--ease),
              background var(--dur) var(--ease);
  opacity: 0.9;
}
.bar-fill.good { background: var(--primary); }
.bar-fill.fair { background: var(--accent-clay); }
.bar-fill.warn { background: var(--accent-clay); }
.bar-fill.bad  { background: var(--text-muted); }
.trend-bar-item.today .bar-fill { opacity: 1; }

.bar-label {
  font-size: var(--fs-xs);
  color: var(--text-faint);
  margin-top: 0.3rem;
}
.bar-value {
  font-size: var(--fs-xs);
  font-weight: 500;
  color: var(--text-strong);
}

/* 表单 */
.diary-form {
  display: flex;
  flex-direction: column;
  gap: 0;
}
.form-group {
  padding: 1rem 0;
  border-bottom: 1px solid var(--bg-line);
}
.form-group:last-of-type { border-bottom: none; }

.form-group label {
  display: block;
  font-size: var(--fs-md);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.6rem;
}

.input-field {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-sunken);
  outline: none;
  transition: border-color var(--dur) var(--ease),
              background var(--dur) var(--ease);
}
.input-field::placeholder { color: var(--text-faint); }
.input-field:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}

.input-select {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-sunken);
  outline: none;
  appearance: auto;
  -webkit-appearance: auto;
}
.input-select:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}

.time-split {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.input-split {
  padding: 0.55rem 0.6rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: 1.2rem;
  font-weight: 500;
  font-family: inherit;
  color: var(--text-strong);
  outline: none;
  background: var(--bg-sunken);
  transition: border-color var(--dur) var(--ease);
  text-align: center;
  flex: 1;
  appearance: auto;
  -webkit-appearance: auto;
}
.input-split:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}
.time-colon {
  font-size: 1.4rem;
  color: var(--text-muted);
  flex-shrink: 0;
}
.hint {
  display: block;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: 0.3rem;
}

/* 滑块组 */
.slider-group { padding-bottom: 1rem; }
.slider-value-display {
  text-align: center;
  margin-bottom: 0.5rem;
}
.big-value {
  font-size: 2rem;
  font-weight: 500;
  color: var(--text-strong);
  font-family: var(--font-serif);
}
.unit {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-left: 0.2rem;
  font-family: var(--font-base);
}

.range-input {
  width: 100%;
  -webkit-appearance: none;
  appearance: none;
  height: 4px;
  border-radius: 2px;
  background: var(--bg-line);
  outline: none;
}
.range-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-base);
  cursor: pointer;
}
.range-input::-moz-range-thumb {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-base);
  cursor: pointer;
}

.energy-range {
  background: var(--bg-line);
}

.slider-marks {
  display: flex;
  justify-content: space-between;
  font-size: var(--fs-xs);
  color: var(--text-faint);
  margin-top: 0.3rem;
}
.energy-labels {
  display: flex;
  justify-content: space-between;
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-top: 0.4rem;
}
.slider-desc {
  text-align: center;
  font-size: var(--fs-sm);
  margin-top: 0.4rem;
  color: var(--text-muted);
}

.input-textarea {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-sunken);
  outline: none;
  resize: vertical;
  min-height: 80px;
  transition: border-color var(--dur) var(--ease);
}
.input-textarea::placeholder { color: var(--text-faint); }
.input-textarea:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}

.diary-footer { padding: 1rem 0; }
.btn-save {
  width: 100%;
  padding: 0.85rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur) var(--ease);
}
.btn-save:hover { background: var(--primary-strong); }
.btn-save:disabled { opacity: 0.5; cursor: not-allowed; }

.toast-success {
  position: fixed;
  top: 1.2rem;
  left: 50%;
  transform: translateX(-50%);
  background: var(--text-strong);
  color: var(--bg-base);
  padding: 0.5rem 1rem;
  font-size: var(--fs-sm);
  z-index: 100;
  border-radius: var(--radius-sm);
  opacity: 0.92;
}

/* ===================== 提交日志抽屉 ===================== */
.log-overlay {
  position: fixed;
  inset: 0;
  z-index: 900;
  background: rgba(42, 42, 40, 0.35);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}
.log-drawer {
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: min(360px, 88vw);
  background: var(--bg-surface);
  border-left: 1px solid var(--bg-line);
  box-shadow: var(--shadow-float);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.log-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.2rem;
  border-bottom: 1px solid var(--bg-line);
}
.log-header h3 {
  font-size: var(--fs-lg);
  color: var(--text-strong);
}
.log-close {
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
.log-close:hover {
  background: var(--bg-hover);
  color: var(--text-strong);
}

.log-body {
  flex: 1;
  overflow-y: auto;
  padding: 0.8rem 1.2rem;
}
.log-empty {
  text-align: center;
  color: var(--text-muted);
  font-size: var(--fs-sm);
  padding: 2rem 0;
}
.log-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.log-item {
  padding: 0.7rem 0.9rem;
  background: var(--bg-sunken);
  border: 1px solid var(--border-soft);
  border-left: 3px solid transparent;
  border-radius: var(--radius-sm);
}
.log-item.current {
  border-left-color: var(--primary);
  background: var(--bg-surface);
}
.log-main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.3rem;
}
.log-date {
  font-size: var(--fs-sm);
  font-weight: 500;
  color: var(--text-strong);
}
.log-eff {
  font-size: var(--fs-sm);
  font-weight: 600;
}
.log-eff.good { color: var(--primary); }
.log-eff.fair { color: var(--accent-clay); }
.log-eff.warn { color: var(--accent-clay); }
.log-eff.bad { color: var(--text-muted); }
.log-meta {
  display: flex;
  gap: 0.8rem;
  font-size: var(--fs-xs);
  color: var(--text-muted);
}
.log-notes {
  margin-top: 0.3rem;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  line-height: 1.5;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-footer {
  padding: 0.9rem 1.2rem calc(0.9rem + var(--safe-bottom));
  border-top: 1px solid var(--bg-line);
  background: var(--bg-surface);
}
.btn-close-log {
  width: 100%;
  padding: 0.75rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur) var(--ease);
}
.btn-close-log:hover { background: var(--primary-strong); }

/* 抽屉过渡 */
.drawer-enter-active,
.drawer-leave-active {
  transition: opacity 220ms var(--ease);
}
.drawer-enter-active .log-drawer,
.drawer-leave-active .log-drawer {
  transition: transform 220ms var(--ease);
}
.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
}
.drawer-enter-from .log-drawer,
.drawer-leave-to .log-drawer {
  transform: translateX(100%);
}

@media (prefers-reduced-motion: reduce) {
  .drawer-enter-active,
  .drawer-leave-active,
  .drawer-enter-active .log-drawer,
  .drawer-leave-active .log-drawer {
    transition: none;
  }
}

@keyframes fadeInOut {
  0% { opacity: 0; }
  20% { opacity: 1; }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
