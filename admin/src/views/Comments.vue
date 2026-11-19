<template>
  <el-card shadow="never">
    <div class="toolbar">
      <el-select v-model="targetType" clearable placeholder="按目标筛选" style="width: 160px">
        <el-option label="团队" value="team" />
        <el-option label="员工" value="employee" />
        <el-option label="需求" value="need" />
      </el-select>
      <div class="spacer" />
      <span style="font-size: 12px; color: #8a909c">最近 100 条</span>
      <el-button size="small" @click="load">刷新</el-button>
    </div>

    <el-table :data="filtered" stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="账号" width="110" />
      <el-table-column prop="user" label="昵称" width="120" />
      <el-table-column label="类型" width="80">
        <template #default="{ row }">
          <el-tag size="small" :type="row.parentId ? 'warning' : 'success'">
            {{ row.parentId ? '回复' : '主评' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="对象" width="130">
        <template #default="{ row }">
          <el-tag size="small" type="info">{{ typeLabel(row.targetType) }} #{{ row.targetId }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="评分" width="70">
        <template #default="{ row }">{{ row.parentId ? '—' : row.score }}</template>
      </el-table-column>
      <el-table-column label="内容" min-width="260" show-overflow-tooltip>
        <template #default="{ row }">
          <span v-if="row.parentId" style="color: #8a909c">
            回复 {{ row.replyToName ? '@' + row.replyToName : '#' + row.parentId }}：
          </span>{{ row.text }}
        </template>
      </el-table-column>
      <el-table-column prop="likes" label="赞" width="70" />
      <el-table-column label="时间" width="160">
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
import { computed, onMounted, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { api, errMsg } from '../api';

const list = ref([]);
const targetType = ref('');
const loading = ref(false);

const filtered = computed(() =>
  targetType.value ? list.value.filter(c => c.targetType === targetType.value) : list.value,
);

function typeLabel(t) {
  return { team: '团队', employee: '员工', need: '需求' }[t] || t;
}

function fmtTime(v) {
  const d = new Date(v);
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/admin/comments');
    list.value = data.comments;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

async function remove(row) {
  try {
    const kind = row.parentId ? '回复' : '短评';
    await ElMessageBox.confirm(
      `删除「${row.user}」的这条${kind}？其下的回复会一并删除。`,
      '删除评论',
      { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' },
    );
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/comments/${row.id}`);
    ElMessage.success('已删除');
    await load();
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(load);
</script>
