// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    uint256 maxSupply = 3456000000 * 10 ** 18;
    mapping(address => uint8) public minted;
    uint256 private last_mint_time;
    uint256 public mint_amount = 100000 * 10 ** 18;
    uint public Interval_time = 10;
    uint public mint_price = 0.003456 * 10 ** 18;
    bool public is_active = true;

    constructor() ERC20("ImmuneCell", "IC") {}

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function mint() public payable {
        uint256 ts = block.timestamp;
        require(is_active, "n");
        // require(minted[msg.sender]<mint_times,"Mint limited");
        require(msg.value >= mint_price, "IB");
        require(totalSupply() + mint_amount <= maxSupply);
        require(ts - last_mint_time > Interval_time, "Unarrived time interval");
        _mint(msg.sender, mint_amount);
        if (msg.value >= 0) {
            payable(owner()).transfer(msg.value);
        }
        last_mint_time = ts;
        minted[msg.sender] += 1;
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
}
