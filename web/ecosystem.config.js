// Shared settings: production env, and back off instead of hammering if the app ever crash-loops
const common = {
  script: "node_modules/.bin/next",
  env: { NODE_ENV: "production" },
  exp_backoff_restart_delay: 200,
  max_restarts: 15,
};

module.exports = {
  apps: [
    {
      ...common,
      name: "app-3004",
      cwd: "/var/www/html/uscitylink/web-3004",
      args: "start -p 3004",
    },
    {
      ...common,
      name: "app-3012",
      cwd: "/var/www/html/uscitylink/web-3012",
      args: "start -p 3012",
    },
  ],
};
