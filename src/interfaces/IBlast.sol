// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IBlast {
    function configureClaimableGas() external;
    function claimAllGas(address contractAddress, address recipient) external returns (uint256);
}
