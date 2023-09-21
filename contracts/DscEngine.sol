// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Dsc} from "./Dsc.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/*
-1 Token == $1 peg
-Exogenous collateral
-Algorimitically stable

based on MakerDAO(DAI)

*/
contract DscEngine {

   //errors
   error DscEngine_NeedsMorethanZero();
    error  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DscEngine__TokenNotAllowed(token);

 /// @dev Mapping of token address to price feed address

    mapping(address collateralToken => address priceFeed) private s_priceFeeds;



   //modifiers
   modifier moreThanZero(uint256 amount) {
    if(amount == 0){
        revert DscEngine_NeedsMorethanZero();}
    _;
   }

   modifier isAllowed(address token) {
    if(s_priceFeeds[token] == address(0)){
        revert DscEngine__TokenNotAllowed(token);

    }
   }



     Dsc private immutable i_dsc;


    constructor(address[] memory tokenAddresses,address[]memory priceFeedaddresses,address dscAddress) {
        
        if(tokenAddresses.length != priceFeedaddresses.length){
            revert  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
            }

            for(uint256 i=0;i<tokenAddresses.length;i++){
              s_priceFeeds[tokenAddresses[i]]=priceFeedaddresses[i];
            }

         i_dsc =Dsc(dscAddress);
    }
  



  function depositeCollateralAndMintDsc() external {}

  function  deposite(address tokenCollateralAddress,uint256 amountCollateral )external
   moreThanZero(amountCollateral) isAllowed(tokenCollateralAddress) nonReentrant{
    


  }

  function redeemCollateralForDsc()external {}

  function burnDsc() external{}

  function Liquidation() external {}

  function getHealfactor() external {}


}