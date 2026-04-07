/** @type {import('next').NextConfig} */
const config = {
  eslint: {
    ignoreDuringBuilds: true,
  },

  env: {
    API_URL:
      process.env.NEXT_ENV == "development"
        ? "http://localhost:4300/api/v1/"
        : process.env.NEXT_PUBLIC_API_URL,
    SOCKET_URL:
      process.env.NEXT_ENV == "development"
        ? "http://localhost:4300"
        : process.env.NEXT_PUBLIC_SOCKET_URL,
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