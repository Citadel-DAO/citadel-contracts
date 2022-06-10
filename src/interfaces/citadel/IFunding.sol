// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IFunding {
    function initialize(
        address _gac,
        address _citadel,
        address _asset,
        address _xCitadel,
        address _saleRecipient,
        address _citadelPriceInAssetOracle,
        uint256 _assetCap
    ) external;
}
