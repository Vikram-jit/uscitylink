/** @type {import('next').NextConfig} */
const config = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  env: {
    API_URL: process.env.NEXT_ENV == 'development' ? 'http://localhost:4300/api/v1/' : 'http://52.8.75.98:4300/api/v1/',
    SOCKET_URL: process.env.NEXT_ENV == 'development' ? 'http://localhost:4000' : 'http://52.8.75.98:4000',
  },
};

export default config;
