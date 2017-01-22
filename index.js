#!/usr/bin/env node

const fs = require('fs');
const cp = require('child_process');
const path = require('path');

const {Duplex} = require('stream');
const uuidV4 = require('uuid/v4');

const delimiter = '\n';

const add = path.resolve(__dirname, 'scripts', 'add-user.sh');
const install = path.resolve(__dirname, 'scripts', 'install-root.sh');
const initialize = path.resolve(__dirname, 'scripts', 'initialize-scheme.sh');
const start = path.resolve(__dirname, 'scripts', 'start-scheme.sh');
const jail = path.resolve(__dirname, 'jail');
const encoding = 'utf8';

const cwd = {cwd: __dirname};

const superOptions = {
    allowHalfOpen: false,
    decodeStrings: false,
    encoding
};

const identity = i => i;
const types = {
    0: 'value',
    1: 'error',
    2: 'canvas'
};

function mapJSON(data) {
    try {
        return JSON.parse(data);
    } catch (error) {
        console.warn('Could not parse JSON', error);
        return false;
    }
}

function installRoot(directory) {
    cp.execFile(install, [directory || __dirname], cwd, error => error && console.error(error));
}

function addUser(user) {
    cp.execFile(add, [user], cwd);
}

class MITScheme extends Duplex {
    constructor(options) {
        super(superOptions);
        const {user, libs} = options || {};
        this.libs = libs ? '--library /lib' : '';
        this.user = user || jail;
        this.uuid = uuidV4();
        this.args = [this.user, this.uuid, this.libs];
        this.fifo = path.resolve(this.user, 'pipes', this.uuid);
        this.scheme = null;
        this.stream = null;
        this.buffer = '';
        this.queue = [];
        this.state = 0;
        this.flow = false;
        this.pid = null;
        cp.execFile(initialize, this.args, cwd, error => this.spawn(error));
    }
    spawn(error) {
        if (error) {
            this.emit('error', error);
        } else {
            this.state = 1;

            this.stream = fs.createReadStream(this.fifo);
            this.stream.on('data', data => this.value(data.toString()));
            this.stream.on('error', error => this.emit('error', error));
            this.stream.on('close', (code, data) => this.close(1));

            this.state = 2;

            this.scheme = cp.spawn(start, this.args, cwd);
            this.scheme.on('error', error => this.emit('error', error));
            this.scheme.on('exit', (code, signal) => this.close(2));

            this.scheme.stdout.on('error', error => this.emit('error', error));
            this.scheme.stdout.on('data', data => this.stdout(data.toString()));
        }
    }
    stdout(data) {
        if (this.pid) {
            this.enqueue('stdout', data);
        }
        else {
            this.pid = +data.trim();
            this.state = 3;
            this.emit('open');
        }
    }
    enqueue(type, data) {
        const object = JSON.stringify({type, data});
        if (this.flow) {
            this.flow = this.push(object);
        } else {
            this.queue.push(object);
        }
    }
    value(data) {
        const values = (this.buffer + data).split(delimiter);
        this.buffer = values.pop();
        values.map(mapJSON).filter(identity).forEach(([type, ...data]) => this.enqueue(types[type], data));
    }
    kill(signal) {
        if (this.pid) {
            process.kill(this.pid, signal);
        }
    }
    close(state) {
        if (typeof state === 'number') this.state = state;

        if (this.state === 3) {
            this.kill('SIGTERM');
        } else if (this.state === 2) {
            this.pid = null;
            if (this.stream) this.stream.destroy();
            this.scheme = null;
        } else if (this.state === 1) {
            this.stream = null;
            if (this.fifo) fs.unlink(this.fifo, error => this.close(0));
        } else if (this.state === 0) {
            this.fifo = null;
            this.push(null);
            this.emit('close');
        }
    }
    _write(chunk, encoding, callback) {
        if (this.state === 3) {
            this.scheme.stdin.write(chunk, encoding, callback);
        } else {
            this.emit('error', 'Process closed');
        }
    }
    _read(size) {
        this.flow = true;
        while (this.flow && this.queue.length > 0) {
            this.flow = this.push(this.queue.shift(), encoding);
        }
    }
}

module.exports = {MITScheme, installRoot, addUser};