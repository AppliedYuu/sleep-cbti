<template>
  <div id="app-container">
    <router-view v-slot="{ Component }">
      <transition name="route" mode="out-in">
        <component :is="Component" />
      </transition>
    </router-view>
  </div>
</template>

<script setup>
// 睡益良方 - 主应用入口
</script>

<style>
/* 全局基础样式已迁移至 styles/theme.css（静谧夜空主题） */
#app-container {
  display: flex;
  flex-direction: column;
}
</style>
