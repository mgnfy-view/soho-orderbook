// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Soho } from "../../src/Soho.sol";

abstract contract EventsAndErrors {
    event Deposited(address indexed by, address indexed token, uint256 indexed amount, address onBehalfOf);
    event Withdrawn(address indexed by, address indexed token, uint256 indexed amount, address to);
    event OrdersSettled(Soho.Matching indexed matching);
    event CounterIncremented(address indexed by, uint256 indexed value);
    event TradingFeeChanged(uint256 indexed newTradingFeeBPS);

    error Soho__NotEngine();
    error Soho__AddressZero();
    error Soho__IncorrectChains();
    error Soho__NotTargetChain();
    error Soho__TradeNotStartedYet();
    error Soho__DeadlinePassed();
    error Soho__NotCorrectSettler();
    error Soho__InvalidTokens();
    error Soho__InsufficientMakerInputAmount();
    error Soho__InsufficientTakerInputAmount();
    error Soho__OrderCancelled();
    error Soho__OrderSettled();
    error Soho__InvalidSignature();
}
