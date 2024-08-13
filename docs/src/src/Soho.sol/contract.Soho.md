# Soho
[Git Source](https://github.com/mgnfy-view/soho-orderbook/blob/b0de44209c38bec76a892649fa8f58821082ae7c/src/Soho.sol)

**Inherits:**
Ownable2Step, EIP712


## State Variables
### i_engine

```solidity
address private immutable i_engine;
```


### s_tradingFeeBPS

```solidity
uint256 private s_tradingFeeBPS;
```


### BPS

```solidity
uint256 private constant BPS = 10_000;
```


### ORDER_TYPE_HASH

```solidity
string private constant ORDER_TYPE_HASH =
    "Order(address creator,uint256 chainId,uint256 startTimestamp,uint256 endingTimestamp,address settler,uint256 counter,address inputToken,uint256 inputAmount,address outputToken,uint256 outputAmount)";
```


### s_orderStatus

```solidity
BitMaps.BitMap private s_orderStatus;
```


### s_userToTokenToBalance

```solidity
mapping(address user => mapping(address token => uint256 amount)) private s_userToTokenToBalance;
```


### s_userToCounter

```solidity
mapping(address user => uint256 counter) private s_userToCounter;
```


## Functions
### onlyEngine


```solidity
modifier onlyEngine();
```

### constructor


```solidity
constructor(address _engine, uint256 _tradingFeeBPS) Ownable(msg.sender) EIP712(name(), version());
```

### deposit

Allows users to deposit tokens to start trading on the orderbook.


```solidity
function deposit(address _token, uint256 _amount, address _onBehalfOf) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The token to deposit.|
|`_amount`|`uint256`|The amount of tokens to deposit.|
|`_onBehalfOf`|`address`|The address whose token deposit balance is increased.|


### withdraw

Allows users to withdraw their deposited tokens.


```solidity
function withdraw(address _token, uint256 _amount, address _to) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The token to withdraw.|
|`_amount`|`uint256`|The amount of tokens to withdraw.|
|`_to`|`address`|The receiver of the tokens.|


### settleOrders

Allows the off-chain engine to settle orders by matching maker and taker orders.


```solidity
function settleOrders(Matching calldata _matching) external onlyEngine;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_matching`|`Matching`|The struct holding the maker and taker order details, as well as the maker and taker signatures.|


### incrementCounter

Each order (maker or taker order) is associated with a counter value.
Incrementing the counter value cancels that order.


```solidity
function incrementCounter() external;
```

### changeTradingFee

Allows the owner to change the trading fee.


```solidity
function changeTradingFee(uint256 _tradingFeeBPS) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tradingFeeBPS`|`uint256`|The new trading fee in BIPS (basis points).|


### _applyFee

Applies the trading fee on the input amount and returns the fee
amount as well as the amount after fee has been applied.


```solidity
function _applyFee(uint256 _amount) internal view returns (uint256 _feeAmount, uint256 _amountAfterFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount to apply the fee on.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_feeAmount`|`uint256`|The fee amount to deduct from the input amount.|
|`_amountAfterFee`|`uint256`|The amount remaining after fee has been applied.|


### getEnginePublicKey

Gets the address used by the off-chain engine to settle orders.


```solidity
function getEnginePublicKey() external view returns (address _enginePublicKey);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_enginePublicKey`|`address`|The address used by the off-chain matching engine.|


### getTradingFeeInBPS

Gets the trading fee.


```solidity
function getTradingFeeInBPS() external view returns (uint256 _tradingFeeBPS);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_tradingFeeBPS`|`uint256`|The trading fee in BPS.|


### getOrderStatus

Gets the status of an order. True if resolved, false otherwise.


```solidity
function getOrderStatus(uint256 _orderIndex) external view returns (bool _orderStatus);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_orderIndex`|`uint256`|The index of the order. You get it by casting the order hash to uint256.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_orderStatus`|`bool`|The status of the order.|


### getUserBalance

Gets the user's deposited token balance.


```solidity
function getUserBalance(address _user, address _token) external view returns (uint256 _balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The user's address.|
|`_token`|`address`|The token's address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_balance`|`uint256`|The user's deposited token balance.|


### getUserCounter

Gets the user's counter values.


```solidity
function getUserCounter(address _user) external view returns (uint256 _counter);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The user's address.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_counter`|`uint256`|The counter value for the user.|


### getOrderStructHash

Creates an EIP712 struct hash for an order.


```solidity
function getOrderStructHash(Order memory _order) public view returns (bytes32 _orderStructHash);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_order`|`Order`|The order details.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_orderStructHash`|`bytes32`|The hash of the order.|


### name

Gets the protocol's name.


```solidity
function name() public pure returns (string memory _name);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|The protocol's string name.|


### version

Gets the protocol's version.


```solidity
function version() public pure returns (string memory _version);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_version`|`string`|The protocol's stringified version.|


## Events
### Deposited

```solidity
event Deposited(address indexed by, address indexed token, uint256 indexed amount, address onBehalfOf);
```

### Withdrawn

```solidity
event Withdrawn(address indexed by, address indexed token, uint256 indexed amount, address to);
```

### OrdersSettled

```solidity
event OrdersSettled(Matching indexed matching);
```

### CounterIncremented

```solidity
event CounterIncremented(address indexed by, uint256 indexed value);
```

### TradingFeeChanged

```solidity
event TradingFeeChanged(uint256 indexed newTradingFeeBPS);
```

## Errors
### Soho__NotEngine

```solidity
error Soho__NotEngine();
```

### Soho__AddressZero

```solidity
error Soho__AddressZero();
```

### Soho__IncorrectChains

```solidity
error Soho__IncorrectChains();
```

### Soho__NotTargetChain

```solidity
error Soho__NotTargetChain();
```

### Soho__TradeNotStartedYet

```solidity
error Soho__TradeNotStartedYet();
```

### Soho__DeadlinePassed

```solidity
error Soho__DeadlinePassed();
```

### Soho__NotCorrectSettler

```solidity
error Soho__NotCorrectSettler();
```

### Soho__InvalidTokens

```solidity
error Soho__InvalidTokens();
```

### Soho__InsufficientMakerInputAmount

```solidity
error Soho__InsufficientMakerInputAmount();
```

### Soho__InsufficientTakerInputAmount

```solidity
error Soho__InsufficientTakerInputAmount();
```

### Soho__OrderCancelled

```solidity
error Soho__OrderCancelled();
```

### Soho__OrderSettled

```solidity
error Soho__OrderSettled();
```

### Soho__InvalidSignature

```solidity
error Soho__InvalidSignature();
```

## Structs
### Order

```solidity
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
```

### Matching

```solidity
struct Matching {
    Order makerOrder;
    Order takerOrder;
    bytes makerSignature;
    bytes takerSignature;
}
```

