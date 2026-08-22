<template>
  <div class="register-page">
    <div class="register-card">
      <div class="register-header">
        <span class="logo">🌙</span>
        <h1>创建账号</h1>
        <p>加入睡益良方，开始改善睡眠</p>
      </div>

      <form @submit.prevent="handleRegister" class="register-form">
        <div class="form-item">
          <label>用户名</label>
          <input
            v-model="username"
            type="text"
            placeholder="3-50个字符，字母数字下划线"
            class="input-field"
            autocomplete="username"
          />
        </div>

        <div class="form-item">
          <label>昵称（选填）</label>
          <input
            v-model="nickname"
            type="text"
            placeholder="如何称呼你？"
            class="input-field"
          />
        </div>

        <div class="form-item">
          <label>密码</label>
          <input
            v-model="password"
            type="password"
            placeholder="至少6个字符"
            class="input-field"
            autocomplete="new-password"
          />
        </div>

        <div class="form-item">
          <label>确认密码</label>
          <input
            v-model="confirmPassword"
            type="password"
            placeholder="再次输入密码"
            class="input-field"
            autocomplete="new-password"
          />
        </div>

        <button type="submit" class="btn-register" :disabled="loading">
          {{ loading ? '注册中...' : '注 册' }}
        </button>

        <div class="form-footer">
          <router-link to="/login">已有账号？立即登录</router-link>
        </div>
      </form>

      <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = useRouter();
const authStore = useAuthStore();

const username = ref('');
const nickname = ref('');
const password = ref('');
const confirmPassword = ref('');
const loading = ref(false);
const errorMsg = ref('');

async function handleRegister() {
  errorMsg.value = '';

  if (!username.value || !password.value) {
    errorMsg.value = '请输入用户名和密码';
    return;
  }

  if (password.value !== confirmPassword.value) {
    errorMsg.value = '两次输入的密码不一致';
    return;
  }

  if (password.value.length < 6) {
    errorMsg.value = '密码至少6个字符';
    return;
  }

  loading.value = true;

  try {
    await authStore.doRegister(username.value, password.value, nickname.value || undefined);
    router.push('/');
  } catch (err) {
    errorMsg.value = err.response?.data?.message || '注册失败';
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.register-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  /* 静谧夜空背景 */
  background:
    radial-gradient(900px 500px at 50% -10%, rgba(138, 180, 248, 0.12), transparent 60%),
    radial-gradient(700px 420px at 85% 15%, rgba(183, 148, 246, 0.10), transparent 55%),
    linear-gradient(180deg, #0b1020 0%, #0f1426 60%, #0c1124 100%);
  padding: 2rem 1.2rem;
}

.register-card {
  width: 100%;
  max-width: 400px;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-lg);
  padding: 2.2rem 1.8rem;
  box-shadow: var(--shadow-float);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  animation: rise-in var(--dur-slow) var(--ease-out) both;
}

.register-header {
  text-align: center;
  margin-bottom: 1.8rem;
}

.logo {
  font-size: 3rem;
  display: block;
  margin-bottom: 0.5rem;
  filter: drop-shadow(0 0 18px var(--primary-glow));
  animation: floaty 5s ease-in-out infinite;
}

.register-header h1 {
  font-size: 1.6rem;
  background: linear-gradient(135deg, #fff 0%, var(--primary) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0.3rem;
  letter-spacing: 0.04em;
}

.register-header p { font-size: 0.85rem; color: var(--text-muted); }

.form-item { margin-bottom: 1rem; }

.form-item label {
  display: block;
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--text-base);
  margin-bottom: 0.4rem;
}

.input-field {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 1rem;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  outline: none;
  transition: border-color var(--dur-fast), box-shadow var(--dur-fast);
}
.input-field::placeholder { color: var(--text-faint); }
.input-field:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.btn-register {
  width: 100%;
  padding: 0.8rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-size: 1.05rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  margin-top: 0.5rem;
  box-shadow: var(--glow-primary);
  transition: transform var(--dur-fast) var(--ease-out), opacity var(--dur-fast);
}
.btn-register:active { transform: scale(0.98); }
.btn-register:disabled { opacity: 0.6; cursor: not-allowed; }

.form-footer {
  text-align: center;
  margin-top: 1rem;
}

.form-footer a {
  font-size: 0.85rem;
  color: var(--primary);
  text-decoration: none;
  transition: opacity var(--dur-fast);
}
.form-footer a:hover { opacity: 0.8; text-decoration: underline; }

.error-msg {
  margin-top: 0.8rem;
  padding: 0.6rem;
  background: rgba(255, 138, 155, 0.12);
  border: 1px solid rgba(255, 138, 155, 0.35);
  border-radius: var(--radius-sm);
  color: var(--danger);
  font-size: 0.85rem;
  text-align: center;
}
</style>
