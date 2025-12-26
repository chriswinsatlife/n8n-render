# n8n Background Worker on Render Docker Command History

## Note
- These Docker commands are for a different repo (`n8n-background-worker`)
- The current repo (`n8n-render`), which is the main n8n service, has an empty Docker command in Render
- The n8n worker needs to receive `worker --concurrency=10` arguments somehow. Without dockerCommand, it would just start as a regular n8n instance, not a worker.

## URL
[https://dashboard.render.com/worker/srv-d117ruqdbo4c739o7bhg/settings]

## Docker Command
Optionally override your Dockerfile's CMD and ENTRYPOINT instructions with a different command to start your service.

### Docker Command - Last Known Working Command
`/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`

### Docker Command - Current 
`/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`

—

## Previously Tried Docker Commands
- `/bin/sh -c 'export PATH=/usr/local/bin:$PATH && exec n8n worker --concurrency=10'`
- `n8n worker --concurrency=10`
- `worker --concurrency=10`
- `tini -- /docker-entrypoint.sh n8n worker --concurrency=10`
- `/usr/local/bin/node /usr/local/lib/node_modules/n8n/packages/cli/bin/n8n.js worker --concurrency=10`
- `` (blank)
- `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- `/bin/sh /worker-entrypoint.sh`
- `/worker-entrypoint.sh`
- `worker-entrypoint.sh`
