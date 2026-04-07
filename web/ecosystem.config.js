module.exports = {
  apps: [
    {
      name: "app-3004",
      cwd: "/var/www/html/uscitylink/web-3004",
      script: "node_modules/.bin/next",
      args: "start -p 3004",
    },
    {
      name: "app-3012",
      cwd: "/var/www/html/uscitylink/web-3012",
      script: "node_modules/.bin/next",
      args: "start -p 3012",
    },
  ],
};