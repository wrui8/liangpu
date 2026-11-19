<template>
  <div class="login-page">
    <div class="login-card">
      <h1>良扑 · 管理后台</h1>
      <p>内网评分系统 · 请使用管理员账号登录</p>
      <el-form :model="form" label-position="top" @submit.prevent>
        <el-form-item label="用户名">
          <el-input v-model="form.username" placeholder="admin" @keyup.enter="submit" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="form.password" type="password" show-password placeholder="••••••" @keyup.enter="submit" />
        </el-form-item>
        <el-button type="primary" size="large" :loading="loading" @click="submit">登录</el-button>
      </el-form>
      <p style="margin-top: 18px; font-size: 12px; color: #b3b8c2">
        初始账号：admin / admin123（首次登录后建议修改）
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { api, errMsg } from '../api';

const router = useRouter();
const loading = ref(false);
const form = reactive({ username: 'admin', password: '' });

async function submit() {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入用户名和密码');
    return;
  }
  loading.value = true;
  try {
    const { data } = await api.post('/auth/login', form);
    if (data.user.role !== 'admin') {
      ElMessage.error('该账号没有管理权限');
      return;
    }
    localStorage.setItem('lp-token', data.token);
    localStorage.setItem('lp-user', JSON.stringify(data.user));
    router.push('/');
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}
</script>
