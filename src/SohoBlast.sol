// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IBlast } from "./interfaces/IBlast.sol";

import { Soho } from "./Soho.sol";

contract SohoBlast is Soho {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    constructor(address _engine, uint256 _tradingFeeBPS) Soho(_engine, _tradingFeeBPS) {
        BLAST.configureClaimableGas();
    }

    /**
     * @notice Allows the owner to claim all of the contract's gas.
     */
    function claimContractGas() external onlyOwner {
        BLAST.claimAllGas(address(this), msg.sender);
    }
}
