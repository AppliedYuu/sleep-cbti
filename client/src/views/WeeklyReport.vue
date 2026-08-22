<template>
  <div class="report-page">
    <header class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1 class="serif">睡眠改善周报</h1>
      <p>每周数据总结 · 趋势分析 · 改善建议</p>
    </header>

    <nav class="week-picker">
      <button class="btn-week" @click="prevWeek">‹ 前一周</button>
      <span class="week-range serif">{{ displayWeekRange }}</span>
      <button class="btn-week" @click="nextWeek" :disabled="isCurrentWeek">后一周 ›</button>
    </nav>

    <p v-if="loading" class="status">加载中…</p>
    <p v-else-if="!hasData" class="status">
      本周还没有足够的睡眠日记数据。
      <router-link to="/diary" class="status-link">去记录 →</router-link>
    </p>

    <template v-else>
      <!-- 总体评级 -->
      <section class="rating-card">
        <div class="rating-row">
          <span class="rating-mark serif">{{ rating.emoji }}</span>
          <div class="rating-meta">
            <span class="rating-level serif">{{ rating.level }}</span>
            <span class="rating-score">{{ reportData.avgEfficiency }}% · 睡眠效率</span>
          </div>
        </div>
      </section>

      <!-- 数据指标 -->
      <section class="section">
        <h2 class="serif">数据指标</h2>
        <div class="metrics-grid">
          <div class="metric-item">
            <span class="metric-val serif">{{ reportData.avgDuration }}h</span>
            <span class="metric-label">平均时长</span>
          </div>
          <div class="metric-item">
            <span class="metric-val serif">{{ reportData.avgEfficiency }}%</span>
            <span class="metric-label">平均效率</span>
          </div>
          <div class="metric-item">
            <span class="metric-val serif">{{ reportData.avgLatency }}</span>
            <span class="metric-label">入睡耗时 (分)</span>
          </div>
          <div class="metric-item">
            <span class="metric-val serif">{{ reportData.avgAwakenings }}</span>
            <span class="metric-label">夜醒次数</span>
          </div>
        </div>
      </section>

      <!-- 亮点 -->
      <section v-if="highlights.length" class="section">
        <h2 class="serif">本周亮点</h2>
        <ul class="plain-list">
          <li v-for="(h, i) in highlights" :key="i" class="highlight-item">
            <span class="hi-mark" aria-hidden="true">·</span>
            <span class="hi-text">{{ h }}</span>
          </li>
        </ul>
      </section>

      <!-- 改善建议 -->
      <section v-if="suggestions.length" class="section">
        <h2 class="serif">改善建议</h2>
        <ol class="plain-list">
          <li v-for="(s, i) in suggestions" :key="i" class="suggestion-item">
            <span class="si-num serif">{{ i + 1 }}.</span>
            <span class="si-text">{{ s }}</span>
          </li>
        </ol>
      </section>

      <router-link to="/diary" class="btn-to-diary">查看我的睡眠日记 →</router-link>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import request from '@/api/request';
import { useAuthStore } from '@/stores/auth';

const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);

const weekOffset = ref(0);
const reportData = ref(null);
const loading = ref(true);
const isCurrentWeek = computed(() => weekOffset.value >= 0);

const rating = computed(() => {
  if (!reportData.value) return { level: '', emoji: '' };
  const e = reportData.value.avgEfficiency;
  if (e >= 85) return { level: '睡眠状态良好', emoji: '良' };
  if (e >= 75) return { level: '睡眠状态平稳', emoji: '平' };
  return { level: '需要关注', emoji: '差' };
});

const hasData = computed(() => reportData.value && reportData.value.avgDuration);

const displayWeekRange = computed(() => {
  const end = new Date();
  end.setDate(end.getDate() + weekOffset.value * 7);
  const start = new Date(end);
  start.setDate(end.getDate() - 6);
  const f = d => `${d.getMonth() + 1}.${d.getDate()}`;
  return `${f(start)} – ${f(end)}`;
});

const highlights = computed(() => reportData.value?.highlights || []);
const suggestions = computed(() => reportData.value?.suggestions || []);

async function load() {
  loading.value = true;
  try {
    const res = await request.get(`/report/${userId.value}?week=${weekOffset.value}`);
    reportData.value = res.data;
  } catch {
    reportData.value = null;
  } finally {
    loading.value = false;
  }
}
function prevWeek() { weekOffset.value -= 1; load(); }
function nextWeek() {
  if (isCurrentWeek.value) return;
  weekOffset.value += 1;
  load();
}

onMounted(load);
</script>

<style scoped>
.report-page {
  min-height: 100vh;
  padding: 1rem 1.4rem 3rem;
}

.page-header {
  padding: 0.6rem 0 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1rem;
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
.page-header h1 {
  font-size: var(--fs-xl);
  font-weight: 500;
  color: var(--text-strong);
  letter-spacing: 0.04em;
  margin-bottom: 0.3rem;
}
.page-header p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.week-picker {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
}
.btn-week {
  background: transparent;
  border: 1px solid var(--border);
  color: var(--text-base);
  font-family: inherit;
  font-size: var(--fs-sm);
  padding: 0.35rem 0.7rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease);
}
.btn-week:hover:not(:disabled) {
  border-color: var(--primary);
  color: var(--primary);
}
.btn-week:disabled { opacity: 0.4; cursor: not-allowed; }
.week-range {
  font-size: var(--fs-md);
  color: var(--text-strong);
}

.status {
  text-align: center;
  color: var(--text-muted);
  padding: 3rem 0;
  font-size: var(--fs-sm);
}
.status-link {
  display: block;
  margin-top: 0.8rem;
  color: var(--primary);
  text-decoration: none;
}

.rating-card {
  padding: 1.2rem 0;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
}
.rating-row {
  display: flex;
  align-items: center;
  gap: 1rem;
}
.rating-mark {
  font-size: 2.4rem;
  color: var(--primary);
  font-weight: 500;
  line-height: 1;
}
.rating-meta {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}
.rating-level {
  font-size: var(--fs-lg);
  color: var(--text-strong);
}
.rating-score {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.section {
  padding: 1.2rem 0;
  border-bottom: 1px solid var(--bg-line);
}
.section h2 {
  font-size: var(--fs-lg);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.9rem;
}

.metrics-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem 1.4rem;
}
.metric-item {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}
.metric-val {
  font-size: 1.5rem;
  font-weight: 500;
  color: var(--text-strong);
  line-height: 1;
}
.metric-label {
  font-size: var(--fs-xs);
  color: var(--text-muted);
}

.plain-list { list-style: none; }
.highlight-item,
.suggestion-item {
  display: flex;
  gap: 0.6rem;
  padding: 0.55rem 0;
  font-size: var(--fs-sm);
  color: var(--text-base);
  line-height: 1.7;
}
.hi-mark {
  color: var(--primary);
  font-weight: 600;
}
.si-num {
  color: var(--text-muted);
  font-weight: 500;
  flex-shrink: 0;
}
.hi-text, .si-text {
  color: var(--text-base);
  flex: 1;
}

.btn-to-diary {
  display: block;
  text-align: center;
  margin-top: 1.6rem;
  padding: 0.7rem;
  color: var(--primary);
  text-decoration: none;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease);
}
.btn-to-diary:hover {
  border-color: var(--primary);
}
</style>