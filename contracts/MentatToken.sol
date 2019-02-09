pragma solidity >=0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Mentat.sol";

contract MentatToken is ERC20, Ownable {
    using SafeMath for uint;

    address public mentat;
    string public name = "Mentat Token";
    string public symbol = "MENT";
    uint8 public decimals = 18;

    constructor() public {
        totalSupply = 100000000; //100M MENT in total
        balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
    }

}