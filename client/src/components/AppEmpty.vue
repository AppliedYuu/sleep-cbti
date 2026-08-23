<template>
  <div class="app-empty">
    <svg class="empty-icon" viewBox="0 0 64 64" aria-hidden="true">
      <circle cx="32" cy="32" r="17" fill="none" stroke="var(--border-mid)" stroke-width="2"/>
      <circle cx="40" cy="26" r="15" fill="var(--bg-base)"/>
    </svg>
    <p class="empty-text">{{ text }}</p>
    <slot />
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: '' }, // 已废弃：保留参数兼容旧调用，不再渲染 emoji
  text: { type: String, default: '暂无数据' },
});
</script>

<style scoped>
.app-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1.2rem;
  color: var(--text-muted);
  text-align: center;
}

.empty-icon {
  width: 56px;
  height: 56px;
  margin-bottom: 0.6rem;
}

.empty-text {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}
</style>
