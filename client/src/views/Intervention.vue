<template>
  <div class="intervention-page">
    <div class="page-header">
      <router-link to="/" class="btn-back-link">← 返回首页</router-link>
      <h1>💊 智能干预处方</h1>
      <p>基于您的评估结果，为您定制CBT-I干预方案</p>
    </div>

    <!-- Tab 导航 -->
    <div class="tab-bar">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="tab-btn"
        :class="{ active: activeTab === tab.key }"
        @click="activeTab = tab.key"
      >
        <span class="tab-icon">{{ tab.icon }}</span>
        <span class="tab-label">{{ tab.label }}</span>
      </button>
    </div>

    <!-- Tab 内容 -->
    <div class="tab-content" :key="activeTab">
      <SleepRestriction v-if="activeTab === 'restriction'" :userId="userId" />
      <StimulusControl v-if="activeTab === 'stimulus'" :userId="userId" />
      <CognitiveRestructure v-if="activeTab === 'cognitive'" :userId="userId" />
      <Relaxation v-if="activeTab === 'relaxation'" :userId="userId" />
      <SleepHygiene v-if="activeTab === 'hygiene'" :userId="userId" />
      <AIChat v-if="activeTab === 'ai'" :userId="userId" />
    </div>
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
  { key: 'restriction', label: '睡眠限制', icon: '⏰' },
  { key: 'stimulus', label: '刺激控制', icon: '🛌' },
  { key: 'cognitive', label: '认知重塑', icon: '🧠' },
  { key: 'relaxation', label: '放松训练', icon: '🧘' },
  { key: 'hygiene', label: '卫生任务', icon: '✅' },
  { key: 'ai', label: 'AI助手', icon: '🤖' },
];
</script>

<style scoped>
.intervention-page {
  min-height: 100vh;
  /* 与全局 body 一致的静谧夜空背景 */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.10), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.08), transparent 55%),
    linear-gradient(180deg, var(--bg-deep) 0%, var(--bg-base) 60%, #0c1124 100%);
  padding: 0 1.1rem 3rem;
}

.page-header {
  padding: calc(var(--space-4) + 0.4rem) 0.2rem var(--space-3);
  text-align: center;
  position: relative;
}

/* 页眉柔光月晕，呼应 Home 的 hero 氛围 */
.page-header::after {
  content: '';
  position: absolute;
  top: -8px;
  left: 50%;
  width: 200px;
  height: 140px;
  transform: translateX(-50%);
  background: radial-gradient(circle, var(--primary-glow), transparent 70%);
  filter: blur(14px);
  z-index: -1;
}

.btn-back-link {
  display: inline-block;
  color: var(--text-muted);
  text-decoration: none;
  font-size: var(--fs-sm);
  margin-bottom: var(--space-2);
  padding: 0.3rem 0.7rem;
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  background: var(--bg-glass);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition: color var(--dur-fast) var(--ease-out),
              border-color var(--dur-fast) var(--ease-out);
}

.btn-back-link:hover {
  color: var(--primary);
  border-color: var(--border-glow);
}

.page-header h1 {
  font-size: var(--fs-xl);
  background: linear-gradient(135deg, #fff 0%, var(--primary) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 0.04em;
  margin-bottom: 0.3rem;
}

.page-header p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-top: var(--space-1);
}

/* ---- Tab 导航：玻璃条 ---- */
.tab-bar {
  display: flex;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  padding: 0.35rem;
  gap: 0.25rem;
  overflow-x: auto;
  box-shadow: var(--shadow-soft);
  position: sticky;
  top: var(--safe-top, 0);
  z-index: 10;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.tab-bar::-webkit-scrollbar { display: none; }

.tab-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.12rem;
  flex-shrink: 0;
  min-width: 58px;
  padding: 0.4rem 0.5rem;
  border: 1px solid transparent;
  background: transparent;
  border-radius: var(--radius-pill);
  cursor: pointer;
  transition: background var(--dur-base) var(--ease-out),
              color var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              transform var(--dur-base) var(--ease-out);
  color: var(--text-faint);
  font-size: var(--fs-xs);
  font-family: inherit;
}

/* 每个 CBT-I 模块 tab 用对应强调色描边/图标光晕 */
.tab-btn:nth-child(1) { --tab-accent: var(--primary); }      /* 睡眠限制 */
.tab-btn:nth-child(2) { --tab-accent: var(--accent-cyan); }  /* 刺激控制 */
.tab-btn:nth-child(3) { --tab-accent: var(--accent-purple); }/* 认知重塑 */
.tab-btn:nth-child(4) { --tab-accent: var(--accent-mint); }  /* 放松训练 */
.tab-btn:nth-child(5) { --tab-accent: var(--accent-amber); } /* 睡眠卫生 */
.tab-btn:nth-child(6) { --tab-accent: var(--text-muted); }   /* AI助手 */

.tab-btn:active { transform: scale(0.97); }

.tab-btn:hover {
  color: var(--text-base);
  background: var(--bg-hover);
}

.tab-btn.active {
  background: var(--bg-glass-strong);
  color: var(--tab-accent);
  font-weight: 600;
  border-color: color-mix(in srgb, var(--tab-accent) 45%, transparent);
  box-shadow: 0 0 18px color-mix(in srgb, var(--tab-accent) 22%, transparent);
}

.tab-icon {
  font-size: 1.2rem;
  line-height: 1;
  filter: drop-shadow(0 0 6px color-mix(in srgb, var(--tab-accent) 35%, transparent));
}

.tab-label { white-space: nowrap; line-height: 1; }

/* ---- Tab 内容区 ---- */
.tab-content {
  padding: var(--space-3) 0.1rem 0;
}

/* 内容错峰入场 */
.tab-content > * {
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

@keyframes rise-in {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}

@media (prefers-reduced-motion: reduce) {
  .tab-content > *,
  .btn-back-link,
  .tab-btn {
    animation: none !important;
    transition-duration: 0.001ms !important;
  }
}
</style>
