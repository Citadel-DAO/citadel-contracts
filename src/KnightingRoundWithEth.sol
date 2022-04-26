// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {KnightingRound} from "./KnightingRound.sol";

interface WETH {
    function deposit() external payable;
}

contract KnightingRoundWithEth is KnightingRound {

    function buyEth(
        uint256 _tokenInAmount,
        uint8 _daoId,
        bytes32[] calldata _proof
    ) external payable gacPauseable returns (uint256 tokenOutAmount_) {
        WETH(tokenIn).deposit{value: msg.value}();
        uint256 tokenOutAmount_ = buy(_tokenInAmount, _daoId, _proof);
    }
}
