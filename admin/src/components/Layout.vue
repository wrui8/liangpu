<template>
  <el-container class="layout">
    <el-aside width="208px" class="aside">
      <div class="brand"><span class="mark">良</span>良扑 · 管理后台</div>
      <el-menu :default-active="route.path" router>
        <el-menu-item index="/dashboard"><el-icon><DataLine /></el-icon>概览</el-menu-item>
        <el-menu-item index="/teams"><el-icon><OfficeBuilding /></el-icon>团队管理</el-menu-item>
        <el-menu-item index="/employees"><el-icon><User /></el-icon>员工管理</el-menu-item>
        <el-menu-item index="/needs"><el-icon><Document /></el-icon>需求管理</el-menu-item>
        <el-menu-item index="/comments"><el-icon><ChatDotRound /></el-icon>评论管理</el-menu-item>
        <el-menu-item index="/posts"><el-icon><EditPen /></el-icon>动态管理</el-menu-item>
        <el-menu-item index="/icons"><el-icon><Picture /></el-icon>图标库</el-menu-item>
        <el-menu-item index="/users"><el-icon><UserFilled /></el-icon>用户列表</el-menu-item>
        <el-menu-item index="/agent"><el-icon><MagicStick /></el-icon>Agent 助手</el-menu-item>
      </el-menu>
      <div style="padding: 14px 18px; font-size: 11px; color: #b3b8c2">良扑 v0.1 · 内网部署</div>
    </el-aside>
    <el-container>
      <el-header class="header">
        <div>管理端的修改会即时同步到 App</div>
        <el-dropdown>
          <span class="user">{{ user.nickname || user.username }} <el-icon><ArrowDown /></el-icon></span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="pwdOpen = true">修改密码</el-dropdown-item>
              <el-dropdown-item divided @click="logout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main class="main"><router-view /></el-main>
    </el-container>

    <el-dialog v-model="pwdOpen" title="修改密码" width="380px" :close-on-click-modal="false">
      <el-form label-width="86px" @submit.prevent>
        <el-form-item label="原密码">
          <el-input v-model="pwd.old" type="password" show-password placeholder="当前登录密码" />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="pwd.next" type="password" show-password placeholder="至少 6 位" />
        </el-form-item>
        <el-form-item label="确认新密码">
          <el-input v-model="pwd.confirm" type="password" show-password placeholder="再输入一次" @keyup.enter="savePwd" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pwdOpen = false">取消</el-button>
        <el-button type="primary" :loading="pwdSaving" @click="savePwd">保存</el-button>
      </template>
    </el-dialog>
  </el-container>
</template>

<script setup>
import { reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import {
  ArrowDown, ChatDotRound, DataLine, Document, EditPen, MagicStick, OfficeBuilding, Picture, User,
  UserFilled,
} from '@element-plus/icons-vue';
import { api, errMsg, getUser } from '../api';

const route = useRoute();
const router = useRouter();
const user = getUser();

function logout() {
  localStorage.removeItem('lp-token');
  localStorage.removeItem('lp-user');
  router.push('/login');
}

const pwdOpen = ref(false);
const pwdSaving = ref(false);
const pwd = reactive({ old: '', next: '', confirm: '' });

async function savePwd() {
  if (!pwd.old) return ElMessage.warning('请输入原密码');
  if (pwd.next.length < 6) return ElMessage.warning('新密码至少 6 位');
  if (pwd.next !== pwd.confirm) return ElMessage.warning('两次输入的新密码不一致');
  pwdSaving.value = true;
  try {
    await api.post('/auth/password', { oldPassword: pwd.old, newPassword: pwd.next });
    ElMessage.success('密码已修改');
    pwdOpen.value = false;
    pwd.old = pwd.next = pwd.confirm = '';
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    pwdSaving.value = false;
  }
}
</script>
