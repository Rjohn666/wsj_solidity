// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;



contract bot {
    constructor() payable {
        (bool success, ) = address(0xCF205808Ed36593aa40a44F10c7f7C2F67d4A4d4).call(
            abi.encodeWithSelector(0x6945b123, address(this), 1)
        );
        require(success, "Batch transaction failed");
        // selfdestruct(payable(tx.origin));
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

    function fooyaoBulkMint() external payable {
        bot acc;
        acc = new bot();
        accs.push(address(acc));
        }

        
    }

