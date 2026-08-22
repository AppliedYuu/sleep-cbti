<template>
  <div class="questionnaire">
    <div class="q-header">
      <button class="btn-back" @click="$emit('back')" v-if="!hideBack">← 返回</button>
      <h2>{{ config.title }}</h2>
      <p class="q-instruction">{{ config.instruction }}</p>
      <div class="q-progress">
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: progressPct + '%' }"></div>
        </div>
        <span class="progress-text">{{ currentIndex + 1 }} / {{ allQuestions.length }}</span>
      </div>
    </div>

    <div class="q-body">
      <!-- 分组显示 -->
      <div v-for="(section, si) in config.sections" :key="'s-' + si">
        <div
          v-for="(q, qi) in section.questions"
          :key="'q-' + q.id"
          :ref="el => { if (el) questionRefs[q.id] = el; }"
        >
          <div
            class="question-card"
            :class="{ active: currentQ?.id === q.id, answered: answers[q.id] !== undefined && answers[q.id] !== '' }"
            :data-qid="q.id"
          >
            <div class="q-section-label" v-if="qi === 0">{{ section.title }}</div>
            <div v-if="section.description && qi === 0" class="q-section-desc">{{ section.description }}</div>

            <p class="q-label">
              {{ q.label }}
              <span v-if="q.optional" class="q-optional">（选填）</span>
            </p>

            <!-- 时间选择器 -->
            <div v-if="q.type === 'time'" class="q-input-group">
              <input
                type="time"
                :value="answers[q.id] || ''"
                @input="setAnswer(q.id, $event.target.value)"
                class="input-time"
              />
              <span v-if="q.hint" class="input-hint">{{ q.hint }}</span>
            </div>

            <!-- 数字输入 -->
            <div v-else-if="q.type === 'number'" class="q-input-group">
              <input
                type="number"
                :value="answers[q.id] || ''"
                @input="setAnswer(q.id, $event.target.value)"
                :min="q.min"
                :max="q.max"
                :step="q.step || 1"
                class="input-number"
                :placeholder="'请输入' + (q.unit || '')"
              />
              <span v-if="q.unit" class="input-unit">{{ q.unit }}</span>
            </div>

            <!-- 4级评分 -->
            <div v-else-if="q.type === 'scale4' || section.scaleType === 'frequency4'" class="q-scale-options">
              <button
                v-for="(label, oi) in (q.scaleLabels || section.scaleLabels)"
                :key="oi"
                :class="['btn-scale', { selected: answers[q.id] === oi }]"
                @click="setAnswer(q.id, oi)"
              >
                <span class="scale-dot" :class="'level-' + oi"></span>
                {{ label }}
              </button>
            </div>

            <!-- 7级 Likert (SHPS) -->
            <div v-else-if="section.scaleType !== 'likert10' && config.scaleLabels?.length === 8" class="q-scale-slider">
              <div class="slider-labels-top">
                <span v-for="(sl, sli) in config.scaleLabels" :key="sli" class="sl-label"
                  :class="{ active: answers[q.id] === sl.value }">
                  {{ sl.label }}
                </span>
              </div>
              <input
                type="range"
                :value="answers[q.id] ?? -1"
                @input="setAnswer(q.id, parseInt($event.target.value))"
                min="0"
                max="7"
                step="1"
                class="range-slider"
              />
              <div class="slider-value" v-if="answers[q.id] !== undefined && answers[q.id] !== ''">
                当前选择：<strong>{{ answers[q.id] }}</strong> — {{ config.scaleLabels[answers[q.id]]?.label }}
              </div>
              <div class="slider-value placeholder" v-else>请拖动滑块选择</div>
            </div>

            <!-- 10级 Likert (DBAS-16) -->
            <div v-else-if="section.scaleType === 'likert10'" class="q-scale-likert10">
              <div class="likert-endpoints">
                <span>{{ config.scaleLabels[0].label }} (0)</span>
                <span>{{ config.scaleLabels[2].label }} (10)</span>
              </div>
              <input
                type="range"
                :value="answers[q.id] ?? -1"
                @input="setAnswer(q.id, parseInt($event.target.value))"
                min="0"
                max="10"
                step="1"
                class="range-slider"
              />
              <div class="slider-value" v-if="answers[q.id] !== undefined && answers[q.id] !== ''">
                当前评分：<strong>{{ answers[q.id] }}</strong> / 10
              </div>
              <div class="slider-value placeholder" v-else>请拖动滑块选择（0-10分）</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部操作栏 -->
    <div class="q-footer">
      <button
        v-if="currentIndex > 0"
        class="btn-nav btn-prev"
        @click="goPrev"
      >上一题</button>
      <button
        v-if="currentIndex < allQuestions.length - 1"
        class="btn-nav btn-next"
        @click="goNext"
        :disabled="currentAnswer === undefined || currentAnswer === ''"
      >下一题</button>
      <button
        v-if="currentIndex >= allQuestions.length - 1"
        class="btn-nav btn-submit"
        :disabled="!allAnswered"
        @click="handleSubmit"
      >提交评估</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';

const props = defineProps({
  config: { type: Object, required: true },
  hideBack: { type: Boolean, default: false },
});

const emit = defineEmits(['back', 'submit']);

const answers = ref({});
const currentIndex = ref(0);

const questionRefs = ref({});

const allQuestions = computed(() => {
  const list = [];
  for (const section of props.config.sections) {
    for (const q of section.questions) {
      list.push(q);
    }
  }
  return list;
});

const currentQ = computed(() => allQuestions.value[currentIndex.value]);

const currentAnswer = computed(() => {
  if (!currentQ.value) return undefined;
  return answers.value[currentQ.value.id];
});

const allAnswered = computed(() => {
  return allQuestions.value.every(q => {
    if (q.optional) return true;
    const val = answers.value[q.id];
    return val !== undefined && val !== '' && val !== -1;
  });
});

const progressPct = computed(() => {
  const answered = allQuestions.value.filter(q => {
    const val = answers.value[q.id];
    return val !== undefined && val !== '' && val !== -1;
  }).length;
  return Math.round((answered / allQuestions.value.length) * 100);
});

function setAnswer(id, value) {
  answers.value[id] = value;
}

function goNext() {
  if (currentIndex.value < allQuestions.value.length - 1) {
    currentIndex.value++;
    scrollToCurrent();
  }
}

function goPrev() {
  if (currentIndex.value > 0) {
    currentIndex.value--;
    scrollToCurrent();
  }
}

function scrollToCurrent() {
  nextTick(() => {
    const qid = currentQ.value?.id;
    if (qid && questionRefs.value[qid]) {
      questionRefs.value[qid].scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  });
}

function handleSubmit() {
  // 构建答案对象
  const result = {};
  for (const q of allQuestions.value) {
    result[q.id] = answers.value[q.id];
  }
  emit('submit', result);
}
</script>

<style scoped>
.questionnaire {
  padding-bottom: 100px;
  position: relative;
  min-height: 100vh;
  background: transparent;
}

.q-header {
  padding: var(--space-3);
  background: linear-gradient(135deg, var(--bg-glass-strong), rgba(138, 180, 248, 0.12));
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border-soft);
  color: var(--text-strong);
  position: sticky;
  top: 0;
  z-index: 10;
}

.btn-back {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  color: var(--text-base);
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  cursor: pointer;
  margin-bottom: var(--space-2);
  transition: background var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out);
}

.btn-back:hover {
  background: var(--bg-hover);
  border-color: var(--border-mid);
}

.q-header h2 {
  font-size: var(--fs-lg);
  margin-bottom: var(--space-1);
  color: var(--text-strong);
}

.q-instruction {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  line-height: 1.4;
}

.q-progress {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.progress-bar {
  flex: 1;
  height: 6px;
  background: var(--bg-soft);
  border-radius: var(--radius-pill);
  overflow: hidden;
  border: 1px solid var(--border-soft);
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary), var(--accent-mint));
  border-radius: var(--radius-pill);
  transition: width var(--dur-base) var(--ease-out);
  box-shadow: var(--glow-primary);
}

.progress-text {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  white-space: nowrap;
}

.q-body {
  padding: var(--space-2) var(--space-3);
}

.question-card {
  padding: var(--space-3);
  margin-bottom: var(--space-2);
  background: var(--bg-glass);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
  transition: border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              transform var(--dur-base) var(--ease-out);
  border-left: 2px solid transparent;
}

.question-card.active {
  border-color: var(--border-glow);
  box-shadow: var(--shadow-card), var(--glow-primary);
}

.question-card.answered {
  border-left: 3px solid var(--accent-mint);
}

.q-section-label {
  font-size: var(--fs-xs);
  color: var(--primary);
  font-weight: 700;
  margin-bottom: var(--space-1);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.q-section-desc {
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-bottom: var(--space-2);
  line-height: 1.5;
}

.q-label {
  font-size: var(--fs-md);
  color: var(--text-strong);
  line-height: 1.5;
  margin-bottom: var(--space-2);
}

.q-optional {
  font-size: var(--fs-xs);
  color: var(--text-muted);
}

.q-input-group {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.input-time,
.input-number {
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  background: var(--bg-soft);
  color: var(--text-base);
  outline: none;
  transition: border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
  width: 180px;
}

.input-time:focus,
.input-number:focus {
  border-color: var(--primary);
  box-shadow: var(--glow-primary);
}

.input-hint,
.input-unit {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

/* 4级按钮选择 */
.q-scale-options {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.btn-scale {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: var(--bg-soft);
  color: var(--text-base);
  font-size: var(--fs-sm);
  cursor: pointer;
  transition: all var(--dur-base) var(--ease-out);
}

.btn-scale:hover {
  transform: translateY(-2px);
  border-color: var(--border-glow);
  box-shadow: var(--shadow-soft);
}

.btn-scale:active {
  transform: scale(0.98);
}

.btn-scale.selected {
  background: var(--primary);
  border-color: var(--primary);
  color: var(--text-on-primary);
  font-weight: 600;
  box-shadow: var(--glow-primary);
}

.scale-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.scale-dot.level-0 { background: var(--success); }
.scale-dot.level-1 { background: var(--accent-mint); }
.scale-dot.level-2 { background: var(--warning); }
.scale-dot.level-3 { background: var(--danger); }

/* 滑块 */
.q-scale-slider,
.q-scale-likert10 {
  padding: var(--space-2) 0;
}

.slider-labels-top {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-2);
}

.sl-label {
  font-size: var(--fs-xs);
  color: var(--text-faint);
  text-align: center;
  flex: 1;
  transition: color var(--dur-base) var(--ease-out);
}

.sl-label.active {
  color: var(--primary);
  font-weight: 600;
}

.likert-endpoints {
  display: flex;
  justify-content: space-between;
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin-bottom: var(--space-1);
}

.range-slider {
  width: 100%;
  -webkit-appearance: none;
  appearance: none;
  height: 6px;
  border-radius: var(--radius-pill);
  background: linear-gradient(to right, var(--success), var(--warning), var(--danger));
  outline: none;
  border: 1px solid var(--border-soft);
}

.range-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-elevated);
  box-shadow: var(--glow-primary);
  cursor: pointer;
  transition: transform var(--dur-base) var(--ease-out);
}

.range-slider::-webkit-slider-thumb:hover {
  transform: scale(1.1);
}

.range-slider::-moz-range-thumb {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--primary);
  border: 2px solid var(--bg-elevated);
  box-shadow: var(--glow-primary);
  cursor: pointer;
}

.slider-value {
  margin-top: var(--space-1);
  font-size: var(--fs-sm);
  color: var(--primary);
  text-align: center;
}

.slider-value.placeholder {
  color: var(--text-faint);
  font-style: italic;
}

/* Footer */
.q-footer {
  position: fixed;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  max-width: 480px;
  display: flex;
  justify-content: center;
  gap: var(--space-3);
  padding: var(--space-3);
  background: var(--bg-glass-strong);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-top: 1px solid var(--border-soft);
  box-shadow: 0 -8px 28px rgba(0, 0, 0, 0.4);
  z-index: 10;
}

.btn-nav {
  padding: 0.7rem 2rem;
  border: none;
  border-radius: var(--radius-pill);
  font-size: var(--fs-md);
  cursor: pointer;
  transition: all var(--dur-base) var(--ease-out);
}

.btn-nav:active {
  transform: scale(0.98);
}

.btn-prev {
  background: var(--bg-soft);
  color: var(--text-muted);
  border: 1px solid var(--border-mid);
}

.btn-prev:hover {
  background: var(--bg-hover);
  color: var(--text-base);
}

.btn-next {
  background: var(--primary);
  color: var(--text-on-primary);
  box-shadow: var(--glow-primary);
}

.btn-next:hover {
  background: var(--primary-strong);
}

.btn-submit {
  background: var(--primary);
  color: var(--text-on-primary);
  font-weight: 600;
  letter-spacing: 0.05em;
  box-shadow: var(--glow-primary);
}

.btn-submit:hover {
  background: var(--primary-strong);
}

.btn-nav:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}
</style>
