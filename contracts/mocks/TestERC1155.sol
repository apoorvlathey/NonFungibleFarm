pragma solidity ^0.6.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155("sampleURI") {
    constructor() public {
        _mint(msg.sender, 0, 100, "");
    }
}