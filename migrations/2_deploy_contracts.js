const Champion = artifacts.require('Champion.sol')

module.exports = function(deployer) {
  deployer.deploy(Champion)
}
