<template>
  <div class="home">
    <!-- 用户状态栏 -->
    <div class="user-bar">
      <template v-if="authStore.isLoggedIn">
        <span class="user-info">
          <span class="user-avatar">😴</span>
          <span class="user-name">{{ authStore.user?.nickname || authStore.user?.username }}</span>
          <span v-if="authStore.isAdmin" class="admin-badge">管理员</span>
        </span>
        <button class="btn-notify" @click="notifyRef?.open()">🔔</button>
        <button class="btn-logout" @click="handleLogout">退出</button>
      </template>
      <template v-else>
        <router-link to="/login" class="btn-login">登录</router-link>
        <router-link to="/register" class="btn-register-link">注册</router-link>
      </template>
    </div>

    <div class="hero">
      <div class="moon-icon">🌙</div>
      <h1>睡益良方</h1>
      <p class="subtitle">大学生 CBT-I 数字疗法助手</p>
      <p class="slogan">不靠药物，用行为改变赢回睡眠</p>
    </div>

    <!-- 数据概览 -->
    <div class="stats-row" v-if="authStore.isLoggedIn">
      <div class="stat-card">
        <span class="stat-val">{{ dash.latestScore != null ? dash.latestScore + '分' : '--' }}</span>
        <span class="stat-label">最新测评得分</span>
      </div>
      <div class="stat-card">
        <span class="stat-val">{{ dash.avgDuration != null ? dash.avgDuration + 'h' : '--' }}</span>
        <span class="stat-label">平均睡眠时长</span>
      </div>
      <div class="stat-card">
        <span class="stat-val">{{ dash.avgEfficiency != null ? dash.avgEfficiency + '%' : '--' }}</span>
        <span class="stat-label">平均睡眠效率</span>
      </div>
    </div>

    <div class="module-cards stagger">
      <router-link to="/assessment" class="module-card card-assessment">
        <span class="card-icon">📋</span>
        <div class="card-text">
          <h3>睡眠档案与评估</h3>
          <p>完成三大量表，获取专属睡眠六维图</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>

      <router-link to="/diary" class="module-card card-diary">
        <span class="card-icon">📓</span>
        <div class="card-text">
          <h3>睡眠日记</h3>
          <p>每日快速记录，追踪睡眠效率变化</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>

      <router-link to="/intervention" class="module-card card-intervention">
        <span class="card-icon">💊</span>
        <div class="card-text">
          <h3>智能干预处方</h3>
          <p>睡眠限制 · 刺激控制 · 认知重塑 · 放松训练</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>

      <router-link to="/report" class="module-card card-report">
        <span class="card-icon">📊</span>
        <div class="card-text">
          <h3>睡眠改善周报</h3>
          <p>每周数据总结 · 趋势分析 · 改善建议</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>

      <router-link to="/achievements" class="module-card card-achievements">
        <span class="card-icon">🏆</span>
        <div class="card-text">
          <h3>成就徽章</h3>
          <p>规律之星 · 早起勇士 · 效率达人</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>

      <router-link to="/community" class="module-card card-community">
        <span class="card-icon">👥</span>
        <div class="card-text">
          <h3>社区与打卡</h3>
          <p>匿名睡眠挑战营 · 还债日记话题圈</p>
        </div>
        <span class="card-arrow">→</span>
      </router-link>
    </div>

    <NotifySetting ref="notifyRef" />

    <div v-if="toastMsg" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import request from '@/api/request';
import NotifySetting from '@/components/NotifySetting.vue';
import AppCard from '@/components/AppCard.vue';

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
  padding: 0 1.1rem 3rem;
  text-align: center;
}

/* 用户状态栏 */
.user-bar {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 0.7rem;
  padding: 0.7rem 0;
  margin-bottom: 0.4rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.25rem 0.7rem 0.25rem 0.4rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.user-avatar {
  font-size: 1.3rem;
  filter: drop-shadow(0 0 8px var(--primary-glow));
}

.user-name {
  font-size: 0.85rem;
  color: var(--text-base);
  font-weight: 500;
}

.admin-badge {
  font-size: 0.62rem;
  background: var(--accent-purple);
  color: #2a0a4a;
  padding: 0.12rem 0.5rem;
  border-radius: 8px;
  font-weight: 700;
}

.btn-notify {
  width: 36px;
  height: 36px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--border-mid);
  border-radius: 50%;
  background: var(--bg-glass);
  color: var(--primary);
  font-size: 1rem;
  cursor: pointer;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition: transform 0.18s ease, border-color 0.18s ease;
}
.btn-notify:active { transform: scale(0.92); }

.btn-logout {
  padding: 0.4rem 0.85rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: var(--bg-glass);
  color: var(--text-muted);
  font-size: 0.78rem;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-logout:hover { border-color: var(--danger); color: var(--danger); }

.btn-login, .btn-register-link {
  padding: 0.4rem 1rem;
  border-radius: var(--radius-pill);
  font-size: 0.82rem;
  text-decoration: none;
  transition: all 0.2s;
}

.btn-login {
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  font-weight: 600;
  box-shadow: var(--glow-primary);
}

.btn-register-link {
  border: 1px solid var(--primary);
  color: var(--primary);
  background: transparent;
}

/* Hero */
.hero {
  margin: 0.6rem 0 1.4rem;
  position: relative;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

.hero::after {
  content: '';
  position: absolute;
  top: -10px; left: 50%;
  width: 160px; height: 160px;
  transform: translateX(-50%);
  background: radial-gradient(circle, var(--primary-glow), transparent 70%);
  filter: blur(10px);
  z-index: -1;
}

.moon-icon {
  font-size: 3.6rem;
  margin-bottom: 0.4rem;
  filter: drop-shadow(0 0 18px var(--primary-glow));
  animation: moon-float 5s ease-in-out infinite;
}

@keyframes moon-float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

.home h1 {
  font-size: 2rem;
  background: linear-gradient(135deg, #fff 0%, var(--primary) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 0.06em;
  margin-bottom: 0.3rem;
}

.subtitle {
  font-size: 0.95rem;
  color: var(--text-muted);
  margin-bottom: 0.3rem;
}

.slogan {
  font-size: 0.82rem;
  color: var(--text-faint);
  font-style: italic;
}

/* 数据概览 */
.stats-row {
  display: flex;
  gap: 0.55rem;
  margin-bottom: 1.3rem;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

.stat-card {
  flex: 1;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 0.8rem 0.3rem;
  text-align: center;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--shadow-soft);
}

.stat-val {
  display: block;
  font-size: 1.35rem;
  font-weight: 700;
  color: var(--primary);
  text-shadow: 0 0 16px var(--primary-glow);
}

.stat-label {
  display: block;
  font-size: 0.64rem;
  color: var(--text-muted);
  margin-top: 0.2rem;
}

/* 模块卡片 */
.module-cards {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.module-card {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  padding: 1rem 1.1rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-left: 4px solid var(--primary);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-soft);
  text-decoration: none;
  color: inherit;
  cursor: pointer;
  transition: transform 0.24s ease, box-shadow 0.24s ease, border-color 0.24s ease;
  text-align: left;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.module-card:active { transform: scale(0.99); }
.module-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-card), var(--glow-primary);
  border-left-color: var(--primary-strong);
}

.card-assessment { border-left-color: var(--primary); }
.card-diary { border-left-color: var(--accent-mint); }
.card-intervention { border-left-color: var(--accent-purple); }
.card-report { border-left-color: var(--accent-cyan); }
.card-achievements { border-left-color: var(--accent-amber); }
.card-community { border-left-color: var(--accent-rose); }
.card-locked { border-left-color: var(--text-faint); opacity: 0.55; }

/* 各卡片悬浮时投射对应色调柔光 */
.card-assessment:hover  { box-shadow: var(--shadow-card), var(--glow-primary); }
.card-diary:hover       { box-shadow: var(--shadow-card), var(--glow-mint); }
.card-intervention:hover{ box-shadow: var(--shadow-card), var(--glow-purple); }
.card-report:hover      { box-shadow: var(--shadow-card), 0 0 22px rgba(125,211,252,0.22); }
.card-achievements:hover{ box-shadow: var(--shadow-card), var(--glow-amber); }
.card-community:hover   { box-shadow: var(--shadow-card), 0 0 22px rgba(255,155,179,0.22); }

.card-icon {
  font-size: 1.8rem;
  flex-shrink: 0;
  filter: drop-shadow(0 0 10px rgba(255,255,255,0.08));
  transition: transform var(--dur-base) var(--ease-spring);
}
.module-card:hover .card-icon { transform: scale(1.12); }
.card-assessment:hover .card-icon  { filter: drop-shadow(0 0 12px var(--primary-glow)); }
.card-diary:hover .card-icon       { filter: drop-shadow(0 0 12px rgba(94,234,212,0.45)); }
.card-intervention:hover .card-icon{ filter: drop-shadow(0 0 12px rgba(183,148,246,0.45)); }
.card-report:hover .card-icon      { filter: drop-shadow(0 0 12px rgba(125,211,252,0.45)); }
.card-achievements:hover .card-icon{ filter: drop-shadow(0 0 12px rgba(255,210,138,0.45)); }
.card-community:hover .card-icon   { filter: drop-shadow(0 0 12px rgba(255,155,179,0.45)); }

.card-text { flex: 1; }

.card-text h3 {
  font-size: 1rem;
  color: var(--text-strong);
  margin-bottom: 0.18rem;
}

.card-text h3 small {
  font-size: 0.7rem;
  color: var(--text-faint);
  font-weight: normal;
}

.card-text p {
  font-size: 0.76rem;
  color: var(--text-muted);
  line-height: 1.45;
}

.card-arrow {
  font-size: 1.2rem;
  color: var(--primary);
  flex-shrink: 0;
  opacity: 0.7;
  transition: transform 0.2s ease;
}

.module-card:active .card-arrow { transform: translateX(3px); }

.card-lock {
  font-size: 1.2rem;
  flex-shrink: 0;
}

/* Toast */
.toast {
  position: fixed;
  bottom: 100px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(11, 16, 32, 0.92);
  color: var(--text-strong);
  padding: 0.6rem 1.2rem;
  border-radius: var(--radius-pill);
  border: 1px solid var(--border-mid);
  font-size: 0.85rem;
  z-index: 100;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  animation: fadeInOut 2s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; }
  20% { opacity: 1; }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
