// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract Soho is Ownable2Step, EIP712 {
    using SafeERC20 for IERC20;
    using BitMaps for BitMaps.BitMap;

    struct Order {
        address creator;
        uint256 chainId;
        uint256 startTimestamp;
        uint256 endingTimestamp;
        address settler;
        uint256 counter;
        address inputToken;
        uint256 inputAmount;
        address outputToken;
        uint256 outputAmount;
    }

    struct Matching {
        Order makerOrder;
        Order takerOrder;
        bytes makerSignature;
        bytes takerSignature;
    }

    address private immutable i_engine;
    uint256 private s_tradingFeeBPS;
    uint256 private constant BPS = 10_000;
    string private constant ORDER_TYPE_HASH =
        "Order(address creator,uint256 chainId,uint256 startTimestamp,uint256 endingTimestamp,address settler,uint256 counter,address inputToken,uint256 inputAmount,address outputToken,uint256 outputAmount)";
    BitMaps.BitMap private s_orderStatus;
    mapping(address user => mapping(address token => uint256 amount)) private s_userToTokenToBalance;
    mapping(address user => uint256 counter) private s_userToCounter;

    event Deposited(address indexed by, address indexed token, uint256 indexed amount, address onBehalfOf);
    event Withdrawn(address indexed by, address indexed token, uint256 indexed amount, address to);
    event OrdersSettled(Matching indexed matching);
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

    modifier onlyEngine() {
        if (msg.sender != i_engine) revert Soho__NotEngine();
        _;
    }

    constructor(address _engine, uint256 _tradingFeeBPS) Ownable(msg.sender) EIP712(name(), version()) {
        i_engine = _engine;
        s_tradingFeeBPS = _tradingFeeBPS;
    }

    /**
     * @notice Allows users to deposit tokens to start trading on the orderbook.
     * @param _token The token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _onBehalfOf The address whose token deposit balance is increased.
     */
    function deposit(address _token, uint256 _amount, address _onBehalfOf) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        s_userToTokenToBalance[_onBehalfOf][_token] += _amount;

        emit Deposited(msg.sender, _token, _amount, _onBehalfOf);
    }

    /**
     * @notice Allows users to withdraw their deposited tokens.
     * @param _token The token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _to The receiver of the tokens.
     */
    function withdraw(address _token, uint256 _amount, address _to) external {
        s_userToTokenToBalance[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(_to, _amount);

        emit Withdrawn(msg.sender, _token, _amount, _to);
    }

    /**
     * @notice Allows the off-chain engine to settle orders by matching maker and taker orders.
     * @param _matching The struct holding the maker and taker order details, as well as the maker
     * and taker signatures.
     */
    function settleOrders(Matching calldata _matching) external onlyEngine {
        if (_matching.makerOrder.creator == address(0) || _matching.takerOrder.creator == address(0)) {
            revert Soho__AddressZero();
        }

        if (_matching.makerOrder.chainId != _matching.takerOrder.chainId) revert Soho__IncorrectChains();
        if (_matching.makerOrder.chainId != block.chainid) revert Soho__NotTargetChain();

        if (
            _matching.makerOrder.startTimestamp > block.timestamp
                || _matching.takerOrder.startTimestamp > block.timestamp
        ) revert Soho__TradeNotStartedYet();
        if (
            _matching.makerOrder.endingTimestamp < block.timestamp
                || _matching.takerOrder.endingTimestamp < block.timestamp
        ) revert Soho__DeadlinePassed();

        if (_matching.makerOrder.settler != address(this) || _matching.takerOrder.settler != address(this)) {
            revert Soho__NotCorrectSettler();
        }

        if (_matching.makerOrder.inputToken != _matching.takerOrder.outputToken) revert Soho__InvalidTokens();
        if (_matching.makerOrder.outputToken != _matching.takerOrder.inputToken) revert Soho__InvalidTokens();

        (uint256 fee, uint256 amountAfterFee) = _applyFee(_matching.takerOrder.inputAmount);

        if (_matching.makerOrder.inputAmount < _matching.takerOrder.outputAmount) {
            revert Soho__InsufficientMakerInputAmount();
        }
        if (_matching.makerOrder.outputAmount > amountAfterFee) {
            revert Soho__InsufficientTakerInputAmount();
        }

        if (
            _matching.makerOrder.counter < s_userToCounter[_matching.makerOrder.creator]
                || _matching.takerOrder.counter < s_userToCounter[_matching.takerOrder.creator]
        ) revert Soho__OrderCancelled();

        bytes32 makerOrderHash = getOrderStructHash(_matching.makerOrder);
        bytes32 takerOrderHash = getOrderStructHash(_matching.takerOrder);

        if (s_orderStatus.get(uint256(makerOrderHash)) || s_orderStatus.get(uint256(takerOrderHash))) {
            revert Soho__OrderSettled();
        }

        if (
            !SignatureChecker.isValidSignatureNow(_matching.makerOrder.creator, makerOrderHash, _matching.makerSignature)
                || !SignatureChecker.isValidSignatureNow(_matching.takerOrder.creator, takerOrderHash, _matching.takerSignature)
        ) revert Soho__InvalidSignature();

        s_orderStatus.set(uint256(makerOrderHash));
        s_orderStatus.set(uint256(takerOrderHash));

        s_userToTokenToBalance[_matching.makerOrder.creator][_matching.makerOrder.inputToken] -=
            _matching.makerOrder.inputAmount;
        s_userToTokenToBalance[_matching.takerOrder.creator][_matching.takerOrder.outputToken] +=
            _matching.makerOrder.inputAmount;

        s_userToTokenToBalance[_matching.takerOrder.creator][_matching.takerOrder.inputToken] -=
            _matching.takerOrder.inputAmount;
        s_userToTokenToBalance[_matching.makerOrder.creator][_matching.makerOrder.outputToken] += amountAfterFee;

        s_userToTokenToBalance[owner()][_matching.takerOrder.inputToken] += fee;

        emit OrdersSettled(_matching);
    }

    /**
     * @notice Each order (maker or taker order) is associated with a counter value.
     * Incrementing the counter value cancels that order.
     */
    function incrementCounter() external {
        uint256 counter = ++s_userToCounter[msg.sender];

        emit CounterIncremented(msg.sender, counter);
    }

    /**
     * @notice Allows the owner to change the trading fee.
     * @param _tradingFeeBPS The new trading fee in BIPS (basis points).
     */
    function changeTradingFee(uint256 _tradingFeeBPS) external onlyOwner {
        s_tradingFeeBPS = _tradingFeeBPS;

        emit TradingFeeChanged(_tradingFeeBPS);
    }

    /**
     * @notice Applies the trading fee on the input amount and returns the fee
     * amount as well as the amount after fee has been applied.
     * @param _amount The amount to apply the fee on.
     * @return _feeAmount The fee amount to deduct from the input amount.
     * @return _amountAfterFee The amount remaining after fee has been applied.
     */
    function _applyFee(uint256 _amount) internal view returns (uint256 _feeAmount, uint256 _amountAfterFee) {
        _feeAmount = (_amount * s_tradingFeeBPS) / BPS;
        _amountAfterFee = _amount - _feeAmount;
    }

    /**
     * @notice Gets the address used by the off-chain engine to settle orders.
     * @return _enginePublicKey The address used by the off-chain matching engine.
     */
    function getEnginePublicKey() external view returns (address _enginePublicKey) {
        _enginePublicKey = i_engine;
    }

    /**
     * @notice Gets the trading fee.
     * @return _tradingFeeBPS The trading fee in BPS.
     */
    function getTradingFeeInBPS() external view returns (uint256 _tradingFeeBPS) {
        _tradingFeeBPS = s_tradingFeeBPS;
    }

    /**
     * @notice Gets the status of an order. True if resolved, false otherwise.
     * @param _orderIndex The index of the order. You get it by casting the order hash to uint256.
     * @return _orderStatus The status of the order.
     */
    function getOrderStatus(uint256 _orderIndex) external view returns (bool _orderStatus) {
        _orderStatus = s_orderStatus.get(_orderIndex);
    }

    /**
     * @notice Gets the user's deposited token balance.
     * @param _user The user's address.
     * @param _token The token's address.
     * @return _balance The user's deposited token balance.
     */
    function getUserBalance(address _user, address _token) external view returns (uint256 _balance) {
        _balance = s_userToTokenToBalance[_user][_token];
    }

    /**
     * @notice Gets the user's counter values.
     * @param _user The user's address.
     * @return _counter The counter value for the user.
     */
    function getUserCounter(address _user) external view returns (uint256 _counter) {
        _counter = s_userToCounter[_user];
    }

    /**
     * @notice Creates an EIP712 struct hash for an order.
     * @param _order The order details.
     * @return _orderStructHash The hash of the order.
     */
    function getOrderStructHash(Order memory _order) public view returns (bytes32 _orderStructHash) {
        _orderStructHash = _hashTypedDataV4(
            keccak256(
                abi.encodePacked(
                    keccak256(bytes(ORDER_TYPE_HASH)),
                    _order.creator,
                    _order.chainId,
                    _order.startTimestamp,
                    _order.endingTimestamp,
                    _order.settler,
                    _order.counter,
                    _order.inputToken,
                    _order.inputAmount,
                    _order.outputToken,
                    _order.outputAmount
                )
            )
        );
    }

    /**
     * @notice Gets the protocol's name.
     * @return _name The protocol's string name.
     */
    function name() public pure returns (string memory _name) {
        _name = "Soho";
    }

    /**
     * @notice Gets the protocol's version.
     * @return _version The protocol's stringified version.
     */
    function version() public pure returns (string memory _version) {
        _version = "1";
    }
}
