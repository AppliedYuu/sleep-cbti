<template>
  <div class="assessment-page">
    <!-- 顶部：纯文字 -->
    <div class="top-bar">
      <router-link to="/" class="back-link">← 返回</router-link>
      <h1 class="serif">睡眠健康测评</h1>
      <button class="toggle-btn" @click="showHistory = !showHistory">
        {{ showHistory ? '回到测评' : '历史记录' }}
      </button>
    </div>

    <!-- 测评 iframe -->
    <div v-if="!showHistory" class="iframe-wrap">
      <div v-if="loading" class="loading-state">
        <span>测评加载中…</span>
      </div>
      <iframe
        ref="iframeRef"
        src="/sleep-h5/index.html"
        class="assessment-iframe"
        @load="onIframeLoad"
        allow="clipboard-write"
      ></iframe>
    </div>

    <!-- 历史列表 -->
    <section v-else class="history-panel">
      <h2 class="serif">测评历史</h2>
      <p v-if="history.length === 0" class="empty">暂无测评记录</p>
      <ol v-else class="history-list">
        <li v-for="(item, i) in history" :key="i" class="history-row">
          <div class="hr-head">
            <span class="hr-date">{{ formatDate(item.completed_at) }}</span>
            <span class="hr-score serif" :style="{ color: scoreColor(item.total_score) }">
              {{ item.total_score }}<span class="hr-score-unit">分</span>
            </span>
          </div>
          <div class="hr-dims">
            <span>睡眠质量 {{ item.sleep_quality }}</span>
            <span>习惯 {{ item.habit }}</span>
            <span>认知 {{ item.cognition }}</span>
            <span>时长 {{ item.duration }}</span>
          </div>
        </li>
      </ol>
    </section>

    <p v-if="toast" class="toast">{{ toast }}</p>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useAuthStore } from '@/stores/auth';
import request from '@/api/request';

const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);

const iframeRef = ref(null);
const loading = ref(true);
const showHistory = ref(false);
const history = ref([]);
const toast = ref('');

function onIframeLoad() { loading.value = false; }

function handleMessage(e) {
  if (e.data?.type === 'sleepAssessmentResult' && e.data.scores) {
    saveScores(e.data.scores);
  }
}

async function saveScores(scores) {
  try {
    await request.post('/assessment/save', {
      userId: userId.value,
      scores: {
        total: scores.total,
        sleepQuality: scores.sleepQuality,
        duration: scores.duration,
        habit: scores.habit,
        cognition: scores.cognition,
      },
    });
    toast.value = '分数已保存';
    setTimeout(() => { toast.value = ''; }, 2000);
    loadHistory();
  } catch (e) {
    toast.value = '保存失败：' + (e.response?.data?.message || '网络错误');
    setTimeout(() => { toast.value = ''; }, 3000);
  }
}

async function loadHistory() {
  try {
    const res = await request.get(`/assessment/history/${userId.value}`);
    history.value = res.data || [];
  } catch { history.value = []; }
}

function formatDate(d) {
  if (!d) return '';
  return new Date(d).toLocaleString('zh-CN', {
    month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
  });
}

function scoreColor(s) {
  if (s >= 80) return '#7C9885';   // sage：良好
  if (s >= 60) return '#C97B5A';   // clay：中等
  return '#8A8A85';                // muted：偏低
}

onMounted(() => {
  window.addEventListener('message', handleMessage);
  loadHistory();
});
onUnmounted(() => window.removeEventListener('message', handleMessage));
</script>

<style scoped>
.assessment-page {
  min-height: 100vh;
  padding: 1rem 1.4rem 3rem;
}

/* 顶部条：纯文字 */
.top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.6rem 0 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
}
.back-link {
  color: var(--text-muted);
  text-decoration: none;
  font-size: var(--fs-sm);
  transition: color var(--dur) var(--ease);
}
.back-link:hover { color: var(--text-strong); }

.top-bar h1 {
  font-size: var(--fs-lg);
  font-weight: 500;
  color: var(--text-strong);
  margin: 0;
}

.toggle-btn {
  background: transparent;
  border: 1px solid var(--border);
  color: var(--text-base);
  font-size: var(--fs-sm);
  font-family: inherit;
  padding: 0.35rem 0.8rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease);
}
.toggle-btn:hover {
  border-color: var(--primary);
  color: var(--primary);
}

/* iframe */
.iframe-wrap {
  flex: 1 1 auto;
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-sm);
  background: var(--bg-sunken);
  min-height: 70vh;
}
.loading-state {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  font-size: var(--fs-sm);
}
.assessment-iframe {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  border: none;
  display: block;
}

/* 历史列表 */
.history-panel { min-height: 60vh; }
.history-panel h2 {
  font-size: var(--fs-xl);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 1rem;
}
.empty {
  color: var(--text-muted);
  text-align: center;
  padding: 3rem 0;
  font-size: var(--fs-sm);
}
.history-list { list-style: none; }
.history-row {
  padding: 1rem 0;
  border-bottom: 1px solid var(--bg-line);
}
.history-row:last-child { border-bottom: none; }

.hr-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.4rem;
}
.hr-date {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}
.hr-score {
  font-size: 1.3rem;
  font-weight: 500;
}
.hr-score-unit {
  font-size: var(--fs-sm);
  margin-left: 2px;
  color: var(--text-muted);
  font-family: var(--font-base);
  font-weight: 400;
}
.hr-dims {
  display: flex;
  gap: 0.9rem;
  flex-wrap: wrap;
  font-size: var(--fs-xs);
  color: var(--text-muted);
}

/* Toast */
.toast {
  position: fixed;
  top: 1.5rem;
  left: 50%;
  transform: translateX(-50%);
  background: var(--text-strong);
  color: var(--bg-base);
  padding: 0.5rem 1rem;
  font-size: var(--fs-sm);
  z-index: 999;
  border-radius: var(--radius-sm);
  opacity: 0.92;
}
</style>