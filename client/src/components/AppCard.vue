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
  transition: box-shadow 0.22s ease, border-color 0.22s ease;
}

/* glass 属性已废弃（保留兼容旧调用），映射为实体纸卡 */
.app-card--glass {
  background: var(--bg-surface);
}

/* glow 属性已废弃，仅保留主色描边语义 */
.app-card--glow {
  border-color: var(--border-glow);
}

.app-card--accent {
  border-left-width: 4px;
}

a.app-card:hover,
.app-card.is-clickable:hover {
  box-shadow: var(--shadow-float);
  border-color: var(--border-mid);
}
</style>
