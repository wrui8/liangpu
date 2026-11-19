<template>
  <div v-loading="loading">
    <el-alert
      type="info"
      :closable="false"
      show-icon
      title="客户端启动后会从本页配置实时拉取名称、头像、简介、问候语与快捷指令；保存后无需重新发版，重新打开即可生效。"
      style="margin-bottom: 14px"
    />

    <el-row :gutter="16">
      <el-col :span="14">
        <el-card shadow="never" header="形象与名称">
          <el-form label-width="92px">
            <el-form-item label="头像">
              <div class="avatar-row">
                <div class="avatar-box">
                  <img v-if="avatarSrc" :src="avatarSrc" alt="头像" />
                  <img v-else src="/lion.svg" alt="默认小狮子" />
                </div>
                <div class="avatar-ops">
                  <el-button size="small" :loading="avatarSaving" @click="pickAvatar">上传头像</el-button>
                  <el-button v-if="form.avatarUrl" size="small" text @click="removeAvatar">移除</el-button>
                  <div class="hint">JPG / PNG / WEBP / GIF，≤ 4MB；未上传时使用内置小狮子形象</div>
                </div>
                <el-input v-model="form.avatarEmoji" maxlength="8" style="width: 90px" placeholder="🦁" />
                <input ref="fileInput" type="file" accept="image/*" hidden @change="onFile" />
              </div>
            </el-form-item>
            <el-form-item label="名称" required>
              <el-input v-model="form.name" maxlength="20" show-word-limit style="width: 240px" />
            </el-form-item>
            <el-form-item label="别名">
              <el-select
                v-model="form.aliases"
                multiple
                filterable
                allow-create
                default-first-option
                :reserve-keyword="false"
                placeholder="输入后回车添加，用于评论区 @ 识别"
                style="width: 100%"
              />
            </el-form-item>
            <el-form-item label="启用">
              <el-switch v-model="form.enabled" />
              <span class="hint" style="margin-left: 10px">关闭后客户端不显示悬浮球与 @ 入口</span>
            </el-form-item>
            <el-form-item label="可发评论">
              <el-switch v-model="form.canComment" />
              <span class="hint" style="margin-left: 10px">允许在评论区被 @ 后回应（暂未接入模型，先保存配置）</span>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never" header="介绍与问候" style="margin-top: 14px">
          <el-form label-width="92px">
            <el-form-item label="简介">
              <el-input
                v-model="form.intro"
                type="textarea"
                :rows="3"
                maxlength="500"
                show-word-limit
                placeholder="名片里展示的一句话介绍"
              />
            </el-form-item>
            <el-form-item label="问候语">
              <el-input
                v-model="form.greeting"
                type="textarea"
                :rows="2"
                maxlength="200"
                show-word-limit
                placeholder="打开聊天面板且没有消息时显示"
              />
            </el-form-item>
            <el-form-item label="快捷指令">
              <el-select
                v-model="form.suggestions"
                multiple
                filterable
                allow-create
                default-first-option
                :reserve-keyword="false"
                placeholder="聊天面板空态展示的推荐问题，输入后回车添加"
                style="width: 100%"
              />
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never" header="人设与模型（预留）" style="margin-top: 14px">
          <el-form label-width="92px">
            <el-form-item label="人设">
              <el-input
                v-model="form.persona"
                type="textarea"
                :rows="5"
                maxlength="4000"
                show-word-limit
                placeholder="接入模型后作为系统提示词"
              />
            </el-form-item>
            <el-form-item label="模型">
              <el-input v-model="form.model" maxlength="64" style="width: 260px" placeholder="留空使用网关默认模型" />
            </el-form-item>
            <el-form-item label="温度">
              <el-slider v-model="form.temperature" :min="0" :max="2" :step="0.1" show-input style="width: 420px" />
            </el-form-item>
          </el-form>
        </el-card>

        <div class="save-bar">
          <el-button type="primary" :loading="saving" @click="save">保存配置</el-button>
          <el-button :disabled="saving" @click="load">重置</el-button>
        </div>
      </el-col>

      <el-col :span="10">
        <el-card shadow="never" header="预览">
          <div class="preview">
            <div class="orb">
              <img v-if="avatarSrc" :src="avatarSrc" alt="" class="round" />
              <img v-else src="/lion.svg" alt="小狮子" />
            </div>
            <div class="panel">
              <div class="panel-name">{{ form.name || '未命名助手' }}</div>
              <div class="panel-greeting">
                {{ form.greeting || '这里显示问候语' }}
              </div>
              <div v-if="form.suggestions.length" class="chips">
                <span v-for="s in form.suggestions" :key="s" class="chip">{{ s }}</span>
              </div>
              <div v-else class="hint">暂无快捷指令</div>
            </div>
          </div>
          <el-descriptions :column="1" size="small" style="margin-top: 16px">
            <el-descriptions-item label="状态">
              <el-tag :type="form.enabled ? 'success' : 'info'" size="small">
                {{ form.enabled ? '已启用' : '已停用' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="评论回应">
              {{ form.canComment ? '允许' : '不允许' }}
            </el-descriptions-item>
            <el-descriptions-item label="全部别名">
              {{ [form.name, ...form.aliases].filter(Boolean).join(' / ') || '—' }}
            </el-descriptions-item>
            <el-descriptions-item label="最后更新">
              {{ fmtTime(updatedAt) }}
            </el-descriptions-item>
          </el-descriptions>
          <div class="hint" style="margin-top: 8px">
            提示：聊天回复目前仍是客户端内置演示脚本；接入内网模型网关后会使用这里的人设与知识库。
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { ElMessage } from 'element-plus';
import { api, errMsg } from '../api';

const loading = ref(false);
const saving = ref(false);
const avatarSaving = ref(false);
const updatedAt = ref(null);
const fileInput = ref(null);

const form = reactive(emptyForm());

function emptyForm() {
  return {
    name: '小狮',
    aliases: [],
    avatarUrl: null,
    avatarEmoji: '🦁',
    intro: '',
    greeting: '',
    suggestions: [],
    persona: '',
    enabled: true,
    canComment: true,
    model: '',
    temperature: 0.4,
  };
}

const avatarSrc = computed(() => form.avatarUrl || '');

function fmtTime(v) {
  if (!v) return '—';
  const d = new Date(v);
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/admin/agent');
    const a = data.agent;
    Object.assign(form, {
      name: a.name,
      aliases: a.aliases || [],
      avatarUrl: a.avatarUrl || null,
      avatarEmoji: a.avatarEmoji || '🦁',
      intro: a.intro || '',
      greeting: a.greeting || '',
      suggestions: a.suggestions || [],
      persona: a.persona || '',
      enabled: a.enabled !== false,
      canComment: a.canComment !== false,
      model: a.model || '',
      temperature: typeof a.temperature === 'number' ? a.temperature : 0.4,
    });
    updatedAt.value = a.updatedAt;
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    loading.value = false;
  }
}

async function save() {
  if (!form.name.trim()) return ElMessage.warning('请填写名称');
  saving.value = true;
  try {
    const { data } = await api.put('/admin/agent', {
      name: form.name.trim(),
      aliases: form.aliases.map(s => String(s).trim()).filter(Boolean),
      avatarEmoji: form.avatarEmoji,
      intro: form.intro,
      greeting: form.greeting,
      suggestions: form.suggestions.map(s => String(s).trim()).filter(Boolean),
      persona: form.persona,
      enabled: form.enabled,
      canComment: form.canComment,
      model: form.model.trim() || null,
      temperature: form.temperature,
    });
    updatedAt.value = data.agent.updatedAt;
    ElMessage.success('已保存，App 下次拉取配置即生效');
  } catch (e) {
    ElMessage.error(errMsg(e));
  } finally {
    saving.value = false;
  }
}

function pickAvatar() {
  fileInput.value?.click();
}

function onFile(e) {
  const file = e.target.files && e.target.files[0];
  e.target.value = '';
  if (!file) return;
  if (file.size > 4 * 1024 * 1024) return ElMessage.warning('图片不能超过 4MB');
  const reader = new FileReader();
  reader.onload = async () => {
    avatarSaving.value = true;
    try {
      const { data } = await api.post('/admin/agent/avatar', { dataUrl: String(reader.result) });
      form.avatarUrl = data.agent.avatarUrl;
      updatedAt.value = data.agent.updatedAt;
      ElMessage.success('头像已更新');
    } catch (err) {
      ElMessage.error(errMsg(err));
    } finally {
      avatarSaving.value = false;
    }
  };
  reader.readAsDataURL(file);
}

async function removeAvatar() {
  try {
    const { data } = await api.delete('/admin/agent/avatar');
    form.avatarUrl = data.agent.avatarUrl;
    updatedAt.value = data.agent.updatedAt;
    ElMessage.success('已移除头像');
  } catch (e) {
    ElMessage.error(errMsg(e));
  }
}

onMounted(load);
</script>

<style scoped>
.avatar-row {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
}
.avatar-box {
  width: 64px;
  height: 64px;
  border-radius: 18px;
  background: #fff8e1;
  border: 1px solid #f0e2b6;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  overflow: hidden;
  flex: none;
}
.avatar-box img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.avatar-ops {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  max-width: 300px;
}
.hint {
  font-size: 12px;
  color: #8a909c;
  line-height: 1.5;
}
.save-bar {
  margin-top: 18px;
  display: flex;
  gap: 10px;
}
.preview {
  display: flex;
  gap: 18px;
  align-items: flex-start;
}
.orb {
  /* 不加圆形底板/描边，也不加「AI」角标：形象独立展示 */
  position: relative;
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 30px;
  flex: none;
}
.orb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
.orb img.round {
  border-radius: 50%;
  object-fit: cover;
}
.panel {
  flex: 1;
  border: 1px solid #ecedf2;
  border-radius: 14px;
  padding: 12px 14px;
  background: #fafbfe;
}
.panel-name {
  font-weight: 700;
  color: #1f2430;
}
.panel-greeting {
  margin-top: 6px;
  font-size: 13px;
  color: #4a5060;
  line-height: 1.6;
}
.chips {
  margin-top: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.chip {
  font-size: 12px;
  color: #5b6cff;
  background: #eef1ff;
  border-radius: 999px;
  padding: 3px 10px;
}
</style>
