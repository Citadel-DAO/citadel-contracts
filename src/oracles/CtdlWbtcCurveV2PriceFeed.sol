// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICurveCryptoSwap} from "../interfaces/curve/ICurveCryptoSwap.sol";
import {IMedianOracle} from "../interfaces/citadel/IMedianOracle.sol";

contract CtdlWbtcCurveV2PriceFeed {
    IMedianOracle public medianOracle;
    ICurveCryptoSwap public curvePool;

    constructor(address _medianOracle, address _curvePool) {
        medianOracle = IMedianOracle(_medianOracle);
        curvePool = ICurveCryptoSwap(_curvePool);
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function latestAnswer() public view returns (uint256 wbtcPriceInCtdl_) {
        wbtcPriceInCtdl_ = curvePool.price_oracle();
    }

    function pushReport() external {
        medianOracle.pushReport(latestAnswer());
    }
}
