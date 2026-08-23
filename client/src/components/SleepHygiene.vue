<template>
  <div class="sleep-hygiene">
    <div class="day-indicator">{{ todayStr }}</div>

    <div class="points-summary" v-if="totalPoints > 0">
      <span class="pts-value">{{ totalPoints }} 分</span>
      <span class="pts-label">今日已获积分</span>
    </div>

    <div class="task-list">
      <div
        v-for="task in tasks"
        :key="task.id"
        class="task-card"
        :class="{ completed: task.isCompleted }"
        @click="toggleTask(task)"
      >
        <div class="task-left">
          <span class="task-icon">{{ task.icon }}</span>
          <div class="task-info">
            <h4>{{ task.task }}</h4>
            <span class="task-category">{{ task.category }}</span>
          </div>
        </div>
        <div class="task-right">
          <span class="task-points">+{{ task.points }}</span>
          <span class="task-check" :class="{ done: task.isCompleted }" aria-hidden="true"></span>
        </div>
      </div>
    </div>

    <div v-if="tasks.length === 0" class="empty">今日任务加载中...</div>

    <div v-if="showToast" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { getDailyHygiene, toggleHygieneTask } from '@/api/intervention';

const props = defineProps({ userId: String });
const tasks = ref([]);
const toastMsg = ref('');
const showToast = ref(false);

const todayStr = computed(() => {
  return new Date().toLocaleDateString('zh-CN', {
    year: 'numeric', month: 'long', day: 'numeric', weekday: 'long',
  });
});

const totalPoints = computed(() => {
  return tasks.value.filter(t => t.isCompleted).reduce((s, t) => s + (t.points || 0), 0);
});

async function loadTasks() {
  try {
    const res = await getDailyHygiene(props.userId);
    tasks.value = res.data?.tasks || [];
  } catch {
    tasks.value = [];
  }
}

async function toggleTask(task) {
  const newCompleted = !task.isCompleted;
  try {
    const res = await toggleHygieneTask(props.userId, task.id, newCompleted);
    task.isCompleted = newCompleted;
    toastMsg.value = res.message;
    showToast.value = true;
    setTimeout(() => { showToast.value = false; }, 2000);
  } catch {
    alert('操作失败');
  }
}

onMounted(loadTasks);
</script>

<style scoped>
.sleep-hygiene { min-height: 200px; position: relative; }

.day-indicator {
  text-align: center;
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: 0.8rem;
}

.points-summary {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  padding: 0.6rem;
  background: var(--primary-weak);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  margin-bottom: 1rem;
}

.pts-value { font-family: var(--font-serif); font-size: var(--fs-xl); font-weight: 500; color: var(--accent-clay); }
.pts-label { font-size: var(--fs-xs); color: var(--text-muted); }

.task-list { display: flex; flex-direction: column; gap: 0.5rem; }

/* 实体纸卡任务行 */
.task-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.8rem 1rem;
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  cursor: pointer;
  transition: border-color var(--dur-base) var(--ease-out),
              background var(--dur-base) var(--ease-out);
}

.task-card:hover {
  border-color: var(--border-mid);
}

.task-card.completed {
  background: var(--primary-weak);
  border-color: rgba(124, 152, 133, 0.35);
}

.task-card.completed .task-info h4 {
  text-decoration: line-through;
  color: var(--text-muted);
}

.task-left {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  flex: 1;
}

.task-icon { font-size: 1.4rem; flex-shrink: 0; }

.task-info h4 {
  font-size: var(--fs-md);
  color: var(--text-strong);
  margin-bottom: 0.1rem;
}

.task-category {
  font-size: var(--fs-xs);
  color: var(--text-faint);
}

.task-right {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.task-points {
  font-size: var(--fs-sm);
  font-weight: 600;
  color: var(--accent-amber);
}

.task-check {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 1.5px solid var(--border-mid);
  background: transparent;
  flex-shrink: 0;
}

.task-check.done {
  border-color: var(--primary);
  background: var(--primary);
}

.empty { text-align: center; color: var(--text-muted); padding: 2rem; }

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
  white-space: nowrap;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
