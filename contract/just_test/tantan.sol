// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ISwapRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function feeTo() external view returns (address);
}

contract TATANTOKEN is ERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => bool) private has_buyed;
    mapping(address => bool) private tokenHolders;
    mapping(address => bool) private hold_whitelist;
    mapping(address => bool) private trade_whitelist;
    bool public start_trade = false;
    uint256 public startTradeBlock;
    uint256 public buy_price = 0.01 * 10 ** 18;
    uint256 private numberOfTokenHolders;
    uint256 private constant INITIAL_SUPPLY = 10000000000;
    address private blackhole = address(1);
    address private ethPair;
    address private router_address;
    ISwapRouter public uniswapV2Router;
    ISwapFactory public uniswapV2Factory;

    constructor() ERC20("TATAN TOKEN", "TATAN") {
        address _router = address(0xBe4AB2603140F134869cb32aB4BC56d762Ae900B);
        _mint(msg.sender, 1 * 10 ** decimals());
        _mint(address(this), INITIAL_SUPPLY * 10 ** decimals());
        uniswapV2Router = ISwapRouter(_router);
        router_address = _router;
        trade_whitelist[owner()] = true;
        trade_whitelist[address(this)] = true;
        // 持有数量白名单，不受影响
        hold_whitelist[address(this)] = true;
        hold_whitelist[owner()] = true;
        hold_whitelist[_router] = true;
        hold_whitelist[uniswapV2Router.factory()] = true;
        uniswapV2Factory = ISwapFactory(uniswapV2Router.factory());
        ethPair = uniswapV2Factory.createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), _router, INITIAL_SUPPLY * 10 ** decimals());
    }

    function change_trade() public onlyOwner {
        if (start_trade) {
            start_trade = false;
        } else {
            start_trade = true;
            startTradeBlock = block.number;
        }
    }

    // 获取当前持币上限
    function get_limit(
        address recipient
    ) internal view returns (uint256 limit_num) {
        if (hold_whitelist[recipient]) {
            limit_num = INITIAL_SUPPLY * 10 ** decimals();
        }
        if (numberOfTokenHolders < 10000) {
            limit_num = 100000000 * 10 ** decimals();
        } else if (
            numberOfTokenHolders > 5000 && numberOfTokenHolders < 10000
        ) {
            limit_num = 1000000000 * 10 ** decimals();
        } else if (
            numberOfTokenHolders > 10000 && numberOfTokenHolders < 15000
        ) {
            limit_num = 2000000000 * 10 ** decimals();
        } else if (
            numberOfTokenHolders > 15000 && numberOfTokenHolders < 20000
        ) {
            limit_num = 3000000000 * 10 ** decimals();
        } else if (
            numberOfTokenHolders > 20000 && numberOfTokenHolders < 25000
        ) {
            limit_num = 4000000000 * 10 ** decimals();
        } else {
            limit_num = INITIAL_SUPPLY * 10 ** decimals();
        }
    }

    function kill_bot(
        address sender,
        address recipient
    ) internal view returns (bool havedtokill) {
        if (sender == ethPair || recipient == ethPair) {
            if (
                trade_whitelist[sender] == false &&
                trade_whitelist[recipient] == false
            ) {
                require(start_trade, "trade not open");
                if (block.number - startTradeBlock < 1000) {
                    havedtokill = true;
                }
            }
        }
        havedtokill = false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 bot_amount = amount;
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        if (kill_bot(sender, recipient)) {
            amount = SafeMath.div(amount, 100);
            _transfer(sender, blackhole, bot_amount - amount);
        }
        _transfer(sender, recipient, amount);
        // 更新授权额度
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 limit = get_limit(recipient);
        uint256 balance = balanceOf(recipient);
        // 是否大于持币数量
        require(balance + amount <= limit, "amount too big");
        super._transfer(sender, recipient, amount);
        if (!tokenHolders[recipient] && recipient != address(0)) {
            tokenHolders[recipient] = true;
            numberOfTokenHolders += 1;
        }
    }

    function subscribe() public payable {
        require(msg.value >= buy_price, "Insufficient Balance");
        require(has_buyed[msg.sender] == false, "already buyed");
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            100000000 * 10 ** decimals(),
            0,
            0,
            address(this),
            block.timestamp
        );
        // 获取 LP 代币数量
        uint256 lpBalance = IERC20(ethPair).balanceOf(address(this));
        // 将一半的 LP 代币发送给调用者
        IERC20(ethPair).transfer(msg.sender, lpBalance / 2);
        IERC20(ethPair).transfer(blackhole, lpBalance / 2);
        has_buyed[msg.sender] == true;
    }
}
