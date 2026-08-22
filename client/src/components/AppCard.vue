<template>
  <component
    :is="tag"
    :to="tag === 'router-link' ? to : undefined"
    :class="['app-card', { 'app-card--glass': glass, 'app-card--glow': glow, 'app-card--accent': accent }]"
    :style="accent ? { borderLeftColor: accentColor } : null"
  >
    <slot />
  </component>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  tag: { type: String, default: 'div' }, // div | router-link
  to: { type: [String, Object], default: '' },
  glass: { type: Boolean, default: true },
  glow: { type: Boolean, default: false }, // 主色柔光
  accent: { type: String, default: '' },   // primary | mint | amber | rose | cyan | purple
});

const accentColor = computed(() => {
  const map = {
    primary: 'var(--primary)',
    mint: 'var(--accent-mint)',
    amber: 'var(--accent-amber)',
    rose: 'var(--accent-rose)',
    cyan: 'var(--accent-cyan)',
    purple: 'var(--accent-purple)',
  };
  return map[props.accent] || 'var(--primary)';
});
</script>

<style scoped>
.app-card {
  background: var(--bg-elevated);
  border: 1px solid var(--border-soft);
  border-left: 3px solid transparent;
  border-radius: var(--radius-md);
  padding: var(--space-3);
  box-shadow: var(--shadow-card);
  color: var(--text-base);
  text-decoration: none;
  transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
}

.app-card--glass {
  background: var(--bg-glass);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.app-card--glow {
  border-color: var(--border-glow);
  box-shadow: var(--shadow-card), var(--glow-primary);
}

.app-card--accent {
  border-left-width: 4px;
}

a.app-card:hover,
.app-card.is-clickable:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-card), var(--glow-primary);
}
</style>
