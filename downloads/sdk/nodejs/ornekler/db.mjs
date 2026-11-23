// db.mjs
import { connect } from 'stardataparadise';

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} tanımlanmalı`);
  return value;
}

export function openDatabase({ autocommit = false } = {}) {
  return connect({
    host: process.env.SDP_HOST ?? '127.0.0.1',
    port: Number(process.env.SDP_PORT ?? '7443'),
    tlsName: process.env.SDP_TLS_NAME ?? 'localhost',
    caFile: required('SDP_CA'),
    user: required('SDP_USER'),
    password: required('SDP_PASSWORD'),
    timeoutMs: 15000,
    autocommit,
  });
}
