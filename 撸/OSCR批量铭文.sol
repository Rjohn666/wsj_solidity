// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

contract BulkBRC20Mint {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function claim(uint count,bytes calldata _inscription)isOwner public {
        for (uint i = 0; i < count; i++) {
            (bool sent, ) = msg.sender.call{value:0}(_inscription);
            require(sent, "Failed to send");
            }
        }
    }
