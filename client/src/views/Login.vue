<template>
  <div class="login-page">
    <article class="login-card">
      <div class="card-bar" aria-hidden="true"></div>

      <header class="login-header">
        <h1 class="serif">睡益良方</h1>
        <p>CBT-I 数字疗法助手</p>
      </header>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-item">
          <label for="login-username">用户名</label>
          <input
            id="login-username"
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            class="input-field"
            autocomplete="username"
          />
        </div>

        <div class="form-item">
          <label for="login-password">密码</label>
          <input
            id="login-password"
            v-model="password"
            type="password"
            placeholder="请输入密码"
            class="input-field"
            autocomplete="current-password"
          />
        </div>

        <button type="submit" class="btn-login" :disabled="loading">
          {{ loading ? '登录中…' : '登 录' }}
        </button>

        <p class="form-footer">
          <router-link to="/register">还没有账号？立即注册</router-link>
        </p>
      </form>

      <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
    </article>
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
  padding: 2rem 1.4rem;
}

.login-card {
  width: 100%;
  max-width: 380px;
  background: var(--bg-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  position: relative;
  overflow: hidden;
}
.card-bar {
  height: 3px;
  background: var(--primary);
}

.login-header {
  text-align: center;
  padding: 2rem 1.6rem 1.4rem;
}
.login-header h1 {
  font-size: var(--fs-2xl);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.4rem;
  letter-spacing: 0.05em;
}
.login-header p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.login-form {
  padding: 0.4rem 1.6rem 1.8rem;
}
.form-item { margin-bottom: 1.2rem; }
.form-item label {
  display: block;
  font-size: var(--fs-sm);
  color: var(--text-base);
  margin-bottom: 0.4rem;
  font-weight: 500;
}

.input-field {
  width: 100%;
  padding: 0.65rem 0.9rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-sunken);
  outline: none;
  transition: border-color var(--dur) var(--ease),
              background var(--dur) var(--ease);
}
.input-field::placeholder { color: var(--text-faint); }
.input-field:focus {
  border-color: var(--primary);
  background: var(--bg-surface);
}

.btn-login {
  width: 100%;
  padding: 0.75rem;
  background: var(--primary);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-sm);
  font-size: var(--fs-md);
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  margin-top: 0.4rem;
  transition: background var(--dur) var(--ease);
}
.btn-login:hover { background: var(--primary-strong); }
.btn-login:disabled { opacity: 0.6; cursor: not-allowed; }

.form-footer {
  text-align: center;
  margin-top: 1.1rem;
  font-size: var(--fs-sm);
}
.form-footer a {
  color: var(--primary);
  text-decoration: none;
}
.form-footer a:hover { text-decoration: underline; }

.error-msg {
  margin: 0 1.6rem 1.6rem;
  padding: 0.6rem 0.8rem;
  background: var(--accent-clay-weak);
  border-left: 3px solid var(--accent-clay);
  color: var(--text-strong);
  font-size: var(--fs-sm);
}
</style>