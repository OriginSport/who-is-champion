pragma solidity 0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract ChampionRound is Ownable {
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

  function ChampionRound(uint _startTime, uint _minimumBet) payable public {
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
    if (checkPlayerExists(msg.sender)) {
      playerInfo[msg.sender].betAmount = playerInfo[msg.sender].betAmount.add(msg.value);
      playerInfo[msg.sender].choice = choice;
      totalBetAmount = totalBetAmount.add(msg.value);
    } else {
      require(msg.value == minimumBet);
      playerInfo[msg.sender].betAmount = msg.value;
      playerInfo[msg.sender].choice = choice;

      totalBetAmount = totalBetAmount.add(msg.value);
      numberOfBet = numberOfBet.add(1);
      players.push(msg.sender);
      LogParticipant(msg.sender, choice, msg.value);
    }
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
   * @dev owner can withdraw the remain ether if distribute exceeds max length
   */
  function withdraw() onlyOwner public {
    uint _balance = address(this).balance;
    owner.transfer(_balance);
    LogWithdraw(owner, _balance);
  }
}
