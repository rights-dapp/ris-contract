pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract SaleInfo{
	using SafeMath for uint256;

	uint256 public privateOpeningTime;
	uint256 public privateClosingTime;
	uint256 public publicOpeningTime;
	uint256 public publicClosingTime;
	address public admin_wallet;
	address public sale_owner_wallet;
	address public unsale_owner_wallet;
	address public eth_management_wallet;

	constructor(
		uint256 _privateOpeningTime, uint256 _privateClosingTime,
		uint256 _publicOpeningTime, uint256 _publicClosingTime,
		address _admin_wallet, address _sale_owner_wallet, 
		address _unsale_owner_wallet, address _eth_management_wallet ) public
	{
		privateOpeningTime = _privateOpeningTime;
		privateClosingTime = _privateClosingTime;
		publicOpeningTime = _publicOpeningTime;
		publicClosingTime = _publicClosingTime;
		admin_wallet = _admin_wallet;
		sale_owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;
		eth_management_wallet = _eth_management_wallet;
	}

	/**
	* @dev get admin wallet
	*/
	function getAdminAddress() public view returns(address) {
		return admin_wallet;
	}

	/**
	* @dev get owner wallet
	*/
	function getSaleOwnerAddress() public view returns(address) {
		return sale_owner_wallet;
	}

	/**
	* @dev get unsale owner wallet
	*/
	function getUnsaleOwnerAddress() public view returns(address) {
		return unsale_owner_wallet;
	}

	/**
	* @dev get eth management owner wallet
	*/
	function getEtherManagementAddress() public view returns(address) {
		return eth_management_wallet;
	}

	/**
	* @dev get start date for presale
	*/
	function getPresaleOpeningDate() public view returns(uint256) {
		return privateOpeningTime;
	}

	/**
	* @dev get end date for presale
	*/
	function getPresaleClosingDate() public view returns(uint256) {
		return privateClosingTime;
	}

	/**
	* @dev get start date for public sale
	*/
	function getPublicsaleOpeningDate() public view returns(uint256) {
		return publicOpeningTime;
	}

	/**
	* @dev get end date for public sale
	*/
	function getPublicsaleClosingDate() public view returns(uint256) {
		return publicClosingTime;
	}	

	/**
	* @dev current time is in presale period or not
	*/
	function inPresalePeriod() public view returns(bool){
		return ( (now >= privateOpeningTime) && (now <= privateClosingTime) );
	}

	/**
	* @dev current time is in public sale period or not
	*/
	function inPublicsalePeriod() public view returns(bool){
		return ( (now >= publicOpeningTime) && (now <= publicClosingTime) );
	}	
}
