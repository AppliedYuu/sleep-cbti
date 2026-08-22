<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-header">
        <span class="logo">🌙</span>
        <h1>睡益良方</h1>
        <p>CBT-I 数字疗法助手</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-item">
          <label>用户名</label>
          <input
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            class="input-field"
            autocomplete="username"
          />
        </div>

        <div class="form-item">
          <label>密码</label>
          <input
            v-model="password"
            type="password"
            placeholder="请输入密码"
            class="input-field"
            autocomplete="current-password"
          />
        </div>

        <button type="submit" class="btn-login" :disabled="loading">
          {{ loading ? '登录中...' : '登 录' }}
        </button>

        <div class="form-footer">
          <router-link to="/register">还没有账号？立即注册</router-link>
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
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');

async function handleLogin() {
  if (!username.value || !password.value) {
    errorMsg.value = '请输入用户名和密码';
    return;
  }

  loading.value = true;
  errorMsg.value = '';

  try {
    await authStore.doLogin(username.value, password.value);
    router.push('/');
  } catch (err) {
    errorMsg.value = err.response?.data?.message || '登录失败';
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.login-page {
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

.login-card {
  width: 100%;
  max-width: 400px;
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-lg);
  padding: 2.4rem 1.8rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.logo {
  font-size: 3rem;
  display: block;
  margin-bottom: 0.5rem;
  filter: drop-shadow(0 0 18px var(--primary-glow));
  animation: moon-float 5s ease-in-out infinite;
}

@keyframes moon-float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

.login-header h1 {
  font-size: 1.6rem;
  background: linear-gradient(135deg, #fff 0%, var(--primary) 100%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0.3rem;
}

.login-header p { font-size: 0.85rem; color: var(--text-muted); }

.form-item { margin-bottom: 1.2rem; }

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
  transition: border-color 0.2s, box-shadow 0.2s;
}
.input-field::placeholder { color: var(--text-faint); }
.input-field:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.btn-login {
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
  transition: transform 0.18s ease, opacity 0.18s ease;
}
.btn-login:active { transform: scale(0.98); }
.btn-login:disabled { opacity: 0.6; cursor: not-allowed; }

.form-footer {
  text-align: center;
  margin-top: 1rem;
}

.form-footer a {
  font-size: 0.85rem;
  color: var(--primary);
  text-decoration: none;
}
.form-footer a:hover { text-decoration: underline; }

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
