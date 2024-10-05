// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Soho } from "../../src/Soho.sol";
import { Helper } from "../utils/Helper.sol";

contract SohoTest is Helper {
    function testDepositIntoSoho() public {
        uint256 balanceABefore = soho.getUserBalance(user1, address(tokenA));
        uint256 balanceBBefore = soho.getUserBalance(user1, address(tokenB));

        tokenA.mint(user1, MAX_DEPOSIT_AMOUNT);
        tokenB.mint(user1, MAX_DEPOSIT_AMOUNT);
        _depositIntoSoho(user1, MAX_DEPOSIT_AMOUNT);

        uint256 balanceAAfter = soho.getUserBalance(user1, address(tokenA));
        uint256 balanceBAfter = soho.getUserBalance(user1, address(tokenB));

        assertEq(balanceAAfter - balanceABefore, MAX_DEPOSIT_AMOUNT);
        assertEq(balanceBAfter - balanceBBefore, MAX_DEPOSIT_AMOUNT);
    }

    function testDepositIntoSohoEmitsEvent() public {
        tokenA.mint(user1, MAX_DEPOSIT_AMOUNT);

        vm.startPrank(user1);
        tokenA.approve(address(soho), MAX_DEPOSIT_AMOUNT);
        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(user1, address(soho), MAX_DEPOSIT_AMOUNT);
        emit Deposited(user1, address(tokenA), MAX_DEPOSIT_AMOUNT, user1);
        soho.deposit(address(tokenA), MAX_DEPOSIT_AMOUNT, user1);
        vm.stopPrank();
    }

    function testWithdrawFromSoho() public {
        uint256 balanceABefore = IERC20(address(tokenA)).balanceOf(user1);
        uint256 balanceBBefore = IERC20(address(tokenB)).balanceOf(user1);

        vm.startPrank(user1);
        soho.withdraw(address(tokenA), MAX_DEPOSIT_AMOUNT, user1);
        soho.withdraw(address(tokenB), MAX_DEPOSIT_AMOUNT, user1);
        vm.stopPrank();

        uint256 balanceAAfter = IERC20(address(tokenA)).balanceOf(user1);
        uint256 balanceBAfter = IERC20(address(tokenB)).balanceOf(user1);

        assertEq(balanceAAfter - balanceABefore, MAX_DEPOSIT_AMOUNT);
        assertEq(balanceBAfter - balanceBBefore, MAX_DEPOSIT_AMOUNT);
    }

    function testWithdrawFromSohoEmitsEvent() public {
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(address(soho), user1, MAX_DEPOSIT_AMOUNT);
        emit Withdrawn(user1, address(tokenA), MAX_DEPOSIT_AMOUNT, user1);
        soho.withdraw(address(tokenA), MAX_DEPOSIT_AMOUNT, user1);
        vm.stopPrank();
    }

    function testSettleOrders() public {
        Soho.Matching memory matching = _createOrdersAndMatching(user1, user2, block.timestamp);

        uint256 user1TokenABalanceBefore = soho.getUserBalance(user1, address(tokenA));
        uint256 user1TokenBBalanceBefore = soho.getUserBalance(user1, address(tokenB));
        uint256 user2TokenABalanceBefore = soho.getUserBalance(user2, address(tokenA));
        uint256 user2TokenBBalanceBefore = soho.getUserBalance(user2, address(tokenB));

        vm.startPrank(engine);
        soho.settleOrders(matching);
        vm.stopPrank();

        uint256 user1TokenABalanceAfter = soho.getUserBalance(user1, address(tokenA));
        uint256 user1TokenBBalanceAfter = soho.getUserBalance(user1, address(tokenB));
        uint256 user2TokenABalanceAfter = soho.getUserBalance(user2, address(tokenA));
        uint256 user2TokenBBalanceAfter = soho.getUserBalance(user2, address(tokenB));

        assertEq(user1TokenABalanceBefore - user1TokenABalanceAfter, inputAmount);
        assertGt(user1TokenBBalanceAfter - user1TokenBBalanceBefore, outputAmount);
        assertEq(user2TokenBBalanceBefore - user2TokenBBalanceAfter, outputAmount + buffer);
        assertEq(user2TokenABalanceAfter - user2TokenABalanceBefore, inputAmount);
    }

    function testSettleOrdersEmitsEvent() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectEmit(true, true, true, true);
        emit OrdersSettled(matching);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testOnlyEngineCanSettleOrders() public {
        Soho.Matching memory matching = _createOrdersAndMatching(user1, user2, block.timestamp);

        vm.expectRevert(Soho__NotEngine.selector);
        soho.settleOrders(matching);
    }

    function testSettleOrdersFailsDueToPassedDeadline() public {
        uint256 warpBy = 1 minutes;
        vm.warp(block.timestamp + warpBy);
        uint256 deadline = block.timestamp - 1;

        Soho.Matching memory matching = _createOrdersAndMatching(address(0), user2, deadline);

        vm.startPrank(engine);
        vm.expectRevert(Soho__DeadlinePassed.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToAddressZeroCreator() public {
        Soho.Matching memory matching = _createOrdersAndMatching(address(0), user2, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__AddressZero.selector);
        soho.settleOrders(matching);
        vm.stopPrank();

        matching = _createOrdersAndMatching(user1, address(0), block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__AddressZero.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToIncompatibleMakerAndTakerChainIds() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            MAINNET_CHAIN_ID,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            OPTIMISM_CHAIN_ID,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__IncorrectChains.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToIncorrectChainId() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            MAINNET_CHAIN_ID,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            MAINNET_CHAIN_ID,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__NotTargetChain.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToInvalidTimestamps() public {
        uint256 startingTimestamp = block.timestamp + 1;

        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            startingTimestamp,
            block.timestamp,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            startingTimestamp,
            block.timestamp,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__TradeNotStartedYet.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsWhenTradeNotStartedYet() public {
        uint256 startingTimestamp = block.timestamp + 1;

        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            startingTimestamp,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            startingTimestamp,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__TradeNotStartedYet.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsWhenDeadlinePassed() public {
        uint256 deadline = block.timestamp - 1;

        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            deadline,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            deadline,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__DeadlinePassed.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToIncorrectSettler() public {
        address settler = makeAddr("settler");

        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            settler,
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            settler,
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__NotCorrectSettler.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToTokensThatDoNotMatch() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenA),
            outputAmount + buffer,
            address(tokenB),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__InvalidTokens.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToInsufficientMakerInputAmount() public {
        uint256 makerInputAmount = inputAmount - 1;

        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            makerInputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__InsufficientMakerInputAmount.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToInsufficientTakerInputAmount() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__InsufficientTakerInputAmount.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToCounterIncremented() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(user1);
        soho.incrementCounter();
        vm.stopPrank();

        vm.startPrank(engine);
        vm.expectRevert(Soho__OrderCancelled.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsWhenOrderAlreadySettled() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, takerSignature, block.timestamp);

        vm.startPrank(engine);
        soho.settleOrders(matching);
        vm.expectRevert(Soho__OrderSettled.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testSettleOrdersFailsDueToInvalidSignature() public {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createOrderDetailed(
            user1,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user1),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
        (Soho.Order memory takerOrder,) = _createOrderDetailed(
            user2,
            block.chainid,
            block.timestamp,
            block.timestamp + 1,
            address(soho),
            soho.getUserCounter(user2),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );

        Soho.Matching memory matching =
            _createMatching(makerOrder, takerOrder, makerSignature, makerSignature, block.timestamp);

        vm.startPrank(engine);
        vm.expectRevert(Soho__InvalidSignature.selector);
        soho.settleOrders(matching);
        vm.stopPrank();
    }

    function testIncrementCounter() public {
        uint256 counterBefore = soho.getUserCounter(user1);

        vm.startPrank(user1);
        soho.incrementCounter();
        vm.stopPrank();

        uint256 counterAfter = soho.getUserCounter(user1);
        uint256 expectedValue = 1;

        assertEq(counterAfter - counterBefore, expectedValue);
    }

    function testIncrementCounterEmitsEvent() public {
        uint256 expectedValue = 1;

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, false);
        emit CounterIncremented(user1, expectedValue);
        soho.incrementCounter();
        vm.stopPrank();
    }

    function testChangeTradingFeeBPS() public {
        uint256 newTradingFeeBPS = 1000;

        vm.startPrank(owner);
        soho.changeTradingFee(newTradingFeeBPS);
        vm.stopPrank();

        assertEq(soho.getTradingFeeInBPS(), newTradingFeeBPS);
    }

    function testChangeTradingFeeBPSEmitsEvent() public {
        uint256 newTradingFeeBPS = 1000;

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit TradingFeeChanged(newTradingFeeBPS);
        soho.changeTradingFee(newTradingFeeBPS);
        vm.stopPrank();
    }

    function testGetEnginePublicKey() public view {
        assertEq(soho.getEnginePublicKey(), engine);
    }

    function testGetTradingFeeBPS() public view {
        assertEq(soho.getTradingFeeInBPS(), tradingfeeBPS);
    }

    function testGetOrderStatus() public {
        Soho.Matching memory matching = _createOrdersAndMatching(user1, user2, block.timestamp);

        vm.startPrank(engine);
        soho.settleOrders(matching);
        vm.stopPrank();

        bool makerStatus = soho.getOrderStatus(uint256(soho.getOrderStructHash(matching.makerOrder)));
        bool takerStatus = soho.getOrderStatus(uint256(soho.getOrderStructHash(matching.takerOrder)));

        assertTrue(makerStatus);
        assertTrue(takerStatus);
    }

    function testGetUserBalance() public view {
        assertEq(soho.getUserBalance(user1, address(tokenA)), MAX_DEPOSIT_AMOUNT);
    }

    function testGetUserCounter() public view {
        assertEq(soho.getUserCounter(user1), 0);
    }

    function testGetName() public view {
        assertEq(soho.name(), "Soho");
    }

    function testGetVersion() public view {
        assertEq(soho.version(), "1");
    }
}
