<template>
  <el-card shadow="never">
    <div class="toolbar">
      <el-button type="primary" @click="openCreate">新建员工</el-button>
      <el-select v-model="teamFilter" clearable placeholder="按团队筛选" style="width: 180px">
        <el-option v-for="t in teams" :key="t.id" :label="t.name" :value="t.id" />
      </el-select>
      <el-input v-model="keyword" placeholder="搜索姓名或职位" clearable style="width: 200px" />
      <div class="spacer" />
      <span style="font-size: 12px; color: #8a909c">共 {{ filtered.length }} 名员工</span>
    </div>

    <el-table :data="filtered" stripe v-loading="loading">
      <el-table-column label="头像" width="72">
        <template #default="{ row }">
          <span v-if="row.iconKey" class="icon-box" v-html="iconStore.svg(row.iconKey)" />
          <el-avatar v-else :size="34" :style="avatarStyle(row)">{{ row.name.slice(0, 1) }}</el-avatar>
        </template>
      </el-table-column>
      <el-table-column prop="name" label="姓名" width="130" />
      <el-table-column prop="title" label="职位" width="140" />
      <el-table-column prop="teamName" label="所属团队" width="120" />
      <el-table-column label="评分" width="150">
        <template #default="{ row }">{{ row.score }} 分 · {{ row.count }} 人</template>
      </el-table-column>
      <el-table-column label="图标来源" width="120">
        <template #default="{ row }">
          <el-tag v-if="row.iconKey" size="small" type="success">管理端指定</el-tag>
          <el-tag v-else size="small" type="info">首字头像</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="sort" label="排序" width="70" />
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
          <el-button link type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-card>

  <el-dialog v-model="dialog" :title="form.id ? '编辑员工' : '新建员工'" width="600px" append-to-body>
    <el-form label-width="82px">
      <el-form-item label="所属团队" required>
        <el-select v-model="form.teamId" placeholder="选择团队" style="width: 100%">
          <el-option v-for="t in teams" :key="t.id" :label="t.name" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="姓名" required>
        <el-input v-model="form.name" maxlength="20" />
      </el-form-item>
      <el-form-item label="职位" required>
        <el-input v-model="form.title" maxlength="20" placeholder="例如：前端负责人" />
      </el-form-item>
      <el-form-item label="员工图标">
        <div>
          <IconPicker v-model="form.iconKey" kind="employee" :color="form.color1" />
          <el-button v-if="form.iconKey" link type="info" size="small" @click="form.iconKey = ''">
            清除，改用首字头像
          </el-button>
          <div class="icon-key" style="margin-top: 4px">员工图标只能由管理端设置，用户在 App 内不可修改</div>
        </div>
      </el-form-item>
      <el-form-item label="头像配色">
        <el-color-picker v-model="form.color1" />
        <el-color-picker v-model="form.color2" style="margin-left: 10px" />
      </el-form-item>
      <el-form-item label="评分数据">
        <el-input-number v-model="form.score" :min="0" :max="10" :step="0.1" :precision="1" />
        <span style="margin: 0 8px">分 · 共</span>
        <el-input-number v-model="form.count" :min="0" :step="1" />
        <span style="margin-left: 8px">人评分</span>
      </el-form-item>
      <el-form-item label="排序">
        <el-input-number v-model="form.sort" :min="0" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialog = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="save">保存</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import IconPicker from '../components/IconPicker.vue';
import { api, errMsg } from '../api';
import { iconStore } from '../icons';

const list = ref([]);
const teams = ref([]);
const teamFilter = ref(null);
const keyword = ref('');
const loading = ref(false);
const saving = ref(false);
const dialog = ref(false);
const form = reactive(emptyForm());

function emptyForm() {
  return {
    id: null, teamId: null, name: '', title: '', iconKey: '',
    color1: '#8E9BFF', color2: '#5B6CFF', score: 0, count: 0, sort: 0,
  };
}

function avatarStyle(row) {
  return { background: `linear-gradient(135deg, ${row.color1}, ${row.color2})`, fontWeight: 700 };
}

const filtered = computed(() => {
  const kw = keyword.value.trim();
  return list.value.filter(e => {
    if (teamFilter.value && e.teamId !== teamFilter.value) return false;
    if (kw && !e.name.includes(kw) && !e.title.includes(kw)) return false;
    return true;
  });
});

async function load() {
  loading.value = true;
  try {
    const [{ data: emp }, { data: tm }] = await Promise.all([
      api.get('/admin/employees'),
      api.get('/admin/teams'),
    ]);
    list.value = emp.employees;
    teams.value = tm.teams;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

function openCreate() {
  Object.assign(form, emptyForm(), {
    teamId: teamFilter.value || (teams.value[0] && teams.value[0].id) || null,
  });
  dialog.value = true;
  iconStore.load();
}

function openEdit(row) {
  Object.assign(form, JSON.parse(JSON.stringify(row)), { iconKey: row.iconKey || '' });
  dialog.value = true;
  iconStore.load();
}

async function save() {
  if (!form.teamId) return ElMessage.warning('请选择所属团队');
  if (!form.name.trim()) return ElMessage.warning('请填写姓名');
  if (!form.title.trim()) return ElMessage.warning('请填写职位');
  saving.value = true;
  try {
    const body = {
      teamId: form.teamId, name: form.name.trim(), title: form.title.trim(),
      iconKey: form.iconKey || null, color1: form.color1, color2: form.color2,
      score: form.score, count: form.count, sort: form.sort,
    };
    if (form.id) await api.put(`/admin/employees/${form.id}`, body);
    else await api.post('/admin/employees', body);
    ElMessage.success('已保存');
    dialog.value = false;
    await load();
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function remove(row) {
  try {
    await ElMessageBox.confirm(`确定删除员工「${row.name}」吗？`, '删除员工', {
      type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消',
    });
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/employees/${row.id}`);
    ElMessage.success('已删除');
    await load();
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(() => {
  iconStore.load();
  load();
});
</script>
