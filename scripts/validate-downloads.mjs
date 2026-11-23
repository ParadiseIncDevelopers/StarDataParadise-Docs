import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';

const require = createRequire(import.meta.url);
const root = path.resolve(import.meta.dirname, '..');
const {baseUrl} = require('../docusaurus.config.js');
const staticRoot = path.join(root, 'static');
const files = fs.readdirSync(path.join(root, 'docs'), {recursive: true});
let count = 0;

for (const name of files.filter((name) => /\.mdx?$/.test(name))) {
  const markdown = fs.readFileSync(path.join(root, 'docs', name), 'utf8');
  for (const match of markdown.matchAll(/\]\(pathname:\/\/(\/[^\s)]+)\)/g)) {
    const url = new URL(match[1], 'https://docs.invalid');
    if (!url.pathname.startsWith(baseUrl) || url.pathname.endsWith('/')) {
      throw new Error(`Invalid download URL in ${name}: ${match[1]}`);
    }
    const relativePath = decodeURIComponent(url.pathname.slice(baseUrl.length));
    const target = path.resolve(staticRoot, relativePath);
    if (path.relative(staticRoot, target).startsWith('..') || !fs.existsSync(target) || !fs.statSync(target).isFile()) {
      throw new Error(`Missing static download in ${name}: ${relativePath}`);
    }
    count += 1;
  }
}
console.log(`Validated ${count} direct download links.`);
