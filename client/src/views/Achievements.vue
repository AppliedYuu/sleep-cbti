<template>
  <div class="achievements-page">
    <header class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1 class="serif">成就徽章</h1>
    </header>

    <!-- 进度概览 -->
    <section class="progress-card">
      <div class="progress-ring-container">
        <svg width="80" height="80" viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="34" fill="none" stroke="var(--border)" stroke-width="5" />
          <circle
            cx="40" cy="40" r="34"
            fill="none" stroke="var(--primary)" stroke-width="5"
            :stroke-dasharray="2 * Math.PI * 34"
            :stroke-dashoffset="2 * Math.PI * 34 * (1 - (summary.progress || 0) / 100)"
            stroke-linecap="round"
            transform="rotate(-90 40 40)"
          />
        </svg>
        <div class="progress-text-center">
          <span class="ptc-num serif">{{ summary.totalUnlocked || 0 }}</span>
          <span class="ptc-div">/ {{ summary.totalBadges || 0 }}</span>
        </div>
      </div>
      <div class="progress-info">
        <h3 class="serif">成就进度</h3>
        <p>{{ summary.progress || 0 }}% 完成</p>
        <div class="progress-bar-small">
          <div class="pbs-fill" :style="{ width: (summary.progress || 0) + '%' }"></div>
        </div>
      </div>
    </section>

    <!-- 徽章网格 -->
    <ul class="badges-grid">
      <li
        v-for="badge in badges"
        :key="badge.code"
        class="badge-card"
        :class="{ unlocked: badge.unlocked }"
      >
        <div class="badge-stamp" :class="{ locked: !badge.unlocked }">
          <span class="badge-icon">{{ badge.unlocked ? badge.icon : '?' }}</span>
        </div>
        <div class="badge-meta">
          <h4 class="serif">{{ badge.name }}</h4>
          <p>{{ badge.description }}</p>
          <span v-if="badge.unlocked" class="badge-date">
            {{ formatDate(badge.earnedAt) }} 已获得
          </span>
          <span v-else class="badge-locked-label">未解锁</span>
        </div>
      </li>
    </ul>

    <div class="refresh-area">
      <button class="btn-refresh" @click="refreshAchievements">刷新成就状态</button>
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
  padding: 1rem 1.4rem 3rem;
}

.page-header {
  padding: 0.6rem 0 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
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
}

/* 进度卡 */
.progress-card {
  display: flex;
  align-items: center;
  gap: 1.4rem;
  padding: 1.2rem;
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  margin-bottom: 1.6rem;
}
.progress-ring-container {
  position: relative;
  width: 80px;
  height: 80px;
  flex-shrink: 0;
}
.progress-text-center {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.15rem;
}
.ptc-num {
  font-size: 1.4rem;
  font-weight: 500;
  color: var(--text-strong);
}
.ptc-div {
  font-size: var(--fs-xs);
  color: var(--text-muted);
}
.progress-info { flex: 1; }
.progress-info h3 {
  font-size: var(--fs-md);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.3rem;
}
.progress-info p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: 0.6rem;
}
.progress-bar-small {
  height: 4px;
  background: var(--bg-sunken);
  border-radius: 2px;
  overflow: hidden;
}
.pbs-fill {
  height: 100%;
  background: var(--primary);
  transition: width var(--dur) var(--ease);
}

/* 徽章：印章式 */
.badges-grid {
  list-style: none;
  display: flex;
  flex-direction: column;
  border-top: 1px solid var(--bg-line);
}
.badge-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 0;
  border-bottom: 1px solid var(--bg-line);
}
.badge-card.unlocked { opacity: 1; }
.badge-card:not(.unlocked) { opacity: 0.55; }

.badge-stamp {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--primary);
  background: var(--bg-surface);
  flex-shrink: 0;
}
.badge-stamp.locked {
  border-color: var(--border);
}
.badge-icon {
  font-size: 1.5rem;
  color: var(--primary);
}
.badge-stamp.locked .badge-icon {
  color: var(--text-faint);
  font-size: 1.3rem;
}

.badge-meta { flex: 1; }
.badge-meta h4 {
  font-size: var(--fs-md);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.2rem;
}
.badge-meta p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: 0.2rem;
}
.badge-date {
  font-size: var(--fs-xs);
  color: var(--primary);
}
.badge-locked-label {
  font-size: var(--fs-xs);
  color: var(--text-faint);
}

/* 刷新按钮 */
.refresh-area {
  margin-top: 1.4rem;
  text-align: center;
}
.btn-refresh {
  background: transparent;
  border: 1px solid var(--border);
  color: var(--text-base);
  font-family: inherit;
  font-size: var(--fs-sm);
  padding: 0.5rem 1.1rem;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color var(--dur) var(--ease),
              color var(--dur) var(--ease);
}
.btn-refresh:hover {
  border-color: var(--primary);
  color: var(--primary);
}

/* Toast */
.toast {
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
</style>