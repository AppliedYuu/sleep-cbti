<template>
  <div class="challenge-camp">
    <!-- 未加入状态 - 营地选择 -->
    <div v-if="!myCamp.joined" class="camp-select">
      <div class="section-intro">
        <span class="intro-icon">🏕️</span>
        <p>选择一个适合你作息的挑战营，和匿名的伙伴们一起坚持固定作息。</p>
      </div>

      <div class="camp-cards">
        <div v-for="camp in camps" :key="camp.id" class="camp-card" @click="doJoin(camp.id)">
          <div class="camp-card-top">
            <span class="camp-icon">{{ camp.icon }}</span>
            <div class="camp-info">
              <h3>{{ camp.name }}</h3>
              <p>{{ camp.description }}</p>
            </div>
            <span class="camp-difficulty" :class="camp.difficulty === '进阶' ? 'hard' : 'easy'">{{ camp.difficulty }}</span>
          </div>
          <div class="camp-card-bottom">
            <span class="camp-time">{{ camp.timeInBed }}</span>
            <span class="camp-join-hint">点击加入 →</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 已加入状态 - 营地主页 -->
    <div v-else class="camp-main">
      <!-- 我的营地信息 -->
      <div class="my-camp-card">
        <div class="mcc-top">
          <span class="mcc-icon">{{ myCamp.camp?.icon }}</span>
          <div class="mcc-info">
            <h2>{{ myCamp.camp?.name }}</h2>
            <p>{{ myCamp.camp?.description }}</p>
          </div>
        </div>
        <div class="mcc-stats">
          <div class="mcc-stat-item">
            <span class="mcc-stat-val">{{ myCamp.streak || 0 }}天</span>
            <span class="mcc-stat-label">连续打卡</span>
          </div>
          <div class="mcc-stat-item">
            <span class="mcc-stat-val">{{ myCamp.camp?.timeInBed }}</span>
            <span class="mcc-stat-label">目标作息</span>
          </div>
          <div class="mcc-stat-item">
            <span class="mcc-stat-val">{{ myCamp.todayCheckedIn ? '✅' : '○' }}</span>
            <span class="mcc-stat-label">今日打卡</span>
          </div>
        </div>
      </div>

      <!-- 打卡按钮 -->
      <button
        class="btn-checkin-camp"
        :class="{ done: myCamp.todayCheckedIn }"
        :disabled="myCamp.todayCheckedIn"
        @click="doCheckIn"
      >
        {{ myCamp.todayCheckedIn ? '✅ 今日已打卡' : '✊ 今日打卡' }}
      </button>

      <!-- 群体统计（签到率） -->
      <div class="group-stats-card">
        <h3>📊 今日挑战营概览</h3>
        <div class="gs-row">
          <div class="gs-item">
            <span class="gs-val">{{ stats.memberCount || '--' }}</span>
            <span class="gs-label">营员</span>
          </div>
          <div class="gs-item">
            <span class="gs-val">{{ stats.todayCheckinCount != null ? stats.todayCheckinCount : '--' }}</span>
            <span class="gs-label">今日打卡</span>
          </div>
          <div class="gs-item">
            <span class="gs-val">{{ stats.todayCheckinRate != null ? stats.todayCheckinRate + '%' : '--' }}</span>
            <span class="gs-label">今日签到率</span>
          </div>
          <div class="gs-item">
            <span class="gs-val">{{ stats.weightedCheckinRate != null ? stats.weightedCheckinRate + '%' : '--' }}</span>
            <span class="gs-label">综合签到率</span>
          </div>
        </div>
        <p class="gs-message">{{ stats.groupMessage }}</p>
      </div>

      <!-- 连续打卡光荣榜（匿名） -->
      <div v-if="stats.topStreaks?.length" class="streak-board">
        <h3>🔥 连续打卡光荣榜</h3>
        <div class="streak-list">
          <div v-for="(s, i) in stats.topStreaks" :key="i" class="streak-item">
            <span class="streak-rank">{{ ['🥇','🥈','🥉','4️⃣','5️⃣'][i] }}</span>
            <span class="streak-text">{{ s.label }}</span>
          </div>
        </div>
        <p class="streak-note">* 所有数据匿名展示，不透露个人信息</p>
      </div>

      <!-- 退出按钮 -->
      <button class="btn-leave" @click="doLeave">退出当前挑战营</button>
    </div>

    <div v-if="showToast" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import {
  getCampList, getMyCamp, joinCamp, checkInCamp, getCampStats, leaveCamp,
} from '@/api/community';

const props = defineProps({ userId: String });

const camps = ref([]);
const myCamp = reactive({ joined: false, camp: null, streak: 0, todayCheckedIn: false });
const stats = reactive({ memberCount: 0, todayCheckinCount: 0, todayCheckinRate: null, weightedCheckinRate: null, groupMessage: '', topStreaks: [] });
const toastMsg = ref('');
const showToast = ref(false);

function showMsg(msg) {
  toastMsg.value = msg;
  showToast.value = true;
  setTimeout(() => { showToast.value = false; }, 2500);
}

async function loadCamps() { try { const res = await getCampList(); camps.value = res.data || []; } catch {} }

async function loadMyCamp() {
  try {
    const res = await getMyCamp(props.userId);
    Object.assign(myCamp, { joined: false, camp: null, streak: 0, todayCheckedIn: false });
    if (res.data?.joined) {
      Object.assign(myCamp, res.data);
    }
  } catch {}
}

async function loadStats() {
  if (!myCamp.camp?.id) return;
  try {
    const res = await getCampStats(myCamp.camp.id);
    Object.assign(stats, res.data || {});
  } catch {}
}

async function doJoin(campId) {
  try {
    const res = await joinCamp(props.userId, campId);
    showMsg(res.message);
    await loadMyCamp();
    await loadStats();
  } catch (err) { showMsg(err.response?.data?.message || '加入失败'); }
}

async function doCheckIn() {
  try {
    const res = await checkInCamp(props.userId);
    myCamp.todayCheckedIn = true;
    myCamp.streak = res.data.myStreak || 1;
    showMsg(res.data.groupMessage || res.message);
    await loadStats();
  } catch (err) { showMsg(err.response?.data?.message || '打卡失败'); }
}

async function doLeave() {
  try {
    const res = await leaveCamp(props.userId);
    showMsg(res.message);
    Object.assign(myCamp, { joined: false, camp: null, streak: 0, todayCheckedIn: false });
  } catch {}
}

onMounted(async () => {
  await Promise.all([loadCamps(), loadMyCamp()]);
  if (myCamp.joined) await loadStats();
});
</script>

<style scoped>
.challenge-camp {
  min-height: 200px;
  position: relative;
}

/* ---- 营地选择：简介 ---- */
.section-intro {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-sm);
  padding: 0.8rem 1rem;
  margin-bottom: 1rem;
  font-size: 0.85rem;
  color: var(--text-muted);
  line-height: 1.5;
}

.intro-icon { font-size: 1.5rem; flex-shrink: 0; }

.camp-cards { display: flex; flex-direction: column; gap: 0.7rem; }

/* ---- 营地卡片（玻璃） ---- */
.camp-card {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  cursor: pointer;
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out);
}

.camp-card:hover {
  transform: translateY(-2px);
  border-color: var(--border-glow);
  box-shadow: var(--shadow-float), 0 0 22px rgba(255, 155, 179, 0.18);
}

.camp-card:active { transform: scale(0.98); }

.camp-card-top {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-bottom: 0.6rem;
}

.camp-icon { font-size: 1.8rem; }
.camp-info { flex: 1; }
.camp-info h3 { font-size: 0.95rem; color: var(--text-strong); }
.camp-info p { font-size: 0.75rem; color: var(--text-muted); }

.camp-difficulty {
  font-size: 0.68rem;
  padding: 0.2rem 0.5rem;
  border-radius: var(--radius-pill);
  font-weight: 600;
  background: var(--primary-weak);
  color: var(--primary);
}

.camp-difficulty.easy { background: rgba(94, 234, 212, 0.14); color: var(--accent-mint); }
.camp-difficulty.hard { background: rgba(255, 210, 138, 0.14); color: var(--accent-amber); }

.camp-card-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.camp-time { font-size: 0.78rem; color: var(--text-base); font-weight: 500; }
.camp-join-hint { font-size: 0.78rem; color: var(--accent-rose); font-weight: 600; }

/* ---- 已加入：我的营地卡片（玻璃 + 玫瑰光晕） ---- */
.my-camp-card {
  background: var(--bg-glass-strong);
  border: 1px solid var(--border-mid);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-radius: var(--radius-lg);
  padding: 1.2rem;
  box-shadow: var(--shadow-card), 0 0 26px rgba(255, 155, 179, 0.12);
  margin-bottom: 0.8rem;
}

.mcc-top {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-bottom: 0.8rem;
}

.mcc-icon { font-size: 2rem; }
.mcc-info h2 { font-size: 1.1rem; color: var(--text-strong); }
.mcc-info p { font-size: 0.78rem; color: var(--text-muted); }

.mcc-stats {
  display: flex;
  gap: 0.5rem;
}

.mcc-stat-item {
  flex: 1;
  text-align: center;
  background: var(--bg-soft);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-sm);
  padding: 0.5rem 0.3rem;
}

.mcc-stat-val { display: block; font-size: 1.1rem; font-weight: 700; color: var(--text-strong); }
.mcc-stat-label { font-size: 0.68rem; color: var(--text-muted); }

/* ---- 打卡按钮：玫瑰主色 ---- */
.btn-checkin-camp {
  width: 100%;
  padding: 0.8rem;
  background: var(--accent-rose);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 0.8rem;
  box-shadow: 0 0 22px rgba(255, 155, 179, 0.30);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              filter var(--dur-base) var(--ease-out);
}

.btn-checkin-camp:hover {
  transform: translateY(-2px);
  box-shadow: 0 0 30px rgba(255, 155, 179, 0.45);
}

.btn-checkin-camp:active { transform: scale(0.98); }

/* 完成 / 成功态：薄荷绿 */
.btn-checkin-camp.done {
  background: var(--accent-mint);
  color: var(--text-on-primary);
  box-shadow: var(--glow-mint);
  cursor: default;
}

.btn-checkin-camp:disabled { cursor: default; }

/* ---- 群体统计卡片（玻璃） ---- */
.group-stats-card {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  margin-bottom: 0.8rem;
}

.group-stats-card h3 { font-size: 0.9rem; color: var(--text-strong); margin-bottom: 0.6rem; }

.gs-row { display: flex; gap: 0.4rem; margin-bottom: 0.6rem; }

.gs-item {
  flex: 1;
  text-align: center;
  padding: 0.5rem 0.2rem;
  background: var(--bg-soft);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-sm);
}

.gs-val { display: block; font-size: 1.1rem; font-weight: 700; color: var(--accent-rose); }
.gs-label { font-size: 0.68rem; color: var(--text-muted); }

.gs-message {
  font-size: 0.8rem;
  color: var(--text-base);
  line-height: 1.5;
  text-align: center;
}

/* ---- 连续打卡光荣榜（玻璃） ---- */
.streak-board {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  margin-bottom: 0.8rem;
}

.streak-board h3 { font-size: 0.9rem; color: var(--text-strong); margin-bottom: 0.5rem; }

.streak-list { display: flex; flex-direction: column; gap: 0.3rem; }

.streak-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.82rem;
  color: var(--text-base);
}

.streak-rank { font-size: 1rem; }
.streak-note { font-size: 0.68rem; color: var(--text-faint); margin-top: 0.4rem; text-align: center; }

/* ---- 退出按钮（幽灵按钮） ---- */
.btn-leave {
  width: 100%;
  padding: 0.6rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--text-muted);
  font-size: 0.85rem;
  cursor: pointer;
  transition: border-color var(--dur-base) var(--ease-out),
              color var(--dur-base) var(--ease-out);
}

.btn-leave:hover {
  border-color: var(--danger);
  color: var(--danger);
}

/* ---- Toast 提示 ---- */
.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--accent-rose);
  color: var(--text-on-primary);
  padding: 0.6rem 1.2rem;
  border-radius: var(--radius-pill);
  font-size: 0.85rem;
  font-weight: 600;
  z-index: 100;
  box-shadow: 0 0 24px rgba(255, 155, 179, 0.35);
  animation: fadeInOut 2.5s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
