// SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

interface MyInterface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


contract Wsj666 {
    address owner;
    MyInterface nft;

    constructor() {
        owner = msg.sender;
        nft = MyInterface(0x56307423998d608bcf95f0C39cD7E6dc9cb8b43e);
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function claim(address[] calldata addrs,uint256[] calldata tokenids,address to) public isOwner {
        uint256 addrs_len = addrs.length;
        require(addrs_len == tokenids.length,"nonononon");
        for (uint i = 0; i < addrs_len; i++){
            nft.transferFrom(addrs[i], to,tokenids[i]);
            
        }
    }

    }
