// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {KnightingRound} from "./KnightingRound.sol";

interface WETH {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address guy, uint256 wad) external returns (bool);
}

contract KnightingRoundWithEth is KnightingRound {
    function buyEth(uint8 _daoId, bytes32[] calldata _proof)
        external
        payable
        gacPausable
        returns (uint256 tokenOutAmount_)
    {
        WETH weth = WETH(address(tokenIn));
        weth.deposit{value: msg.value}();
        weth.transfer(msg.sender, msg.value);
        tokenOutAmount_ = super.buy(
            msg.value,
            _daoId,
            _proof
        );
    }
}
