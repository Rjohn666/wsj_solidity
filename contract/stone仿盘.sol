// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    uint256 maxSupply = 100000000 * 10**decimals();
    mapping(address => bool) public  minted;
    uint256 private last_mint_time;
    uint256 private mint_amount = 1000 * 10**decimals();
    uint public Interval_time = 5;

    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }

    function mint() public {
        require(!minted[msg.sender],"Address Minted");
        require(block.timestamp - last_mint_time > Interval_time,"Time is not up");
        require(totalSupply()+mint_amount < maxSupply);
        _mint(msg.sender, mint_amount);
        last_mint_time = block.timestamp;
        minted[msg.sender] = true;
    }

    // function check_mint_amount() private {
    //     uint256 supply = totalSupply();
    //     if (supply > 20000000 * 10**decimals())
    //     {
    //         mint_amount = 500 * 10**decimals();
    //     }
    //     else if

    // }

    function change_interval(uint new_interval) onlyOwner public {
        Interval_time = new_interval;
    }

}
