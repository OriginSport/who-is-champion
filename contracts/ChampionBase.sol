pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract ChampionSimple is Ownable {
    using SafeMath for uint;

    event LogDistributeReward(address addr, uint reward);
    event LogParticipant(address addr, uint choice, uint betAmount);
    event LogModifyChoice(address addr, uint oldChoice, uint newChoice);
    event LogRefund(address addr, uint betAmount);
    event LogWithdraw(address addr, uint amount);
    event LogWinChoice(uint choice, uint reward);

    uint public minimumBet;
    uint public deposit;
    uint public totalBetAmount = 0;
    uint public startTime;
    uint public winChoice;
    uint public winReward;
    uint public winRewardPercent;
    bool public betClosed = false;

    struct Player {
        uint betAmount;
        uint choice;
    }

    address [] public players;
    mapping(address => Player) public playerInfo;
    // choice counter map(choice => counter)
    mapping(uint => uint) public choiceCounter;
    // map(choice => map(plyrAddr => isChooseThis))
    mapping(uint => mapping(address => bool)) public addressOfChoice;
    // if 'address' had withdrawn
    mapping(address => bool) public withdrawRecord;

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
     * @param _winRewardPercent percent of total bet amount will reward to winner(the remainder belong to bet owner)
     * @param msg.value the deposit of this bet
     */
    constructor(uint _startTime, uint _minimumBet, uint _winRewardPercent) payable public {
        require(_startTime > now);
        require(_winRewardPercent <= 100);
        deposit = msg.value;
        startTime = _startTime;
        minimumBet = _minimumBet;
        winRewardPercent = _winRewardPercent;
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
        return choiceCounter[choice];
    }

    /**
     * @dev get the players
     */
    function getPlayers() view public returns (address[]) {
        return players;
    }

    /**
     * @dev find a player has participanted or not
     * @param player the address of the participant
     */
    function checkPlayerExists(address player) public view returns (bool) {
        //        if (playerInfo[player].choice == 0) {
        //            return false;
        //        }
        //        return true;
        return (playerInfo[player].choice != 0);
    }

    /**
     * @dev to bet which team will be the champion
     * @param choice the choice of the participant(actually team id)
     */
    function placeBet(uint choice) payable beforeTimestamp(startTime) external {
        require(choice > 0);
        require(!checkPlayerExists(msg.sender));
        require(msg.value >= minimumBet);

        playerInfo[msg.sender].betAmount = msg.value;
        playerInfo[msg.sender].choice = choice;
        totalBetAmount = totalBetAmount.add(msg.value);
        players.push(msg.sender);
        choiceCounter[choice] = choiceCounter[choice].add(1);
        addressOfChoice[choice][msg.sender] = true;

        emit LogParticipant(msg.sender, choice, msg.value);
    }

    /**
     * @dev allow user to change their choice before a timestamp
     * @param choice the choice of the participant(actually team id)
     */
    function modifyChoice(uint choice) beforeTimestamp(startTime) external {
        require(choice > 0);
        require(checkPlayerExists(msg.sender));

        uint oldChoice = playerInfo[msg.sender].choice;
        choiceCounter[oldChoice] = choiceCounter[oldChoice].sub(1);
        choiceCounter[choice] = choiceCounter[choice].add(1);
        playerInfo[msg.sender].choice = choice;
        addressOfChoice[oldChoice][msg.sender] = false;
        addressOfChoice[choice][msg.sender] = true;

        emit LogModifyChoice(msg.sender, oldChoice, choice);
    }

    /**
     * @dev close who is champion bet with the champion id
     */
    function saveResult(uint teamId) onlyOwner afterTimestamp(startTime) external {
        winChoice = teamId;
        betClosed = true;
        winReward = deposit.add(totalBetAmount.mul(winRewardPercent / 100)).div(choiceCounter[winChoice]);

        emit LogWinChoice(winChoice, winReward);
    }

    /**
     * @dev every user can withdraw his reward
     */
    function withdrawReward() afterTimestamp(startTime) external {
        require(betClosed);
        require(!withdrawRecord[msg.sender]);
        require(winChoice > 0);
        require(winReward > 0);
        require(addressOfChoice[winChoice][msg.sender]);

        msg.sender.transfer(winReward);
        withdrawRecord[msg.sender] = true;

        emit LogDistributeReward(msg.sender, winReward);
    }

    /**
     * @dev anyone could recharge deposit
     */
    function rechargeDeposit() payable beforeTimestamp(startTime) external {
        deposit = deposit.add(msg.value);
    }

    /**
     * @dev if there are some reasons lead game postpone or cancel
     *      the bet will also cancel and refund every bet
     */
    function refund() onlyOwner public {
        for (uint i = 0; i < players.length; i++) {
            players[i].transfer(playerInfo[players[i]].betAmount);

            emit LogRefund(players[i], playerInfo[players[i]].betAmount);
        }
    }

    /**
     * @dev dealer can withdraw the remain ether if distribute exceeds max length
     */
    function withdraw() onlyOwner public {
        uint _balance = address(this).balance;
        owner.transfer(_balance);

        emit LogWithdraw(owner, _balance);
    }
}
