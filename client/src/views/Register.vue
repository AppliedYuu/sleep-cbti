<template>
  <div class="register-page">
    <article class="register-card">
      <div class="card-bar" aria-hidden="true"></div>

      <header class="register-header">
        <h1 class="serif">创建账号</h1>
        <p>加入睡益良方，开始改善睡眠</p>
      </header>

      <form @submit.prevent="handleRegister" class="register-form">
        <div class="form-item">
          <label for="reg-username">用户名</label>
          <input id="reg-username" v-model="username" type="text"
            placeholder="3–50 个字符，字母数字下划线" class="input-field"
            autocomplete="username" />
        </div>
        <div class="form-item">
          <label for="reg-nickname">昵称（选填）</label>
          <input id="reg-nickname" v-model="nickname" type="text"
            placeholder="如何称呼你？" class="input-field" />
        </div>
        <div class="form-item">
          <label for="reg-password">密码</label>
          <input id="reg-password" v-model="password" type="password"
            placeholder="至少 6 个字符" class="input-field"
            autocomplete="new-password" />
        </div>
        <div class="form-item">
          <label for="reg-confirm">确认密码</label>
          <input id="reg-confirm" v-model="confirmPassword" type="password"
            placeholder="再次输入密码" class="input-field"
            autocomplete="new-password" />
        </div>

        <button type="submit" class="btn-register" :disabled="loading">
          {{ loading ? '注册中…' : '注 册' }}
        </button>

        <p class="form-footer">
          <router-link to="/login">已有账号？立即登录</router-link>
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
    errorMsg.value = '密码至少 6 个字符';
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
  padding: 2rem 1.4rem;
}

.register-card {
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

.register-header {
  text-align: center;
  padding: 1.8rem 1.6rem 1rem;
}
.register-header h1 {
  font-size: var(--fs-2xl);
  font-weight: 500;
  color: var(--text-strong);
  margin-bottom: 0.4rem;
  letter-spacing: 0.05em;
}
.register-header p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.register-form {
  padding: 0.4rem 1.6rem 1.6rem;
}
.form-item { margin-bottom: 1rem; }
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

.btn-register {
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
.btn-register:hover { background: var(--primary-strong); }
.btn-register:disabled { opacity: 0.6; cursor: not-allowed; }

.form-footer {
  text-align: center;
  margin-top: 1.1rem;
  font-size: var(--fs-sm);
}
.form-footer a { color: var(--primary); text-decoration: none; }
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