<template>
  <el-card shadow="never">
    <div class="toolbar">
      <span style="font-size: 12px; color: #8a909c">
        平台动态按点赞量与发布时间排序展示；这里按最新发布倒序列出最近 100 条
      </span>
      <div class="spacer" />
      <el-button size="small" @click="load">刷新</el-button>
    </div>

    <el-table :data="list" stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="账号" width="110" />
      <el-table-column label="昵称" width="120">
        <template #default="{ row }">{{ row.user?.nickname || '-' }}</template>
      </el-table-column>
      <el-table-column label="内容" min-width="300">
        <template #default="{ row }">
          <div class="post-text">{{ row.content }}</div>
        </template>
      </el-table-column>
      <el-table-column label="配图" width="190">
        <template #default="{ row }">
          <div v-if="row.images && row.images.length" class="thumbs">
            <el-image
              v-for="(src, i) in row.images"
              :key="src"
              :src="src"
              :preview-src-list="row.images"
              :initial-index="i"
              fit="cover"
              class="thumb"
              preview-teleported
            />
          </div>
          <span v-else style="font-size: 12px; color: #b3b8c2">无</span>
        </template>
      </el-table-column>
      <el-table-column prop="likes" label="赞" width="70" />
      <el-table-column label="发布时间" width="160">
        <template #default="{ row }">{{ fmtTime(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="90" fixed="right">
        <template #default="{ row }">
          <el-button link type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { api, errMsg } from '../api';

const list = ref([]);
const loading = ref(false);

function fmtTime(v) {
  const d = new Date(v);
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/admin/posts');
    list.value = data.posts;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

async function remove(row) {
  try {
    await ElMessageBox.confirm(
      `删除「${row.user?.nickname || row.username}」的这条动态？配图会一并清理。`,
      '删除动态',
      { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' },
    );
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/posts/${row.id}`);
    ElMessage.success('已删除');
    await load();
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(load);
</script>

<style scoped>
.post-text {
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 13px;
  line-height: 1.65;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.thumbs {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}
.thumb {
  width: 38px;
  height: 38px;
  border-radius: 6px;
  overflow: hidden;
}
</style>
