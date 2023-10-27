// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// IERC20 代币协议规范，任何人都可以发行代币，只要编写的智能合约里包含以下指定方法，在公链上，就被认为是一个代币合约
interface IERC20 {
    //精度，表明代币的精度是多少，即小数位有多少位
    function decimals() external view returns (uint8);

    //代币符号，一般看到的就是代币符号
    function symbol() external view returns (string memory);

    //代币名称，一般是具体的有意义的英文名称
    function name() external view returns (string memory);

    //代币发行的总量，现在很多代币发行后总量不会改变，有些挖矿的币，总量会随着挖矿产出增多，有些代币的模式可能会通缩，即总量会变少
    function totalSupply() external view returns (uint256);

    //某个账户地址的代币余额，即某地址拥有该代币资产的数量
    function balanceOf(address account) external view returns (uint256);

    //转账，可以将代币转给别人，这种情况是资产拥有的地址主动把代币转给别人
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    //授权额度，某个账户地址授权给使用者使用自己代币的额度，一般是授权给智能合约，让智能合约划转自己的资产
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    //授权，将自己的代币资产授权给其他人使用，一般是授权给智能合约，请尽量不要授权给不明来源的智能合约，有可能会转走你的资产，
    function approve(address spender, uint256 amount) external returns (bool);

    //将指定账号地址的资产转给指定的接收地址，一般是智能合约调用，需要搭配上面的授权方法使用，授权了才能划转别人的代币资产
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //转账事件，一般区块浏览器是根据该事件来做代币转账记录，事件会存在公链节点的日志系统里
    event Transfer(address indexed from, address indexed to, uint256 value);
    //授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Swap 路由接口，实际上接口方法比这里写的还要更多一些，本代币合约里只用到以下方法
interface ISwapRouter {
    //路由的工厂方法，用于创建代币交易对
    function factory() external pure returns (address);

    //将指定数量的代币path[0]兑换为另外一种代币path[path.length-1]，支持手续费滑点
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    //添加代币 tokenA、tokenB 交易对流动性
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
    //创建代币 tokenA、tokenB 的交易对，也就是常说的 LP，LP 交易对本身也是一种代币
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface ISwapPair {
    function sync() external;
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        //合约创建者拥有权限，也可以填写具体的地址
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    //查看权限在哪个地址上
    function owner() public view returns (address) {
        return _owner;
    }

    //拥有权限才能调用
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //放弃权限
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    //转移权限
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//这个合约用于暂存USDT，用于回流和营销钱包，分红
contract TokenDistributor {
    //构造参数传USDT合约地址
    constructor(address tokenA) {
        //将暂存合约的USDT授权给合约创建者，这里的创建者是代币合约，授权数量为最大整数
        IERC20(tokenA).approve(msg.sender, uint(~uint256(0)));
    }
}

abstract contract AbsToken is IERC20, Ownable {
    //用于存储每个地址的余额数量
    mapping(address => uint256) private _balances;
    //存储授权数量，资产拥有者 owner => 授权调用方 spender => 授权数量
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name; //名称
    string private _symbol; //符号
    uint8 private _decimals; //精度
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal; //总量
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    // 团队地址
    address private team_address;
    address private fund_address;

    //ido参数
    bool ido_opening;
    uint256 private numforpresale = 200 * 10 ** 18;
    uint256 private priceforpresale = 200 * 10 ** 6;
    address private USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    mapping (address=>bool) private bought;

    uint256 startTradeBlock;
    // 交易所需参数
    mapping(address => bool) private _feeWhiteList;
    ISwapRouter public _router;
    TokenDistributor public token_distributor;
    address private mainPair;
    bool in_swap;
    modifier lock_swap() {
        in_swap = true;
        _;
        in_swap = false;
    }
    uint256 private NumSelltoFund;
    
    constructor(string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply
        ) 
        {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        team_address = msg.sender;
        fund_address = address(0x3C50d3a325aA9968Ae66b4ED2354D3570f1D9309);
        //总量
        _tTotal = Supply * 10 ** _decimals;
        //初始代币团队预留50%
        // 新建合约收u
        token_distributor = new TokenDistributor(USDC);
        _balances[team_address] = _tTotal * 50 /100;
        _balances[address(token_distributor)] = _tTotal* 50 /100;
        emit Transfer(address(0), team_address, _tTotal * 50 /100);
        emit Transfer(address(0), address(token_distributor), _tTotal * 50 /100);

        // 创建池子
        _router = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        mainPair = ISwapFactory(_router.factory()).createPair(address(this),USDC);

        // 授权代币给路由合约
        _allowances[address(this)][address(_router)] = MAX;
        IERC20(USDC).approve(address(_router), MAX);
        _allowances[msg.sender][address(_router)] = MAX;

        // 授权白名单
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(_router)] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(token_distributor)] = true;

    
        NumSelltoFund = _tTotal / 10000;
    }

    function buy() public {
        require(ido_opening,"Not Open");
        require(!bought[msg.sender],"Already bought");
        require(balanceOf(address(token_distributor))>=numforpresale,"Insufficient quantity");
        IERC20(USDC).transferFrom(msg.sender, team_address, priceforpresale*50/100);
        IERC20(USDC).transferFrom(msg.sender, mainPair, priceforpresale*50/100);
        _transfer(address(token_distributor), msg.sender, numforpresale*50/100);
        _transfer(address(token_distributor), mainPair, numforpresale*50/100);
        bought[msg.sender]=true;
        ISwapPair(mainPair).sync();
    }

    function open(bool enable) public onlyOwner {
        ido_opening = enable;
    }

    function _transfer(
        address from, 
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool pay_tax = false;
        // 判断是否交易
        if (from == mainPair || to == mainPair) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                pay_tax = true;
            }
            if (0 == startTradeBlock) {
                require(
                    _feeWhiteList[from] || _feeWhiteList[to],
                    "Trade not start"
                );
                startTradeBlock = block.number;
            }

            // 判断是否卖币
            uint256 contract_balance = balanceOf(address(this));
            bool need_sell = contract_balance >= NumSelltoFund;
            if (need_sell && !in_swap && from != mainPair && startTradeBlock > 0) {
                SwapTokenToFund(contract_balance);
            }
        }
        _tokenTransfer(from, to, amount, pay_tax);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool pay_tax
    ) private {
        _balances[sender] = _balances[sender] - tAmount;

        if(pay_tax){
            if(sender == mainPair){
                uint256 buyfee;
                buyfee = tAmount * 3 / 100;
                // 销毁1.5%，团队留1.5%
                _takeTransfer(sender,DEAD,buyfee* 50/100);
                _takeTransfer(sender,address(this),buyfee* 50/100);
                tAmount = tAmount - buyfee;
            }else{
            // 卖出
                uint256 sellfee;
                sellfee = tAmount * 5 / 100;
                // 销毁2%，团队留3%
                _takeTransfer(sender,DEAD,sellfee* 40/100);
                _takeTransfer(sender,address(this),sellfee* 60/100);
                tAmount = tAmount - sellfee;
            }
        }

        _takeTransfer(sender, recipient, tAmount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function SwapTokenToFund(uint256 amount) private lock_swap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(token_distributor),
            block.timestamp
        );
        uint256 usdc_amount;
        usdc_amount = IERC20(USDC).balanceOf(address(token_distributor));
        IERC20(USDC).transferFrom(
            address(token_distributor),
            fund_address,
            usdc_amount
        );
    }

    function set_whitelist(address _add,bool enable)public onlyOwner{
        _feeWhiteList[_add] = enable;
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

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //表示能接收主链币
    receive() external payable {}

}


contract wsjtoken is AbsToken {
    constructor()
        AbsToken(
            //名称
            "IDOBI_V2",
            //符号
            "IBV2",
            //精度
            18,
            //总量
            1000000
        ){}

}