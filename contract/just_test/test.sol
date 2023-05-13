// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract test {
    uint256 master_rate = 185.7142857143 * 10 ** 12;
    uint256 son_rate = 1.3 * 10 ** 3;

    function query_cross_need(
        uint256 zm_amount
    ) public view returns (uint256 master_amount, uint256 son_amount) {
        // 判断是否能被130整除
        if (zm_amount % 130000000000000000000 == 0) {
            // 返回整数0.7
            master_amount =
                (zm_amount / 130000000000000000000) *
                700000000000000000;
        } else {
            // 有余数，放大比例返回
            master_amount = (zm_amount * 10 ** 12) / master_rate;
        }
        son_amount = (zm_amount * 10 ** 3) / son_rate;
    }
}
