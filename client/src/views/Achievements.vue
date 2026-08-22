<template>
  <div class="achievements-page">
    <div class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1>🏆 成就徽章</h1>
    </div>

    <!-- 进度概览 -->
    <div class="progress-card">
      <div class="progress-ring-container">
        <svg width="80" height="80" viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="34" fill="none" stroke="rgba(255,255,255,0.10)" stroke-width="5" />
          <circle
            cx="40" cy="40" r="34"
            fill="none" stroke="#ffd28a" stroke-width="5"
            :stroke-dasharray="2 * Math.PI * 34"
            :stroke-dashoffset="2 * Math.PI * 34 * (1 - (summary.progress || 0) / 100)"
            stroke-linecap="round"
            transform="rotate(-90 40 40)"
          />
        </svg>
        <div class="progress-text-center">
          <span class="ptc-num">{{ summary.totalUnlocked || 0 }}</span>
          <span class="ptc-div">/ {{ summary.totalBadges || 0 }}</span>
        </div>
      </div>
      <div class="progress-info">
        <h3>成就进度</h3>
        <p>{{ summary.progress || 0 }}% 完成</p>
        <div class="progress-bar-small">
          <div class="pbs-fill" :style="{ width: (summary.progress || 0) + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- 徽章网格 -->
    <div class="badges-grid">
      <div
        v-for="badge in badges"
        :key="badge.code"
        class="badge-card"
        :class="{ unlocked: badge.unlocked }"
      >
        <div class="badge-icon-wrap" :class="{ locked: !badge.unlocked }">
          <span class="badge-icon">{{ badge.unlocked ? badge.icon : '🔒' }}</span>
        </div>
        <h4>{{ badge.name }}</h4>
        <p>{{ badge.description }}</p>
        <span v-if="badge.unlocked" class="badge-date">
          {{ formatDate(badge.earnedAt) }}
        </span>
        <span v-else class="badge-locked-label">未解锁</span>
      </div>
    </div>

    <div class="refresh-area">
      <button class="btn-refresh" @click="refreshAchievements">🔄 刷新成就状态</button>
    </div>

    <!-- 解锁提示 -->
    <div v-if="showToast" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue';
import { getAchievements, checkAchievements } from '@/api/report';

import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);
const badges = ref([]);
const summary = reactive({ totalUnlocked: 0, totalBadges: 0, progress: 0 });
const toastMsg = ref('');
const showToast = ref(false);

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
}

async function loadAchievements() {
  try {
    const res = await getAchievements(userId.value);
    badges.value = res.data.badges || [];
    Object.assign(summary, res.data.summary || {});
  } catch { /* ignore */ }
}

async function refreshAchievements() {
  try {
    const res = await checkAchievements(userId.value);
    toastMsg.value = res.data.message;
    showToast.value = true;
    setTimeout(() => { showToast.value = false; }, 2500);
    loadAchievements();
  } catch { /* ignore */ }
}

watch(userId, (id) => { if (id) loadAchievements(); }, { immediate: true });
</script>

<style scoped>
.achievements-page {
  min-height: 100vh;
  /* 静谧夜空背景 */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.12), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.10), transparent 55%),
    linear-gradient(180deg, var(--bg-deep) 0%, var(--bg-base) 60%, #0c1124 100%);
  background-attachment: fixed;
  /* 移动端优先：根 padding */
  padding: 0 1.1rem 3rem;
}

.page-header {
  padding: var(--space-4) 0 var(--space-3);
  text-align: center;
  position: relative;
}

.btn-back-link {
  display: inline-block;
  color: var(--text-muted);
  text-decoration: none;
  font-size: var(--fs-sm);
  margin-bottom: var(--space-1);
  transition: color var(--dur-fast) var(--ease-out);
}
.btn-back-link:hover { color: var(--primary); }

.page-header h1 {
  font-size: var(--fs-xl);
  background: linear-gradient(135deg, #fff 0%, var(--accent-amber) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* 进度卡片 */
.progress-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin: var(--space-2) 0;
  padding: var(--space-3);
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.progress-ring-container {
  position: relative;
  flex-shrink: 0;
}

.progress-text-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}

.ptc-num {
  font-size: var(--fs-lg);
  font-weight: 700;
  color: var(--accent-amber);
  text-shadow: var(--glow-amber);
}
.ptc-div { font-size: var(--fs-xs); color: var(--text-faint); }

.progress-info { flex: 1; }
.progress-info h3 { font-size: var(--fs-md); color: var(--text-strong); }
.progress-info p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin: 0.2rem 0 0.4rem;
}

.progress-bar-small {
  height: 6px;
  background: var(--bg-soft);
  border-radius: var(--radius-pill);
  overflow: hidden;
}

.pbs-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--accent-amber), var(--primary));
  border-radius: var(--radius-pill);
  transition: width var(--dur-slow) var(--ease-out);
}

/* 徽章网格 */
.badges-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.6rem;
  padding: 0;
}

.badge-card {
  padding: 0.8rem 0.5rem;
  text-align: center;
  /* 玻璃卡片 */
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-left: 3px solid var(--text-faint);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
  /* 锁定/未解锁：去饱和 */
  opacity: 0.4;
  filter: grayscale(1);
  color: var(--text-faint);
}

.badge-card.unlocked {
  opacity: 1;
  filter: none;
  color: inherit;
  /* 已解锁：暖金光 + 金色左边框 */
  border-left-color: var(--accent-amber);
  box-shadow: var(--shadow-card), var(--glow-amber);
  animation: pop-in var(--dur-base) var(--ease-spring) both;
}

.badge-card.unlocked:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-float), var(--glow-amber);
}

.badge-icon-wrap {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: var(--bg-soft);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 0.4rem;
  border: 1px solid var(--border-mid);
}

.badge-card.unlocked .badge-icon-wrap {
  background: var(--bg-elevated);
  border-color: var(--accent-amber);
}

.badge-icon-wrap.locked {
  background: var(--bg-base);
  border-color: var(--border-soft);
}

.badge-icon {
  font-size: 2rem;
  filter: drop-shadow(0 0 10px var(--glow-amber));
}
.badge-icon-wrap.locked .badge-icon {
  filter: grayscale(1);
  opacity: 0.6;
}

.badge-card h4 {
  font-size: 0.78rem;
  color: var(--text-strong);
  margin-bottom: 0.15rem;
}

.badge-card p {
  font-size: 0.65rem;
  color: var(--text-muted);
  line-height: 1.3;
  margin-bottom: 0.3rem;
}

.badge-date {
  font-size: 0.62rem;
  color: var(--accent-amber);
  font-weight: 600;
}

.badge-locked-label {
  font-size: 0.62rem;
  color: var(--text-faint);
}

.refresh-area {
  text-align: center;
  margin-top: var(--space-4);
}

.btn-refresh {
  padding: 0.6rem 1.5rem;
  border: 1px solid var(--accent-amber);
  border-radius: var(--radius-pill);
  background: var(--bg-glass);
  color: var(--accent-amber);
  font-size: var(--fs-sm);
  cursor: pointer;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition: transform var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-fast) var(--ease-out);
}
.btn-refresh:hover {
  box-shadow: var(--glow-amber);
  transform: translateY(-2px);
}
.btn-refresh:active { transform: scale(0.97); }

.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(11, 16, 32, 0.92);
  color: var(--text-strong);
  padding: 0.6rem 1.5rem;
  border-radius: var(--radius-pill);
  border: 1px solid var(--border-mid);
  font-size: var(--fs-sm);
  z-index: 100;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  animation: fadeInOut 2.5s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}

/* 入场：已解锁徽章逐个弹入（CSS 动画错峰） */
.badges-grid .badge-card.unlocked:nth-child(3n+1) { animation-delay: 0.04s; }
.badges-grid .badge-card.unlocked:nth-child(3n+2) { animation-delay: 0.10s; }
.badges-grid .badge-card.unlocked:nth-child(3n+3) { animation-delay: 0.16s; }

/* 平板及以上：两列更宽松 */
@media (min-width: 600px) {
  .badges-grid { grid-template-columns: repeat(4, 1fr); }
}
</style>
