pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT
interface MyInterface {
    function activate(uint256 _refCode) external payable;
}

interface erc20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract bot {
    address contractAddress = 0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB;

    constructor() public payable {
        (bool success, ) = contractAddress.call{value: msg.value}(
            abi.encodeWithSignature("tixian(uint256)", 1)
        );
        require(success, "Batch transaction failed");
    }

    function tixian() external payable {
        (bool success2, ) = contractAddress.call{value: msg.value}(
            abi.encodeWithSelector(0x3ccfd60b)
        );
        require(success2, "Batch transaction failed");
        erc20 Dragon = erc20(0xF0f942D563A6BaCf875d8cEe5AE663b12Ce62149);
        Dragon.transfer(
            0x3C50d3a325aA9968Ae66b4ED2354D3570f1D9309,
            Dragon.balanceOf(address(this))
        );
        // selfdestruct(payable(tx.origin));
    }
}

contract Batcher is bot {
    address private immutable owner;
    address[] public heyuemen;
    erc20 Dragon = erc20(0xF0f942D563A6BaCf875d8cEe5AE663b12Ce62149);
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function fooyaoBulkMint(uint256 times) external payable {
        for (uint i = 0; i < times; i++) {
            bot c;
            c = new bot();
            heyuemen.push(address(c));
        }
    }

    function withdraw() external payable {
        for (uint i = 0; i < heyuemen.length; i++) {
            bot ziheyue = bot(heyuemen[i]);
            if (Dragon.balanceOf(heyuemen[i]) > 0) {
                ziheyue.tixian();
            }
        }
    }
}
