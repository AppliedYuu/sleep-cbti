<template>
  <div class="report-page">
    <div class="report-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1>📊 睡眠改善周报</h1>
      <div class="week-picker">
        <button class="btn-week" @click="prevWeek">◀</button>
        <span class="week-range">{{ displayWeekRange }}</span>
        <button class="btn-week" @click="nextWeek" :disabled="isCurrentWeek">▶</button>
      </div>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else-if="!report.ready" class="not-ready">
      <span class="nr-icon">📭</span>
      <p>{{ report.message || '本周暂无数据' }}</p>
      <router-link to="/diary" class="btn-to-diary">📓 去记录睡眠日记</router-link>
    </div>

    <div v-else>
      <!-- 评级 -->
      <div class="rating-card" :style="{ borderColor: report.rating.color }">
        <span class="rating-emoji">{{ report.rating.emoji }}</span>
        <div class="rating-info">
          <span class="rating-level" :style="{ color: report.rating.color }">{{ report.rating.level }}</span>
          <span class="rating-score">综合评分 {{ report.rating.score }} 分</span>
        </div>
      </div>

      <section class="section">
        <h3>🔑 关键指标</h3>
        <div class="metrics-grid">
          <div class="metric-item">
            <span class="metric-val">{{ report.current.avgEfficiency }}%</span>
            <span class="metric-label">睡眠效率</span>
          </div>
          <div class="metric-item">
            <span class="metric-val">{{ report.current.avgLatency }}分钟</span>
            <span class="metric-label">入睡耗时</span>
          </div>
          <div class="metric-item">
            <span class="metric-val">{{ report.current.avgEnergy }}/10</span>
            <span class="metric-label">日间精力</span>
          </div>
          <div class="metric-item">
            <span class="metric-val">{{ report.current.diaryCount }}天</span>
            <span class="metric-label">记录天数</span>
          </div>
        </div>
      </section>

      <section class="section" v-if="report.highlights?.length">
        <h3>✨ 亮点</h3>
        <div v-for="(h, i) in report.highlights" :key="i" class="highlight-item">
          <span class="hi-icon">{{ h.icon }}</span> {{ h.text }}
        </div>
      </section>

      <section class="section">
        <h3>💡 建议</h3>
        <div v-for="(s, i) in report.suggestions" :key="i" class="suggestion-item">
          <span class="si-dot">{{ i + 1 }}</span> {{ s }}
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useAuthStore } from '@/stores/auth';
import request from '@/api/request';

const authStore = useAuthStore();
const loading = ref(false);
const report = ref({ ready: false });
const weekOffset = ref(0);

const displayWeekRange = computed(() => {
  const { start, end } = getWeekDates(weekOffset.value);
  return `${start} ~ ${end}`;
});
const isCurrentWeek = computed(() => weekOffset.value >= 0);

function getWeekDates(offset) {
  const now = new Date();
  now.setDate(now.getDate() + offset * 7);
  const dow = now.getDay();
  const monOff = dow === 0 ? -6 : 1 - dow;
  const mon = new Date(now);
  mon.setDate(now.getDate() + monOff);
  const sun = new Date(mon);
  sun.setDate(mon.getDate() + 6);
  return { start: mon.toISOString().slice(0, 10), end: sun.toISOString().slice(0, 10) };
}

function prevWeek() { weekOffset.value--; doLoad(); }
function nextWeek() { if (!isCurrentWeek.value) { weekOffset.value++; doLoad(); } }

async function doLoad() {
  const id = authStore.user?.id;
  if (!id) return;
  loading.value = true;
  try {
    const { start, end } = getWeekDates(weekOffset.value);
    const res = await request.get('/report/weekly/' + id, { params: { weekStart: start, weekEnd: end } });
    report.value = res.data || { ready: false };
  } catch(e) {
    report.value = { ready: false, message: '加载失败' };
    console.error(e);
  }
  loading.value = false;
}

watch(() => authStore.user?.id, id => { if (id) doLoad(); }, { immediate: true });
</script>

<style scoped>
/* 静谧夜空 · 睡眠改善周报 */
.report-page {
  min-height: 100vh;
  /* 夜空背景：与全局 body 渐变保持一致 */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.12), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.10), transparent 55%),
    linear-gradient(180deg, var(--bg-deep) 0%, var(--bg-base) 60%, #0c1124 100%);
  padding: 0 1.1rem 3rem;
  color: var(--text-base);
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

@keyframes rise-in {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}

.report-header {
  padding: 1.5rem 0.4rem 1rem;
  text-align: center;
  background: linear-gradient(135deg, rgba(125, 211, 252, 0.18), rgba(138, 180, 248, 0.12));
  border: 1px solid var(--border-soft);
  border-radius: 0 0 var(--radius-lg) var(--radius-lg);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--shadow-soft);
}

.btn-back-link {
  display: inline-block;
  color: var(--accent-cyan);
  text-decoration: none;
  font-size: var(--fs-sm);
  margin-bottom: var(--space-2);
  transition: color var(--dur-fast) var(--ease-out);
}
.btn-back-link:hover { color: var(--text-strong); }

.report-header h1 {
  font-size: var(--fs-xl);
  color: var(--text-strong);
  background: linear-gradient(135deg, #fff 0%, var(--accent-cyan) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  text-shadow: 0 0 24px rgba(125, 211, 252, 0.25);
}

.week-picker {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-3);
  margin-top: var(--space-2);
}

.btn-week {
  background: var(--bg-glass);
  border: 1px solid var(--border-mid);
  color: var(--accent-cyan);
  padding: 0.3rem 0.7rem;
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  cursor: pointer;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition: transform var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.btn-week:hover:not(:disabled) {
  border-color: var(--border-glow);
  box-shadow: var(--glow-primary);
  transform: translateY(-2px);
}
.btn-week:active:not(:disabled) { transform: scale(0.95); }
.btn-week:disabled { opacity: 0.3; cursor: not-allowed; }

.week-range {
  font-size: var(--fs-sm);
  min-width: 180px;
  color: var(--text-base);
}

.loading, .not-ready {
  text-align: center;
  padding: 3rem 1rem;
  color: var(--text-muted);
}
.loading { animation: pulse 1.6s ease-in-out infinite; }
@keyframes pulse { 0%, 100% { opacity: 0.6; } 50% { opacity: 1; } }

.nr-icon {
  font-size: 3rem;
  display: block;
  margin-bottom: var(--space-2);
  filter: drop-shadow(0 0 14px var(--primary-glow));
}

.btn-to-diary {
  display: inline-block;
  padding: 0.6rem 1.5rem;
  background: var(--accent-cyan);
  color: var(--bg-deep);
  border-radius: var(--radius-pill);
  text-decoration: none;
  margin-top: var(--space-3);
  font-weight: 600;
  box-shadow: 0 0 22px rgba(125, 211, 252, 0.35);
  transition: transform var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.btn-to-diary:hover {
  transform: translateY(-2px);
  box-shadow: 0 0 28px rgba(125, 211, 252, 0.5);
}

/* 玻璃卡片：评级卡 */
.rating-card {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin: var(--space-3) 0;
  padding: var(--space-3);
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-left: 6px solid var(--accent-cyan);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.rating-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-card), 0 0 24px rgba(125, 211, 252, 0.22);
}

.rating-emoji {
  font-size: 2.5rem;
  filter: drop-shadow(0 0 14px var(--primary-glow));
}

.rating-level {
  font-size: var(--fs-xl);
  font-weight: 700;
  display: block;
  color: var(--text-strong);
  text-shadow: 0 0 16px var(--primary-glow);
}

.rating-score {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

/* 玻璃卡片：各区块 */
.section {
  margin: var(--space-3) 0;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: var(--space-3);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.section:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-card), 0 0 20px rgba(125, 211, 252, 0.18);
}

.section h3 {
  font-size: var(--fs-md);
  margin-bottom: var(--space-2);
  color: var(--text-strong);
}

.metrics-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-2);
}

/* 指标块：趋势数据底色，cyan → primary 渐变描边感 */
.metric-item {
  text-align: center;
  padding: var(--space-2);
  background: var(--bg-soft);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-sm);
  transition: transform var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) var(--ease-out);
}
.metric-item:hover {
  transform: translateY(-2px);
  border-color: var(--border-glow);
}

.metric-val {
  display: block;
  font-size: var(--fs-xl);
  font-weight: 700;
  color: var(--text-strong);
  text-shadow: 0 0 16px rgba(125, 211, 252, 0.35);
}

.metric-label {
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: 0.2rem;
}

/* 亮点：正向趋势用 mint 强调 */
.highlight-item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--fs-sm);
  color: var(--text-base);
  padding: 0.3rem 0;
}
.highlight-item .hi-icon {
  flex-shrink: 0;
  filter: drop-shadow(0 0 8px var(--glow-mint));
}

/* 建议项 */
.suggestion-item {
  display: flex;
  align-items: flex-start;
  gap: var(--space-1);
  font-size: var(--fs-sm);
  color: var(--text-muted);
  padding: 0.3rem 0;
}

.si-dot {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--accent-cyan);
  color: var(--bg-deep);
  font-size: var(--fs-xs);
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 0 12px rgba(125, 211, 252, 0.4);
}
</style>
