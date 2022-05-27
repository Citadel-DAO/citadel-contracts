// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./Funding.sol";
import "./GACProxyAdmin.sol";
import "./lib/GlobalAccessControlManaged.sol";

contract FundingRegistry is Initializable, GlobalAccessControlManaged {
    // ===== Libraries  ====
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    GACProxyAdmin public gacProxyAdmin;

    struct FundingAsset {
        address asset;
        address citadelPerAssetOracle;
        uint256 assetCap;
    }

    address gacAddress;
    address citadel;
    address xCitadel;
    address saleRecipient;

    address public fundingImplementation;

    EnumerableSet.AddressSet private fundings;

    function intialize(
        address _gac,
        address _citadel,
        address _xCitadel,
        address _saleRecipient,
        FundingAsset[] calldata _fundingAssets
    ) public initializer {
        __GlobalAccessControlManaged_init(_gac);

        gacAddress = _gac;
        citadel = _citadel;
        xCitadel = _xCitadel;
        saleRecipient = _saleRecipient;

        gacProxyAdmin = new GACProxyAdmin();
        gacProxyAdmin.initialize(_gac);

        fundingImplementation = address(new Funding());

        /// for other
        for (uint256 i = 0; i < _fundingAssets.length; i++) {
            addRound(_fundingAssets[i]);
        }
    }

    function addRound(FundingAsset calldata _fundingAsset)
        public
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
    {
        TransparentUpgradeableProxy currFunding = new TransparentUpgradeableProxy(
                address(fundingImplementation),
                address(gacProxyAdmin),
                abi.encodeWithSelector(
                    Funding(address(0)).initialize.selector,
                    gacAddress,
                    citadel,
                    _fundingAsset.asset,
                    xCitadel,
                    saleRecipient,
                    _fundingAsset.citadelPerAssetOracle,
                    _fundingAsset.assetCap
                )
            );

        fundings.add(address(currFunding));
    }
}
