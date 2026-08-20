import axios from 'axios';

/**
 * API 基地址解析
 * - 默认使用相对路径 '/api'：前端与后端同源部署时（Express 托管 / Vite 代理）自动正确。
 * - 如需跨域（前后端分离部署），可用 api-config.json 或 localStorage('api_base') 覆盖。
 */
function getApiBase() {
  // 1) 显式覆盖（如 api-config.json 在构建时注入 / 运行时设置）
  const dynamic = localStorage.getItem('api_base');
  if (dynamic) return dynamic;

  // 2) 默认同源相对路径，前端与后端共用同一 origin
  return '/api';
}

const request = axios.create({
  baseURL: getApiBase(),
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

request.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  },
  (error) => Promise.reject(error)
);

request.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/#/login';
    }
    return Promise.reject(error);
  }
);

export default request;
