<template>
  <el-card shadow="never">
    <div class="toolbar">
      <el-button type="primary" @click="openCreate">新建团队</el-button>
      <el-input v-model="keyword" placeholder="搜索团队名称" clearable style="width: 220px" />
      <div class="spacer" />
      <span style="font-size: 12px; color: #8a909c">共 {{ filtered.length }} 个团队</span>
    </div>

    <el-table :data="filtered" stripe v-loading="loading">
      <el-table-column label="图标" width="72">
        <template #default="{ row }">
          <span class="icon-box" :style="{ color: row.color1 }" v-html="iconStore.svg(row.iconKey)" />
        </template>
      </el-table-column>
      <el-table-column prop="name" label="团队" min-width="110" />
      <el-table-column label="分类" width="76">
        <template #default="{ row }">
          <el-tag :type="row.category === 'c' ? 'danger' : 'info'" effect="light">{{ row.category }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="评分" width="150">
        <template #default="{ row }">{{ row.score }} 分 · {{ row.count }} 人</template>
      </el-table-column>
      <el-table-column label="员工" width="80">
        <template #default="{ row }">{{ row.employeeCount }} 人</template>
      </el-table-column>
      <el-table-column label="标签" min-width="170">
        <template #default="{ row }">
          <el-tag v-for="t in row.tags" :key="t" size="small" style="margin: 2px 4px 2px 0">{{ t }}</el-tag>
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

  <el-dialog v-model="dialog" :title="form.id ? '编辑团队' : '新建团队'" width="620px" append-to-body>
    <el-form label-width="82px">
      <el-form-item label="团队名称" required>
        <el-input v-model="form.name" maxlength="20" placeholder="例如：闪购" />
      </el-form-item>
      <el-form-item label="分类" required>
        <el-radio-group v-model="form.category">
          <el-radio-button value="c">c</el-radio-button>
          <el-radio-button value="中">中</el-radio-button>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="展示短名">
        <el-input v-model="form.short" maxlength="2" placeholder="留空则取名称首字" style="width: 160px" />
      </el-form-item>
      <el-form-item label="图标" required>
        <IconPicker v-model="form.iconKey" kind="team" :color="form.color1" />
      </el-form-item>
      <el-form-item label="渐变色">
        <el-color-picker v-model="form.color1" />
        <el-color-picker v-model="form.color2" style="margin-left: 10px" />
        <span class="icon-key" style="margin-left: 10px">封面渐变与图标主色</span>
      </el-form-item>
      <el-form-item label="标签">
        <el-select
          v-model="form.tags"
          multiple
          filterable
          allow-create
          default-first-option
          :reserve-keyword="false"
          placeholder="输入后回车添加，最多 6 个"
          style="width: 100%"
        />
      </el-form-item>
      <el-form-item label="评分数据">
        <el-input-number v-model="form.score" :min="0" :max="10" :step="0.1" :precision="1" />
        <span style="margin: 0 8px">分 · 共</span>
        <el-input-number v-model="form.count" :min="0" :step="1" />
        <span style="margin-left: 8px">人评分</span>
      </el-form-item>
      <el-form-item label="排序">
        <el-input-number v-model="form.sort" :min="0" />
        <span class="icon-key" style="margin-left: 10px">数字越小越靠前</span>
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
const keyword = ref('');
const loading = ref(false);
const saving = ref(false);
const dialog = ref(false);
const form = reactive(emptyForm());

function emptyForm() {
  return {
    id: null, name: '', category: '中', short: '', iconKey: '',
    color1: '#8E9BFF', color2: '#5B6CFF', tags: [], score: 0, count: 0, sort: 0,
  };
}

const filtered = computed(() => {
  const kw = keyword.value.trim();
  return kw ? list.value.filter(t => t.name.includes(kw)) : list.value;
});

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/admin/teams');
    list.value = data.teams;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

function openCreate() {
  Object.assign(form, emptyForm(), { sort: list.value.length });
  dialog.value = true;
  iconStore.load();
}

function openEdit(row) {
  Object.assign(form, JSON.parse(JSON.stringify(row)));
  dialog.value = true;
  iconStore.load();
}

async function save() {
  if (!form.name.trim()) return ElMessage.warning('请填写团队名称');
  if (!form.iconKey) return ElMessage.warning('请选择团队图标');
  saving.value = true;
  try {
    const body = {
      name: form.name.trim(), category: form.category, short: form.short || undefined,
      iconKey: form.iconKey, color1: form.color1, color2: form.color2,
      tags: form.tags, score: form.score, count: form.count, sort: form.sort,
    };
    if (form.id) await api.put(`/admin/teams/${form.id}`, body);
    else await api.post('/admin/teams', body);
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
    await ElMessageBox.confirm(`删除「${row.name}」后，其下 ${row.employeeCount} 名员工也会一并删除，确定吗？`, '删除团队', {
      type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消',
    });
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/teams/${row.id}`);
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
