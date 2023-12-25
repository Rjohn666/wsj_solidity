// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function name() external view returns (string memory);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
	function factory() external pure returns (address);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		address msgSender = msg.sender;
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract TokenDistributor {
	constructor(address token) {
		IERC20(token).approve(msg.sender, uint(~uint256(0)));
	}
}

abstract contract AbsToken is IERC20, Ownable {
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal;
	address DEAD = 0x000000000000000000000000000000000000dEaD;

	mapping(address => bool) public _feeWhiteList;
	mapping(address => bool) public _swapPairList;
	mapping(address => bool) public _swapRouters;

	uint256 holdLimit = 166 ether;
	mapping(address => bool) public excludeHolder;

	address public immutable _mainPair;
	ISwapRouter public immutable _swapRouter;

	address fundAddress;
	bool private inSwap;

	IERC20 public USDT;

	modifier lockTheSwap() {
		inSwap = true;
		_;
		inSwap = false;
	}
	TokenDistributor public token_distributor;

	constructor(
		string memory Name,
		string memory Symbol,
		uint8 Decimals,
		uint256 Supply,
		address usdtAddress,
		address routerAddress,
		address ReceiveAddress,
		address FundAddress
	) {
		_name = Name;
		_symbol = Symbol;
		_decimals = Decimals;
		_tTotal = Supply * 10 ** _decimals;
		_balances[ReceiveAddress] = _tTotal;
		emit Transfer(address(0), ReceiveAddress, _tTotal);

		fundAddress = FundAddress;
		ISwapRouter swapRouter = ISwapRouter(routerAddress);
		_swapRouter = swapRouter;
		_allowances[address(this)][address(swapRouter)] = MAX;

		_allowances[fundAddress][address(swapRouter)] = MAX;
		_swapRouters[address(swapRouter)] = true;

		address usdtPair;
		usdtPair = ISwapFactory(swapRouter.factory()).createPair(usdtAddress, address(this));
		_swapPairList[usdtPair] = true;
		_mainPair = usdtPair;

		USDT = IERC20(usdtAddress);
		USDT.approve(address(swapRouter), MAX);

		_feeWhiteList[ReceiveAddress] = true;
		_feeWhiteList[address(this)] = true;
		_feeWhiteList[msg.sender] = true;
		_feeWhiteList[address(0)] = true;
		_feeWhiteList[DEAD] = true;

		excludeHolder[DEAD] = true;
		excludeHolder[ReceiveAddress] = true;
		excludeHolder[address(this)] = true;
		excludeHolder[msg.sender] = true;
		excludeHolder[address(0)] = true;
		excludeHolder[DEAD] = true;
		excludeHolder[address(swapRouter)] = true;
		excludeHolder[usdtPair] = true;

		token_distributor = new TokenDistributor(usdtAddress);
	}

	function symbol() external view override returns (string memory) {
		return _symbol;
	}

	function name() external view override returns (string memory) {
		return _name;
	}

	function decimals() external view override returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override returns (bool) {
		_transfer(sender, recipient, amount);
		if (_allowances[sender][msg.sender] != MAX) {
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
		}
		return true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "approve from the zero address");
		require(spender != address(0), "approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		uint256 balance = _balances[from];
		require(balance >= amount, "Insufficient balance");

		bool takeFee;
		if (_swapPairList[from] || _swapPairList[to]) {
			if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
				takeFee = true;
			}
		}
		_tokenTransfer(from, to, amount, takeFee);
	}

	function _takeTransfer(address sender, address to, uint256 tAmount) private {
		if (!excludeHolder[to]) {
			require(_balances[to] + tAmount <= holdLimit, "Hold limit exceeded");
		}
		_balances[to] = _balances[to] + tAmount;
		emit Transfer(sender, to, tAmount);
	}

	uint256 buyFee = 30;
	uint256 sellFeeForReturn = 480;
	uint256 sellFeeForFund = 10;

	function _tokenTransfer(
		address sender,
		address recipient,
		uint256 tAmount,
		bool takeFee
	) private {
		_balances[sender] -= tAmount;
		uint256 feeAmount;
		if (takeFee) {
			// buy
			if (_swapPairList[sender]) {
				uint256 buyFeeAmount = (tAmount * buyFee) / 1000;
				feeAmount += buyFeeAmount;
				_takeTransfer(sender, address(this), buyFeeAmount);
			}
			// sell
			else if (_swapPairList[recipient]) {
				uint256 FeeForReturnAmount = (tAmount * sellFeeForReturn) / 1000;
				uint256 FeeForFundAmount = (tAmount * sellFeeForFund) / 1000;
				feeAmount += FeeForReturnAmount + FeeForFundAmount;
				_takeTransfer(sender, address(this), FeeForReturnAmount);
				_takeTransfer(sender, fundAddress, FeeForFundAmount);
			}

			uint256 contract_balance = balanceOf(address(this));
			bool need_sell = contract_balance >= numTokensSellToFund;
			if (need_sell && !inSwap && _swapPairList[recipient]) {
				SwapTokenToFund(numTokensSellToFund);
			}
		}
		_takeTransfer(sender, recipient, tAmount - feeAmount);
	}

	uint256 public numTokensSellToFund = 10 * 10 ** 18;

	function SwapTokenToFund(uint256 amount) private lockTheSwap {
		uint256 half = amount / 2;
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = address(USDT);
		_swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			half,
			0,
			path,
			address(token_distributor),
			block.timestamp
		);

		uint256 swapBalance = USDT.balanceOf(address(token_distributor));
		USDT.transferFrom(address(token_distributor), address(this), swapBalance);

		_swapRouter.addLiquidity(
			address(this),
			address(USDT),
			half,
			swapBalance,
			0,
			0,
			fundAddress,
			block.timestamp
		);
	}

	function withDrawToken(address tokenAddr) external onlyOwner {
		uint256 token_num = IERC20(tokenAddr).balanceOf(address(this));
		IERC20(tokenAddr).transfer(msg.sender, token_num);
	}

	function withDrawEth() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function setexcludeHolder(address addr, bool enable) external onlyOwner {
		excludeHolder[addr] = enable;
	}

	function batchSetexcludeHolder(address[] memory addr, bool enable) external onlyOwner {
		for (uint i = 0; i < addr.length; i++) {
			excludeHolder[addr[i]] = enable;
		}
	}

	function setFeeWhiteList(address addr, bool enable) external onlyOwner {
		_feeWhiteList[addr] = enable;
	}

	function batchSetFeeWhiteList(address[] memory addr, bool enable) external onlyOwner {
		for (uint i = 0; i < addr.length; i++) {
			_feeWhiteList[addr[i]] = enable;
		}
	}

	function setFundAddress(address newfund) external onlyOwner {
		fundAddress = newfund;
		_feeWhiteList[newfund] = true;
		excludeHolder[newfund] = true;
	}

	function setHoldLimit(uint256 lim) external onlyOwner {
		holdLimit = lim;
	}

	function setFee(
		uint256 _buyFee,
		uint256 _sellFeeForReturn,
		uint256 _sellFeeForFund
	) external onlyOwner {
		buyFee = _buyFee;
		sellFeeForReturn = _sellFeeForReturn;
		sellFeeForFund = _sellFeeForFund;
	}

	receive() external payable {}
}

contract CDNs is AbsToken {
	constructor()
		AbsToken(
			"CDNs",
			"CDNs",
			18,
			21000000,
			0x2bf945a83d4DAB2101dB95F1Cb0CA54bfa67aB53,
			0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
			0x3A9fC286AA956C38d8C76AA4805bE50C23D41995,
			0x3A9fC286AA956C38d8C76AA4805bE50C23D41995
		)
	{}
}
