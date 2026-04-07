module.exports = {
  apps: [
    {
      name: "app-3004",
      script: "node_modules/.bin/next",
      args: "start -p 3004",
      cwd: "/var/www/html/uscitylink/web",
       env: {
        NODE_ENV: "production",
        NEXT_PUBLIC_API_URL: "http://52.9.12.189:4300//api/v1",
        NEXT_PUBLIC_SOCKET_URL: "http://52.9.12.189:4300",
      },
    },
    {
      name: "app-3012",
      script: "node_modules/.bin/next",
      args: "start -p 3012",
      cwd: "/var/www/html/uscitylink/web",
       env: {
        NODE_ENV: "production",
        NEXT_PUBLIC_API_URL: "https://chatbox-server.truckcrave.com/api/v1",
        NEXT_PUBLIC_SOCKET_URL: "https://chatbox-server.truckcrave.com",
      },
    },
  ],
};