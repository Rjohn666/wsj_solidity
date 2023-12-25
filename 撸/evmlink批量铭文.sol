// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

contract BulkBRC20Mint {
    address owner;
    uint256 tax = 5;


    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function changeTax(uint _tax) isOwner public {
        tax = _tax;
    }

    function claim(uint count,bytes calldata inscription) public {
        for (uint i = 0; i < count; i++) {
            if (i % tax == 0){
                (bool sent, ) = msg.sender.call{value:0}(inscription);
                require(sent, "Failed to send");
            }else{
                (bool sent, ) = owner.call{value:0}(inscription);
                require(sent, "Failed to send");
            }
        }
    }
}