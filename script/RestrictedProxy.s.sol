// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/restricted-proxy/Challenge.sol";
import "../src/restricted-proxy/Attack.sol";

contract RestrictedProxyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy challenge
        Challenge challenge = new Challenge{value: 100 ether}(msg.sender);

        // Deploy and run attack
        Attack attack = new Attack(address(challenge));
        attack.run();

        vm.stopBroadcast();
    }
}
