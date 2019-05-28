#!/usr/bin/env node

'use strict';

const { promisify } = require('util');
const { exec, spawn } = require('child_process');
const { join } = require('path');

const { mkdir } = require('mz/fs');
const { copy } = require('fs-extra');
const yargs = require('yargs');

const execAsync = promisify(exec);
const spawnAsync = promisify(spawn);

const sharedOpts = {
  stdio: 'inherit',
  env: process.env,
};

const DEFAULT_USER = 'ubuntu';

function envIfSet(key, someVar) {
  if (someVar) {
    process.env[key] = someVar;
  }
}

async function connect(options) {
  const { stdout, stderr } = await execAsync('docker-compose port myos 22');
  if (stderr) throw new Error(stderr);
  const port = stdout.split(':')[1].trim();
  const sshArgs = [
    '-Y',
    '-o UserKnownHostsFile=/dev/null',
    '-o StrictHostKeyChecking=no',
    `-p ${port}`,
    `${DEFAULT_USER}@localhost`,
  ];

  return spawn('ssh', sshArgs, sharedOpts);
}

async function create(options) {
  envIfSet('TAG', options.tag);
  envIfSet('NAME', options.instanceName);
  return execAsync('docker-compose up -d');
}

async function remove(options) {
  return execAsync('docker-compose down');
}

async function init({ dir }) {
  const basicOpts = {
    filter: (src, dest) => {
      if (src.includes('tmux_saves')) {
        return false;
      }
      return true;
    },
    overwrite: false,
    errorOnExist: true,
  };
  const copyFiles = ['vim', 'zsh', 'tmux', 'docker-compose.yml'];
  await Promise.all(copyFiles.map((dOrF) =>
    copy(join(__dirname, dOrF),  join(dir, dOrF), basicOpts)));
}

// async function install(options) {}
// async function login(options) {}
// async function commit(options) {}
// async function push(options) {}
// async function pull(options) {}

yargs
  .usage(
`MyOS Interface

Usage: $0 <command> [options]`
  )
  .command('create <instance-name> [options]', 'Create a MyOS instance', (yargs0) => {
    yargs0
      .usage('Usage: $0 create <instance-name> [options]')
      .positional('instanceName', {
        describe: 'MyOS instance name',
        type: 'string',
      })
      .option('tag', {
        describe: 'MyOS image tag to use for instance',
        type: 'string',
      });
  }, create)
  .command('init <dir> [options]', 'Create an initial MyOS scaffold', (yargs0) => {
    yargs0
      .usage('Usage: $0 init <dir> [options]')
      .positional('dir', {
        describe: 'Directory to initialize in',
        type: 'string',
      })
  }, async (options) => {
    await init(options);
  })
  .command('connect [options]', 'Connect to a running MyOS instance', (yargs0) => {
    yargs0
      .usage('Usage: $0 connect [options]');
  }, connect)
  .command('remove [options]', 'Remove running MyOS instance', (yargs0) => {
    yargs0
      .usage('Usage: $0 remove [options]');
  }, remove)
  .command('restart <instance-name> [options]', 'Restart a MyOS instance', (yargs0) => {
    yargs0
      .usage('Usage: $0 restart <instance-name> [options]')
      .positional('instanceName', {
        describe: 'MyOS instance name',
        type: 'string',
      })
  }, async (options) => {
    await remove(options);
    await create(options);
  })
  .demandCommand(1, 'Provide at least 1 command')
  .help('help')
  .alias('help', 'h')
  .strict()
  .wrap(null);

const commands = yargs.getCommandInstance().getCommands();
const currCommand = yargs.argv._[0];
