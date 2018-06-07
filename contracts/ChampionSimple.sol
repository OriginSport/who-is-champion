pragma solidity 0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract ChampionSimple is Ownable {
  using SafeMath for uint;

  event LogDistributeReward(address addr, uint reward);
  event LogParticipant(address addr, uint choice, uint betAmount);
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
 
  modifier beforeTimestamp(uint timestamp) {
    require(now < timestamp);
    _;
  }

  modifier afterTimestamp(uint timestamp) {
    require(now >= timestamp);
    _;
  }

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

  function placeBet(uint choice) payable beforeTimestamp(startTime) public {
    require(msg.value >= minimumBet);
    require(choice >= 0);
    require(!checkPlayerExists(msg.sender));

    playerInfo[msg.sender].betAmount = msg.value;
    playerInfo[msg.sender].choice = choice;

    totalBetAmount = totalBetAmount.add(msg.value);
    numberOfBet = numberOfBet.add(1);
    players.push(msg.sender);
    LogParticipant(msg.sender, choice, msg.value);
  }

  function close(uint teamId) onlyOwner public {
    winChoice = teamId;
    distributeReward();
  }

  function getPlayerBetInfo(address addr) view public returns (uint, uint) {
    return (playerInfo[addr].choice, playerInfo[addr].betAmount);
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
