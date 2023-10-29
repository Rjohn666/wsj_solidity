// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CrossChain {
    using SafeMath for uint256;
    // 目标地址
    address payable public targetAddress;
    address public master_coin;
    address public son_coin;
    address private owner;
    address public blackhole = payable(address(1));
    uint256 public fee;
    bool public is_cross_open = true;
    uint256 master_rate = 185.7142857143 * 10 ** 12; // 将母币的兑换比率乘以 10**12
    uint256 son_rate = 1.3 * 10 ** 3; // 将子币的兑换比率乘以 10**3

    event crossed(uint256 zm_amount, address from_address);

    modifier opening() {
        require(is_cross_open, "cross not open");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier cross_fee() {
        require(msg.value >= fee, "Insufficient balance");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    // 更改开关状态
    function changeOpen() external onlyOwner {
        if (is_cross_open) {
            is_cross_open = false;
        } else {
            is_cross_open = true;
        }
    }

    // 更改接受人地址
    function changetargetAddress(address _targetAddress) external onlyOwner {
        require(
            _targetAddress != address(0),
            "New targetAddress is the zero address"
        );
        targetAddress = payable(_targetAddress);
    }

    // 更改手续费
    function changeFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function change_master_coin(address _master_coin) external onlyOwner {
        master_coin = _master_coin;
    }

    function change_son_coin(address _son_coin) external onlyOwner {
        son_coin = _son_coin;
    }

    constructor() {
        owner = msg.sender;
        targetAddress = payable(msg.sender);
        master_coin = address(0x44ac762dB7E7170A48e895fDC81Bc2e81c188888);
        son_coin = address(0x5131E9b74CA4C6c2Dd0a48f72757d3c75E7c3e7a);
        fee = 0.1 * 10 ** 18;
    }

    // 查询母币跨链所需费用
    function query_master_cross_need(
        uint256 zm_amount
    ) public pure returns (uint256 master_amount) {
        master_amount = master_amount = zm_amount / 100;
    }

    // 查询双币跨链所需费用
    function query_cross_need(
        uint256 zm_amount
    ) public view returns (uint256 master_amount, uint256 son_amount) {
        // 判断是否能被130整除
        if (zm_amount % 130000000000000000000 == 0) {
            // 返回整数0.7
            master_amount =
                (zm_amount / 130000000000000000000) *
                700000000000000000;
        } else {
            // 有余数，放大比例返回
            master_amount = (zm_amount * 10 ** 12) / master_rate;
        }
        son_amount = (zm_amount * 10 ** 3) / son_rate;
    }

    // 母币跨链
    function master_cross(uint256 zm_amount) external payable cross_fee {
        uint256 master_amount;
        master_amount = query_master_cross_need(zm_amount);

        // 接受手续费
        targetAddress.transfer(msg.value);

        // 接收主币
        IERC20 tokenA = IERC20(master_coin);
        require(
            tokenA.transferFrom(msg.sender, blackhole, master_amount),
            "Master_coin transfer failed"
        );
        emit crossed(zm_amount, msg.sender);
    }

    // 双币跨链
    function cross(uint256 zm_amount) external payable cross_fee {
        uint256 master_amount;
        uint256 son_amount;

        (master_amount, son_amount) = query_cross_need(zm_amount);
        // 接受手续费
        targetAddress.transfer(msg.value);

        // 接收主币
        IERC20 tokenA = IERC20(master_coin);
        require(
            tokenA.transferFrom(msg.sender, blackhole, master_amount),
            "Master_coin transfer failed"
        );

        // 接收主币
        IERC20 tokenB = IERC20(son_coin);
        require(
            tokenB.transferFrom(msg.sender, blackhole, son_amount),
            "Son_coin transfer failed"
        );
        emit crossed(zm_amount, msg.sender);
    }
}
