// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INFT {
    function balanceOf(address who) external view returns (uint256);

    function mint(address to) external;
}

contract Batcher {
    address owner;

    INFT private constant DCNT =
        INFT(0x22D21831fA435B9f38E2a67Fe0a4A8CBfEAa1327);

    constructor() {
        owner = msg.sender;
    }

    function bulkMint(address[] calldata minter) external {
        require(msg.sender == owner, "not owner");
        uint balance;
        for (uint8 i = 0; i < minter.length; i++) {
            balance = DCNT.balanceOf(minter[i]);
            if (balance == 0) {
                DCNT.mint(minter[i]);
            }
        }
    }
}
