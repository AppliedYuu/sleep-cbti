<template>
  <div class="intervention-page">
    <header class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1 class="serif">智能干预处方</h1>
      <p>基于您的评估结果，为您定制 CBT-I 干预方案</p>
    </header>

    <!-- 下划线式 tab -->
    <nav class="tab-bar">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="tab-btn"
        :class="{ active: activeTab === tab.key }"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </nav>

    <!-- Tab 内容 -->
    <section class="tab-content">
      <SleepRestriction v-if="activeTab === 'restriction'" :userId="userId" />
      <StimulusControl v-if="activeTab === 'stimulus'" :userId="userId" />
      <CognitiveRestructure v-if="activeTab === 'cognitive'" :userId="userId" />
      <Relaxation v-if="activeTab === 'relaxation'" :userId="userId" />
      <SleepHygiene v-if="activeTab === 'hygiene'" :userId="userId" />
      <AIChat v-if="activeTab === 'ai'" :userId="userId" />
    </section>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import SleepRestriction from '@/components/SleepRestriction.vue';
import StimulusControl from '@/components/StimulusControl.vue';
import CognitiveRestructure from '@/components/CognitiveRestructure.vue';
import Relaxation from '@/components/Relaxation.vue';
import SleepHygiene from '@/components/SleepHygiene.vue';
import AIChat from '@/components/AIChat.vue';

import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
const userId = computed(() => authStore.user?.id);
const activeTab = ref('restriction');

const tabs = [
  { key: 'restriction', label: '睡眠限制' },
  { key: 'stimulus',    label: '刺激控制' },
  { key: 'cognitive',   label: '认知重塑' },
  { key: 'relaxation',  label: '放松训练' },
  { key: 'hygiene',     label: '卫生任务' },
  { key: 'ai',          label: 'AI 助手' },
];
</script>

<style scoped>
.intervention-page {
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

/* 下划线式 tab */
.tab-bar {
  display: flex;
  gap: 1.4rem;
  overflow-x: auto;
  border-bottom: 1px solid var(--bg-line);
  margin-bottom: 1.4rem;
  scrollbar-width: none;
}
.tab-bar::-webkit-scrollbar { display: none; }

.tab-btn {
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 0.6rem 0;
  font-family: inherit;
  font-size: var(--fs-sm);
  color: var(--text-muted);
  cursor: pointer;
  white-space: nowrap;
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
</style>