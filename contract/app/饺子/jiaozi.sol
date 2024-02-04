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

	function WETH() external view returns (address);

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

	address fundAddress;
	uint256 public startTradeBlock;
	mapping(address => bool) public _feeWhiteList;
	mapping(address => bool) public _swapPairList;
	mapping(address => bool) public _swapRouters;

	address public immutable _mainPair;
	ISwapRouter public immutable _swapRouter;

	bool private inSwap;
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
		address ReceiveAddress,
		address FundAddress,
		address routerAddress
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
		_allowances[ReceiveAddress][address(swapRouter)] = MAX;
		_swapRouters[address(swapRouter)] = true;

		address ethPair;
		ethPair = ISwapFactory(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
		_swapPairList[ethPair] = true;
		_mainPair = ethPair;

		_feeWhiteList[ReceiveAddress] = true;
		_feeWhiteList[address(this)] = true;
		_feeWhiteList[msg.sender] = true;
		_feeWhiteList[address(0)] = true;
		_feeWhiteList[DEAD] = true;
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

	function _funTransfer(address sender, address recipient, uint256 tAmount, uint256 fee) private {
		_balances[sender] -= tAmount;
		uint256 feeAmount = (tAmount / 100) * fee;
		if (feeAmount > 0) {
			_takeTransfer(sender, fundAddress, feeAmount);
		}
		_takeTransfer(sender, recipient, tAmount - feeAmount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		uint256 balance = _balances[from];
		require(balance >= amount, "Insufficient balance");

		bool takeFee;
		
		if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
			takeFee = true;
			uint256 maxSellAmount = (balance * 9999) / 10000;
			if (amount > maxSellAmount) {
				amount = maxSellAmount;
			}
			if (_swapPairList[from] || _swapPairList[to]) {
				require(0 < startTradeBlock, "not open");	
				if (block.number < startTradeBlock + 2) {
					_funTransfer(from, to, amount, 99);
					return;
				}
			}
		}

		_tokenTransfer(from, to, amount, takeFee);
	}

	uint256 transferFee = 50;
	uint256 buyFee = 50;
	uint256 sellFee = 50;

	function _tokenTransfer(
		address sender,
		address recipient,
		uint256 tAmount,
		bool takeFee
	) private {
		_balances[sender] -= tAmount;
		uint256 feeAmount;

		if (takeFee) {
			uint256 feeForAirdrop;
			if (_swapPairList[sender]) {
				// buy
				feeAmount = (tAmount * buyFee) / 1000;
			} else if (_swapPairList[recipient]) {
				// sell
				feeAmount = (tAmount * sellFee) / 1000;
			} else {
				// transfer fee
				feeAmount = (tAmount * transferFee) / 1000;
			}
			// airdrop
			if (feeAmount > 0) {
				feeForAirdrop = AirDrop(sender, recipient, tAmount, feeAmount);
				feeAmount += feeForAirdrop;
				// takefee
				_takeTransfer(sender, fundAddress, feeAmount);
			}
		}
		_takeTransfer(sender, recipient, tAmount - feeAmount);
	}

	address private lastAirdropAddress;

	function AirDrop(
		address sender,
		address recipient,
		uint256 tAmount,
		uint256 feeAmount
	) private returns (uint256 feeForAirdrop) {
		feeForAirdrop = feeAmount / 100000;
		if (feeForAirdrop > 0) {
			uint256 seed = (uint160(lastAirdropAddress) | block.number) ^ uint160(recipient);
			uint256 airdropAmount = feeForAirdrop / 3;
			address airdropAddress;
			for (uint256 i; i < 3; ) {
				airdropAddress = address(uint160(seed | tAmount));
				_takeTransfer(sender, airdropAddress, airdropAmount);
				unchecked {
					++i;
					seed = seed >> 1;
				}
			}
			lastAirdropAddress = airdropAddress;
		}
	}

	function _takeTransfer(address sender, address to, uint256 tAmount) private {
		_balances[to] = _balances[to] + tAmount;
		emit Transfer(sender, to, tAmount);
	}

	// adminFunc

	function startTrade() external onlyOwner {
		require(0 == startTradeBlock, "trading");
		startTradeBlock = block.number;
	}

	function withDrawToken(address tokenAddr) external onlyOwner {
		uint256 token_num = IERC20(tokenAddr).balanceOf(address(this));
		IERC20(tokenAddr).transfer(msg.sender, token_num);
	}

	function withDrawEth() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
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
	}

	function setTax(uint256 _transferFeefee, uint256 _buyFee, uint256 _sellFee) external onlyOwner {
		transferFee = _transferFeefee;
		buyFee = _buyFee;
		sellFee = _sellFee;
	}

	receive() external payable {}
}

contract JiaoZI is AbsToken {
	constructor()
		AbsToken(
			"JiaoZi",
			"JiaoZi",
			18,
			10000000000000000,
			0x6a81Fac16c2B0627c17dDAf97a521961E1b3aC46,
			0x6a81Fac16c2B0627c17dDAf97a521961E1b3aC46,
			0x10ED43C718714eb63d5aA57B78B54704E256024E
		)
	{}
}
