<template>
  <div class="app-empty">
    <div class="empty-icon">{{ icon }}</div>
    <p class="empty-text">{{ text }}</p>
    <slot />
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: '🌙' },
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
  font-size: 3rem;
  margin-bottom: 0.6rem;
  opacity: 0.8;
  filter: drop-shadow(0 0 16px var(--primary-glow));
}

.empty-text {
  font-size: var(--fs-sm);
  color: var(--text-muted);
}
</style>
