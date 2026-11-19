export function parseDist(raw: unknown): number[] {
  try {
    const arr = typeof raw === 'string' ? JSON.parse(raw) : Array.isArray(raw) ? raw : [];
    return Array.from({ length: 10 }, (_, i) => Math.max(0, Number(arr[i]) || 0));
  } catch {
    return Array(10).fill(0);
  }
}

export function distPercent(dist: number[]): number[] {
  const total = dist.reduce((a, b) => a + b, 0);
  if (!total) return Array(10).fill(0);
  return dist.map(v => Math.round((v / total) * 100));
}

export function parseTags(raw: unknown): string[] {
  try {
    const arr = typeof raw === 'string' ? JSON.parse(raw) : raw;
    return Array.isArray(arr) ? arr.filter((v): v is string => typeof v === 'string') : [];
  } catch {
    return [];
  }
}

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}
