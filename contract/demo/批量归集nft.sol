// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Batcher {
    address private immutable owner;
    address[] public accs;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getlength() public view returns (uint256 len){
        len = accs.length;
    }
    

    function fooyaoBulkMint(uint256 times) external payable {
        for (uint8 i = 0; i < times; i++) {
            bot newaddress;
            newaddress = new bot();
            accs.push(address(newaddress));
        }
        }

        
    }

