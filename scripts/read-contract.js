const ATestnetConsumer = artifacts.require('ATestnetConsumer')

/*
  This script makes it easy to read the data variable
  of the requesting contract.
*/

module.exports = async callback => {
  const mc = await ATestnetConsumer.deployed()
  const data = await mc.data.call()
  callback(data)
}
