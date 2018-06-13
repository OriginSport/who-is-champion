const ChampionSimple = artifacts.require('ChampionSimple.sol')

module.exports = function(deployer) {
  const startTime = 1529431200
  const minimumBet = 5*10**16
  deployer.deploy(ChampionSimple, startTime, minimumBet)
}
