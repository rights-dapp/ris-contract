pragma solidity ^0.4.18;

contract ERC223ContractInterface{
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}
