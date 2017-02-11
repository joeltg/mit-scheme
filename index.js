const {createReadStream, unlink} = require('fs')
const {execFile, spawn} = require('child_process')
const {resolve} = require('path')
const {Duplex} = require('stream')
const uuidV4 = require('uuid/v4')
const delimiter = '\n'
const encoding = 'utf8'
const identity = i => i

const options = {
  allowHalfOpen: false,
  decodeStrings: false,
  encoding
}

const jail = resolve(__dirname, 'jail')
const initialize = resolve(__dirname, 'scripts', 'initialize.sh')
const start = resolve(__dirname, 'scripts', 'start.sh')

const transform = {
  value: ([text, pretty, latex]) => ({text, pretty, latex}),
  print: ([text, pretty, latex]) => ({text, pretty, latex}),
  stdout: identity,
  canvas: ([action, id, value]) => ({action, id, value}),
  error: ([message, restarts, stack]) => ({message, stack, restarts: restarts.map(([name, report, arity]) => ({name, report, arity}))})
}

const types = {
  0: 'value',
  1: 'error',
  2: 'canvas',
  3: 'print'
}

function mapJSON(data) {
  try {
    return JSON.parse(data)
  } catch (error) {
    console.warn('Failed to parse JSON', error)
    return false
  }
}

class MITScheme extends Duplex {
  constructor(config) {
    super(options)
    const {root, path, scmutils} = config || {}
    this.path = path || jail
    this.root = root || __dirname
    this.band = scmutils ? 'edwin-mechanics.com' : 'runtime.com'
    this.scheme = null
    this.stream = null
    this.buffer = ''
    this.queue = []
    this.state = 0
    this.flow = false
    this.pid = null

    this.uuid = uuidV4()
    this.args = [this.path, this.uuid, this.band]
    this.files = resolve(this.path, 'files')
    this.fifo = resolve(this.path, 'pipes', this.uuid)
    execFile(initialize, this.args, {}, err => this.spawn(err))
  }
  spawn(err) {
    if (err) this.emit('error', err)

    this.state = 1
    this.stream = createReadStream(this.fifo)
    this.stream.on('data', data => this.value(data.toString()))
    this.stream.on('error', err => this.emit('error', err))
    this.stream.on('close', (code, data) => this.close(1))

    this.state = 2
    this.scheme = spawn(start, this.args, {cwd: this.path})
    this.scheme.on('error', err => this.emit('error', err))
    this.scheme.on('exit', (code, signal) => this.close(2))

    this.scheme.stdout.on('error', err => this.emit('error', err))
    this.scheme.stdout.on('data', data => this.stdout(data.toString()))
  }
  stdout(data) {
    if (this.pid) {
      this.enqueue('stdout', data)
    } else {
      this.pid = +data.trim()
      this.state = 3
      this.emit('open')
    }
  }
  enqueue(type, data) {
    const object = JSON.stringify({type, data: transform[type](data)}) + '\n'
    if (this.flow) {
      this.flow = this.push(object, encoding)
    } else {
      this.queue.push(object)
    }
  }
  value(data) {
    const values = (this.buffer + data).split(delimiter)
    this.buffer = values.pop()
    values.map(mapJSON).filter(identity).forEach(([type, ...data]) => this.enqueue(types[type], data))
  }
  kill(signal) {
    if (this.pid) {
      process.kill(this.pid, signal)
    }
  }
  close(state) {
    if (typeof state === 'number') {
      this.state = state
    }
    if (this.state === 3) {
      this.kill('SIGTERM')
    } else if (this.state === 2) {
      this.pid = null
      if (this.stream) {
        this.stream.destroy()
      }
      this.scheme = null
    } else if (this.state === 1) {
      this.stream = null
      if (this.fifo) {
        unlink(this.fifo, err => this.close(0))
      }
    } else if (this.state === 0) {
      this.fifo = 0
      this.push(null)
      this.emit('close')
    }
  }
  _write(chunk, encoding, callback) {
    if (this.state === 3) {
      this.scheme.stdin.write(chunk, encoding, callback)
    } else {
      this.emit('error', 'Process closed')
    }
  }
  _read(size) {
    this.flow = true
    while (this.flow && this.queue.length > 0) {
      this.flow = this.push(this.queue.shift(), encoding)
    }
  }
}

module.exports = MITScheme
