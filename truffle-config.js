require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider')

module.exports = {
  networks: {
    kovan: {
      host: 'localhost',
      port: 8545,
      network_id: '42',
      provider: () =>
        new HDWalletProvider(process.env.MNEMONIC, 'https://kovan.infura.io/v3/5b9224c38ec74955b0061637d4a7e61a')
    },
    ganache: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
    },
    live: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, process.env.RPC_URL)
      },
      network_id: '*',
      // ~~Necessary due to https://github.com/trufflesuite/truffle/issues/1971~~
      // Necessary due to https://github.com/trufflesuite/truffle/issues/3008
      skipDryRun: true,
    },
  },
  compilers: {
    solc: {
      version: '0.4.24',
    },
  },
}
