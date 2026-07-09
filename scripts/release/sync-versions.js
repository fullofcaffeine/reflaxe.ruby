#!/usr/bin/env node

const fs = require('fs')

function readUtf8(path) {
  return fs.readFileSync(path, 'utf8')
}

function writeUtf8(path, text) {
  fs.writeFileSync(path, text)
}

function updateJsonFile(path, update) {
  const original = readUtf8(path)
  const json = JSON.parse(original)
  update(json)
  const next = `${JSON.stringify(json, null, 2)}\n`
  if (next !== original) writeUtf8(path, next)
}

function ensureSemver(version) {
  if (!/^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$/.test(version)) {
    throw new Error(`Invalid semver: ${version}`)
  }
}

function updateHxmlLibraryVersion(path, defineName, version) {
  const original = readUtf8(path)
  const escapedDefine = defineName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const pattern = new RegExp(`^-D\\s+${escapedDefine}=[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?\\s*$`, 'gm')
  if (!pattern.test(original)) {
    throw new Error(`No ${defineName} version define found to update in ${path}`)
  }
  const next = original.replace(pattern, `-D ${defineName}=${version}`)
  if (next !== original) writeUtf8(path, next)
}

function updateRubyVersionConstant(path, version) {
  const original = readUtf8(path)
  const pattern = /^\s*VERSION\s*=\s*"[^"]+"\s*$/m
  if (!pattern.test(original)) {
    throw new Error(`No HXRuby::VERSION constant found to update in ${path}`)
  }
  const next = original.replace(pattern, `  VERSION = "${version}"`)
  if (next !== original) writeUtf8(path, next)
}

function updateReadmeCurrentVersion(path, version) {
  const original = readUtf8(path)
  const pattern = /The current `[^`]+` baseline supports/
  if (!pattern.test(original)) {
    throw new Error(`No current version baseline found to update in ${path}`)
  }
  const next = original.replace(pattern, `The current \`${version}\` baseline supports`)
  if (next !== original) writeUtf8(path, next)
}

function main() {
  const version = process.argv[2]
  if (!version) {
    console.error('Usage: node scripts/release/sync-versions.js <version>')
    process.exit(2)
  }
  ensureSemver(version)

  updateJsonFile('package.json', (json) => {
    json.version = version
  })

  if (fs.existsSync('package-lock.json')) {
    updateJsonFile('package-lock.json', (json) => {
      json.version = version
      if (json.packages && json.packages['']) {
        json.packages[''].version = version
      }
    })
  }

  updateJsonFile('haxelib.json', (json) => {
    json.version = version
    json.releasenote = `v${version}: See CHANGELOG.md`
  })

  updateHxmlLibraryVersion('haxe_libraries/reflaxe.ruby.hxml', 'reflaxe.ruby', version)
  updateHxmlLibraryVersion('haxe_libraries/railshx.client.hxml', 'railshx.client', version)
  updateRubyVersionConstant('lib/hxruby/version.rb', version)
  updateReadmeCurrentVersion('README.md', version)
}

main()
