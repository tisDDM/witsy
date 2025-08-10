import http from 'node:http';
import { URL } from 'node:url';

let server: http.Server | null = null;

/**
 * Start minimal local HTTP server for simple triggers.
 * - GET /trigger?cmd=<string> -> calls handler(cmd) and returns { success: boolean, cmd }
 * - GET /health -> { ok: true }
 * Binds to 127.0.0.1 only. No auth. Minimal by design.
 */
export const start = (port: number, handler: (cmd: string) => Promise<boolean> | boolean): boolean => {
  if (server) {
    return true;
  }
  try {
    server = http.createServer(async (req, res) => {
      try {
        const host = req.headers.host || `127.0.0.1:${port}`;
        const url = new URL(req.url || '/', `http://${host}`);
        res.setHeader('Content-Type', 'application/json');

        if (req.method === 'GET' && url.pathname === '/trigger') {
          const cmd = url.searchParams.get('cmd') || '';
          let ok = false;
          if (cmd) {
            try {
              ok = await Promise.resolve(handler(cmd));
            } catch {
              ok = false;
            }
          }
          res.statusCode = ok ? 200 : 400;
          res.end(JSON.stringify({ success: ok, cmd }));
          return;
        }

        if (req.method === 'GET' && url.pathname === '/health') {
          res.statusCode = 200;
          res.end(JSON.stringify({ ok: true }));
          return;
        }

        res.statusCode = 404;
        res.end(JSON.stringify({ success: false, error: 'NOT_FOUND' }));
      } catch {
        res.statusCode = 500;
        res.end(JSON.stringify({ success: false, error: 'SERVER_ERROR' }));
      }
    }).listen(port, '127.0.0.1');

    server.on('error', (err: any) => {
      console.warn('HTTP server error:', err?.message || err);
    });

    console.info(`HTTP trigger server listening on http://127.0.0.1:${port}`);
    return true;
  } catch (e) {
    console.warn('Failed to start HTTP server:', e);
    server = null;
    return false;
  }
};

export const stop = (): void => {
  if (server) {
    try {
      const s = server;
      server = null;
      s.close();
      console.info('HTTP trigger server stopped');
    } catch {
      /* empty */
    }
  }
};
