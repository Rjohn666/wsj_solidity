// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract exsample {
    address public owner;

    // 构造函数，部署时接收一个地址作为管理员
    constructor(address owner_address) {
        owner = owner_address;
    }

    // 修改器，确认是否为owner调用
    modifier isOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // 更改管理员
    function change_owner(address new_owner) public isOwner {
        owner = new_owner;
    }

    // 隐式返回多个值
    function return_many() public view returns (uint num, address add, bool b) {
        num = 1;
        add = owner;
        b = true;
    }

    // 取方法返回值
    function get_return() public view returns (address add) {
        (, add, ) = return_many();
    }
}
