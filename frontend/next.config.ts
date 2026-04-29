import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    const backendOrigin = process.env.BACKEND_ORIGIN || "http://backend:3000";

    return [
      {
        source: "/api/:path*",
        destination: `${backendOrigin}/api/:path*`,
      },
      {
        source: "/openapi.yaml",
        destination: `${backendOrigin}/openapi.yaml`,
      },
    ];
  },
};

export default nextConfig;
