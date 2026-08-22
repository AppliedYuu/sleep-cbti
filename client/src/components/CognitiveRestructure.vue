<template>
  <div class="cognitive-restructure">
    <div v-if="exercise && !isCompleted">
      <div class="day-badge">第 {{ exercise.dayIndex + 1 }} 天</div>

      <!-- 对比卡片 -->
      <div class="compare-cards">
        <div class="cc-thought">
          <div class="cc-header">💭 常见想法</div>
          <p>{{ exercise.thought }}</p>
        </div>
        <div class="cc-fact">
          <div class="cc-header">🔬 科学事实</div>
          <p>{{ exercise.fact }}</p>
        </div>
      </div>

      <p class="instruction">{{ exercise.instruction }}</p>

      <!-- 填空表单 -->
      <div class="exercise-form">
        <div class="form-item">
          <label>1. 我是否有过类似的想法？请描述你当时的感受：</label>
          <textarea
            v-model="thoughtRecord"
            placeholder="写下你的真实想法和感受..."
            rows="3"
            class="input-textarea"
          ></textarea>
        </div>
        <div class="form-item">
          <label>2. 看到科学事实后，我的想法有什么变化？</label>
          <textarea
            v-model="factCheck"
            placeholder="例如：我意识到...…现在我觉得...…"
            rows="3"
            class="input-textarea"
          ></textarea>
        </div>
      </div>

      <button
        class="btn-submit"
        :disabled="!thoughtRecord.trim() || !factCheck.trim() || submitting"
        @click="doSubmit"
      >
        {{ submitting ? '提交中...' : '✅ 提交练习' }}
      </button>
    </div>

    <!-- 已完成状态 -->
    <div v-if="isCompleted" class="completed-state">
      <div class="complete-icon">🎉</div>
      <h3>今日认知训练已完成！</h3>
      <p>你已经迈出了改变睡眠信念的重要一步。明天会有新的练习。</p>
      <div class="completed-content" v-if="completedData">
        <div class="cc-label">你的记录：</div>
        <p class="cc-record"><strong>想法记录：</strong>{{ completedData.thoughtRecord }}</p>
        <p class="cc-record"><strong>事实检验：</strong>{{ completedData.factCheck }}</p>
      </div>
    </div>

    <div v-if="showToast" class="toast">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getCognitiveTask, submitCognitiveTask } from '@/api/intervention';

const props = defineProps({ userId: String });
const exercise = ref(null);
const isCompleted = ref(false);
const submitting = ref(false);
const thoughtRecord = ref('');
const factCheck = ref('');
const toastMsg = ref('');
const showToast = ref(false);
const completedData = ref(null);

async function loadTask() {
  try {
    const res = await getCognitiveTask(props.userId);
    exercise.value = res.data;
    isCompleted.value = res.data.isCompleted;
  } catch { /* ignore */ }
}

async function doSubmit() {
  submitting.value = true;
  try {
    const res = await submitCognitiveTask(props.userId, {
      exerciseId: exercise.value.id,
      thoughtRecord: thoughtRecord.value,
      factCheck: factCheck.value,
    });
    completedData.value = {
      thoughtRecord: thoughtRecord.value,
      factCheck: factCheck.value,
    };
    isCompleted.value = true;
    toastMsg.value = res.message;
    showToast.value = true;
    setTimeout(() => { showToast.value = false; }, 2500);
  } catch (err) {
    alert(err.response?.data?.message || '提交失败');
  } finally {
    submitting.value = false;
  }
}

onMounted(loadTask);
</script>

<style scoped>
.cognitive-restructure { min-height: 200px; }

.day-badge {
  display: inline-block;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  color: var(--accent-purple);
  padding: 0.25rem 0.8rem;
  border-radius: var(--radius-pill);
  font-size: var(--fs-xs);
  font-weight: 600;
  margin-bottom: var(--space-2);
  box-shadow: var(--glow-purple);
}

.compare-cards {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.cc-thought, .cc-fact {
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: var(--shadow-card);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.cc-thought:hover, .cc-fact:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-soft), var(--glow-purple);
}

.cc-thought {
  border-left: 4px solid var(--accent-amber);
}

.cc-fact {
  border-left: 4px solid var(--accent-purple);
}

.cc-header {
  font-size: var(--fs-sm);
  font-weight: 700;
  margin-bottom: var(--space-1);
  color: var(--text-strong);
}

.cc-thought p, .cc-fact p {
  font-size: var(--fs-sm);
  color: var(--text-base);
  line-height: 1.6;
}

.instruction {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: var(--space-3);
  white-space: pre-line;
  line-height: 1.5;
}

.exercise-form { display: flex; flex-direction: column; gap: var(--space-3); margin-bottom: var(--space-3); }

.form-item {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: var(--space-3);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.form-item label {
  display: block;
  font-size: var(--fs-sm);
  color: var(--text-strong);
  font-weight: 600;
  margin-bottom: var(--space-2);
  line-height: 1.4;
}

.input-textarea {
  width: 100%;
  padding: 0.6rem 0.8rem;
  background: var(--bg-soft);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  color: var(--text-strong);
  outline: none;
  resize: vertical;
  font-family: inherit;
  transition: border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.input-textarea::placeholder { color: var(--text-faint); }
.input-textarea:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.btn-submit {
  width: 100%;
  padding: 0.8rem;
  background: var(--accent-purple);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-size: var(--fs-lg);
  font-weight: 600;
  cursor: pointer;
  transition: all var(--dur-base) var(--ease-out);
  box-shadow: var(--glow-purple);
}

.btn-submit:hover {
  transform: translateY(-2px);
  box-shadow: var(--glow-purple), var(--shadow-soft);
}

.btn-submit:active { transform: scale(0.98); }

.btn-submit:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

.completed-state {
  text-align: center;
  padding: var(--space-5) var(--space-3);
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.complete-icon { font-size: 3rem; margin-bottom: var(--space-2); }

.completed-state h3 { color: var(--text-strong); margin-bottom: var(--space-1); }

.completed-state p { color: var(--text-muted); font-size: var(--fs-sm); line-height: 1.5; }

.completed-content {
  margin-top: var(--space-3);
  background: var(--bg-soft);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: var(--space-3);
  text-align: left;
}

.cc-label { font-size: var(--fs-sm); color: var(--text-muted); margin-bottom: var(--space-1); }

.cc-record { font-size: var(--fs-sm); color: var(--text-base); margin-bottom: 0.3rem; line-height: 1.4; }

.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--accent-mint);
  color: var(--text-on-primary);
  padding: 0.6rem 1.5rem;
  border-radius: var(--radius-pill);
  font-weight: 600;
  z-index: 100;
  box-shadow: var(--glow-mint);
  animation: fadeInOut 2.5s ease;
}

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
