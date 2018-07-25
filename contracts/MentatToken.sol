pragma solidity ^0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Mentat.sol";

contract MentatToken is StandardToken, Ownable {
    address public mentat;
    string public name = "Mentat Token";
    string public symbol = "MENT";
    uint8 public decimals = 18;

    /*
     *  Modifiers
     */
    modifier onlyMentat() {
        require(msg.sender == mentat);
        _;
    }

    /*
     * Public functions
     */
    function setMentat(address newMentat)
    onlyOwner
    public {
        mentat = newMentat;
    }

    function acceptTask(uint taskId)
    public {
        //check if agent
        require(Mentat(mentat).isAgentRegistered(msg.sender));
        //check balance
        require(this.balanceOf(msg.sender) > 0);
        //freeze 20%
        uint transferValue = this.balanceOf(msg.sender).mul(20).div(100);
        require(transferValue > 0 && this.balanceOf(msg.sender) > transferValue);
        this.transfer(mentat, transferValue);
        //accept task in Mentat
        Mentat(mentat).acceptTask(taskId, msg.sender, transferValue);
    }



    constructor() public {
        totalSupply_ = 1000000 ether;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }

}