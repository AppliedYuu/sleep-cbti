<template>
  <div class="assessment-page">
    <!-- 顶部导航 -->
    <div class="top-bar">
      <router-link to="/" class="btn-back">← 返回</router-link>
      <h1>睡眠健康测评</h1>
      <button class="btn-history" @click="showHistory = !showHistory">
        {{ showHistory ? '回到测评' : '📋 历史' }}
      </button>
    </div>

    <!-- 模式1：iframe 测评 -->
    <div v-if="!showHistory" class="iframe-wrap">
      <div v-if="loading" class="loading-state">
        <span class="loading-icon">⏳</span>
        <p>测评加载中...</p>
      </div>
      <iframe
        ref="iframeRef"
        src="/sleep-h5/index.html"
        class="assessment-iframe"
        @load="onIframeLoad"
        allow="clipboard-write"
      ></iframe>
    </div>

    <!-- 模式2：历史记录 -->
    <div v-else class="history-panel">
      <h2>📋 测评历史</h2>
      <div v-if="history.length === 0" class="empty">暂无测评记录</div>
      <div v-for="(item, i) in history" :key="i" class="history-card">
        <div class="hc-header">
          <span class="hc-date">{{ formatDate(item.completed_at) }}</span>
          <span class="hc-score" :style="{color: scoreColor(item.total_score)}">
            {{ item.total_score }} 分
          </span>
        </div>
        <div class="hc-dims">
          <span>睡眠质量 {{ item.sleep_quality }}</span>
          <span>习惯 {{ item.habit }}</span>
          <span>认知 {{ item.cognition }}</span>
          <span>时长 {{ item.duration }}</span>
        </div>
      </div>
    </div>

    <!-- 保存成功提示 -->
    <div v-if="toast" class="toast">{{ toast }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
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

// 监听 iframe 的 postMessage
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
    toast.value = '✅ 分数已保存！';
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
  if (s >= 80) return '#5eead4'; // --success (mint)
  if (s >= 60) return '#ffd28a'; // --warning (amber)
  return '#ff8a9b';              // --danger (rose)
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
  display: flex;
  flex-direction: column;
  padding: 0 1.1rem 3rem;
  /* 静谧夜空背景，与全局 body 渐变协调 */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.10), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.08), transparent 55%),
    linear-gradient(180deg, var(--bg-deep) 0%, var(--bg-base) 60%, #0c1124 100%);
  background-attachment: fixed;
}

.top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.7rem 0;
  margin-bottom: 0.6rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  color: var(--text-strong);
  flex-shrink: 0;
  z-index: 10;
  padding-left: 0.9rem;
  padding-right: 0.9rem;
}

.top-bar h1 {
  font-size: 1rem;
  margin: 0;
  color: var(--text-strong);
}

.btn-back {
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.85rem;
  transition: color var(--dur-fast) var(--ease-out);
}
.btn-back:hover { color: var(--primary); }

.btn-history {
  background: var(--bg-soft);
  border: 1px solid var(--border-mid);
  color: var(--text-strong);
  padding: 0.35rem 0.8rem;
  border-radius: var(--radius-pill);
  font-size: 0.8rem;
  cursor: pointer;
  transition: transform var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.btn-history:hover {
  transform: translateY(-2px);
  border-color: var(--primary);
  box-shadow: var(--glow-primary);
}
.btn-history:active { transform: scale(0.98); }

.iframe-wrap {
  flex: 1 1 auto;
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-md);
  background: var(--bg-soft);
  box-shadow: var(--shadow-soft);
  /* 保证 iframe 容器有确定高度，避免 height:100% 塌缩 */
  min-height: 70vh;
}

.loading-state {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  z-index: 5;
}

.loading-icon {
  font-size: 2rem;
  animation: pulse 1.5s infinite;
  filter: drop-shadow(0 0 12px var(--primary-glow));
}

@keyframes pulse {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 1; }
}

.assessment-iframe {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  border: none;
  display: block;
}

/* 历史面板 */
.history-panel {
  flex: 1 1 auto;
  overflow-y: auto;
  padding: 0.4rem 0;
  min-height: 60vh;
}

.history-panel h2 {
  font-size: 1.1rem;
  color: var(--text-strong);
  margin-bottom: 0.8rem;
}

.empty {
  text-align: center;
  color: var(--text-faint);
  padding: 3rem;
}

.history-card {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-left: 4px solid var(--primary);
  border-radius: var(--radius-md);
  padding: 0.8rem 1rem;
  margin-bottom: 0.6rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
/* PSQI / SHPS / DBAS 三大量表尺度强调色 */
.history-card:nth-of-type(3n+1) { border-left-color: var(--primary); }
.history-card:nth-of-type(3n+2) { border-left-color: var(--accent-mint); }
.history-card:nth-of-type(3n+3) { border-left-color: var(--accent-purple); }
.history-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-card), var(--glow-primary);
}

.hc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.4rem;
}

.hc-date { font-size: 0.8rem; color: var(--text-muted); }

.hc-score {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--text-strong);
}

.hc-dims {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.hc-dims span {
  font-size: 0.72rem;
  color: var(--text-muted);
  background: var(--bg-soft);
  padding: 0.15rem 0.5rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-soft);
}

.toast {
  position: fixed;
  top: 60px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--bg-glass-strong);
  color: var(--text-strong);
  padding: 0.5rem 1.2rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  font-size: 0.85rem;
  z-index: 999;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  box-shadow: var(--shadow-float);
  animation: fade 2s ease;
}

@keyframes fade {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
