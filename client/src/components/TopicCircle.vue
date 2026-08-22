<template>
  <div class="topic-circle">
    <!-- 发布表单 -->
    <div class="post-form">
      <div class="form-header">
        <span class="form-icon">✍️</span>
        <span>分享你的 CBT-I 实践心得</span>
      </div>
      <textarea
        v-model="newPost"
        placeholder="例如：今天尝试了刺激控制，睡不着时起床看了会儿书，20分钟后再回床上，居然很快就睡着了...…"
        rows="4"
        maxlength="500"
        class="post-textarea"
      ></textarea>
      <div class="form-footer">
        <span class="char-count">{{ newPost.length }}/500</span>
        <button
          class="btn-post"
          :disabled="!newPost.trim() || posting"
          @click="doPost"
        >{{ posting ? '发布中...' : '📤 发布' }}</button>
      </div>
    </div>

    <!-- 帖子列表 -->
    <div v-if="posts.length" class="post-list">
      <div v-for="post in posts" :key="post.id" class="post-card">
        <div class="post-header">
          <span class="post-avatar">😴</span>
          <span class="post-user">{{ post.display_name }}</span>
          <span class="post-time">{{ post.timeAgo }}</span>
        </div>
        <p class="post-content">{{ post.content }}</p>
        <div class="post-footer">
          <button
            class="btn-like"
            :class="{ liked: post.likedByMe }"
            @click="doLike(post.id)"
          >
            {{ post.likedByMe ? '❤️' : '🤍' }} {{ post.likes || 0 }}
          </button>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <span class="empty-icon">📖</span>
      <p>还没有人分享，来做第一个吧！</p>
      <p class="empty-hint">分享你的CBT-I实践心得、小胜利或感悟</p>
    </div>

    <!-- 加载更多 -->
    <div v-if="hasMore" class="load-more">
      <button class="btn-load-more" @click="loadMore">加载更多</button>
    </div>

    <div v-if="showToast" class="toast" :class="toastType">{{ toastMsg }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getPostList, createPost, likePost } from '@/api/community';

const props = defineProps({ userId: String });

const posts = ref([]);
const newPost = ref('');
const posting = ref(false);
const page = ref(1);
const hasMore = ref(false);
const toastMsg = ref('');
const toastType = ref('');
const showToast = ref(false);

function showMsg(msg, type = '') {
  toastMsg.value = msg;
  toastType.value = type;
  showToast.value = true;
  setTimeout(() => { showToast.value = false; }, 3000);
}

async function loadPosts() {
  try {
    const res = await getPostList(page.value);
    if (page.value === 1) {
      posts.value = res.data.posts || [];
    } else {
      posts.value.push(...(res.data.posts || []));
    }
    hasMore.value = res.data.hasMore;
  } catch {}
}

async function loadMore() {
  page.value++;
  await loadPosts();
}

async function doPost() {
  if (!newPost.value.trim()) return;
  posting.value = true;
  try {
    const res = await createPost(props.userId, newPost.value.trim());
    newPost.value = '';
    page.value = 1;
    await loadPosts();
    showMsg(res.message || '发布成功！');
  } catch (err) {
    const msg = err.response?.data?.message || '发布失败';
    const risk = err.response?.data?.risk;
    showMsg(msg, risk === 'high' ? 'error' : risk === 'medium' ? 'warn' : '');
  } finally {
    posting.value = false;
  }
}

async function doLike(postId) {
  try {
    const res = await likePost(postId);
    const post = posts.value.find(p => p.id === postId);
    if (!post) return;
    // 后端返回 liked 状态，据此增/减点赞数并切换高亮（支持点赞/取消）
    if (res.liked) {
      post.likedByMe = true;
      post.likes = (post.likes || 0) + 1;
    } else {
      post.likedByMe = false;
      post.likes = Math.max((post.likes || 0) - 1, 0);
    }
  } catch {}
}

onMounted(() => loadPosts());
</script>

<style scoped>
.topic-circle { min-height: 200px; position: relative; }

/* 发布表单 —— 玻璃卡片 */
.post-form {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  margin-bottom: 1rem;
}

.form-header {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-strong);
  margin-bottom: 0.6rem;
}

.form-icon { font-size: 1.1rem; }

/* 输入框 —— 软背景 + 月光聚焦 */
.post-textarea {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-sm);
  font-size: 0.88rem;
  outline: none;
  resize: vertical;
  font-family: inherit;
  color: var(--text-strong);
  background: var(--bg-soft);
  transition: border-color var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out);
}

.post-textarea::placeholder { color: var(--text-faint); }

.post-textarea:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--primary-weak);
}

.form-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 0.5rem;
}

.char-count { font-size: 0.72rem; color: var(--text-faint); }

/* 发布按钮 —— 玫瑰强调 + 暖光 */
.btn-post {
  padding: 0.5rem 1.5rem;
  background: var(--accent-rose);
  color: var(--text-on-primary);
  border: none;
  border-radius: var(--radius-pill);
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 0 18px rgba(255, 155, 179, 0.35);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              filter var(--dur-base) var(--ease-out);
}

.btn-post:hover:not(:disabled) {
  filter: brightness(1.05);
  box-shadow: 0 0 24px rgba(255, 155, 179, 0.5);
}

.btn-post:active:not(:disabled) { transform: scale(0.98); }

.btn-post:disabled { opacity: 0.45; cursor: not-allowed; }

/* 帖子列表 */
.post-list {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

/* 帖子卡片 —— 玻璃 + 悬停抬升 + 玫瑰柔光 */
.post-card {
  background: var(--bg-glass);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-md);
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  transition: transform var(--dur-base) var(--ease-out),
              box-shadow var(--dur-base) var(--ease-out),
              border-color var(--dur-base) var(--ease-out);
}

.post-card:hover {
  transform: translateY(-3px);
  border-color: var(--border-glow);
  box-shadow: var(--shadow-float), 0 0 22px rgba(255, 155, 179, 0.18);
}

.post-header {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-bottom: 0.6rem;
}

/* 头像 —— 圆形 + 玫瑰柔光 */
.post-avatar {
  font-size: 1.2rem;
  width: 2rem;
  height: 2rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: var(--bg-soft);
  filter: drop-shadow(0 0 8px rgba(255, 155, 179, 0.4));
}

.post-user {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--accent-rose);
}

.post-time {
  font-size: 0.7rem;
  color: var(--text-muted);
  margin-left: auto;
}

.post-content {
  font-size: 0.88rem;
  color: var(--text-base);
  line-height: 1.7;
  margin-bottom: 0.6rem;
  white-space: pre-wrap;
}

.post-footer { display: flex; justify-content: flex-end; }

/* 点赞按钮 —— 玫瑰浅底胶囊 */
.btn-like {
  display: flex;
  align-items: center;
  gap: 0.2rem;
  padding: 0.3rem 0.8rem;
  border: 1px solid var(--border-soft);
  border-radius: var(--radius-pill);
  background: rgba(255, 155, 179, 0.12);
  font-size: 0.78rem;
  cursor: pointer;
  color: var(--accent-rose);
  transition: all var(--dur-base) var(--ease-out);
}

.btn-like:hover {
  border-color: var(--accent-rose);
  background: rgba(255, 155, 179, 0.2);
}

.btn-like.liked {
  border-color: var(--accent-rose);
  background: rgba(255, 155, 179, 0.24);
  color: var(--accent-rose);
  box-shadow: 0 0 14px rgba(255, 155, 179, 0.3);
}

/* 空状态 */
.empty-state {
  text-align: center;
  padding: 3rem 1rem;
}

.empty-icon { font-size: 3rem; display: block; margin-bottom: 0.5rem; }

.empty-state p { color: var(--text-muted); font-size: 0.9rem; }
.empty-hint { font-size: 0.78rem !important; margin-top: 0.3rem; color: var(--text-faint); }

.load-more { text-align: center; margin-top: 1rem; }

.btn-load-more {
  padding: 0.5rem 1.5rem;
  border: 1px solid var(--border-mid);
  border-radius: var(--radius-pill);
  background: var(--bg-soft);
  color: var(--text-muted);
  font-size: 0.85rem;
  cursor: pointer;
  transition: all var(--dur-base) var(--ease-out);
}

.btn-load-more:hover {
  color: var(--text-strong);
  border-color: var(--border-glow);
  background: var(--bg-hover);
}

/* 提示 toast —— 语义色 */
.toast {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 0.6rem 1.2rem;
  border-radius: var(--radius-pill);
  font-size: 0.85rem;
  font-weight: 600;
  z-index: 100;
  animation: fadeInOut 3s ease;
  background: var(--success);
  color: var(--text-on-primary);
  border: 1px solid var(--border-soft);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.toast.warn { background: var(--warning); color: var(--text-on-primary); }
.toast.error { background: var(--danger); color: var(--text-on-primary); }

@keyframes fadeInOut {
  0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
  20% { opacity: 1; transform: translateX(-50%) translateY(0); }
  80% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
