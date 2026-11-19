<template>
  <el-card shadow="never">
    <el-tabs v-model="kind">
      <el-tab-pane label="团队图标" name="team" />
      <el-tab-pane label="员工图标" name="employee" />
      <el-tab-pane label="用户头像池" name="user" />
    </el-tabs>

    <div class="toolbar">
      <el-button type="primary" @click="openCreate">新增图标</el-button>
      <span style="font-size: 12px; color: #8a909c">{{ kindHint }}</span>
      <div class="spacer" />
      <el-button size="small" @click="reload">刷新</el-button>
    </div>

    <div v-if="icons.length" class="icon-grid">
      <div v-for="ic in icons" :key="ic.key" class="icon-cell" style="cursor: default">
        <span v-html="ic.svg" />
        <small>{{ ic.name }}</small>
        <small style="color: #c3c7cf">{{ ic.key }}</small>
        <div>
          <el-button link type="primary" size="small" @click="openEdit(ic)">编辑</el-button>
          <el-button link type="danger" size="small" @click="remove(ic)">删除</el-button>
        </div>
      </div>
    </div>
    <el-empty v-else description="该分类下还没有图标" />
  </el-card>

  <el-dialog v-model="dialog" :title="form.id ? '编辑图标' : '新增图标'" width="640px" append-to-body>
    <el-form label-width="76px">
      <el-form-item label="所属分类" required>
        <el-select v-model="form.kind" :disabled="!!form.id" style="width: 180px">
          <el-option label="团队图标" value="team" />
          <el-option label="员工图标" value="employee" />
          <el-option label="用户头像" value="user" />
        </el-select>
      </el-form-item>
      <el-form-item label="key" required>
        <el-input v-model="form.key" :disabled="!!form.id" maxlength="32" placeholder="小写字母/数字/_，例如 team_rocket" />
      </el-form-item>
      <el-form-item label="名称" required>
        <el-input v-model="form.name" maxlength="20" />
      </el-form-item>
      <el-form-item label="SVG 代码" required>
        <el-input v-model="form.svg" type="textarea" :rows="7" placeholder="<svg viewBox=&quot;0 0 24 24&quot; ...>...</svg>" />
      </el-form-item>
      <el-form-item label="预览">
        <span class="icon-box big" v-html="form.svg" />
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
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { api, errMsg } from '../api';
import { iconStore } from '../icons';

const kind = ref('team');
const saving = ref(false);
const dialog = ref(false);
const form = reactive(emptyForm());

function emptyForm() {
  return { id: null, kind: 'team', key: '', name: '', svg: '', sort: 99 };
}

const icons = computed(() => iconStore.byKind(kind.value));
const kindHint = computed(
  () =>
    ({
      team: '团队封面图标：在团队管理里选择，用户端只读',
      employee: '员工图标：由管理端分配给员工，用户不可修改',
      user: '用户头像池：App 用户可从中自行更换头像',
    }[kind.value]),
);

watch(kind, () => iconStore.load());

function reload() {
  iconStore.load(true);
}

function openCreate() {
  Object.assign(form, emptyForm(), { kind: kind.value, sort: icons.value.length });
  dialog.value = true;
}

function openEdit(ic) {
  Object.assign(form, { id: ic.id, kind: ic.kind, key: ic.key, name: ic.name, svg: ic.svg, sort: ic.sort });
  dialog.value = true;
}

async function save() {
  if (!form.id && !/^[a-z0-9_-]{2,32}$/.test(form.key)) {
    return ElMessage.warning('key 只能使用小写字母、数字、下划线、短横线');
  }
  if (!form.name.trim()) return ElMessage.warning('请填写名称');
  if (!/<svg[\s>]/i.test(form.svg)) return ElMessage.warning('SVG 代码无效');
  saving.value = true;
  try {
    if (form.id) {
      await api.put(`/admin/icons/${form.id}`, { name: form.name, svg: form.svg, sort: form.sort });
    } else {
      await api.post('/admin/icons', {
        key: form.key, kind: form.kind, name: form.name, svg: form.svg, sort: form.sort,
      });
    }
    ElMessage.success('已保存');
    dialog.value = false;
    iconStore.load(true);
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function remove(ic) {
  try {
    await ElMessageBox.confirm(`删除图标「${ic.name}」？正在使用中的图标无法删除。`, '删除图标', {
      type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消',
    });
  } catch {
    return;
  }
  try {
    await api.delete(`/admin/icons/${ic.id}`);
    ElMessage.success('已删除');
    iconStore.load(true);
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(() => iconStore.load());
</script>
