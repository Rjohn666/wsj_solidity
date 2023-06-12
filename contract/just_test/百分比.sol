// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    // mint
    uint256 maxSupply = 3456000000 * 10 ** 18;
    // mapping(address => uint8) public  minted;
    uint256 private last_mint_time;
    uint256 public mint_amount = 100000 * 10 ** 18;
    uint public Interval_time = 10;
    uint public mint_price = 0.0023456 * 10 ** 18;
    bool public is_active = true;

    // pool
    uint256 private MINT_THRESHOLD = 10;
    uint256 private mintCount;
    uint256 private prizePool;
    mapping(uint256 => address) private mintParticipants;

    constructor() ERC20("ImmuneCell", "IC") {}

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function check_mint_amount() private {
        uint256 supply = totalSupply();
        if (supply > 1728000000 * 10 ** 18 && supply < 2592000000 * 10 ** 18) {
            mint_amount = 50000 * 10 ** 18;
        } else if (supply > 2592000000 * 10 ** 18) {
            mint_amount = 25000 * 10 ** 18;
        }
    }

    function update_interval(uint new_interval) public onlyOwner {
        Interval_time = new_interval;
    }

    function update_price(uint new_price) public onlyOwner {
        mint_price = new_price;
    }

    // function update_mint_times(uint new_times) onlyOwner public {
    //     mint_times = new_times;
    // }

    function update_status() public onlyOwner {
        if (is_active) {
            is_active = false;
        } else {
            is_active = true;
        }
    }

    function get_random_int(uint8 limit) public view returns (uint8) {
        bytes32 callHash = keccak256(
            abi.encodePacked(msg.sig, block.number, block.timestamp, msg.sender)
        );
        uint256 hashAsInteger = uint256(callHash);
        return uint8(hashAsInteger) % limit;
    }

    function calculatePercentage(
        uint256 percentage
    ) external payable returns (uint256) {
        require(percentage <= 100, "Invalid percentage"); // 确保百分比不超过100

        uint256 percentageAmount = msg.value.mul(percentage).div(100);
        return percentageAmount;
    }
}
