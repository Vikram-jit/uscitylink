/** @type {import('next').NextConfig} */
const config = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  env: {
    API_URL: process.env.NEXT_ENV == 'development' ? 'http://localhost:4300/api/v1/' : 'http://52.8.75.98:4300/api/v1/',
    SOCKET_URL: process.env.NEXT_ENV == 'development' ? 'http://localhost:4000' : 'http://52.8.75.98:4000',
  },
  images: {
    domains: [
      'ciity-sms.s3.us-west-1.amazonaws.com', // Add this line to allow images from the AWS S3 domain
      // You can add other allowed image domains here if necessary
    ],
  },
  async headers() {
    return [
      {
        source: '/(.*)', // applies to all routes, adjust if needed
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store', // Prevents browser caching
          },
        ],
      },
    ];
  },
};

export default config;
