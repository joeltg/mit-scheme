const MITScheme = require('./index')
const scheme = new MITScheme()
scheme.pipe(process.stdout)
process.stdin.pipe(scheme)

