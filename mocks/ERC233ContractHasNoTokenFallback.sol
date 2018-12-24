pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/ownership/CanReclaimToken.sol";


/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <remco@2π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract ERC233ContractHasNoTokenFallback is CanReclaimToken {

}
