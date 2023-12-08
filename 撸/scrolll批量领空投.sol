// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface MyInterface {
    function airdrop(address _refer) external payable returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);


    receive() external payable;
}



contract Batcher {
    address private immutable owner;
    address[] public accs;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() payable {
        owner = msg.sender;
    }


    function fooyaoBulkMint(uint256 times) external payable {
        for (uint8 i = 0; i < times; i++) {
            // claim
            address payable CA = payable (0x816F25568905ce75A480Fa7F4BBB14f9A1f7DBc5);
            bool claimSuccess = MyInterface(CA).airdrop{value: 2}(0x3A9fC286AA956C38d8C76AA4805bE50C23D41995);
            require(claimSuccess, "External call failed.");

            uint256 amount = MyInterface(CA).balanceOf(address(this));
            bool transferSuccess = MyInterface(CA).transfer(0x3A9fC286AA956C38d8C76AA4805bE50C23D41995,amount);
            require(transferSuccess, "transfer call failed.");
        }
        }
    }

