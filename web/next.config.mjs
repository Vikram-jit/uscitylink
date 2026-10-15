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
    // Chat photos come straight from S3 / the API server. Letting the Next server proxy and
    // re-encode them (without sharp) cost CPU/memory and spammed 404s for files moved to S3.
    unoptimized: true,
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