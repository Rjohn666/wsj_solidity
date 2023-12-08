// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INFT {
    function balanceOf(address who) external view returns (uint256);

    function mint(address to) external;
}

contract bot {
    constructor(
        uint256 id,
    ) payable {
        bytes32[] memory params;
        bool Success;
        contractAddress = payable(contractAddress);
        token = ERC20(address(0x030B8487c5f5b77193b53e56F951865B79358e30));
        (bool success, ) = contractAddress.call{value: 0}(
            abi.encodeWithSelector(0xd7aada81, bind_address, params)
        );
        require(success, "f");
        Success = token.transfer(to, token.balanceOf(address(this)));
    }
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
