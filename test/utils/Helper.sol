// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { Soho } from "../../src/Soho.sol";
import { EventsAndErrors } from "./EventsAndErrors.sol";
import { Token } from "./Token.sol";

abstract contract Helper is Test, EventsAndErrors {
    address public owner;
    address public user1;
    uint256 public user1PrivateKey;
    address public user2;
    uint256 public user2PrivateKey;

    address public engine;
    uint256 public tradingfeeBPS;
    Soho public soho;

    Token public tokenA;
    Token public tokenB;

    uint256 public constant MAX_DEPOSIT_AMOUNT = 1_000_000e18;
    uint256 public inputAmount = 100e18;
    uint256 public outputAmount = 50e18;
    uint256 public buffer = 1e18;

    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 OPTIMISM_CHAIN_ID = 10;

    function setUp() public {
        owner = makeAddr("owner");
        (user1, user1PrivateKey) = makeAddrAndKey("user1");
        (user2, user2PrivateKey) = makeAddrAndKey("user2");
        engine = makeAddr("engine");

        tradingfeeBPS = 100; // 1%
        vm.startPrank(owner);
        soho = new Soho(engine, tradingfeeBPS);
        vm.stopPrank();

        tokenA = new Token("Token A", "TKNA");
        tokenB = new Token("Token B", "TKNB");

        tokenA.mint(user1, MAX_DEPOSIT_AMOUNT);
        tokenB.mint(user1, MAX_DEPOSIT_AMOUNT);
        tokenA.mint(user2, MAX_DEPOSIT_AMOUNT);
        tokenB.mint(user2, MAX_DEPOSIT_AMOUNT);

        _depositIntoSoho(user1, MAX_DEPOSIT_AMOUNT);
        _depositIntoSoho(user2, MAX_DEPOSIT_AMOUNT);
    }

    function _depositIntoSoho(address _user, uint256 _amount) internal {
        vm.startPrank(_user);
        tokenA.approve(address(soho), _amount);
        tokenB.approve(address(soho), _amount);
        soho.deposit(address(tokenA), _amount, _user);
        soho.deposit(address(tokenB), _amount, _user);
        vm.stopPrank();
    }

    function _createOrdersAndMatching(
        address _maker,
        address _taker
    )
        internal
        view
        returns (Soho.Matching memory _matching)
    {
        (Soho.Order memory makerOrder, bytes memory makerSignature) = _createMakerOrder(_maker);
        (Soho.Order memory takerOrder, bytes memory takerSignature) = _createTakerOrder(_taker);
        _matching = _createMatching(makerOrder, takerOrder, makerSignature, takerSignature);
    }

    function _createMatching(
        Soho.Order memory _makerOrder,
        Soho.Order memory _takerOrder,
        bytes memory _makerSignature,
        bytes memory _takerSignature
    )
        internal
        pure
        returns (Soho.Matching memory _matching)
    {
        _matching = Soho.Matching({
            makerOrder: _makerOrder,
            takerOrder: _takerOrder,
            makerSignature: _makerSignature,
            takerSignature: _takerSignature
        });
    }

    function _createMakerOrder(
        address _user
    )
        internal
        view
        returns (Soho.Order memory _order, bytes memory _signature)
    {
        (_order, _signature) = _createOrderDetailed(
            _user,
            block.chainid,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(_user),
            address(tokenA),
            inputAmount,
            address(tokenB),
            outputAmount
        );
    }

    function _createTakerOrder(
        address _user
    )
        internal
        view
        returns (Soho.Order memory _order, bytes memory _signature)
    {
        (_order, _signature) = _createOrderDetailed(
            _user,
            block.chainid,
            block.timestamp - 1,
            type(uint256).max,
            address(soho),
            soho.getUserCounter(_user),
            address(tokenB),
            outputAmount + buffer,
            address(tokenA),
            inputAmount
        );
    }

    function _createOrderDetailed(
        address _creator,
        uint256 _chainId,
        uint256 _startTimestamp,
        uint256 _endingTimestamp,
        address _settler,
        uint256 _counter,
        address _inputToken,
        uint256 _inputAmount,
        address _outputToken,
        uint256 _outputAmount
    )
        internal
        view
        returns (Soho.Order memory _order, bytes memory _signature)
    {
        _order = Soho.Order({
            creator: _creator,
            chainId: _chainId,
            startTimestamp: _startTimestamp,
            endingTimestamp: _endingTimestamp,
            settler: _settler,
            counter: _counter,
            inputToken: _inputToken,
            inputAmount: _inputAmount,
            outputToken: _outputToken,
            outputAmount: _outputAmount
        });

        bytes32 hash = soho.getOrderStructHash(_order);
        uint256 signerPrivateKey = _creator == user1 ? user1PrivateKey : user2PrivateKey;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, hash);
        _signature = abi.encodePacked(r, s, v);
    }
}
