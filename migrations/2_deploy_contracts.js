const ChampionSimple = artifacts.require('ChampionSimple.sol')
const ChampionRound = artifacts.require('ChampionRound.sol')

module.exports = function(deployer) {
  const startTime = 1528988400
  deployer.deploy(ChampionSimple, startTime, 5*10**16)
  //deployer.deploy(ChampionRound, startTime, 5*10**16)
}
