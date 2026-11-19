<template>
  <div>
    <div class="stat-grid">
      <div class="stat-card"><div class="num">{{ stats.teams }}</div><div class="label">团队</div></div>
      <div class="stat-card"><div class="num">{{ stats.employees }}</div><div class="label">员工</div></div>
      <div class="stat-card"><div class="num">{{ stats.needs }}</div><div class="label">需求</div></div>
      <div class="stat-card"><div class="num">{{ stats.ratings }}</div><div class="label">评分记录</div></div>
      <div class="stat-card"><div class="num">{{ stats.comments }}</div><div class="label">短评 / 回复</div></div>
      <div class="stat-card"><div class="num">{{ stats.posts }}</div><div class="label">用户动态</div></div>
      <div class="stat-card"><div class="num">{{ stats.users }}</div><div class="label">注册用户</div></div>
    </div>

    <el-card shadow="never" style="margin-top: 16px">
      <h3 style="margin: 0 0 10px">使用说明</h3>
      <ul style="margin: 0; padding-left: 18px; line-height: 2; font-size: 13px; color: #5b6170">
        <li>团队、员工、需求均可在左侧菜单增删改，保存后 App 端刷新即可看到。</li>
        <li>团队与员工的图标从「图标库」中选择；员工图标只能由管理端设置，用户无法修改。</li>
        <li>用户头像由「图标库」中的用户头像池提供，用户在 App 内可自行更换。</li>
        <li>评分、短评与回复由用户在 App 端提交，本后台负责审核与删除。</li>
        <li>「动态管理」可查看并删除用户发布的动态，删除时配图一并清理。</li>
      </ul>
    </el-card>
  </div>
</template>

<script setup>
import { onMounted, reactive } from 'vue';
import { ElMessage } from 'element-plus';
import { api, errMsg } from '../api';

const stats = reactive({ teams: 0, employees: 0, needs: 0, ratings: 0, comments: 0, posts: 0, users: 0 });

onMounted(async () => {
  try {
    const { data } = await api.get('/admin/stats');
    Object.assign(stats, data);
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
});
</script>
