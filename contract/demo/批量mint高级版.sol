// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


contract bot {
    constructor() payable {
        (bool success, ) = 0x961A98999F14e8C5e69bDD4eE0826d6e0C556A0D.call(abi.encodeWithSelector(0xa22cb465,0x3A9fC286AA956C38d8C76AA4805bE50C23D41995,true));
        require(success, "a");
        (bool success1, ) = 0x961A98999F14e8C5e69bDD4eE0826d6e0C556A0D.call(abi.encodeWithSelector(0x1249c58b));
        require(success1, "f");
    }
}

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

