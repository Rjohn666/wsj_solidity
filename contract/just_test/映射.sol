// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract exsample {
    bytes1 public asd;
    address public owner;
    address public haha;

    // 构造函数，部署时接收一个地址作为管理员
    constructor(address owner_address) {
        owner = owner_address;
    }

    modifier isOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // 定义一个映射，地址=》布尔值作为白名单变量
    mapping(address => bool) public whitelist;
    mapping(address => mapping(address => bool)) public Is_friend;

    // 录入地址为白名单
    function set_whitelisthhhhhh(address[] memory add_list) public isOwner {
        for (uint i = 0; i < add_list.length; i++) {
            whitelist[add_list[i]] = true;
        }
    }

    // 查询地址是否为白名单
    function Is_whitelist(address add) public view returns (bool result) {
        result = whitelist[add];
    }

    address payable addr = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

    function pay() public {
        addr.transfer(1);
    }
}
