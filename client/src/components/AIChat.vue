<template>
  <div class="ai-chat">
    <!-- 消息列表 -->
    <div class="chat-messages" ref="msgList">
      <div v-if="messages.length === 0" class="chat-welcome">
        <span class="welcome-icon">AI</span>
        <p>你好！我是你的 AI 睡眠顾问。</p>
        <p class="welcome-hint">我已经读取了你的睡眠数据，可以问我任何问题：</p>
        <div class="quick-asks">
          <button v-for="q in quickQuestions" :key="q" @click="ask(q)" class="btn-quick">{{ q }}</button>
        </div>
      </div>

      <div v-for="(m, i) in messages" :key="i" class="chat-msg" :class="m.role">
        <span class="msg-avatar">{{ m.role === 'user' ? '你' : 'AI' }}</span>
        <div class="msg-bubble">{{ m.content }}</div>
      </div>

      <div v-if="loading" class="chat-msg assistant">
        <span class="msg-avatar">AI</span>
        <div class="msg-bubble typing"><span></span><span></span><span></span></div>
      </div>
    </div>

    <!-- 输入区 -->
    <div class="chat-input">
      <textarea
        ref="inputEl"
        v-model="input"
        @keydown.enter.exact.prevent="send"
        placeholder="输入你的问题…（Shift+Enter 换行）"
        class="input-msg"
        rows="1"
        :disabled="loading"
      ></textarea>
      <button @click="send" class="btn-send" :disabled="loading || !input.trim()">发送</button>
      <button @click="clearHistory" class="btn-clear" v-if="messages.length" aria-label="清空对话历史">清空</button>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, watch } from 'vue';
import { useAuthStore } from '@/stores/auth';
import request from '@/api/request';

const props = defineProps({ userId: [String, Number] });
const authStore = useAuthStore();

const STORAGE_KEY = 'ai_chat_history';

function loadHistory() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || []; }
  catch { return []; }
}
function saveHistory() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(messages.value.slice(-50))); }
  catch { /* ignore */ }
}

const messages = ref(loadHistory());
const input = ref('');
const loading = ref(false);
const msgList = ref(null);
const inputEl = ref(null);

// 输入框自适应高度（最多约 4 行，超出滚动）
watch(input, () => {
  const el = inputEl.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 96) + 'px';
});

const quickQuestions = [
  '我的睡眠状况怎么样？',
  '怎么才能更快入睡？',
  '半夜醒了睡不着怎么办？',
  '午睡到底好不好？',
];

async function send() {
  const text = input.value.trim();
  if (!text || loading.value) return;
  input.value = '';

  messages.value.push({ role: 'user', content: text });
  saveHistory();
  loading.value = true;
  await scrollBottom();

  try {
    const id = props.userId || authStore.user?.id;
    const res = await request.post('/ai/chat', {
      userId: id,
      messages: messages.value.map(m => ({ role: m.role, content: m.content })),
    });
    messages.value.push(res.data);
  } catch (e) {
    messages.value.push({ role: 'assistant', content: '抱歉，AI 服务暂时不可用：' + (e.response?.data?.message || e.message) });
  }
  saveHistory();
  loading.value = false;
  await scrollBottom();
}

function ask(q) { input.value = q; send(); }
function clearHistory() { messages.value = []; localStorage.removeItem(STORAGE_KEY); }

async function scrollBottom() {
  await nextTick();
  if (msgList.value) msgList.value.scrollTop = msgList.value.scrollHeight;
}
</script>

<style scoped>
.ai-chat {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 160px);
  min-height: 350px;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  padding: 0.5rem 0;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

/* 实体纸卡欢迎区 */
.chat-welcome {
  text-align: center;
  padding: 1.5rem 1rem;
  background: var(--bg-surface);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
}

.welcome-icon {
  font-family: var(--font-serif);
  font-size: 1rem;
  letter-spacing: 0.08em;
  width: 3rem;
  height: 3rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.6rem;
  border-radius: 50%;
  background: var(--primary-weak);
  color: var(--primary-strong);
}

.chat-welcome p { font-size: var(--fs-md); color: var(--text-base); }

.chat-welcome .welcome-hint { font-size: var(--fs-sm); color: var(--text-muted); margin: 0.8rem 0 0.5rem; }

.quick-asks {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  justify-content: center;
  margin-top: 0.6rem;
}

.btn-quick {
  padding: 0.4rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: var(--bg-sunken);
  color: var(--primary-strong);
  font-size: var(--fs-xs);
  font-family: inherit;
  cursor: pointer;
  transition: border-color var(--dur-base) var(--ease-out),
              background var(--dur-base) var(--ease-out);
}

.btn-quick:hover {
  background: var(--primary-weak);
  border-color: var(--primary);
}

.chat-msg {
  display: flex;
  gap: 0.5rem;
  align-items: flex-start;
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

@keyframes rise-in {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}

.chat-msg.user { flex-direction: row-reverse; }

/* 衬线圆章头像 */
.msg-avatar {
  font-family: var(--font-serif);
  font-size: 0.72rem;
  width: 1.8rem;
  height: 1.8rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: var(--bg-sunken);
  color: var(--text-muted);
  flex-shrink: 0;
}

.msg-bubble {
  max-width: 80%;
  padding: 0.6rem 0.9rem;
  border-radius: var(--radius-md);
  font-size: var(--fs-sm);
  line-height: 1.6;
  white-space: pre-wrap;
}

.chat-msg.assistant .msg-bubble {
  background: var(--bg-surface);
  color: var(--text-base);
  border: 1px solid var(--border-soft);
  border-bottom-left-radius: var(--radius-sm);
}

/* 用户气泡：同结构、弱主色铺底 */
.chat-msg.user .msg-avatar { background: var(--primary-weak); color: var(--primary-strong); }
.chat-msg.user .msg-bubble {
  background: var(--primary-weak);
  color: var(--text-strong);
  border: 1px solid rgba(124, 152, 133, 0.35);
  border-bottom-right-radius: var(--radius-sm);
}

/* 三点跳点加载 */
.msg-bubble.typing {
  display: inline-flex;
  gap: 4px;
  align-items: center;
  min-height: 1.2em;
}
.msg-bubble.typing span {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--text-faint);
  animation: dot-jump 1s infinite;
}
.msg-bubble.typing span:nth-child(2) { animation-delay: 0.15s; }
.msg-bubble.typing span:nth-child(3) { animation-delay: 0.3s; }

@keyframes dot-jump {
  0%, 100% { opacity: 0.3; transform: translateY(0); }
  50% { opacity: 1; transform: translateY(-3px); }
}

/* 纸面输入栏 */
.chat-input {
  display: flex;
  gap: 0.5rem;
  align-items: flex-end;
  padding: 0.6rem 0;
  border-top: 1px solid var(--border-soft);
  background: var(--bg-base);
  position: sticky;
  bottom: 0;
}

.input-msg {
  flex: 1;
  padding: 0.55rem 0.9rem;
  background: var(--bg-sunken);
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-md);
  font-size: var(--fs-sm);
  font-family: inherit;
  line-height: 1.5;
  color: var(--text-strong);
  outline: none;
  resize: none;
  overflow-y: auto;
  transition: border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.input-msg::placeholder { color: var(--text-faint); }
.input-msg:focus {
  border-color: var(--primary);
  box-shadow: var(--focus-ring);
}

.btn-send {
  padding: 0.55rem 1.2rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-size: var(--fs-sm);
  font-family: inherit;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: background var(--dur-base) var(--ease-out);
}

.btn-send:hover:not(:disabled) {
  background: var(--primary-strong);
}

.btn-send:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-clear {
  padding: 0.55rem 0.7rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--text-muted);
  font-size: var(--fs-xs);
  font-family: inherit;
  cursor: pointer;
  transition: color var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out);
}

.btn-clear:hover { color: var(--danger); border-color: var(--danger); }
</style>
