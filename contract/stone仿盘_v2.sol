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
    uint256 private MINT_THRESHOLD = 20;
    uint256 private mintCount;
    uint256 private prizePool;
    mapping(uint256 => address) private mintParticipants;

    mapping(address => bool) blacklist;

    constructor() ERC20("ImmuneCell", "IC") {
        _mint(msg.sender, 691200000 * 10 ** 18);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function mint() public payable {
        uint256 ts = block.timestamp;
        require(is_active, "Mint event has not started yet");
        require(msg.sender == tx.origin, "Contract minting is not allowed");
        require(msg.value >= mint_price, "ETH value sent is not correct");
        require(
            totalSupply() + mint_amount <= maxSupply,
            "Mint would exceed max supply"
        );
        if (ts - last_mint_time > Interval_time) {
            _mint(msg.sender, mint_amount);
            last_mint_time = ts;
            payable(owner()).transfer(msg.value);
        } else {
            payable(msg.sender).transfer(calculatePercentage(50));
            payable(owner()).transfer(calculatePercentage(25));
            mintParticipants[mintCount] = msg.sender;
            mintCount += 1;

            if (mintCount >= MINT_THRESHOLD) {
                uint8 winnerIndex = get_random_int(uint8(MINT_THRESHOLD));
                address winner = mintParticipants[winnerIndex];
                payable(winner).transfer(address(this).balance);
                mintCount = 0;
                prizePool = 0;
            }
        }
    }

    function check_mint_amount() private {
        uint256 supply = totalSupply();
        if (supply > 1728000000 * 10 ** 18 && supply < 2592000000 * 10 ** 18) {
            mint_amount = 50000 * 10 ** 18;
            MINT_THRESHOLD = 15;
        } else if (supply > 2592000000 * 10 ** 18) {
            mint_amount = 25000 * 10 ** 18;
            MINT_THRESHOLD = 10;
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

    function addBlacklistedAddress(address addr) public onlyOwner {
        blacklist[addr] = true;
    }

    function removeBlacklistedAddress(address addr) public onlyOwner {
        blacklist[addr] = false;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(!blacklist[msg.sender], "blacked");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(!blacklist[sender], "blacked");
        return super.transferFrom(sender, recipient, amount);
    }

    // 记得改权限
    function get_random_int(uint8 limit) private view returns (uint8) {
        bytes32 callHash = keccak256(
            abi.encodePacked(msg.sig, block.number, block.timestamp, msg.sender)
        );
        uint256 hashAsInteger = uint256(callHash);
        return uint8(hashAsInteger) % limit;
    }

    function calculatePercentage(
        uint256 percentage
    ) internal returns (uint256) {
        require(percentage <= 100, "Invalid percentage"); // 确保百分比不超过100

        uint256 percentageAmount = msg.value.mul(percentage).div(100);
        return percentageAmount;
    }
}
