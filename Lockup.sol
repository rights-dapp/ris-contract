pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract Lockup is Ownable{
	using SafeMath for uint256;

	uint256 public lockupTime;
	mapping(address => bool) public lockup_list;

	event UpdateLockup(address indexed owner, uint256 lockup_date);

	event UpdateLockupList(address indexed owner, address indexed user_address, bool flag);

	constructor(uint256 _lockupTime ) public
	{
		lockupTime = _lockupTime;

		emit UpdateLockup(msg.sender, lockupTime);
	}

	/**
	* @dev Function to get lockup date
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getLockup()public view returns (uint256){
		return lockupTime;
	}

	/**
	* @dev Function to check token locked date that is reach or not
	* @return A bool that indicates if the operation was successful.
	*/
	function isLockup() public view returns(bool){
		return (now < lockupTime);
	}

	/**
	* @dev Function to update token lockup time
	* @param _newLockUpTime uint256 lockup date
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockup(uint256 _newLockUpTime) onlyOwner public returns(bool){

		lockupTime = _newLockUpTime;

		emit UpdateLockup(msg.sender, lockupTime);
		
		return true;
	}

	/**
	* @dev Function get user's lockup status
	* @param _add address
	* @return A bool that indicates if the operation was successful.
	*/
	function inLockupList(address _add)public view returns(bool){
		return lockup_list[_add];
	}

	/**
	* @dev Function update lockup status for purchaser, if user in the lockup list, they can only transfer token after lockup date
	* @param _add address
	* @param _flag bool this user's token should be lockup or not
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address _add, bool _flag)onlyOwner public returns(bool){
		lockup_list[_add] = _flag;

		emit UpdateLockupList(msg.sender, _add, _flag);

		return true;
	}

}
