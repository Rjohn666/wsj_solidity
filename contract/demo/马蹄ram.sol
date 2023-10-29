// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

interface INFT {
    function balanceOf(address who) external view returns (uint256);

    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }

    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes calldata _data
    ) external payable;
}

contract Batcher {
    INFT private constant DCNT =
        INFT(0x8E0DCCa4E6587d2028ed948b7285791269059a62);

    function bulkMint(address[] calldata minter) external {
        uint balance;
        for (uint8 i = 0; i < minter.length; i++) {
            balance = DCNT.balanceOf(minter[i]);

            if (balance == 0) {
                bytes32[] memory proofArray = new bytes32[](1);
                proofArray[0] = bytes32(0x0);
                INFT.AllowlistProof memory proof = INFT.AllowlistProof({
                    proof: proofArray,
                    quantityLimitPerWallet: 1,
                    pricePerToken: 0,
                    currency: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                });

                DCNT.claim(
                    minter[i],
                    1,
                    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                    0,
                    proof,
                    bytes("")
                );
            }
        }
    }
}
