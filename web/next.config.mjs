/** @type {import('next').NextConfig} */
const config = {
  eslint: {
    ignoreDuringBuilds: true,
  },

  env: {
    API_URL:
      process.env.NEXT_ENV == "development"
        ? "http://localhost:4300/api/v1/"
        : "http://52.8.75.98:4300/api/v1/",
    SOCKET_URL:
      process.env.NEXT_ENV == "development"
        ? "http://localhost:4300"
        : "http://52.8.75.98:4300",
  },

  images: {
    remotePatterns: [
      {
        protocol: "http",
        hostname: "**",
      },
      {
        protocol: "https",
        hostname: "**",
      },
    ],
  },

  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          {
            key: "Cache-Control",
            value: "no-store",
          },
        ],
      },
    ];
  },
};

export default config;