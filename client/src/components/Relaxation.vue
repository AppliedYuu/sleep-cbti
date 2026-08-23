<template>
  <div class="relaxation">
    <!-- 列表模式 -->
    <div v-if="!activeExercise" class="exercise-list">
      <div
        v-for="ex in exercises"
        :key="ex.id"
        class="exercise-card"
        @click="startExercise(ex)"
      >
        <span class="ex-icon">{{ ex.icon }}</span>
        <div class="ex-info">
          <h4>{{ ex.title }}</h4>
          <p>{{ ex.description }}</p>
          <span class="ex-duration">{{ formatDuration(ex.duration) }}</span>
        </div>
        <span class="ex-arrow">→</span>
      </div>
    </div>

    <!-- 播放模式 -->
    <div v-else class="player-mode">
      <button class="btn-back-player" @click="stopExercise">← 返回列表</button>

      <div class="player-card">
        <div class="player-icon">{{ activeExercise.icon }}</div>
        <h2>{{ activeExercise.title }}</h2>
        <p class="player-desc">{{ activeExercise.description }}</p>

        <!-- 定时器 -->
        <div class="timer-section">
          <div class="timer-display" :class="{ running: isPlaying }">
            {{ formatTime(timerRemaining) }}
          </div>
          <div class="timer-controls">
            <button class="btn-timer" @click="toggleTimer">
              {{ isPlaying ? '暂停' : '开始' }}
            </button>
            <button class="btn-timer btn-reset" @click="resetTimer">重置</button>
          </div>
        </div>

        <!-- 定时关闭设置 -->
        <div class="auto-stop" v-if="isPlaying">
          <label>定时关闭（分钟后）</label>
          <div class="auto-stop-options">
            <button
              v-for="min in [5, 10, 15, 20, 30]"
              :key="min"
              class="btn-auto-stop"
              :class="{ selected: autoStopMinutes === min }"
              @click="setAutoStop(min)"
            >{{ min }}分钟</button>
          </div>
          <p v-if="autoStopMinutes" class="auto-stop-info">
            将在 {{ autoStopMinutes }} 分钟后自动停止播放
          </p>
        </div>

        <!-- 呼吸引导（腹式呼吸） -->
        <div v-if="activeExercise.type === 'breathing' && isPlaying" class="breathing-guide">
          <div class="breath-circle" :class="breathPhase">
            <span class="breath-text">{{ breathText }}</span>
          </div>
          <p class="breath-counter">第 {{ breathCount }} / {{ activeExercise.repeat || 15 }} 次</p>
        </div>

        <!-- PMR 引导 -->
        <div v-if="activeExercise.type === 'pmr' && isPlaying" class="pmr-guide">
          <div class="pmr-current">
            <span class="pmr-index">{{ currentMuscleIndex + 1 }} / {{ activeExercise.muscleGroups?.length }}</span>
            <p class="pmr-instruction">{{ currentMuscleGroup?.instruction }}</p>
          </div>
          <div class="pmr-progress">
            <div
              v-for="(mg, mi) in activeExercise.muscleGroups"
              :key="mi"
              class="pmr-dot"
              :class="{ done: mi < currentMuscleIndex, current: mi === currentMuscleIndex }"
            ></div>
          </div>
          <button class="btn-next-muscle" @click="nextMuscle">下一个肌群 →</button>
        </div>

        <!-- 正念冥想 -->
        <div v-if="activeExercise.type === 'mindfulness' && isPlaying" class="mindfulness-guide">
          <p class="mindfulness-step">{{ currentMindfulnessStep }}</p>
          <div class="mindfulness-progress">
            <div class="mp-bar">
              <div class="mp-fill" :style="{ width: mindfulnessProgress + '%' }"></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showAutoStopToast" class="toast">定时关闭已触发，播放已停止</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { getRelaxationList, getRelaxationDetail } from '@/api/intervention';

const props = defineProps({ userId: String });

const exercises = ref([]);
const activeExercise = ref(null);
const isPlaying = ref(false);
const timerRemaining = ref(0);
const autoStopMinutes = ref(0);
const showAutoStopToast = ref(false);

// 所有计时句柄统一放外层，确保卸载时可清理
let timerInterval = null;
let autoStopTimeout = null;
let breathInterval = null;
let mindInterval = null;

// Breathing state
const breathPhase = ref('inhale');
const breathText = ref('吸气...');
const breathCount = ref(1);

// PMR state
const currentMuscleIndex = ref(0);

// Mindfulness state
const currentMindfulnessStep = ref('');
const mindfulnessProgress = ref(0);

const currentMuscleGroup = computed(() => {
  return activeExercise.value?.muscleGroups?.[currentMuscleIndex.value];
});

function formatDuration(seconds) {
  const m = Math.floor(seconds / 60);
  return m + '分钟';
}

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

async function loadList() {
  try {
    const res = await getRelaxationList();
    exercises.value = res.data || [];
  } catch { /* ignore */ }
}

async function startExercise(ex) {
  try {
    const res = await getRelaxationDetail(ex.id);
    activeExercise.value = res.data;
    timerRemaining.value = res.data.duration || 300;
    isPlaying.value = false;
    currentMuscleIndex.value = 0;
    breathCount.value = 1;
    mindfulnessProgress.value = 0;
    currentMindfulnessStep.value = '';
  } catch { /* ignore */ }
}

function toggleTimer() {
  if (isPlaying.value) {
    pauseTimer();
  } else {
    startTimer();
  }
}

function startTimer() {
  isPlaying.value = true;
  clearInterval(timerInterval);

  // 呼吸引导动画
  if (activeExercise.value?.type === 'breathing') {
    startBreathingCycle();
  }

  // 正念脚本
  if (activeExercise.value?.type === 'mindfulness') {
    startMindfulnessScript();
  }

  timerInterval = setInterval(() => {
    if (timerRemaining.value > 0) {
      timerRemaining.value--;
    } else {
      stopExercise();
    }
  }, 1000);
}

function pauseTimer() {
  isPlaying.value = false;
  clearInterval(timerInterval);
  clearInterval(breathInterval);
  clearInterval(mindInterval);
}

function resetTimer() {
  clearInterval(timerInterval);
  clearInterval(breathInterval);
  clearInterval(mindInterval);
  isPlaying.value = false;
  timerRemaining.value = activeExercise.value?.duration || 300;
  breathCount.value = 1;
  breathPhase.value = 'inhale';
  currentMuscleIndex.value = 0;
  mindfulnessProgress.value = 0;
}

function stopExercise() {
  clearInterval(timerInterval);
  clearInterval(breathInterval);
  clearInterval(mindInterval);
  clearTimeout(autoStopTimeout);
  isPlaying.value = false;
  activeExercise.value = null;
  autoStopMinutes.value = 0;
}

function setAutoStop(min) {
  autoStopMinutes.value = min;
  clearTimeout(autoStopTimeout);
  autoStopTimeout = setTimeout(() => {
    isPlaying.value = false;
    clearInterval(timerInterval);
    clearInterval(breathInterval);
    clearInterval(mindInterval);
    showAutoStopToast.value = true;
    setTimeout(() => { showAutoStopToast.value = false; }, 3000);
    autoStopMinutes.value = 0;
  }, min * 60 * 1000);
}

// 呼吸引导
function startBreathingCycle() {
  clearInterval(breathInterval);
  let phaseSec = 0;
  const inhaleSec = 4;
  const holdSec = 2;
  const exhaleSec = 6;
  const cycleTotal = inhaleSec + holdSec + exhaleSec;

  breathPhase.value = 'inhale';
  breathText.value = '吸气...';

  breathInterval = setInterval(() => {
    phaseSec++;
    if (phaseSec <= inhaleSec) {
      breathPhase.value = 'inhale';
      breathText.value = '吸气...';
    } else if (phaseSec <= inhaleSec + holdSec) {
      breathPhase.value = 'hold';
      breathText.value = '屏住...';
    } else if (phaseSec < cycleTotal) {
      breathPhase.value = 'exhale';
      breathText.value = '呼气...';
    } else {
      phaseSec = 0;
      breathCount.value++;
    }
  }, 1000);
}

// PMR
function nextMuscle() {
  if (currentMuscleIndex.value < (activeExercise.value?.muscleGroups?.length || 0) - 1) {
    currentMuscleIndex.value++;
  }
}

// 正念冥想
function startMindfulnessScript() {
  const steps = activeExercise.value?.guideScript || [];
  if (steps.length === 0) return;

  let stepIdx = 0;
  const totalTime = activeExercise.value.duration || 480;
  const stepDuration = Math.round(totalTime / steps.length);

  currentMindfulnessStep.value = steps[0];
  mindfulnessProgress.value = 0;

  clearInterval(mindInterval);
  mindInterval = setInterval(() => {
    stepIdx++;
    if (stepIdx < steps.length) {
      currentMindfulnessStep.value = steps[stepIdx];
      mindfulnessProgress.value = Math.round((stepIdx / steps.length) * 100);
    } else {
      clearInterval(mindInterval);
    }
  }, stepDuration * 1000);
}

watch(() => activeExercise.value, (newVal) => {
  if (!newVal) {
    clearInterval(breathInterval);
    clearInterval(timerInterval);
    clearInterval(mindInterval);
  }
});

onMounted(loadList);
onUnmounted(() => {
  clearInterval(timerInterval);
  clearInterval(breathInterval);
  clearInterval(mindInterval);
  clearTimeout(autoStopTimeout);
});
</script>

<style scoped>
.relaxation { min-height: 200px; }

.exercise-list { display: flex; flex-direction: column; gap: var(--space-2); }

/* 实体纸卡：无玻璃、无发光、无位移弹跳 */
.exercise-card {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: 1rem 1.2rem;
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  cursor: pointer;
  transition: box-shadow var(--dur) var(--ease),
              border-color var(--dur) var(--ease);
}

.exercise-card:hover {
  box-shadow: var(--shadow-float);
  border-color: var(--border-mid);
}
.ex-icon { font-size: 2rem; flex-shrink: 0; }

.ex-info { flex: 1; }
.ex-info h4 { font-size: var(--fs-md); color: var(--text-strong); margin-bottom: 0.2rem; }
.ex-info p { font-size: var(--fs-xs); color: var(--text-muted); line-height: 1.4; margin-bottom: 0.3rem; }
.ex-duration { font-size: var(--fs-xs); color: var(--primary-strong); font-weight: 500; }
.ex-arrow { font-size: 1.2rem; color: var(--text-faint); }

.btn-back-player {
  display: block;
  background: none;
  border: none;
  color: var(--primary-strong);
  font-size: var(--fs-sm);
  font-family: inherit;
  cursor: pointer;
  padding: 0;
  margin-bottom: var(--space-2);
  transition: opacity var(--dur-fast) var(--ease-out);
}
.btn-back-player:hover { opacity: 0.75; }

.player-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  text-align: center;
  box-shadow: var(--shadow-card);
}

.player-icon { font-size: 3rem; margin-bottom: 0.5rem; }

.player-card h2 { font-size: var(--fs-xl); color: var(--text-strong); margin-bottom: 0.3rem; }

.player-desc { font-size: var(--fs-sm); color: var(--text-muted); margin-bottom: var(--space-3); }

.timer-section { margin-bottom: var(--space-3); }

/* 衬线大数字计时器，运行态换主色、无发光 */
.timer-display {
  font-family: var(--font-serif);
  font-size: 3rem;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  color: var(--text-faint);
  margin-bottom: 0.6rem;
  transition: color var(--dur) var(--ease);
}

.timer-display.running {
  color: var(--primary-strong);
}

.timer-controls {
  display: flex;
  justify-content: center;
  gap: var(--space-2);
}

.btn-timer {
  padding: 0.6rem 1.5rem;
  border: 1px solid var(--primary);
  border-radius: var(--radius-pill);
  background: var(--primary);
  color: var(--text-on-primary);
  font-size: var(--fs-md);
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur) var(--ease);
}
.btn-timer:hover { background: var(--primary-strong); }

.btn-reset {
  border-color: var(--border-mid);
  color: var(--text-muted);
  background: transparent;
}
.btn-reset:hover { background: var(--bg-surface); border-color: var(--primary); color: var(--primary-strong); }

.auto-stop { margin-bottom: var(--space-3); text-align: left; }

.auto-stop label { font-size: var(--fs-sm); color: var(--text-muted); display: block; margin-bottom: 0.4rem; }

.auto-stop-options { display: flex; gap: 0.4rem; flex-wrap: wrap; }

.btn-auto-stop {
  padding: 0.35rem 0.7rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-muted);
  font-size: var(--fs-xs);
  font-family: inherit;
  cursor: pointer;
  transition: border-color var(--dur-fast) var(--ease-out),
              color var(--dur-fast) var(--ease-out),
              background var(--dur-fast) var(--ease-out);
}

.btn-auto-stop:hover { border-color: var(--primary); color: var(--primary-strong); }

.btn-auto-stop.selected {
  background: var(--primary-weak);
  color: var(--primary-strong);
  border-color: var(--primary);
}

.auto-stop-info {
  font-size: var(--fs-xs);
  color: var(--primary-strong);
  margin-top: 0.4rem;
}

/* 呼吸引导：纯色描边圆 + 缩放，无渐变无光晕 */
.breathing-guide { margin: var(--space-2) 0; }

.breath-circle {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  margin: 0 auto 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid rgba(127, 179, 166, 0.45);
  background: rgba(127, 179, 166, 0.10);
  transition: transform var(--dur-slow) var(--ease-out),
              background var(--dur-slow) var(--ease-out),
              border-color var(--dur-slow) var(--ease-out);
}

.breath-circle.inhale {
  transform: scale(1.3);
  background: rgba(127, 179, 166, 0.22);
  border-color: rgba(127, 179, 166, 0.70);
}
.breath-circle.hold {
  transform: scale(1.3);
  background: rgba(127, 179, 166, 0.16);
  border-color: rgba(127, 179, 166, 0.55);
}
.breath-circle.exhale {
  transform: scale(1);
  background: rgba(127, 179, 166, 0.10);
  border-color: rgba(127, 179, 166, 0.45);
}

.breath-text { font-size: var(--fs-md); color: var(--primary-strong); font-weight: 500; }
.breath-counter { font-size: var(--fs-sm); color: var(--text-muted); }

/* PMR */
.pmr-guide { margin: var(--space-2) 0; }

.pmr-current { margin-bottom: var(--space-2); }

.pmr-index { display: inline-block; background: var(--primary-weak); color: var(--primary-strong); padding: 0.2rem 0.6rem; border-radius: var(--radius-sm); font-size: var(--fs-xs); margin-bottom: 0.4rem; }

.pmr-instruction { font-size: var(--fs-sm); color: var(--text-base); line-height: 1.5; }

.pmr-progress { display: flex; justify-content: center; gap: 0.3rem; margin-bottom: var(--space-2); }

.pmr-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--border-mid);
  transition: background var(--dur-base) var(--ease-out), transform var(--dur-base) var(--ease-out);
}

.pmr-dot.done { background: var(--accent-mint); }
.pmr-dot.current { background: var(--primary-strong); transform: scale(1.3); }

.btn-next-muscle {
  padding: 0.4rem 1rem;
  border: 1px solid var(--primary);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--primary-strong);
  font-size: var(--fs-sm);
  font-family: inherit;
  cursor: pointer;
  transition: background var(--dur-fast) var(--ease-out),
              color var(--dur-fast) var(--ease-out);
}
.btn-next-muscle:hover { background: var(--primary-weak); }

/* 正念冥想 */
.mindfulness-guide { margin: var(--space-2) 0; }

.mindfulness-step {
  font-size: var(--fs-md);
  color: var(--text-base);
  line-height: 1.6;
  min-height: 60px;
}

.mindfulness-progress { margin-top: var(--space-2); }

.mp-bar {
  height: 6px;
  background: var(--bg-line);
  border-radius: var(--radius-pill);
  overflow: hidden;
}

.mp-fill {
  height: 100%;
  background: var(--primary);
  border-radius: var(--radius-pill);
  transition: width var(--dur-slow) var(--ease-out);
}

/* Toast：与全站统一的深墨底 */
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
  animation: fadeInOut 3s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
