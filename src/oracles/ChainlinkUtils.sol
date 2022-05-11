// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3Interface} from "../interfaces/chainlink/IAggregatorV3Interface.sol";

abstract contract ChainlinkUtils {
    /// =========================
    /// ===== Internal view =====
    /// =========================

    function safeLatestAnswer(IAggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256 answer_)
    {
        (
            uint256 roundId,
            int256 price,
            ,
            uint256 updateTime,
            uint256 answeredInRound
        ) = _priceFeed.latestRoundData();

        require(price > 0, "Chainlink price <= 0");
        require(updateTime != 0, "Incomplete round");
        require(answeredInRound >= roundId, "Stale price");

        answer_ = uint256(price);
    }
}
