<template>
  <div class="icon-field">
    <span class="icon-box" :style="{ color: color || '#5b6cff' }" v-html="currentSvg" />
    <span class="icon-key">{{ modelValue || '未选择图标' }}</span>
    <el-button size="small" @click="open = true">选择图标</el-button>
  </div>

  <el-dialog v-model="open" :title="`选择${kindLabel}`" width="580px" append-to-body>
    <div v-if="icons.length" class="icon-grid">
      <button
        v-for="ic in icons"
        :key="ic.key"
        type="button"
        class="icon-cell"
        :class="{ on: ic.key === modelValue }"
        @click="pick(ic.key)"
      >
        <span v-html="ic.svg" />
        <small>{{ ic.name }}</small>
      </button>
    </div>
    <el-empty v-else description="图标池为空，请先到「图标库」添加" />
    <template #footer>
      <el-button @click="open = false">关闭</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { iconStore } from '../icons';

const props = defineProps({
  modelValue: { type: String, default: '' },
  kind: { type: String, default: 'team' },
  color: { type: String, default: '' },
});
const emit = defineEmits(['update:modelValue']);

const open = ref(false);
const icons = computed(() => iconStore.byKind(props.kind));
const currentSvg = computed(() => iconStore.svg(props.modelValue));
const kindLabel = computed(() => ({ team: '团队图标', employee: '员工图标', user: '用户头像' }[props.kind] || '图标'));

onMounted(() => iconStore.load());

function pick(key) {
  emit('update:modelValue', key);
  open.value = false;
}
</script>
