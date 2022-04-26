// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {KnightingRound} from "./KnightingRound.sol";

interface WETH {
    function deposit() external payable;
    function approve(address guy, uint wad) external returns (bool);
}

contract KnightingRoundWithEth is KnightingRound {

    function buyEth(
        uint256 _tokenInAmount,
        uint8 _daoId,
        bytes32[] calldata _proof
    ) external payable gacPausable  returns (uint256 tokenOutAmount_) {
        WETH weth = WETH(address(tokenIn));
        weth.deposit{value: msg.value}();
        weth.approve(address(this), 2**256 - 1);
        tokenOutAmount_ = KnightingRound(
            address(this)
        ).buy(_tokenInAmount, _daoId, _proof);
    }
}
