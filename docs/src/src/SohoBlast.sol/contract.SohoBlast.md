# SohoBlast
[Git Source](https://github.com/mgnfy-view/soho-orderbook/blob/b350bfaab71abb17c2012b562288a1838b48b478/src/SohoBlast.sol)

**Inherits:**
[Soho](/src/Soho.sol/contract.Soho.md)


## State Variables
### BLAST

```solidity
IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
```


## Functions
### constructor


```solidity
constructor(address _engine, uint256 _tradingFeeBPS) Soho(_engine, _tradingFeeBPS);
```

### claimContractGas

Allows the owner to claim all of the contract's gas.


```solidity
function claimContractGas() external onlyOwner;
```

