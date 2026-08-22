<template>
  <button
    v-if="!to"
    :class="['app-btn', `app-btn--${variant}`, { 'app-btn--block': block, 'app-btn--ghost': ghost }]"
    :disabled="disabled"
    @click="$emit('click', $event)"
  >
    <slot />
  </button>
  <router-link
    v-else
    :to="to"
    :class="['app-btn', `app-btn--${variant}`, { 'app-btn--block': block, 'app-btn--ghost': ghost }]"
  >
    <slot />
  </router-link>
</template>

<script setup>
defineProps({
  variant: { type: String, default: 'primary' }, // primary | mint | amber | rose | cyan | purple
  block: { type: Boolean, default: false },
  ghost: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  to: { type: [String, Object], default: '' },
});
defineEmits(['click']);
</script>

<style scoped>
.app-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  padding: 0.7rem 1.3rem;
  border: 1px solid transparent;
  border-radius: var(--radius-pill);
  font-size: var(--fs-md);
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  text-decoration: none;
  color: var(--text-on-primary);
  background: var(--primary);
  transition: transform 0.18s ease, box-shadow 0.18s ease, opacity 0.18s ease;
  user-select: none;
}

.app-btn:active { transform: scale(0.97); }
.app-btn:disabled { opacity: 0.45; cursor: not-allowed; }

.app-btn--block { width: 100%; }

/* 变体 */
.app-btn--primary { background: var(--primary); color: var(--text-on-primary); box-shadow: var(--glow-primary); }
.app-btn--mint { background: var(--accent-mint); color: #052e2b; }
.app-btn--amber { background: var(--accent-amber); color: #3a2a00; }
.app-btn--rose { background: var(--accent-rose); color: #3a0011; }
.app-btn--cyan { background: var(--accent-cyan); color: #04293a; }
.app-btn--purple { background: var(--accent-purple); color: #2a0a4a; }

/* 幽灵（描边）按钮 */
.app-btn--ghost {
  background: transparent;
  border-color: var(--border-mid);
  color: var(--text-base);
  box-shadow: none;
}
.app-btn--ghost.app-btn--primary { border-color: var(--primary); color: var(--primary); }
.app-btn--ghost.app-btn--mint { border-color: var(--accent-mint); color: var(--accent-mint); }
.app-btn--ghost.app-btn--amber { border-color: var(--accent-amber); color: var(--accent-amber); }
.app-btn--ghost.app-btn--rose { border-color: var(--accent-rose); color: var(--accent-rose); }
.app-btn--ghost.app-btn--cyan { border-color: var(--accent-cyan); color: var(--accent-cyan); }
.app-btn--ghost.app-btn--purple { border-color: var(--accent-purple); color: var(--accent-purple); }
</style>
