const { assertRevert } = require('truffle-js-test-helper')
const w3 = require('web3')
const ChampionSimple = artifacts.require('./ChampionSimple.sol')

function getStr(hexStr) {
  return w3.utils.hexToAscii(hexStr).replace(/\u0000/g, '')
}
function getBytes(str) {
  return w3.utils.fromAscii(str)
}

contract('Champion Simple', accounts => {
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

  console.log(`owner:${owner}\nuser1:${user1}\nuser2:${user2}`)
  let bet
  const startTime = 1528988400
  const minimumBet = 5*10**16
  const deposit = 1e18
 
  before(() => {
    return ChampionSimple.new(startTime, minimumBet, {from: owner, value: deposit})
    .then(instance => {
      bet = instance
    })
  })

  it('check bet params is correct', async () => {
    const st = await bet.startTime()
    const mb = await bet.minimumBet()
    const d = await bet.deposit()

    assert.equal(st.toNumber(), startTime)
    assert.equal(mb.toNumber(), minimumBet)
    assert.equal(d.toNumber(), deposit)
  })

  it('test recharge deposit', async () => {
    const od = await bet.deposit()
    await bet.rechargeDeposit({from: owner, value: deposit*10})
    const nd = await bet.deposit()
    assert.equal(od.add(deposit*10).toNumber(), nd.toNumber())
  })

  it('check get player bet info', async () => {
    const p = await bet.getPlayerBetInfo(user1)
    console.log(p)
  })
  
  it('test user place bet', async () => {
    const choice = 2
    const addr = user1
    const tx = await bet.placeBet(choice, {from: addr, value: minimumBet})
    const _totalBetAmount = await bet.totalBetAmount()
    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.choice, choice)
    assert.equal(tx.logs[0].args.betAmount, minimumBet)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), choice)
    assert.equal(_totalBetAmount.toNumber(), minimumBet)
  })

  it('test user place bet', async () => {
    const choice = 3
    const addr = user1
    await assertRevert(bet.placeBet(choice, {from: addr, value: minimumBet}))
  })

  it('test multi place bet', async () => {
    let choice = 1
    for (let i = 5; i < 100; i++) {
      choice = Math.floor(Math.random() * 32) + 1
      await bet.placeBet(choice, {from: accounts[i], value: minimumBet})
    }
  })

  it('test close bet', async () => {
    let w = 1
    const tx = await bet.close(3)
    console.log(tx.logs)
  })

  after(async () => {
    const choice = await bet.winChoice()
    const players = await bet.getPlayers()
    const _totalBetAmount = await bet.totalBetAmount()
    const _deposit = await bet.deposit()
    console.log("The winner's choice is:   ", choice)
    console.log('Total bet amount is:      ', _totalBetAmount)
    console.log('Deposit amount is:        ', _deposit)
    console.log('Number of participant is: ', players.length)
  })
})
