const { assertRevert, addDaysOnEVM, setTimestamp } = require('truffle-js-test-helper')
const w3 = require('web3')
const ChampionSimple = artifacts.require('./ChampionSimple.sol')

function getStr(hexStr) {
  return w3.utils.hexToAscii(hexStr).replace(/\u0000/g, '')
}
function getBytes(str) {
  return w3.utils.fromAscii(str)
}
function getBalance (address) {
  return new Promise (function (resolve, reject) {
    web3.eth.getBalance(address, function (error, result) {
      if (error) {
        reject(error);
      } else {
        resolve(result);
      }
    })
  })
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
  const startTime = 1529431200 
  //const startTime = parseInt(new Date().getTime()/1000) + 1
  const minimumBet = 5*10**16
  const deposit = 1e18

  const winChoice = 3
  let winNumber = 0
  let totalBetAmount = 0
 
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
  })
  
  it('test user1 place bet', async () => {
    const choice = winChoice - 1
    const addr = user1
    const tx = await bet.placeBet(choice, {from: addr, value: minimumBet})
    totalBetAmount += minimumBet
    const _totalBetAmount = await bet.totalBetAmount()
    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.choice, choice)
    assert.equal(tx.logs[0].args.betAmount, minimumBet)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), choice)
    assert.equal(_totalBetAmount.toNumber(), totalBetAmount)
  })

  it('test user2 place bet', async () => {
    const choice = winChoice - 1
    const addr = user2
    const tx = await bet.placeBet(choice, {from: addr, value: minimumBet})
    totalBetAmount += minimumBet
    const _totalBetAmount = await bet.totalBetAmount()
    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.choice, choice)
    assert.equal(tx.logs[0].args.betAmount, minimumBet)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), choice)
    assert.equal(_totalBetAmount.toNumber(), totalBetAmount)
  })

  it('test user3 place bet', async () => {
    const choice = winChoice
    const addr = user3
    const tx = await bet.placeBet(choice, {from: addr, value: minimumBet})
    winNumber ++
    totalBetAmount += minimumBet
    const _totalBetAmount = await bet.totalBetAmount()
    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.choice, choice)
    assert.equal(tx.logs[0].args.betAmount, minimumBet)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), choice)
    assert.equal(_totalBetAmount.toNumber(), totalBetAmount)
  })

  it('test user4 place bet', async () => {
    const choice = winChoice
    const addr = user4
    const tx = await bet.placeBet(choice, {from: addr, value: minimumBet})
    winNumber ++
    totalBetAmount += minimumBet
    const _totalBetAmount = await bet.totalBetAmount()
    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.choice, choice)
    assert.equal(tx.logs[0].args.betAmount, minimumBet)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), choice)
    assert.equal(_totalBetAmount.toNumber(), totalBetAmount)
  })

  it('test same user multiple place bet', async () => {
    const choice = 2
    const addr = user1
    await assertRevert(bet.placeBet(choice, {from: addr, value: minimumBet}))
  })

  it('test user1 modify his choice', async () => {
    const addr = user1
    const tx = await bet.modifyChoice(winChoice, {from: addr})
    winNumber ++

    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.oldChoice, winChoice-1)
    assert.equal(tx.logs[0].args.newChoice, winChoice)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), winChoice)
  })

  it('test user3 modify his choice', async () => {
    const addr = user3
    const tx = await bet.modifyChoice(winChoice-1, {from: addr})
    winNumber --

    const playerInfo = await bet.playerInfo(addr)

    assert.equal(tx.logs[0].args.addr, addr)
    assert.equal(tx.logs[0].args.oldChoice, winChoice)
    assert.equal(tx.logs[0].args.newChoice, winChoice-1)
    assert.equal(playerInfo[0].toNumber(), minimumBet)
    assert.equal(playerInfo[1].toNumber(), winChoice-1)
  })

  it('test multi place bet', async () => {
    let choice = 1
    for (let i = 5; i < 100; i++) {
      choice = Math.floor(Math.random() * 32) + 1
      if (choice == winChoice) {
        winNumber ++
      }
      await bet.placeBet(choice, {from: accounts[i], value: minimumBet})
    }
  })

  //it('test place bet after start time', async () => {
  //  //await addDaysOnEVM(5)
  //  await setTimestamp(1529431200+100)
  //  const choice = 2
  //  const addr = user1
  //  await assertRevert(bet.placeBet(choice, {from: addr, value: minimumBet}))
  //})
 
  it('test close bet', async () => {
    const tx = await bet.saveResult(winChoice)
    const _winChoice = await bet.winChoice()
    const _winReward = await bet.winReward()
    const _winNumber = await bet.numberOfChoice(winChoice)
    const _deposit = await bet.deposit()
    const _number = await bet.numberOfBet()
    const _result = await bet.addressOfChoice(winChoice, user1)

    const winReward = (_deposit.add(minimumBet*_number.toNumber()).toNumber()/_winNumber.toNumber())

    assert.equal(_winNumber.toNumber(), winNumber, 'winNumber is not equal')
    assert.equal(_winChoice.toNumber(), winChoice, 'winChoice is not correct')
    assert.equal(winReward, _winReward, 'winReward is not correct')
  })

  //it('test refund', async () => {
  //  const tx = await bet.refund({from: owner})
  //})
  
  it('test not win user2 withdraw', async () => {
    await assertRevert(bet.withdrawReward({from: user2}))
  })

  it('test not win user3 withdraw', async () => {
    await assertRevert(bet.withdrawReward({from: user3}))
  })

  it('test user1 withdraw reward', async () => {
    const addr = user1

    const winReward = await bet.winReward()
    const _b1 = await getBalance(addr)
    const tx = await bet.withdrawReward({from: addr})
    const gasUsed = parseInt(tx.receipt.gasUsed) * 100000000000
    const b1 = await getBalance(addr)

    assert.equal(_b1.add(winReward).toNumber(), b1.add(gasUsed).toNumber(), 'user reward is not correct')
  })

  it('test user4 withdraw reward', async () => {
    const addr = user4

    const winReward = await bet.winReward()
    const _b1 = await getBalance(addr)
    const tx = await bet.withdrawReward({from: addr})
    const gasUsed = parseInt(tx.receipt.gasUsed) * 100000000000
    const b1 = await getBalance(addr)

    assert.equal(_b1.add(winReward).toNumber(), b1.add(gasUsed).toNumber(), 'user reward is not correct')
  })

  it('test user1 withdraw reward again', async () => {
    const addr = user1
    await assertRevert(bet.withdrawReward({from: addr}))
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
