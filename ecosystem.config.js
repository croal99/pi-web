// pm2 process config for pi-web (production, served on port 80).
// Start from the deploy directory:  pm2 start ecosystem.config.js
// Persist:                         pm2 save   (then  pm2 startup  for auto-start on boot)
module.exports = {
  apps: [
    {
      name: "pi-web",
      cwd: "/home/kaka/byg-web",         // absolute deploy directory (edit if your deploy dir differs)
      script: "npm",
      args: "start",                    // package.json "start" = next start -H 0.0.0.0 -p 80
      interpreter: "none",              // exec the npm CLI directly (needs `node` on PATH, e.g. via nvm)
      instances: 1,
      exec_mode: "fork",                // single fork; avoid two processes binding the same port 80
      env: {
        NODE_ENV: "production"
      },
      error_file: "./pm2-error.log",
      out_file: "./pm2-out.log",
      merge_logs: true,
      autorestart: true,
      max_memory_restart: "1G",
      watch: false
    }
  ]
};

// NOTE: port 80 is privileged. Either run `pm2 start` as root, or let a non-root
// user bind 80 once with:  sudo setcap cap_net_bind_service=+ep "$(readlink -f "$(which node)")"
