<template>
  <div class="community-page">
    <header class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1 class="serif">社区</h1>
      <p>匿名互动，互相支持，一起进步</p>
    </header>

    <!-- 下划线 tab -->
    <nav class="tab-bar">
      <button
        :class="['tab-btn', { active: activeTab === 'camp' }]"
        @click="activeTab = 'camp'"
      >挑战营</button>
      <button
        :class="['tab-btn', { active: activeTab === 'diary' }]"
        @click="activeTab = 'diary'"
      >还债日记</button>
    </nav>

    <section class="tab-content" :key="activeTab">
      <ChallengeCamp v-if="activeTab === 'camp'" :userId="userId" />
      <TopicCircle v-if="activeTab === 'diary'" :userId="userId" />
    </section>
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
.community-page {
  min-height: 100vh;
  padding: 1rem 1.4rem 3rem;
}

.page-header {
  padding: 0.6rem 0 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 0.4rem;
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

/* 下划线式 tab */
.tab-bar {
  display: flex;
  gap: 1.4rem;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
}
.tab-btn {
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 0.6rem 0;
  font-family: inherit;
  font-size: var(--fs-sm);
  color: var(--text-muted);
  cursor: pointer;
  margin-bottom: -1px;
  transition: color var(--dur) var(--ease),
              border-color var(--dur) var(--ease);
}
.tab-btn:hover { color: var(--text-strong); }
.tab-btn.active {
  color: var(--text-strong);
  border-bottom-color: var(--primary);
  font-weight: 500;
}

.tab-content { padding: 0; }

/* 子组件卡片统一对齐纸色主题（穿透到 ChallengeCamp / TopicCircle） */
.community-page :deep(.challenge-card),
.community-page :deep(.topic-card),
.community-page :deep(.post-card),
.community-page :deep(.glass-card) {
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  box-shadow: none;
}

.community-page :deep(.avatar),
.community-page :deep(.user-avatar) {
  border-radius: 50%;
  background: var(--bg-sunken);
  box-shadow: none;
}

.community-page :deep(.btn-primary),
.community-page :deep(.btn-checkin),
.community-page :deep(.btn-rose) {
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-weight: 500;
}
.community-page :deep(.btn-primary):hover,
.community-page :deep(.btn-checkin):hover {
  background: var(--primary-strong);
}

.community-page :deep(.check-in-success),
.community-page :deep(.is-checked),
.community-page :deep(.success-badge) {
  color: var(--primary);
  border-color: var(--primary);
}
</style>