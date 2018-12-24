pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract ERC223Token is StandardToken{
  function transfer(address to, uint256 value, bytes data) public returns (bool);
  event TransferERC223(address indexed from, address indexed to, uint256 value, bytes data);
}
