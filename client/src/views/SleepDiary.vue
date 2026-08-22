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
      <h3>📈 近7天睡眠效率趋势</h3>
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
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { saveDiary, getDiary, getEfficiencyTrend } from '@/api/diary';

import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);
const diaryDate = ref(todayStr());
const saving = ref(false);
const showSuccess = ref(false);
const trend = ref([]);

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
    const res = await getEfficiencyTrend(userId.value, 7);
    trend.value = res.data || [];
  } catch {
    trend.value = [];
  }
}

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
  /* 静谧夜空背景（与 Login / Home 一致） */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.12), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.10), transparent 55%),
    linear-gradient(180deg, #0b1020 0%, #0f1426 60%, #0c1124 100%);
  background-attachment: fixed;
  padding: 0 1.1rem 3rem;
  color: var(--text-base);
}

.diary-header {
  padding: 1.5rem 1.2rem 0.9rem;
  text-align: center;
  border-bottom: 1px solid var(--border-soft);
  margin-bottom: 0.4rem;
}

.btn-back-link {
  display: inline-block;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.85rem;
  margin-bottom: 0.5rem;
  transition: color var(--dur-fast) var(--ease-out);
}
.btn-back-link:hover { color: var(--primary); }

.diary-header h1 {
  font-size: 1.3rem;
  color: var(--text-strong);
  letter-spacing: 0.04em;
  text-shadow: 0 0 18px var(--primary-glow);
}

.diary-date {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-top: 0.2rem;
}

/* 日期选择器 */
.date-picker {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.8rem;
  padding: 1rem;
  background: var(--bg-glass);
  margin: 0.8rem 0;
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.btn-date {
  padding: 0.4rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  background: var(--bg-soft);
  font-size: 0.8rem;
  font-family: inherit;
  cursor: pointer;
  color: var(--text-base);
  transition: border-color var(--dur-fast) var(--ease-out),
              color var(--dur-fast) var(--ease-out),
              transform var(--dur-fast) var(--ease-out);
}
.btn-date:hover { border-color: var(--primary); color: var(--primary); }
.btn-date:active { transform: scale(0.97); }

.input-date {
  padding: 0.4rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  outline: none;
  text-align: center;
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.input-date::placeholder { color: var(--text-faint); }
.input-date:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

/* 趋势卡片 */
.trend-card {
  background: var(--bg-glass);
  margin: 0 0 0.8rem;
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.trend-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-card), var(--glow-primary);
}

.trend-card h3 {
  font-size: 0.9rem;
  color: var(--text-strong);
  margin-bottom: 0.8rem;
}

.trend-bars {
  display: flex;
  gap: 0.5rem;
  justify-content: space-around;
  align-items: flex-end;
  height: 100px;
}

.trend-bar-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}

.trend-bar-item.today .bar-fill {
  opacity: 1;
  box-shadow: 0 0 10px var(--primary-glow);
}

.bar-fill-wrapper {
  width: 100%;
  height: 60px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.bar-fill {
  width: 22px;
  border-radius: var(--radius-sm) var(--radius-sm) 0 0;
  min-height: 4px;
  transition: height var(--dur-slow) var(--ease-out), background var(--dur-base) var(--ease-out);
  opacity: 0.85;
}

/* 睡眠效率色阶：good(≥85%) 薄荷 / fair(75-85%) 警告 / poor(<75%) 危险 */
.bar-fill.good { background: var(--accent-mint); box-shadow: 0 0 10px var(--glow-mint); }
.bar-fill.fair { background: var(--warning); }
.bar-fill.warn { background: var(--danger); }
.bar-fill.bad  { background: var(--danger); }

.bar-label {
  font-size: 0.65rem;
  color: var(--text-faint);
  margin-top: 0.3rem;
}

.bar-value {
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--text-strong);
}

/* 表单 */
.diary-form {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.form-group {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.form-group:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-card), var(--glow-primary);
}

.form-group label {
  display: block;
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--text-strong);
  margin-bottom: 0.6rem;
}

.input-field {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 1rem;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  outline: none;
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.input-field::placeholder { color: var(--text-faint); }
.input-field:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.input-select {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 1.1rem;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  outline: none;
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
  appearance: auto;
  -webkit-appearance: auto;
}
.input-select:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.time-split {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.input-split {
  padding: 0.55rem 0.6rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 1.2rem;
  font-weight: 600;
  font-family: inherit;
  color: var(--text-strong);
  outline: none;
  background: var(--bg-soft);
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
  text-align: center;
  flex: 1;
  appearance: auto;
  -webkit-appearance: auto;
}
.input-split:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.time-colon {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--primary);
  flex-shrink: 0;
}

.hint {
  display: block;
  font-size: 0.75rem;
  color: var(--text-faint);
  margin-top: 0.3rem;
}

/* 滑块组 */
.slider-group {
  padding-bottom: 0.5rem;
}

.slider-value-display {
  text-align: center;
  margin-bottom: 0.5rem;
}

.big-value {
  font-size: 2.2rem;
  font-weight: 700;
  color: var(--primary);
  text-shadow: 0 0 16px var(--primary-glow);
}

.unit {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-left: 0.2rem;
}

.range-input {
  width: 100%;
  -webkit-appearance: none;
  appearance: none;
  height: 8px;
  border-radius: var(--radius-pill);
  background: linear-gradient(to right, var(--danger), var(--warning), var(--accent-mint));
  outline: none;
}
.range-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-soft);
  box-shadow: var(--glow-primary);
  cursor: pointer;
  transition: transform var(--dur-fast) var(--ease-out);
}
.range-input::-webkit-slider-thumb:active { transform: scale(1.12); }
.range-input::-moz-range-thumb {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-soft);
  box-shadow: var(--glow-primary);
  cursor: pointer;
}

.energy-range {
  background: linear-gradient(to right, var(--danger), var(--warning), var(--accent-mint));
}

.slider-marks {
  display: flex;
  justify-content: space-between;
  font-size: 0.7rem;
  color: var(--text-faint);
  margin-top: 0.3rem;
}

.energy-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  color: var(--text-muted);
  margin-top: 0.4rem;
}

.slider-desc {
  text-align: center;
  font-size: 0.82rem;
  margin-top: 0.4rem;
  color: var(--accent-mint);
  font-weight: 500;
}

.input-textarea {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  outline: none;
  resize: vertical;
  transition: border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.input-textarea::placeholder { color: var(--text-faint); }
.input-textarea:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.diary-footer {
  padding: 1rem 0;
}

.btn-save {
  width: 100%;
  padding: 0.85rem;
  background: var(--accent-mint);
  color: var(--bg-deep);
  border: none;
  border-radius: var(--radius-pill);
  font-size: 1rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  box-shadow: var(--glow-mint);
  transition: transform var(--dur-fast) var(--ease-out),
              opacity var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.btn-save:hover {
  box-shadow: var(--glow-mint), 0 0 32px rgba(94, 234, 212, 0.35);
}
.btn-save:active { transform: scale(0.98); }
.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  box-shadow: none;
}

.toast-success {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(11, 16, 32, 0.92);
  color: var(--accent-mint);
  padding: 0.6rem 1.5rem;
  border-radius: var(--radius-pill);
  border: 1px solid var(--accent-mint);
  font-weight: 600;
  font-size: 0.9rem;
  z-index: 100;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  box-shadow: var(--glow-mint);
  animation: fadeInOut 2s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
