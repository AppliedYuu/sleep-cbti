<template>
  <header class="app-navbar">
    <button v-if="back" class="nav-btn nav-back" @click="onBack" aria-label="返回">
      <span class="nav-arrow">‹</span>
      <span v-if="backText" class="nav-back-text">{{ backText }}</span>
    </button>
    <span v-else class="nav-btn nav-placeholder"></span>

    <h1 class="nav-title">{{ title }}</h1>

    <div class="nav-btn nav-right">
      <slot name="right" />
    </div>
  </header>
</template>

<script setup>
import { useRouter } from 'vue-router';

const props = defineProps({
  title: { type: String, default: '' },
  back: { type: Boolean, default: true },
  backText: { type: String, default: '' },
});

const router = useRouter();
function onBack() {
  if (window.history.length > 1) router.back();
  else router.push('/');
}
</script>

<style scoped>
.app-navbar {
  position: sticky;
  top: var(--safe-top);
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  padding: 0.7rem 1rem;
  background: linear-gradient(180deg, rgba(15, 20, 38, 0.92), rgba(15, 20, 38, 0.55));
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border-bottom: 1px solid var(--border-soft);
}

.nav-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.2rem;
  min-width: 56px;
  border: none;
  background: transparent;
  color: var(--primary);
  font-size: var(--fs-sm);
  font-family: inherit;
  cursor: pointer;
}

.nav-placeholder { pointer-events: none; }

.nav-back { justify-content: flex-start; padding: 0; }
.nav-arrow { font-size: 1.6rem; line-height: 1; margin-top: -2px; }
.nav-back-text { font-size: var(--fs-sm); }

.nav-title {
  flex: 1;
  text-align: center;
  font-size: var(--fs-lg);
  font-weight: 600;
  color: var(--text-strong);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.nav-right { justify-content: flex-end; color: var(--text-muted); }
</style>
