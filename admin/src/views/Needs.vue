<template>
  <el-card shadow="never">
    <div class="toolbar">
      <el-button type="primary" @click="openCreate">新建需求</el-button>
      <el-select v-model="statusFilter" clearable placeholder="按状态筛选" style="width: 150px">
        <el-option v-for="s in STATUSES" :key="s" :label="s" :value="s" />
      </el-select>
      <el-input v-model="keyword" placeholder="搜索标题" clearable style="width: 200px" />
      <div class="spacer" />
      <span style="font-size: 12px; color: #8a909c">共 {{ filtered.length }} 条需求</span>
    </div>

    <el-table :data="filtered" stripe v-loading="loading">
      <el-table-column label="需求" min-width="280">
        <template #default="{ row }">
          <div class="need-cell">
            <el-image
              v-if="row.images && row.images.length"
              :src="row.images[0]"
              :preview-src-list="row.images"
              fit="cover"
              class="need-thumb"
              preview-teleported
            />
            <div class="need-main">
              <div class="need-title" :title="row.title">{{ row.title }}</div>
              <div class="need-meta">
                <el-tag v-if="row.proposerId" size="small" type="success" effect="plain">
                  用户发布
                </el-tag>
                <span v-if="row.proposerName" class="proposer">{{ row.proposerName }}</span>
                <span v-if="row.images && row.images.length" class="img-count">
                  {{ row.images.length }} 张配图
                </span>
              </div>
            </div>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="96">
        <template #default="{ row }">
          <el-tag :type="statusType(row.status)" effect="light">{{ row.status }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="归属团队" width="110">
        <template #default="{ row }">{{ row.teamName || '—' }}</template>
      </el-table-column>
      <el-table-column prop="category" label="分类" width="110" />
      <el-table-column label="评分" width="140">
        <template #default="{ row }">{{ row.score }} 分 · {{ row.count }} 人</template>
      </el-table-column>
      <el-table-column label="相关员工" min-width="170">
        <template #default="{ row }">
          <el-tag
            v-for="m in row.membersDetail"
            :key="m.employeeId"
            size="small"
            style="margin: 2px 4px 2px 0"
            :type="m.role === '负责' ? 'danger' : m.role === '提议' ? 'warning' : 'info'"
          >
            {{ m.name }}·{{ m.role }}
          </el-tag>
          <span v-if="!row.membersDetail || !row.membersDetail.length" style="color: #b3b8c2">—</span>
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

  <el-dialog v-model="dialog" :title="form.id ? '编辑需求' : '新建需求'" width="680px" append-to-body>
    <el-form label-width="82px">
      <el-form-item label="标题" required>
        <el-input v-model="form.title" maxlength="60" />
      </el-form-item>
      <el-form-item label="描述" required>
        <el-input v-model="form.desc" type="textarea" :rows="4" maxlength="1000" show-word-limit />
      </el-form-item>
      <el-form-item label="分类" required>
        <el-input v-model="form.category" maxlength="16" style="width: 200px" placeholder="例如：办公效率" />
      </el-form-item>
      <el-form-item label="状态" required>
        <el-radio-group v-model="form.status">
          <el-radio-button v-for="s in STATUSES" :key="s" :value="s">{{ s }}</el-radio-button>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="归属团队">
        <el-select v-model="form.teamId" clearable placeholder="可不选" style="width: 220px">
          <el-option v-for="t in teams" :key="t.id" :label="t.name" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="提议人">
        <el-input v-model="form.proposerName" maxlength="20" style="width: 220px" />
      </el-form-item>
      <el-form-item label="标签">
        <el-select
          v-model="form.tags"
          multiple
          filterable
          allow-create
          default-first-option
          :reserve-keyword="false"
          placeholder="输入后回车添加"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="评分数据">
        <el-input-number v-model="form.score" :min="0" :max="10" :step="0.1" :precision="1" />
        <span style="margin: 0 8px">分 · 共</span>
        <el-input-number v-model="form.count" :min="0" :step="1" />
        <span style="margin-left: 8px">人参与</span>
      </el-form-item>
      <el-form-item label="排序">
        <el-input-number v-model="form.sort" :min="0" />
      </el-form-item>
      <el-form-item label="相关员工">
        <div style="width: 100%">
          <div v-for="(m, i) in form.members" :key="i" class="member-row">
            <el-select v-model="m.employeeId" filterable placeholder="选择员工" style="flex: 1">
              <el-option
                v-for="e in employees"
                :key="e.id"
                :label="`${e.teamName} · ${e.name}（${e.title}）`"
                :value="e.id"
              />
            </el-select>
            <el-select v-model="m.role" style="width: 100px">
              <el-option v-for="r in ROLES" :key="r" :label="r" :value="r" />
            </el-select>
            <el-button link type="danger" @click="form.members.splice(i, 1)">移除</el-button>
          </div>
          <el-button size="small" @click="form.members.push({ employeeId: null, role: '参与' })">+ 添加成员</el-button>
        </div>
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
import { api, errMsg } from '../api';

const STATUSES = ['评审中', '进行中', '已完成'];
const ROLES = ['提议', '负责', '参与'];

const list = ref([]);
const teams = ref([]);
const employees = ref([]);
const statusFilter = ref('');
const keyword = ref('');
const loading = ref(false);
const saving = ref(false);
const dialog = ref(false);
const form = reactive(emptyForm());

function emptyForm() {
  return {
    id: null, title: '', desc: '', category: '', status: '评审中', teamId: null,
    proposerName: '', tags: [], score: 0, count: 0, sort: 0, members: [],
  };
}

function statusType(s) {
  if (s === '已完成') return 'success';
  if (s === '进行中') return 'warning';
  return 'danger';
}

const filtered = computed(() => {
  const kw = keyword.value.trim();
  return list.value.filter(n => {
    if (statusFilter.value && n.status !== statusFilter.value) return false;
    if (kw && !n.title.includes(kw)) return false;
    return true;
  });
});

async function load() {
  loading.value = true;
  try {
    const [{ data: needs }, { data: tm }, { data: emp }] = await Promise.all([
      api.get('/admin/needs'),
      api.get('/admin/teams'),
      api.get('/admin/employees'),
    ]);
    list.value = needs.needs;
    teams.value = tm.teams;
    employees.value = emp.employees;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

function openCreate() {
  Object.assign(form, emptyForm(), { sort: list.value.length });
  dialog.value = true;
}

function openEdit(row) {
  Object.assign(form, {
    id: row.id,
    title: row.title,
    desc: row.desc,
    category: row.category,
    status: row.status,
    teamId: row.teamId,
    proposerName: row.proposerName || '',
    tags: [...row.tags],
    score: row.score,
    count: row.count,
    sort: row.sort,
    members: (row.membersDetail || []).map(m => ({ employeeId: m.employeeId, role: m.role })),
  });
  dialog.value = true;
}

async function save() {
  if (!form.title.trim()) return ElMessage.warning('请填写需求标题');
  if (!form.desc.trim()) return ElMessage.warning('请填写需求描述');
  if (!form.category.trim()) return ElMessage.warning('请填写分类');
  const members = form.members.filter(m => m.employeeId);
  saving.value = true;
  try {
    const body = {
      title: form.title.trim(),
      desc: form.desc.trim(),
      category: form.category.trim(),
      status: form.status,
      teamId: form.teamId || null,
      proposerName: form.proposerName.trim() || null,
      tags: form.tags,
      score: form.score,
      count: form.count,
      sort: form.sort,
      members,
    };
    if (form.id) await api.put(`/admin/needs/${form.id}`, body);
    else await api.post('/admin/needs', body);
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
    await ElMessageBox.confirm(`确定删除需求「${row.title}」吗？`, '删除需求', {
      type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消',
    });
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/needs/${row.id}`);
    ElMessage.success('已删除');
    await load();
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(load);
</script>

<style scoped>
.need-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}
.need-thumb {
  width: 44px;
  height: 44px;
  flex: none;
  border-radius: 8px;
  border: 1px solid #ecedf2;
}
.need-main {
  min-width: 0;
}
.need-title {
  font-weight: 600;
  color: #1f2430;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.need-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 3px;
  min-height: 20px;
  font-size: 12px;
  color: #8a909c;
}
.proposer::before {
  content: '提议人：';
  color: #b3b8c2;
}
.img-count {
  color: #b3b8c2;
}
</style>
