<template>
  <div class="report-page">
    <div class="report-header">
      <button class="btn-back" @click="$emit('back')">← 返回</button>
      <h1>我的睡眠评估报告</h1>
      <p class="report-date">{{ reportDate }}</p>
    </div>

    <!-- 睡眠六维图 -->
    <section class="report-section">
      <h2>我的睡眠六维图</h2>
      <p class="section-desc">分数越高越好（0-100分），反映您的睡眠综合状况</p>
      <RadarChart :data="reportData.radarData" />
    </section>

    <!-- 量表结果概览 -->
    <section class="report-section">
      <h2>三大量表结果</h2>

      <div class="result-cards">
        <div class="result-card" :class="psqiClass">
          <div class="rc-header">
            <span class="rc-name">PSQI</span>
          </div>
          <div class="rc-score">{{ reportData.psqi?.totalScore }} <small>/ 21</small></div>
          <div class="rc-level">{{ psqiLevel }}</div>
        </div>

        <div class="result-card" :class="shpsClass">
          <div class="rc-header">
            <span class="rc-name">SHPS</span>
          </div>
          <div class="rc-score">{{ reportData.shps?.totalScore }} <small>/ 133</small></div>
          <div class="rc-level">{{ shpsLevel }}</div>
        </div>

        <div class="result-card" :class="dbas16Class">
          <div class="rc-header">
            <span class="rc-name">DBAS-16</span>
          </div>
          <div class="rc-score">{{ reportData.dbas16?.averageScore }} <small>/ 10</small></div>
          <div class="rc-level">{{ dbas16Level }}</div>
        </div>
      </div>
    </section>

    <!-- 综合评估 -->
    <section class="report-section">
      <h2>综合评估</h2>
      <div class="summary-box">
        <p>{{ reportData.summary }}</p>
      </div>
    </section>

    <!-- 干预策略推荐 -->
    <section class="report-section">
      <h2>干预策略推荐</h2>
      <div class="intervention-list">
        <div
          v-for="(item, idx) in reportData.interventions"
          :key="idx"
          class="intervention-card"
          :class="'priority-' + item.priority"
        >
          <div class="int-header">
            <span class="int-priority" :class="item.priority">
              {{ item.priority === 'high' ? '优先推荐' : item.priority === 'medium' ? '建议尝试' : '可选' }}
            </span>
          </div>
          <h4>{{ item.name }}</h4>
          <p>{{ item.reason }}</p>
        </div>
      </div>
    </section>

    <!-- 行动按钮 -->
    <div class="report-actions">
      <button class="btn-primary" @click="goToIntervention">查看详细干预方案</button>
      <button class="btn-secondary" @click="goToDiary">开始记录睡眠日记</button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import RadarChart from '@/components/RadarChart.vue';

const props = defineProps({
  reportData: { type: Object, required: true },
});

defineEmits(['back']);
const router = useRouter();

const reportDate = computed(() => new Date().toLocaleDateString('zh-CN', {
  year: 'numeric', month: 'long', day: 'numeric',
}));

const psqiLevel = computed(() => {
  const s = props.reportData.psqi?.totalScore;
  if (s <= 5) return '睡眠质量很好';
  if (s <= 10) return '睡眠质量还行';
  if (s <= 15) return '睡眠质量一般';
  return '睡眠质量很差';
});
const psqiClass = computed(() => {
  const s = props.reportData.psqi?.totalScore;
  if (s <= 5) return 'good';
  if (s <= 10) return 'fair';
  if (s <= 15) return 'warn';
  return 'bad';
});

const shpsLevel = computed(() => {
  const s = props.reportData.shps?.totalScore;
  if (s <= 33) return '习惯良好';
  if (s <= 66) return '习惯一般';
  if (s <= 99) return '习惯较差';
  return '习惯很差';
});
const shpsClass = computed(() => {
  const s = props.reportData.shps?.totalScore;
  if (s <= 33) return 'good';
  if (s <= 66) return 'fair';
  if (s <= 99) return 'warn';
  return 'bad';
});

const dbas16Level = computed(() => {
  const s = props.reportData.dbas16?.averageScore;
  if (s < 3.5) return '信念健康';
  if (s < 4.0) return '轻度不合理';
  if (s <= 5.0) return '需认知重构';
  return '不合理较严重';
});
const dbas16Class = computed(() => {
  const s = props.reportData.dbas16?.averageScore;
  if (s < 3.5) return 'good';
  if (s < 4.0) return 'fair';
  if (s <= 5.0) return 'warn';
  return 'bad';
});

function goToIntervention() {
  router.push('/intervention');
}

function goToDiary() {
  router.push('/diary');
}
</script>

<style scoped>
.report-page {
  padding-bottom: 100px;
  min-height: 100vh;
  background: var(--bg-base);
  color: var(--text-base);
}

/* 纸面头部：无渐变无玻璃 */
.report-header {
  padding: 1.5rem 1.2rem 1rem;
  background: var(--bg-base);
  border-bottom: 1px solid var(--border-soft);
  color: var(--text-strong);
  text-align: center;
}

.btn-back {
  background: transparent;
  border: 1px solid var(--border-mid);
  color: var(--text-base);
  padding: 0.35rem 0.8rem;
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  font-family: inherit;
  cursor: pointer;
  margin-bottom: 0.5rem;
  transition: border-color var(--dur-fast) var(--ease-out),
              color var(--dur-fast) var(--ease-out);
}

.btn-back:hover {
  border-color: var(--primary);
  color: var(--primary-strong);
}

.report-header h1 {
  font-size: 1.3rem;
  color: var(--text-strong);
}

.report-date {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-top: 0.3rem;
}

/* 实体纸卡分区 */
.report-section {
  background: var(--bg-surface);
  margin: 0.8rem 1.2rem;
  border-radius: var(--radius-md);
  padding: 1.2rem;
  border: 1px solid var(--border-soft);
  box-shadow: var(--shadow-card);
}

.report-section:hover {
  box-shadow: var(--shadow-float);
}

.report-section h2 {
  font-size: 1.05rem;
  color: var(--text-strong);
  margin-bottom: 0.3rem;
}

.section-desc {
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-bottom: 0.8rem;
}

.result-cards {
  display: flex;
  gap: 0.6rem;
  flex-wrap: wrap;
}

.result-card {
  flex: 1;
  min-width: 90px;
  text-align: center;
  padding: 0.8rem 0.5rem;
  border-radius: var(--radius-md);
  background: var(--bg-sunken);
  border: 1px solid var(--border-soft);
  border-left-width: 3px;
}

/* 四档状态：弱色铺底 + 左侧实色条，数字保持浓墨 */
.result-card.good {
  background: var(--accent-mint-weak);
  border-color: rgba(127, 179, 166, 0.35);
  border-left-color: var(--accent-mint);
}
.result-card.fair {
  background: var(--accent-amber-weak);
  border-color: rgba(217, 164, 65, 0.35);
  border-left-color: var(--accent-amber);
}
.result-card.warn {
  background: var(--accent-clay-weak);
  border-color: rgba(201, 123, 90, 0.35);
  border-left-color: var(--accent-clay);
}
.result-card.bad {
  background: var(--accent-rose-weak);
  border-color: rgba(217, 138, 158, 0.35);
  border-left-color: var(--accent-rose);
}

.rc-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.3rem;
  margin-bottom: 0.3rem;
}

.rc-name { font-size: var(--fs-sm); font-weight: 600; color: var(--text-muted); letter-spacing: 0.04em; }

.rc-score {
  font-family: var(--font-serif);
  font-size: 1.5rem;
  font-weight: 500;
  color: var(--text-strong);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.rc-score small { font-size: var(--fs-xs); color: var(--text-muted); }
.rc-level { font-size: var(--fs-xs); color: var(--text-muted); margin-top: 0.2rem; }

.summary-box {
  background: var(--bg-sunken);
  border-radius: var(--radius-sm);
  padding: 1rem;
  border-left: 3px solid var(--primary);
}

.summary-box p {
  font-size: var(--fs-md);
  color: var(--text-base);
  line-height: 1.6;
}

.intervention-list {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.intervention-card {
  padding: 1rem;
  border-radius: var(--radius-md);
  background: var(--bg-sunken);
  border: 1px solid var(--border-soft);
}

.intervention-card.priority-high {
  background: var(--primary-weak);
  border-color: rgba(124, 152, 133, 0.35);
}

.intervention-card.priority-medium {
  background: var(--accent-amber-weak);
  border-color: rgba(217, 164, 65, 0.40);
}

.int-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.4rem;
}

.int-priority {
  font-size: var(--fs-xs);
  padding: 0.15rem 0.5rem;
  border-radius: var(--radius-pill);
  font-weight: 500;
}

.int-priority.high { background: var(--primary); color: var(--text-on-primary); }
.int-priority.medium { background: var(--accent-amber); color: var(--bg-deep); }
.int-priority.low { background: var(--bg-surface); color: var(--text-muted); border: 1px solid var(--border-soft); }

.intervention-card h4 {
  font-size: var(--fs-lg);
  color: var(--text-strong);
  margin-bottom: 0.3rem;
}

.intervention-card p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  line-height: 1.4;
}

.report-actions {
  padding: 1rem 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.btn-primary,
.btn-secondary {
  padding: 0.8rem;
  border: none;
  border-radius: var(--radius-pill);
  font-size: 1rem;
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur) var(--ease),
              border-color var(--dur) var(--ease);
}

.btn-primary {
  background: var(--primary);
  color: var(--text-on-primary);
  font-weight: 500;
}

.btn-primary:hover {
  background: var(--primary-strong);
}

.btn-secondary {
  background: transparent;
  color: var(--primary-strong);
  border: 1px solid var(--border-mid);
}

.btn-secondary:hover {
  background: var(--bg-hover);
  border-color: var(--primary);
}
</style>
