import { execFileSync } from 'node:child_process';

const container = `schoolpro-upgrade-${process.pid}`;
const run = (args, options = {}) =>
  execFileSync('docker', args, { stdio: 'inherit', ...options });

try {
  run([
    'run', '-d', '--name', container,
    '-e', 'POSTGRES_PASSWORD=test',
    '-e', 'POSTGRES_DB=schoolpro_upgrade_test',
    '-v', `${process.cwd()}:/work`,
    '-w', '/work',
    'postgres:16-alpine',
  ]);

  let ready = false;
  for (let i = 0; i < 30; i++) {
    try {
      execFileSync('docker', [
        'exec', container, 'pg_isready',
        '-U', 'postgres', '-d', 'schoolpro_upgrade_test',
      ], { stdio: 'ignore' });
      ready = true;
      break;
    } catch {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  if (!ready) throw new Error('Disposable PostgreSQL did not become ready');

  run([
    'exec', '-w', '/work', container,
    'psql', '-v', 'ON_ERROR_STOP=1',
    '-U', 'postgres', '-d', 'schoolpro_upgrade_test',
    '-f', 'scripts/test-schoolpro-annual-upgrade-postgres.integration.sql',
  ]);

  console.log('PASS: annual upgrade PostgreSQL integration fixture');
} finally {
  try {
    run(['rm', '-f', container], { stdio: 'ignore' });
  } catch {}
}
