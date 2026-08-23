<template>
  <div class="stimulus-control">
    <!-- 指令卡片 -->
    <div class="card-main" v-if="card">
      <div class="card-badge">第 {{ card.dayIndex + 1 }} 天 / 共 {{ card.totalCards }} 条</div>
      <div class="card-icon-large">{{ card.icon }}</div>
      <h2>{{ card.title }}</h2>
      <p class="card-content">{{ card.content }}</p>

      <div class="challenge-box">
        <p>{{ card.challenge }}</p>
      </div>

      <button
        class="btn-checkin"
        :class="{ checked: isCheckedIn }"
        :disabled="isCheckedIn"
        @click="doCheckIn"
      >
        {{ isCheckedIn ? '今日已打卡' : '完成打卡' }}
      </button>
    </div>

    <!-- 打卡记录 -->
    <div class="checkin-history" v-if="card">
      <h3>本周刺激控制打卡</h3>
      <div class="week-dots">
        <span
          v-for="(day, di) in weekDays"
          :key="di"
          class="week-dot"
        >
          <span
            class="dot-circle"
            :class="{ done: di < card.dayIndex || isCheckedIn, today: di === card.dayIndex && !isCheckedIn }"
            aria-hidden="true"
          ></span>
          <span class="dot-label">{{ day }}</span>
        </span>
      </div>
    </div>

    <div v-if="showToast" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getStimulusCard, checkInStimulus } from '@/api/intervention';

const props = defineProps({ userId: String });
const card = ref(null);
const isCheckedIn = ref(false);
const toastMsg = ref('');
const showToast = ref(false);

const weekDays = ['一', '二', '三', '四', '五', '六', '日'];

async function loadCard() {
  try {
    const res = await getStimulusCard(props.userId);
    card.value = res.data;
    isCheckedIn.value = res.data.isCheckedIn;
  } catch { /* ignore */ }
}

async function doCheckIn() {
  try {
    const res = await checkInStimulus(props.userId);
    isCheckedIn.value = true;
    toastMsg.value = res.message;
    showToast.value = true;
    setTimeout(() => { showToast.value = false; }, 2000);
  } catch {
    alert('打卡失败');
  }
}

onMounted(loadCard);
</script>

<style scoped>
.stimulus-control { position: relative; min-height: 200px; }

/* 实体纸卡 */
.card-main {
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1.5rem;
  text-align: center;
  box-shadow: var(--shadow-card);
  position: relative;
  overflow: hidden;
}

.card-badge {
  display: inline-block;
  background: var(--primary-weak);
  color: var(--primary-strong);
  padding: 0.25rem 0.8rem;
  border-radius: var(--radius-pill);
  font-size: var(--fs-xs);
  font-weight: 500;
  margin-bottom: 1rem;
}

.card-icon-large { font-size: 3.5rem; margin-bottom: 0.5rem; }

.card-main h2 {
  font-size: var(--fs-xl);
  color: var(--text-strong);
  margin-bottom: 0.8rem;
}

.card-content {
  font-size: var(--fs-md);
  color: var(--text-base);
  line-height: 1.7;
  margin-bottom: 1.2rem;
}

.challenge-box {
  background: var(--bg-sunken);
  border: 1px solid var(--border-soft);
  border-left: 3px solid var(--primary);
  border-radius: var(--radius-sm);
  padding: 0.8rem;
  margin-bottom: 1.2rem;
  text-align: left;
}

.challenge-box p { font-size: var(--fs-sm); color: var(--text-muted); line-height: 1.5; }

/* 主色按钮：无发光、无位移 */
.btn-checkin {
  width: 100%;
  padding: 0.8rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-size: var(--fs-lg);
  font-family: inherit;
  font-weight: 500;
  cursor: pointer;
  transition: background var(--dur-base) var(--ease-out),
              color var(--dur-base) var(--ease-out);
}

.btn-checkin:hover:not(:disabled) {
  background: var(--primary-strong);
}

.btn-checkin.checked {
  background: var(--primary-weak);
  color: var(--primary-strong);
  box-shadow: inset 0 0 0 1px var(--primary);
}

.btn-checkin:disabled { cursor: default; }

.checkin-history {
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1rem;
  margin-top: 1rem;
  box-shadow: var(--shadow-card);
}

.checkin-history h3 { font-size: var(--fs-md); color: var(--text-strong); margin-bottom: 0.8rem; }

.week-dots {
  display: flex;
  justify-content: space-around;
}

.week-dot {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.3rem;
}

/* 圆点状态：未到=描边圆 / 今日=主色描边 / 已完成=实心主色 */
.dot-circle {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 1.5px solid var(--border-mid);
  background: transparent;
}

.dot-circle.today {
  border-color: var(--primary-strong);
  box-shadow: inset 0 0 0 2px var(--bg-surface);
  background: var(--primary-weak);
}

.dot-circle.done {
  border-color: var(--primary);
  background: var(--primary);
}

.dot-label { font-size: var(--fs-xs); color: var(--text-muted); }

/* Toast：全站统一深墨底 */
.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--text-strong);
  color: var(--bg-base);
  padding: 0.6rem 1.5rem;
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  z-index: 100;
  animation: fadeInOut 2s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
