// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract OskrLaunch is Ownable {


	constructor(){
		whitelist[msg.sender] = true;
	}

    uint256 public totalSupply = 21000;
    uint256 public totalBoughtNum;

    uint256 public SellPrice = 0.06686 ether;	
	uint256 public WhitelistSellPrice = 0.06686 ether;
	uint256[] public wlType = [12];
	uint256[] public plType = [24,48,108];


	mapping(address => bool) public bought;
    mapping(address => uint256) public boughtNum;

    uint public STATUS = 0;
    uint256 public OpenTime= 1705680000;

	mapping(address => bool) public whitelist;

	function getTypes() public view returns (uint256[] memory wl,uint256[] memory pl){
		wl = wlType;
		pl = plType;
	}

	function publicBuy(uint _index) public payable {
		require(STATUS == 2,"NP");
		address buyer = msg.sender;
		require(!bought[buyer],"AB");
		uint256 _num = plType[_index];
		require(_num > 0,"WN");
		require(totalBoughtNum + _num <= totalSupply,"NN");
		uint256 price =  _num * SellPrice;
		require(msg.value >= price,"IB");

		bought[buyer] = true;
		boughtNum[buyer] += _num;
		totalBoughtNum += _num;
		addHolder(buyer);
	}


	function whitelistBuy(uint _index) public payable {


		require(STATUS == 1,"NP");
		address buyer = msg.sender;
		require(whitelist[buyer],"NW");
		require(!bought[buyer],"AB");
		uint256 _num = wlType[_index];
		require(_num > 0,"WN");
		require(totalBoughtNum + _num <= totalSupply,"NN");
		uint256 price =  _num * WhitelistSellPrice;
		require(msg.value >= price,"IB");

		bought[buyer] = true;
		boughtNum[buyer] += _num;
		totalBoughtNum += _num;
		addHolder(buyer);
	}

	function setWl(address addr,bool enable) public onlyOwner{
		whitelist[addr] = enable;
	}

	function batchSetWl(address[] calldata addrs,bool enable) public onlyOwner{
		for (uint i = 0; i < addrs.length; i++) {
			whitelist[addrs[i]] = enable;
		}
	}

	function setTime(uint256 _ts) onlyOwner public {
        OpenTime = _ts;
    }

    function setStatus(uint _status) onlyOwner public {
		STATUS = _status;
    }

	function setPrices(uint256 wl,uint256 pl) onlyOwner public {
		SellPrice = pl;
		WhitelistSellPrice = wl;
    }



	function setTypes(uint256[] calldata _wlType,uint256[] calldata _plType)public onlyOwner{
		wlType = _wlType;
		plType = _plType;
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
	
	function withDarw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

    }
