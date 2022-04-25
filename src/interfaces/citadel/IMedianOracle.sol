/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IMedianOracle {

    struct Report {
        uint256 timestamp;
        uint256 payload;
    }

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);
    event ReportTimestampOutOfRange(address provider);
    event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);

    function reportExpirationTimeSec() external view returns(uint256);
    function reportDelaySec() external view returns(uint256);
    function minimumProviders() external view returns(uint256);

    function providers(uint256) external view returns (address);
    function providersSize() external view returns (uint256);
    function providerReports(address, uint256) external view returns (uint256, uint256);
    function getData() external view returns (uint256, bool);

    function addProvider(address provider) external;
    function removeProvider(address provider) external;
    function pushReport(uint256 payload) external;
}
