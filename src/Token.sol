// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("RUPEES", "RPE") {
        _mint(msg.sender, 1000 * 10 ** 18);
        //console.log("minted");
    }
}