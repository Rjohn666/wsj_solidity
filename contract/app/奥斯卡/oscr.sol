// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract SellBot is Ownable {
    IERC20 public  TOKEN = IERC20(0x2bf945a83d4DAB2101dB95F1Cb0CA54bfa67aB53);
    uint256 public totalSupply = 21000;
    uint256 public totalBoughtNum;

    uint256 public SellPrice = 1 ether;	
	uint256 public WhitelistSellPrice = 800 ether;	
    uint256 public limitPerWallet = 30;
    
    mapping(address => uint256) boughtNum;
    mapping(address => uint256) PayedNum;

    uint public STATUS=1;
    uint256 public OpenTime=1673280000;


	mapping(address => bool) public whitelist;


    function buy(uint256 _num) public {
        require(STATUS==2,"not open");
		uint256 _price;
		_price = SellPrice * _num;
		exOrder(msg.sender, _price, _num);
        
    }

	function whiteListBuy(uint256 _num) public {
        require(STATUS==1,"not open");
		uint256 _price;
		_price = WhitelistSellPrice * _num;
		exOrder(msg.sender, _price, _num);
        
    }

	function exOrder(address buyer,uint256 _price,uint256 _num) private {
		require(_num > 0,"num must be greater than 0");
        require(totalBoughtNum + _num <= totalSupply,"Inadequate supply");
        require(boughtNum[buyer] + _num <= limitPerWallet,"Exceed the limit");

		uint256 balanceBefore = TOKEN.balanceOf(address(this));
        TOKEN.transferFrom(buyer, address(this), _price);
        require(TOKEN.balanceOf(address(this)) - balanceBefore >= _price,"Error payment amount");

        addHolder(buyer);
        boughtNum[buyer] += _num;
        totalBoughtNum += _num;

        PayedNum[buyer] += _price;
	}


    function getAddressStatus(address addr) view public returns(uint256 _bought,uint256 _payed) {
        _bought = boughtNum[addr];
        _payed = PayedNum[addr];
    }
    

    address[] public buyers;
	mapping(address => uint256) public buyerIndex;

	function getBuyersLength() public view returns (uint256 len){
		len = buyers.length;
	}

	function addHolder(address adr) private {
		if (0 == buyerIndex[adr]) {
			if (0 == buyers.length || buyers[0] != adr) {
				uint256 size;
				assembly {
					size := extcodesize(adr)
				}
				if (size > 0) {
					return;
				}
				buyerIndex[adr] = buyers.length;
				buyers.push(adr);
			}
		}
	}

    function setTime(uint256 _ts) onlyOwner public {
        OpenTime = _ts;
    }

    function setStatus(uint _status) onlyOwner public {
		STATUS = _status;
    }

    function setQkcPrice(uint256 _price) onlyOwner public {
        SellPrice = _price;
    }

    function setLimit(uint256 _lim) onlyOwner public {
        limitPerWallet = _lim;
    }

    }
