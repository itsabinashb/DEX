//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/Dex.sol";
import "../src/Token.sol";

contract DeployScript is Script {
    function run() public {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);
        Dex dex = new Dex();
        Token token = new Token();
        vm.stopBroadcast();
    }
}