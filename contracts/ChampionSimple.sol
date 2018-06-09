pragma solidity 0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract ChampionSimple is Ownable {
  using SafeMath for uint;

  event LogDistributeReward(address addr, uint reward);
  event LogParticipant(address addr, uint choice, uint betAmount);
  event LogModifyChoice(address addr, uint choice);
  event LogRefund(address addr, uint betAmount);
  event LogWithdraw(address addr, uint amount);

  uint public minimumBet = 5 * 10 ** 16;
  uint public deposit = 0;
  uint public totalBetAmount = 0;
  uint public startTime;
  uint public winChoice;
  uint public numberOfBet;

  struct Player {
    uint betAmount;
    uint choice;
  }

  address [] public players;
  mapping(address => Player) public playerInfo;
  mapping(uint => uint) public choiceNumber;
 
  modifier beforeTimestamp(uint timestamp) {
    require(now < timestamp);
    _;
  }

  modifier afterTimestamp(uint timestamp) {
    require(now >= timestamp);
    _;
  }

  /**
   * @dev the construct function
   * @param _startTime the deadline of betting
   * @param _minimumBet the minimum bet amount
   */
  function ChampionSimple(uint _startTime, uint _minimumBet) payable public {
    require(_startTime > now);
    deposit = msg.value;
    startTime = _startTime;
    minimumBet = _minimumBet;
  }

  /**
   * @dev find a player has participanted or not
   * @param player the address of the participant
   */
  function checkPlayerExists(address player) public view returns (bool) {
    if (playerInfo[player].choice == 0) {
      return false;
    }
    return true;
  }

  /**
   * @dev to bet which team will be the champion
   * @param chioce the choice of the participant(actually team id)
   */
  function placeBet(uint choice) payable beforeTimestamp(startTime) public {
    require(choice > 0);
    require(!checkPlayerExists(msg.sender));
    require(msg.value >= minimumBet);

    playerInfo[msg.sender].betAmount = msg.value;
    playerInfo[msg.sender].choice = choice;
    totalBetAmount = totalBetAmount.add(msg.value);
    numberOfBet = numberOfBet.add(1);
    players.push(msg.sender);
    choiceNumber[choice] = choiceNumber[choice].add(1);
    LogParticipant(msg.sender, choice, msg.value);
  }

  /**
   * @dev allow user to change their choice before a timestamp
   * @param chioce the choice of the participant(actually team id)
   */
  function updateChoice(uint choice) beforeTimestamp(startTime) public {
    require(choice > 0);
    require(checkPlayerExists(msg.sender));

    choiceNumber[playerInfo[msg.sender].choice] = choiceNumber[playerInfo[msg.sender].choice].sub(1);
    choiceNumber[choice] = choiceNumber[choice].add(1);
    playerInfo[msg.sender].choice = choice;
    LogModifyChoice(msg.sender, choice);
  }

  /**
   * @dev close who is champion bet with the champion id
   */
  function close(uint teamId) onlyOwner public {
    winChoice = teamId;
    distributeReward();
  }

  /**
   * @dev get player bet information
   * @param addr indicate the bet address
   */
  function getPlayerBetInfo(address addr) view public returns (uint, uint) {
    return (playerInfo[addr].choice, playerInfo[addr].betAmount);
  }

  /**
   * @dev get the bet numbers of a specific choice
   * @param choice indicate the choice
   */
  function getNumberByChoice(uint choice) view public returns (uint) {
    return choiceNumber[choice];
  }

  /**
   * @dev if there are some reasons lead game postpone or cancel
   *      the bet will also cancel and refund every bet
   */
  function refund() onlyOwner public {
    for (uint i = 0; i < players.length; i++) {
      players[i].transfer(playerInfo[players[i]].betAmount);
      LogRefund(players[i], playerInfo[players[i]].betAmount);
    }
  }

  /**
   * @dev distribute ether to every winner as they choosed odds
   */
  function distributeReward() internal {
    for (uint i = 0; i < players.length; i++) {
      if (playerInfo[players[i]].choice == winChoice) {
        uint reward = deposit.add(totalBetAmount).mul(playerInfo[players[i]].betAmount).div(totalBetAmount);
        players[i].transfer(reward);
        LogDistributeReward(players[i], reward);
      }
    }
  }

  /**
   * @dev get the players
   */
  function getPlayers() view public returns (address[]) {
    return players;
  }

  /**
   * @dev dealer can withdraw the remain ether if distribute exceeds max length
   */
  function withdraw() onlyOwner public {
    uint _balance = address(this).balance;
    owner.transfer(_balance);
    LogWithdraw(owner, _balance);
  }
}
