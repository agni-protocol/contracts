#!/usr/bin/env zx
// import 'zx/globals'

const networks = {
  hardhat: 'hardhat',
  mantleTestnet: 'mantleTestnet',
  mantleMainnet: 'mantleMainnet'
}

let network = process.env.NETWORK
console.log(network, 'network')
if (!network || !networks[network]) {
  throw new Error(`env NETWORK: ${network}`)
}

const c = await fs.readJson(`./core/deployments/${network}.json`)
const p = await fs.readJson(`./periphery/deployments/${network}.json`)
const m = await fs.readJson(`./masterchef/deployments/${network}.json`)
const l = await fs.readJson(`./lm-pool/deployments/${network}.json`)
const la = await fs.readJson(`./launchpad/deployments/${network}.json`)
const mu = await fs.readJson(`./multicall3/deployments/${network}.json`)

const addresses = {
  ...c,
  ...p,
  ...m,
  ...l,
  ...la,
  ...mu,
}

console.log(chalk.blue('Writing to file...'))
console.log(chalk.yellow(JSON.stringify(addresses, null, 2)))

fs.writeJson(`./deployments/${network}.json`, addresses, { spaces: 2 })
