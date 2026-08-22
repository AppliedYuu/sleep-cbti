<template>
  <div class="community-page">
    <div class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1>👥 社区</h1>
      <p>匿名互动，互相支持，一起进步</p>
    </div>

    <div class="tab-bar">
      <button
        :class="['tab-btn', { active: activeTab === 'camp' }]"
        @click="activeTab = 'camp'"
      >🏕️ 挑战营</button>
      <button
        :class="['tab-btn', { active: activeTab === 'diary' }]"
        @click="activeTab = 'diary'"
      >📖 还债日记</button>
    </div>

    <div class="tab-content" :key="activeTab">
      <ChallengeCamp v-if="activeTab === 'camp'" :userId="userId" />
      <TopicCircle v-if="activeTab === 'diary'" :userId="userId" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import ChallengeCamp from '@/components/ChallengeCamp.vue';
import TopicCircle from '@/components/TopicCircle.vue';

import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);
const activeTab = ref('camp');
</script>

<style scoped>
/* 静谧夜空 · 社区页（社区/温暖 → accent-rose；打卡成功 → accent-mint） */
.community-page {
  min-height: 100vh;
  padding: 0 1.1rem 3rem;
  /* 与全局 body 星空背景叠加一层柔和社区暖光 */
  background:
    radial-gradient(700px 360px at 50% -8%, rgba(255, 155, 179, 0.10), transparent 60%),
    radial-gradient(620px 420px at 88% 6%, rgba(183, 148, 246, 0.07), transparent 55%);
  background-attachment: fixed;
}

/* 页头 */
.page-header {
  padding: 1.6rem 0.4rem 1.1rem;
  text-align: center;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

.btn-back-link {
  display: inline-block;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.85rem;
  margin-bottom: 0.6rem;
  padding: 0.25rem 0.7rem;
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  background: var(--bg-glass);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition: color var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) var(--ease-out),
              transform var(--dur-fast) var(--ease-out);
}
.btn-back-link:hover {
  color: var(--accent-rose);
  border-color: var(--accent-rose);
  transform: translateX(-2px);
}

.page-header h1 {
  font-size: 1.35rem;
  font-weight: 700;
  background: linear-gradient(135deg, var(--text-strong) 0%, var(--accent-rose) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 0.04em;
  margin-bottom: 0.3rem;
}

.page-header p {
  font-size: 0.82rem;
  color: var(--text-muted);
  margin-top: 0.2rem;
}

/* 顶部标签栏（玻璃胶囊） */
.tab-bar {
  display: flex;
  gap: 0.4rem;
  margin: 0.4rem 0 1.2rem;
  padding: 0.35rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  box-shadow: var(--shadow-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.tab-btn {
  flex: 1;
  padding: 0.6rem 0.4rem;
  border: none;
  background: transparent;
  font-size: 0.9rem;
  font-family: inherit;
  cursor: pointer;
  color: var(--text-muted);
  border-radius: var(--radius-pill);
  position: relative;
  transition: color var(--dur-base) var(--ease-out),
              background var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.tab-btn:hover {
  color: var(--text-base);
  background: var(--bg-hover);
}

.tab-btn.active {
  color: var(--text-on-primary);
  font-weight: 600;
  background: var(--accent-rose);
  box-shadow: 0 0 20px rgba(255, 155, 179, 0.32);
}

.tab-content {
  padding: 0.2rem 0;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

/* 复用的玻璃卡片：社区内容容器 */
.community-page :deep(.glass-card),
.community-page :deep(.challenge-card),
.community-page :deep(.topic-card),
.community-page :deep(.post-card) {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out);
}

.community-page :deep(.glass-card):hover,
.community-page :deep(.challenge-card):hover,
.community-page :deep(.topic-card):hover,
.community-page :deep(.post-card):hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-card), 0 0 22px rgba(255, 155, 179, 0.18);
  border-color: var(--accent-rose);
}

/* 头像：圆形 + 柔光 */
.community-page :deep(.avatar),
.community-page :deep(.user-avatar) {
  border-radius: 50%;
  background: var(--bg-soft);
  box-shadow: 0 0 14px rgba(255, 155, 179, 0.25);
}

/* 打卡成功 / 正向状态 → 薄荷绿 */
.community-page :deep(.check-in-success),
.community-page :deep(.is-checked),
.community-page :deep(.success-badge) {
  color: var(--accent-mint);
  border-color: var(--accent-mint);
  box-shadow: var(--glow-mint);
}

/* 主交互按钮 / 打卡按钮 → rose 强调 */
.community-page :deep(.btn-primary),
.community-page :deep(.btn-checkin),
.community-page :deep(.btn-rose) {
  background: var(--accent-rose);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-weight: 600;
  box-shadow: 0 0 20px rgba(255, 155, 179, 0.30);
  transition: transform var(--dur-fast) var(--ease-out),
              opacity var(--dur-fast) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}
.community-page :deep(.btn-primary):hover,
.community-page :deep(.btn-checkin):hover,
.community-page :deep(.btn-rose):hover {
  transform: translateY(-2px);
  box-shadow: 0 0 26px rgba(255, 155, 179, 0.42);
}
.community-page :deep(.btn-primary):active,
.community-page :deep(.btn-checkin):active,
.community-page :deep(.btn-rose):active {
  transform: scale(0.97);
}

@keyframes rise-in {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}

@media (prefers-reduced-motion: reduce) {
  .page-header,
  .tab-content,
  .community-page :deep(.glass-card),
  .community-page :deep(.challenge-card),
  .community-page :deep(.topic-card),
  .community-page :deep(.post-card) {
    animation: none !important;
    transition-duration: 0.001ms !important;
  }
}
</style>
