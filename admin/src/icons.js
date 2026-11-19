import { reactive } from 'vue';
import { api } from './api';

export const iconStore = reactive({
  list: [],
  loading: false,
  async load(force = false) {
    if (this.loading) return;
    if (this.list.length && !force) return;
    this.loading = true;
    try {
      const { data } = await api.get('/icons');
      this.list = data.icons;
    } finally {
      this.loading = false;
    }
  },
  byKind(kind) {
    return this.list.filter(i => i.kind === kind);
  },
  svg(key) {
    const icon = this.list.find(i => i.key === key);
    return icon ? icon.svg : '';
  },
  has(key) {
    return this.list.some(i => i.key === key);
  },
});
