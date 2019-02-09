pragma solidity >=0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MNFT is ERC721, Ownable {
    string public constant name = "Mentat NFT";
    string public constant symbol = "MNFT";
    struct token {
        string name;
        uint level;
    }
    mapping(uint => token) tokens;
    uint tokensCount;

    function mint(string _name, uint _level) public {
        tokensCount++;

        tokens[tokensCount].name = _name;
        tokens[tokensCount].level = _level;

        _mint(msg.sender, tokensCount);
    }

    function burn(uint _tokenID) public {
        tokens[_tokenID].name = "";
        tokens[_tokenID].level = 0;

        _burn(msg.sender, _tokenID);
    }
}