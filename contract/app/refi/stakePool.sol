// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

abstract contract Pool is Ownable {
	IERC20 public REFI;
	IERC20 public REFI_LP;

	// global stats
	bool claimEnable = true;

	uint256 totalStaked;
	uint256 totalClaimed;

	// user stats
	mapping(address => uint256) public staked;
	mapping(address => uint256) public claimed;
	mapping(address => uint256) public unClaim;

	constructor(address refi, address refiLp) {
		REFI_LP = IERC20(refiLp);
		REFI = IERC20(refi);
	}

	function stake(uint256 _num) public {
		address user = msg.sender;
		uint256 numBefore = REFI_LP.balanceOf(address(this));
		REFI_LP.transferFrom(user, address(this), _num);
		uint256 numAfter = REFI_LP.balanceOf(address(this));
		uint256 num = numAfter - numBefore;
		staked[user] += num;
		totalStaked += num;
		addHolder(user);

		calReward();
	}

	function claim() public {
		address user = msg.sender;
		uint256 num = unClaim[user];
		if (num > 0) {
			claimed[user] += num;
			totalClaimed += num;
			unClaim[user] = 0;
			REFI.transfer(user, num);
		}

		calReward();
	}

	function unStake(uint256 _num) public {
		address user = msg.sender;
		uint256 num = staked[user];
		if (_num > num) {
			_num = num;
		}
		if (_num > 0) {
			staked[user] -= _num;
			totalStaked -= _num;
			REFI_LP.transfer(user, _num);
		}

		calReward();
	}

	address[] public stakers;
	mapping(address => uint256) public stakerIndex;

	function addHolder(address adr) private {
		if (0 == stakerIndex[adr]) {
			if (0 == stakers.length || stakers[0] != adr) {
				uint256 size;
				assembly {
					size := extcodesize(adr)
				}
				if (size > 0) {
					return;
				}
				stakerIndex[adr] = stakers.length;
				stakers.push(adr);
			}
		}
	}

	uint256 public unCalrewards;

	function addRewards(uint256 _num) public {
		uint256 numBefore = REFI.balanceOf(address(this));
		REFI_LP.transferFrom(msg.sender, address(this), _num);
		uint256 numAfter = REFI.balanceOf(address(this));

		uint256 addNum = numAfter - numBefore;
		unCalrewards += addNum;
		calReward();
	}

	uint256 public currentIndex;
	uint256 public lasttime;
	uint256 public gasForReward = 1000000;
	uint256 public RewardCondition = 1 ether;

	function calReward() public {
		if (unCalrewards < RewardCondition) {
			return;
		}
		address shareHolder;
		uint256 shareholderCount = stakers.length;
		uint256 gasUsed = 0;
		uint256 iterations = 0;
		uint256 gasLeft = gasleft();

		while (gasUsed < gasForReward && iterations < shareholderCount) {
			if (currentIndex >= shareholderCount) {
				currentIndex = 0;
			}
			shareHolder = stakers[currentIndex];
			uint256 stakednum = staked[shareHolder];
			if (stakednum > 0) {
				uint256 reward = (unCalrewards * stakednum) / totalStaked;
				unClaim[shareHolder] += reward;
				unCalrewards -= reward;
			}
			gasUsed = gasUsed + (gasLeft - gasleft());
			gasLeft = gasleft();
			currentIndex++;
			iterations++;
		}
		lasttime = block.timestamp;
	}

	receive() external payable {
		calReward();
	}

	function setStakeEnable(bool enable) external onlyOwner {
		claimEnable = enable;
	}

	function setRewardGas(uint256 rewardGas) external onlyOwner {
		require(rewardGas >= 200000 && rewardGas <= 2000000, "200000-2000000");
		gasForReward = rewardGas;
	}

	function setRewardCondition(uint256 condition) external onlyOwner {
		RewardCondition = condition;
	}

	function withDrawToken(address tokenAddr) external onlyOwner {
		uint256 token_num = IERC20(tokenAddr).balanceOf(address(this));
		IERC20(tokenAddr).transfer(msg.sender, token_num);
	}

	function withDrawEth() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}

contract REFIPOOl is Pool {
	constructor()
		Pool(0x2bf945a83d4DAB2101dB95F1Cb0CA54bfa67aB53, 0x2fd7f812Fc9602d10942A274a02601CE1Dd850Ef)
	{}
}
