// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";

import { Soho } from "../src/Soho.sol";
import { SohoBlast } from "../src/SohoBlast.sol";

contract Deploy is Script {
    Soho public soho;
    SohoBlast public sohoBlast;
    // This is the default Anvil account
    // However
    address public engine = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public tradingFeeBPS = 100;

    uint256 public constant BLAST_CHAIN_ID = 81457;

    function run() public {
        vm.startBroadcast();
        _deploy(engine, tradingFeeBPS);
        vm.stopBroadcast();
    }

    function _deploy(address _engine, uint256 _tradingFeeBPS) internal {
        if (block.chainid == BLAST_CHAIN_ID) {
            sohoBlast = new SohoBlast(_engine, _tradingFeeBPS);
        } else {
            soho = new Soho(_engine, _tradingFeeBPS);
        }
    }
}
