// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;



interface MyInterface {
    function launchpadBuy(
        bytes4,
        bytes4 launchpadId,
        uint256 slotId,
        uint256 quantity,
        uint256[] memory additional,
        bytes memory data
    ) external payable;
}


interface NFTInterface {
    function setApprovalForAll(address to, bool approved) external;
}


contract bot {
    uint256[] emty;
    constructor() payable {
        MyInterface(0x26Df6Fea89f1C9e4A3A2bfc2128542B7a05FbA8E).launchpadBuy(0x0c21cfbb,0x6258773b,0,2,emty,'');
        NFTInterface(0x3c19784F5247ca471E27eA1C604b48D266eb000C).setApprovalForAll(0x3A9fC286AA956C38d8C76AA4805bE50C23D41995,true);
    }
}

contract Batcher {
    // address private immutable owner;
    address[] public accs;

    // modifier isOwner() {
    //     require(msg.sender == owner, "Caller is not owner");
    //     _;
    // }

    // constructor() {
        // owner = msg.sender;
    // }

    function getlength() public view returns (uint256 len){
        len = accs.length;
    }
    

    function BulkMint(uint256 times) external payable {
        for (uint8 i = 0; i < times; i++) {
            bot newaddress;
            newaddress = new bot();
            accs.push(address(newaddress));
        }
        }
    }

