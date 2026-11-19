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
              <el-dropdown-item @click="logout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main class="main"><router-view /></el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router';
import {
  ArrowDown, ChatDotRound, DataLine, Document, EditPen, MagicStick, OfficeBuilding, Picture, User,
  UserFilled,
} from '@element-plus/icons-vue';
import { getUser } from '../api';

const route = useRoute();
const router = useRouter();
const user = getUser();

function logout() {
  localStorage.removeItem('lp-token');
  localStorage.removeItem('lp-user');
  router.push('/login');
}
</script>
