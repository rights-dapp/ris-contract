pragma solidity ^0.4.18;

import './WhiteList.sol';
import './RISCoin.sol';
import './SaleInfo.sol';
import './Lockup.sol';
import './BatchTransferable.sol';
import 'zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract RISCoinCrowdsale is TimedCrowdsale, Ownable, Pausable, BatchTransferable{
	using SafeMath for uint256;

	address public admin_wallet; //wallet to controll system
	address public sale_owner_wallet; 
	address public unsale_owner_wallet;
	address public eth_management_wallet; //wallet to reveive eth

	uint256 public minimum_weiAmount;

	RISCoin public ris_token;
	SaleInfo public sale_info;
	WhiteList public white_list;
	Lockup public lockup;

	event PresalePurchase(address indexed purchaser, uint256 value);
	event PublicsalePurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 rate);
	event UpdateRate(address indexed updater, uint256 rate);
	event UpdateMinimumAmount( address indexed updater, uint256 minimumWeiAmount);
	event GiveToken(address indexed purchaser, uint256 amount, uint8 lockup);

	constructor(
		uint256 _openingTime, 
		uint256 _closingTime,
		uint256 _rate,
		uint256 _minimum_weiAmount,
		address _admin_wallet, 
		address _sale_owner_wallet, 
		address _unsale_owner_wallet, 
		address _eth_management_wallet,
		RISCoin _ris , 
		SaleInfo _sale_info,
		WhiteList _whiteList, 
		Lockup _lockup) public
	    Crowdsale(_rate, _eth_management_wallet, _ris)
	    TimedCrowdsale(_openingTime, _closingTime)
	{
		admin_wallet = _admin_wallet;
		sale_owner_wallet = _sale_owner_wallet;
		unsale_owner_wallet = _unsale_owner_wallet;
		eth_management_wallet = _eth_management_wallet;
		ris_token = _ris;
		sale_info = _sale_info;
		white_list = _whiteList;
		lockup = _lockup;
		minimum_weiAmount = _minimum_weiAmount;

		emit UpdateRate( msg.sender, _rate);
		emit UpdateMinimumAmount(msg.sender, _minimum_weiAmount);
	}

	/**
	* @dev low level token purchase ***DO NOT OVERRIDE***
	* @param _beneficiary Address performing the token purchase
	*/
	function buyTokens(address _beneficiary) onlyWhileOpen whenNotPaused public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		// calculate token amount to be created
		uint256 tokens = _getTokenAmount(weiAmount);

		// update state
		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, tokens);
		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	/**
	* @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
	* @param _beneficiary Address performing the token purchase
	* @param _weiAmount Value in wei involved in the purchase
	*/
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);

		//minimum ether check
		require(_weiAmount >= minimum_weiAmount);

		//owner can not purchase token
		require(_beneficiary != admin_wallet);
		require(_beneficiary != sale_owner_wallet);
		require(_beneficiary != unsale_owner_wallet);
		require(_beneficiary != eth_management_wallet);

		require( sale_info.inPresalePeriod() || sale_info.inPublicsalePeriod() );

		//whitelist check
		//whitelist status:1-presale user, 2-public sale user
		uint8 inWhitelist = white_list.checkList(_beneficiary);

		if(sale_info.inPresalePeriod()){
			//if need to check whitelist status in presale period
			if( white_list.getPresaleWhitelistStatus() ){
				require( inWhitelist == 1);
			}
		}else{
			//if need to check whitelist status in public sale period
			if( white_list.getPublicSaleWhitelistStatus() ){
				require( (inWhitelist == 1) || (inWhitelist == 2) );
			}
		}

	}

	/**
	* @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
	* @param _beneficiary Address performing the token purchase
	* @param _tokenAmount Number of tokens to be emitted
	*/
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {

		//will not send token directly when purchaser purchase the token in presale 
		if( sale_info.inPresalePeriod() ){
			emit PresalePurchase( _beneficiary, msg.value );
		}else{
			require(ris_token.sendTokens(_beneficiary, _tokenAmount));
			emit PublicsalePurchase( _beneficiary, msg.value, _tokenAmount, rate);
		}

	}

	/**
	* @dev send token and set token lockup status to specific user
	*     file format:
	*		[
	*	      [<address>, <token amount>, <lockup flag>],
	*	      [<address>, <token amount>, <lockup flag>],...
	*	    ]
	* @param _beneficiary Address 
	* @param _tokenAmount token amount
	* @param _needLockUp this address can transfer token or not before token lockup
	* @return A bool that indicates if the operation was successful.
	*/
	function giveToken(address _beneficiary, uint256 _tokenAmount, uint8 _needLockUp) onlyOwner public returns (bool){
		require(_beneficiary != address(0));

		require(_tokenAmount > 0);

		if(_needLockUp == 1){
			//add this account in to lockup list
			require(updateLockupList(_beneficiary, true));
		}

		require(ris_token.sendTokens(_beneficiary, _tokenAmount));

		emit GiveToken(_beneficiary, _tokenAmount, _needLockUp);

		return true;
	}

	/**
	* @dev send token to mulitple user
	* @param _from token provider address 
	* @param _users user address list
	* @param _values the token amount list that want to deliver
	* @return A bool the operation was successful.
	*/
	function batchTransfer(address _from, address[] _users, uint256[] _values) onlyOwner whenBatchTransferNotStoped public returns (bool){
		require(_users.length > 0 && _values.length > 0 && _users.length == _values.length, "list error");

		require(_from != address(0), "token giver wallet is not the correct address");

		ris_token.batchTransfer(_from, _users, _values);
		return true;
	}

	/**
	* @dev set lockup status to mulitple user
	* @param _users user address list
	* @param _flags user lockup status 
	* @return A bool the operation was successful.
	*/
	function batchUpdateLockupList( address[] _users, bool[] _flags) onlyOwner public returns (bool){
		require(_users.length > 0 && _flags.length > 0 && _users.length == _flags.length, "list error");

		address user;
		bool flag;

		for(uint i = 0; i < _users.length; i++) {
			user = _users[i];
			flag = _flags[i];

            updateLockupList(user, flag);
        }		

		return true;
	}

	/**
	* @dev Function update lockup date
	* @param _newLockUpTime uint256 lockup date
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockup(uint256 _newLockUpTime) onlyOwner public returns (bool){

		require( _newLockUpTime > now );

		return lockup.updateLockup(_newLockUpTime);
	}

	/**
	* @dev Function update lockup status for purchaser
	* @param _add address
	* @param _flag bool this user's token should be lockup or not
	* @return A bool that indicates if the operation was successful.
	*/
	function updateLockupList(address _add, bool _flag) onlyOwner public returns (bool){
		
		return lockup.updateLockupList(_add, _flag);
	}	

	/**
	* @dev called for get status of pause.
	*/
	function ispause() public view returns(bool){
		return paused;
	}	

	/**
	* @dev Function update rate
	* @param _newRate rate
	* @return A bool that indicates if the operation was successful.
	*/
	function updateRate(int256 _newRate)onlyOwner public returns(bool){
		require(_newRate >= 1);

		rate = uint256(_newRate);

		emit UpdateRate( msg.sender, rate);

		return true;
	}

	/**
	* @dev Function get rate
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getRate() public view returns(uint256){
		return rate;
	}

	/**
	* @dev Function get minimum wei amount
	* @return A uint256 that indicates if the operation was successful.
	*/
	function getMinimumAmount() public view returns(uint256){
		return minimum_weiAmount;
	}

	/**
	* @dev Function update minimum wei amount
	* @return A uint256 that indicates if the operation was successful.
	*/
	function updateMinimumAmount(int256 _new_minimum_weiAmount)onlyOwner public returns(bool){

		require(_new_minimum_weiAmount >= 0);

		minimum_weiAmount = uint256(_new_minimum_weiAmount);

		emit UpdateMinimumAmount( msg.sender, minimum_weiAmount);

		return true;
	}
}
