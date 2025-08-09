import http from 'node:http';
import { URL } from 'node:url';

let server: http.Server | null = null;

/**
 * Start minimal local HTTP server for simple triggers.
 * - GET /trigger?cmd=<string> -> calls handler(cmd) and returns { success: boolean, cmd }
 * - GET /health -> { ok: true }
 * Binds to 127.0.0.1 only. No auth. Minimal by design.
 */
export const start = (
  port: number,
  handler: (cmd: string, params?: { text?: string; action?: string }) => Promise<boolean> | boolean
): boolean => {
  if (server) {
    return true;
  }
  try {
    server = http.createServer((req, res) => {
      const host = req.headers.host || `127.0.0.1:${port}`;
      const url = new URL(req.url || '/', `http://${host}`);
      res.setHeader('Content-Type', 'application/json');

      const respond = (status: number, obj: any) => {
        res.statusCode = status;
        res.end(JSON.stringify(obj));
      };

      // Health endpoint
      if (req.method === 'GET' && url.pathname === '/health') {
        return respond(200, { ok: true });
      }

      if (url.pathname === '/trigger' && (req.method === 'GET' || req.method === 'POST')) {

        const finalize = async (cmd: string, params: { text?: string; action?: string }) => {
          let ok = false;
          if (cmd) {
            try {
              ok = await Promise.resolve(handler(cmd, params));
            } catch {
              ok = false;
            }
          }
          return respond(ok ? 200 : 400, { success: ok, cmd });
        };

        if (req.method === 'GET') {
          const cmd = url.searchParams.get('cmd') || '';
          const text = url.searchParams.get('text') || undefined;
          const action = url.searchParams.get('action') || undefined;
          return finalize(cmd, { text, action });
        }

        // POST JSON payload
        let body = '';
        req.on('data', (chunk) => {
          body += chunk;
          if (body.length > 1e6) {
            req.socket.destroy();
          }
        });
        req.on('end', () => {
          try {
            const json = body ? JSON.parse(body) : {};
            const cmd = (json?.cmd ?? '').toString();
            const text = typeof json?.text === 'string' ? json.text : undefined;
            const action = typeof json?.action === 'string' ? json.action : undefined;
            finalize(cmd, { text, action });
          } catch {
            respond(400, { success: false, error: 'INVALID_JSON' });
          }
        });
        return;
      }

      // Not found
      respond(404, { success: false, error: 'NOT_FOUND' });
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
