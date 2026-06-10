#!/usr/bin/env node

const fs = require('fs')

function fail(message) {
  console.error(`[version-sync] ERROR: ${message}`)
  process.exitCode = 1
}

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, 'utf8'))
}

const packageJson = readJson('package.json')
const haxelibJson = readJson('haxelib.json')
const rubyHxml = fs.readFileSync('haxe_libraries/reflaxe.ruby.hxml', 'utf8')
const hxrubyVersion = fs.readFileSync('lib/hxruby/version.rb', 'utf8')

const expectedVersion = packageJson.version

if (haxelibJson.version !== expectedVersion) {
  fail(`haxelib.json version ${haxelibJson.version} != package.json version ${expectedVersion}`)
}

if (haxelibJson.releasenote !== `v${expectedVersion}: See CHANGELOG.md` && expectedVersion !== '0.1.0') {
  fail(`haxelib.json releasenote does not match version ${expectedVersion}`)
}

const hxmlVersion = rubyHxml.match(/^-D\s+reflaxe\.ruby=([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?)\s*$/m)
if (!hxmlVersion) {
  fail('missing -D reflaxe.ruby=<version> in haxe_libraries/reflaxe.ruby.hxml')
} else if (hxmlVersion[1] !== expectedVersion) {
  fail(`haxe_libraries/reflaxe.ruby.hxml version ${hxmlVersion[1]} != package.json version ${expectedVersion}`)
}

const gemVersion = hxrubyVersion.match(/^\s*VERSION\s*=\s*"([^"]+)"\s*$/m)
if (!gemVersion) {
  fail('missing HXRuby::VERSION in lib/hxruby/version.rb')
} else if (gemVersion[1] !== expectedVersion) {
  fail(`lib/hxruby/version.rb version ${gemVersion[1]} != package.json version ${expectedVersion}`)
}

if (process.exitCode) {
  process.exit(process.exitCode)
}

console.log(`[version-sync] OK: ${expectedVersion}`)
