const { assertRevert } = require('truffle-js-test-helper')
const w3 = require('web3')
const ChampionSimple = artifacts.require('./ChampionSimple.sol')

function getStr(hexStr) {
  return w3.utils.hexToAscii(hexStr).replace(/\u0000/g, '')
}
function getBytes(str) {
  return w3.utils.fromAscii(str)
}

contract('DataCenter', accounts => {
  // account[0] points to the owner on the testRPC setup
  var owner = accounts[0]
  var user1 = accounts[1]
  var user2 = accounts[2]
  var user3 = accounts[3]
  var user4 = accounts[4]
  var user5 = accounts[5]
  var user6 = accounts[6]
  var user7 = accounts[7]
  var user8 = accounts[8]
  var user9 = accounts[9]

  let bet
  const startTime = 1528988400
  const minimumBet = 5*10**16
 
  before(() => {
    return ChampionSimple.deployed(startTime, minimumBet, {from: owner})
    .then(instance => {
      bet = instance
    })
  })


})
