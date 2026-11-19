<template>
  <el-card shadow="never">
    <div class="toolbar">
      <span style="font-size: 12px; color: #8a909c">用户头像由「用户头像池」提供，用户可在 App 内自行更换</span>
      <div class="spacer" />
      <el-button size="small" @click="load">刷新</el-button>
    </div>

    <el-table :data="list" stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="账号" width="140" />
      <el-table-column prop="nickname" label="昵称" width="140" />
      <el-table-column label="角色" width="100">
        <template #default="{ row }">
          <el-tag :type="row.role === 'admin' ? 'danger' : 'info'" size="small">
            {{ row.role === 'admin' ? '管理员' : '普通用户' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="头像" width="90">
        <template #default="{ row }">
          <span class="icon-box plain" v-html="iconStore.svg(row.avatarIcon)" />
        </template>
      </el-table-column>
      <el-table-column prop="avatarIcon" label="头像 key" width="110" />
      <el-table-column label="注册时间" min-width="170">
        <template #default="{ row }">{{ fmtTime(row.createdAt) }}</template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { api, errMsg } from '../api';
import { iconStore } from '../icons';

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
    const { data } = await api.get('/admin/users');
    list.value = data.users;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  iconStore.load();
  load();
});
</script>
