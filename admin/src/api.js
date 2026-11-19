import axios from 'axios';

export const api = axios.create({ baseURL: '/api' });

api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('lp-token');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

api.interceptors.response.use(
  res => res,
  err => {
    if (err.response && err.response.status === 401) {
      localStorage.removeItem('lp-token');
      localStorage.removeItem('lp-user');
      if (!location.hash.includes('/login')) location.hash = '#/login';
    }
    return Promise.reject(err);
  },
);

export function errMsg(err) {
  return (err.response && err.response.data && err.response.data.error) || err.message || '请求失败';
}

export const getUser = () => {
  try {
    return JSON.parse(localStorage.getItem('lp-user') || '{}');
  } catch {
    return {};
  }
};
