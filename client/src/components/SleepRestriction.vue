<template>
  <div class="sleep-restriction">
    <!-- 未就绪状态 -->
    <div v-if="!data.ready" class="not-ready">
      <div class="nr-icon">📊</div>
      <h3>数据收集中</h3>
      <p>{{ data.message }}</p>
      <router-link to="/diary" class="btn-to-diary">📓 去记录睡眠日记</router-link>
    </div>

    <!-- 处方 -->
    <div v-else>
      <!-- 效率概览 -->
      <div class="efficiency-card" :class="efficiencyClass">
        <span class="eff-icon">{{ efficiencyIcon }}</span>
        <div class="eff-info">
          <span class="eff-value">{{ data.avgEfficiency }}%</span>
          <span class="eff-label">平均睡眠效率</span>
        </div>
        <span class="eff-level">{{ data.efficiencyLevel }}</span>
      </div>

      <!-- 时间窗对比 -->
      <div class="window-compare">
        <div class="window-card current">
          <h4>📋 当前卧床</h4>
          <div class="time-range">
            <span class="time">{{ data.currentWindow.bedTime }}</span>
            <span class="arrow">→</span>
            <span class="time">{{ data.currentWindow.wakeTime }}</span>
          </div>
          <span class="duration">共 {{ data.currentWindow.timeInBed }}</span>
        </div>

        <div class="window-card suggested" v-if="data.avgEfficiency < 85">
          <h4>🎯 建议调整</h4>
          <div class="time-range">
            <span class="time highlight">{{ data.suggestedWindow.bedTime }}</span>
            <span class="arrow">→</span>
            <span class="time highlight">{{ data.suggestedWindow.wakeTime }}</span>
          </div>
          <span class="duration">共 {{ data.suggestedWindow.timeInBed }}</span>
          <p class="tip">{{ data.suggestedWindow.tip }}</p>
        </div>

        <div class="window-card good" v-else>
          <h4>✅ 保持当前作息</h4>
          <p class="tip">{{ data.suggestedWindow.tip }}</p>
        </div>
      </div>

      <!-- 效率趋势曲线 -->
      <div class="trend-section">
        <h3>📈 睡眠效率提升曲线</h3>
        <div class="trend-chart">
          <svg :viewBox="`0 0 ${chartW} ${chartH}`" class="efficiency-chart">
            <!-- 参考线 -->
            <line x1="0" :y1="y(85)" :x2="chartW" :y2="y(85)" stroke="#5eead4" stroke-dasharray="4,4" stroke-width="1" />
            <text :x="chartW - 30" :y="y(85) - 5" font-size="10" fill="#5eead4">85%目标</text>

            <!-- 折线 -->
            <polyline
              :points="linePoints"
              fill="none"
              stroke="#8ab4f8"
              stroke-width="2.5"
              stroke-linejoin="round"
              stroke-linecap="round"
            />

            <!-- 数据点 -->
            <circle
              v-for="(pt, i) in chartPoints"
              :key="i"
              :cx="pt.x"
              :cy="pt.y"
              r="4"
              fill="#0f1426"
              stroke="#8ab4f8"
              stroke-width="2"
            />

            <!-- 日期标签 -->
            <text
              v-for="(pt, i) in chartPoints"
              :key="'d-' + i"
              :x="pt.x"
              :y="chartH - 5"
              text-anchor="middle"
              font-size="9"
              fill="#8a93b2"
            >{{ formatDate(pt.date) }}</text>

            <!-- 效率值标签 -->
            <text
              v-for="(pt, i) in chartPoints"
              :key="'v-' + i"
              :x="pt.x"
              :y="pt.y - 10"
              text-anchor="middle"
              font-size="10"
              :fill="pt.val >= 85 ? '#5eead4' : '#ffd28a'"
              font-weight="600"
            >{{ pt.val }}%</text>
          </svg>
        </div>
      </div>

      <!-- 数据摘要 -->
      <div class="data-summary">
        <div class="ds-item">
          <span class="ds-val">{{ Math.round(data.avgSleepDuration) }}分钟</span>
          <span class="ds-label">平均实际睡眠</span>
        </div>
        <div class="ds-item">
          <span class="ds-val">{{ data.avgLatency }}分钟</span>
          <span class="ds-label">平均入睡耗时</span>
        </div>
        <div class="ds-item">
          <span class="ds-val">{{ Math.round(data.avgTimeInBed) }}分钟</span>
          <span class="ds-label">平均卧床时间</span>
        </div>
      </div>
    </div>

    <div v-if="loading" class="loading">加载中...</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { getSleepRestriction } from '@/api/intervention';

const props = defineProps({ userId: String });
const data = ref({ ready: false });
const loading = ref(true);

const chartW = 320;
const chartH = 160;
const padding = { top: 25, right: 10, bottom: 20, left: 10 };

const efficiencyClass = computed(() => {
  const v = data.value.avgEfficiency;
  if (v >= 85) return 'good';
  if (v >= 75) return 'fair';
  if (v >= 65) return 'warn';
  return 'bad';
});

const efficiencyIcon = computed(() => {
  const v = data.value.avgEfficiency;
  if (v >= 85) return '✅';
  if (v >= 75) return '⚠️';
  return '🔴';
});

const chartPoints = computed(() => {
  if (!data.value.efficiencyTrend) return [];
  return data.value.efficiencyTrend.map((d, i) => ({
    x: padding.left + (i / Math.max(data.value.efficiencyTrend.length - 1, 1)) * (chartW - padding.left - padding.right),
    y: y(d.efficiency),
    val: d.efficiency,
    date: d.date,
  }));
});

const linePoints = computed(() => {
  return chartPoints.value.map(p => `${p.x},${p.y}`).join(' ');
});

function y(val) {
  return chartH - padding.bottom - (val / 100) * (chartH - padding.top - padding.bottom);
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  return dateStr.slice(5); // MM-DD
}

onMounted(async () => {
  try {
    const res = await getSleepRestriction(props.userId);
    data.value = res.data;
  } catch { /* ignore */ }
  loading.value = false;
});
</script>

<style scoped>
.sleep-restriction {
  min-height: 200px;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

.not-ready {
  text-align: center;
  padding: 3rem 1rem;
}

.nr-icon { font-size: 3rem; margin-bottom: 1rem; }

.not-ready h3 {
  color: var(--text-strong);
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.not-ready p {
  color: var(--text-muted);
  font-size: var(--fs-sm);
  line-height: 1.5;
  margin-bottom: 1.5rem;
}

.btn-to-diary {
  display: inline-block;
  padding: 0.6rem 1.5rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border-radius: var(--radius-pill);
  text-decoration: none;
  font-size: var(--fs-md);
  font-weight: 600;
  box-shadow: var(--glow-primary);
  transition: transform var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              background var(--dur-base) var(--ease-out);
}

.btn-to-diary:hover {
  transform: translateY(-2px);
  background: var(--primary-strong);
  box-shadow: 0 0 28px rgba(138, 180, 248, 0.30);
}

.btn-to-diary:active {
  transform: scale(0.98);
}

.efficiency-card {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 1rem 1.2rem;
  border-radius: var(--radius-md);
  margin-bottom: 1rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--shadow-card);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.efficiency-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-float);
}

.efficiency-card.good {
  background: rgba(94, 234, 212, 0.12);
  border: 1px solid rgba(94, 234, 212, 0.35);
}
.efficiency-card.fair {
  background: rgba(255, 210, 138, 0.12);
  border: 1px solid rgba(255, 210, 138, 0.35);
}
.efficiency-card.warn {
  background: rgba(255, 155, 179, 0.12);
  border: 1px solid rgba(255, 155, 179, 0.35);
}
.efficiency-card.bad {
  background: rgba(255, 138, 155, 0.12);
  border: 1px solid rgba(255, 138, 155, 0.35);
}

.eff-icon { font-size: 1.8rem; }
.eff-info { flex: 1; }
.eff-value {
  font-size: var(--fs-2xl);
  font-weight: 700;
  color: var(--text-strong);
  display: block;
}
.eff-label { font-size: var(--fs-xs); color: var(--text-muted); }
.eff-level {
  font-weight: 600;
  font-size: var(--fs-sm);
  color: var(--text-base);
}

.window-compare {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
  margin-bottom: 1.2rem;
}

.window-card {
  padding: 1rem 1.2rem;
  border-radius: var(--radius-md);
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--shadow-card);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.window-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-float);
}

.window-card.suggested {
  border-left: 4px solid var(--primary);
  background: var(--bg-glass-strong);
}

.window-card.good {
  border-left: 4px solid var(--accent-mint);
  background: rgba(94, 234, 212, 0.12);
}

.window-card h4 {
  font-size: var(--fs-md);
  color: var(--text-strong);
  margin-bottom: 0.6rem;
  font-weight: 600;
}

.time-range {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 0.4rem;
}

.time {
  font-size: 1.8rem;
  font-weight: 700;
  font-family: 'Courier New', monospace;
  color: var(--text-base);
}

.time.highlight {
  color: var(--primary);
  background: var(--primary-weak);
  padding: 0.3rem 0.8rem;
  border-radius: var(--radius-sm);
}

.arrow { font-size: 1.2rem; color: var(--text-faint); }

.duration {
  display: block;
  text-align: center;
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.tip {
  text-align: center;
  font-size: var(--fs-sm);
  color: var(--primary);
  margin-top: 0.5rem;
  line-height: 1.5;
}

.trend-section {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-md);
  padding: 1rem;
  margin-bottom: 1rem;
  box-shadow: var(--shadow-card);
}

.trend-section h3 {
  font-size: var(--fs-lg);
  color: var(--text-strong);
  margin-bottom: 0.6rem;
  font-weight: 600;
}

.trend-chart { overflow-x: auto; }

.efficiency-chart { display: block; width: 100%; min-width: 320px; }

.data-summary {
  display: flex;
  gap: 0.5rem;
}

.ds-item {
  flex: 1;
  text-align: center;
  padding: 0.8rem 0.4rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-sm);
  box-shadow: var(--shadow-card);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.ds-item:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-float);
}

.ds-val {
  display: block;
  font-size: var(--fs-lg);
  font-weight: 700;
  color: var(--primary);
}
.ds-label {
  display: block;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: 0.2rem;
}

.loading {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
}
</style>
