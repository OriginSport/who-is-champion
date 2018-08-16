const ChampionBase = artifacts.require('ChampionBase.sol')

module.exports = function (deployer) {
    const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 60
    console.info('startTime:', startTime)
    const minimumBet = 5 * 10 ** 16
    const winRewardPercent = 50
    deployer.deploy(ChampionBase, startTime, minimumBet, winRewardPercent)
}
