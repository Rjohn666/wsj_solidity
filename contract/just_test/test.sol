// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Test {
    uint256 public _sellFeeForFund = 30;
    uint256 public _sellFeeForMoss = 200;
    uint256 public _sellFeeForW3n = 80;



    function getBuyAmout(uint256 num) public view returns (uint256 sellFeeForMoss ,uint256 sellFeeForW3n) {
        uint256 totalFee = _sellFeeForMoss + _sellFeeForW3n;
        sellFeeForMoss =  num * _sellFeeForMoss / totalFee;
        sellFeeForW3n =  num * _sellFeeForW3n / totalFee;
    }
}
