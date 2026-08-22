<template>
  <div class="home">
    <!-- 顶部：极简导航 -->
    <header class="top">
      <div class="top-title serif">睡益良方</div>
      <nav class="top-nav">
        <template v-if="authStore.isLoggedIn">
          <span class="user-name">{{ authStore.user?.nickname || authStore.user?.username }}</span>
          <button class="nav-link" @click="notifyRef?.open()">通知</button>
          <button class="nav-link" @click="handleLogout">退出</button>
        </template>
        <template v-else>
          <router-link to="/login" class="nav-link">登录</router-link>
          <router-link to="/register" class="nav-link">注册</router-link>
        </template>
      </nav>
    </header>

    <!-- 主标题：纯文字 + 衬线 -->
    <section class="intro">
      <h1 class="serif">愿你今夜安眠。</h1>
      <p class="intro-sub">大学生 CBT-I 数字疗法助手 · 不靠药物，用行为改变赢回睡眠。</p>
    </section>

    <!-- 数据概览：去发光 -->
    <section v-if="authStore.isLoggedIn" class="stats">
      <div class="stat">
        <div class="stat-val serif">{{ dash.latestScore != null ? dash.latestScore : '—' }}</div>
        <div class="stat-label">最新测评得分</div>
      </div>
      <div class="stat">
        <div class="stat-val serif">{{ dash.avgDuration != null ? dash.avgDuration + 'h' : '—' }}</div>
        <div class="stat-label">平均睡眠时长</div>
      </div>
      <div class="stat">
        <div class="stat-val serif">{{ dash.avgEfficiency != null ? dash.avgEfficiency + '%' : '—' }}</div>
        <div class="stat-label">平均睡眠效率</div>
      </div>
    </section>

    <!-- 模块清单：左侧 3px 实色块 + 文字 -->
    <nav class="modules">
      <router-link to="/assessment" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">睡眠档案与评估</span>
          <span class="module-desc">三大量表测评，获取专属睡眠六维图</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>

      <router-link to="/diary" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">睡眠日记</span>
          <span class="module-desc">每日快速记录，追踪睡眠效率变化</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>

      <router-link to="/intervention" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">智能干预处方</span>
          <span class="module-desc">睡眠限制 · 刺激控制 · 认知重塑 · 放松训练</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>

      <router-link to="/report" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">睡眠改善周报</span>
          <span class="module-desc">每周数据总结 · 趋势分析 · 改善建议</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>

      <router-link to="/achievements" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">成就徽章</span>
          <span class="module-desc">规律之星 · 早起勇士 · 效率达人</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>

      <router-link to="/community" class="module">
        <span class="module-bar" aria-hidden="true"></span>
        <span class="module-text">
          <span class="module-name serif">社区与打卡</span>
          <span class="module-desc">匿名睡眠挑战营 · 还债日记话题圈</span>
        </span>
        <span class="module-arrow" aria-hidden="true">→</span>
      </router-link>
    </nav>

    <NotifySetting ref="notifyRef" />

    <div v-if="toastMsg" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, reactive, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import request from '@/api/request';
import NotifySetting from '@/components/NotifySetting.vue';

const router = useRouter();
const notifyRef = ref(null);
const authStore = useAuthStore();
const toastMsg = ref('');
const dash = reactive({ latestScore: null, avgDuration: null, avgEfficiency: null });

async function loadDash() {
  const id = authStore.user?.id;
  if (!id) return;
  try {
    const res = await request.get('/dashboard/' + id);
    Object.assign(dash, res.data);
  } catch { /* ignore */ }
}

watch(() => authStore.user?.id, id => { if (id) loadDash(); }, { immediate: true });

function handleLogout() {
  authStore.logout();
  router.push('/login');
}

function showToast(msg) {
  toastMsg.value = msg;
  setTimeout(() => { toastMsg.value = ''; }, 2000);
}
</script>

<style scoped>
.home {
  min-height: 100vh;
  padding: 1.5rem 1.4rem 4rem;
  color: var(--text-base);
}

/* ---- 顶部 ---- */
.top {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 2.5rem;
}
.top-title {
  font-size: 1.15rem;
  letter-spacing: 0.06em;
  color: var(--text-strong);
}
.top-nav {
  display: flex;
  gap: 1rem;
  align-items: baseline;
  font-size: var(--fs-sm);
}
.user-name {
  color: var(--text-muted);
  font-size: var(--fs-sm);
}
.nav-link {
  color: var(--text-muted);
  text-decoration: none;
  background: transparent;
  border: none;
  font-family: inherit;
  font-size: var(--fs-sm);
  padding: 0;
  cursor: pointer;
  transition: color var(--dur) var(--ease);
}
.nav-link:hover {
  color: var(--text-strong);
}

/* ---- 主标题 ---- */
.intro {
  margin-bottom: 2.6rem;
}
.intro h1 {
  font-size: var(--fs-2xl);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.5rem;
  line-height: 1.3;
}
.intro-sub {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  line-height: 1.7;
  max-width: 28em;
}

/* ---- 数据概览：纯文字三列 ---- */
.stats {
  display: flex;
  gap: 0;
  border-top: 1px solid var(--bg-line);
  border-bottom: 1px solid var(--bg-line);
  padding: 1.2rem 0;
  margin-bottom: 2.4rem;
}
.stat {
  flex: 1;
  text-align: center;
  border-right: 1px solid var(--bg-line);
}
.stat:last-child { border-right: none; }
.stat-val {
  font-size: 1.5rem;
  color: var(--text-strong);
  font-weight: 500;
  line-height: 1;
}
.stat-label {
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: 0.4rem;
}

/* ---- 模块清单：左侧 3px 实色块 + 文字 ---- */
.modules {
  border-top: 1px solid var(--bg-line);
}
.module {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.1rem 0.4rem;
  text-decoration: none;
  color: inherit;
  border-bottom: 1px solid var(--bg-line);
  transition: background var(--dur) var(--ease);
}
.module:hover {
  background: var(--bg-hover);
}
.module-bar {
  width: 3px;
  align-self: stretch;
  background: var(--primary);
  flex-shrink: 0;
  border-radius: 1px;
}
.module-text {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.module-name {
  font-size: var(--fs-lg);
  color: var(--text-strong);
}
.module-desc {
  font-size: var(--fs-xs);
  color: var(--text-muted);
}
.module-arrow {
  color: var(--text-faint);
  font-size: var(--fs-md);
  flex-shrink: 0;
}

/* ---- Toast：极简 ---- */
.toast {
  position: fixed;
  top: 1.5rem;
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