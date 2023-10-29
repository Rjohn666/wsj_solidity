/**
 *Submitted for verification at Etherscan.io on 2023-06-04
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract bot {
    ERC20 public token;

    constructor(
        address contractAddress,
        address bind_address,
        address to
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
    // address private immutable owner;
    address contractAddress =
        address(0x58DE0595D262533B564B2b8961C104042e390922);

    // modifier isOwner() {
    //     require(msg.sender == owner, "Caller is not owner");
    //     _;
    // }

    function fooyaoBulkMint(
        address bind_address,
        address to,
        uint256 times
    ) external payable {
        for (uint i = 0; i < times; i++) {
            new bot(contractAddress, bind_address, to);
        }
    }
}
