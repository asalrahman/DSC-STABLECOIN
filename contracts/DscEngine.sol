// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Dsc} from "./Dsc.sol";



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

   //modifiers
   modifier moreThanZero(uint256 amount) {
    if(amount == 0){
        revert DscEngine_NeedsMorethanZero();}
    _;
   }

//    modifier isAllowed(address token) {
//     if(s_)
//    }



    // Dsc private immutable i_dsc;


    constructor(address[] memory tokenAddresses,address[]memory priceFeedaddresses,address dscAddress) {
        
        if(tokenAddresses.length != priceFeedaddresses.length){
            revert  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
            }

         
    }
  
  function depositeCollateralAndMintDsc() external {}

  function  deposite(address tokenCollateralAddress,uint256 amountCollateral )external moreThanZero(amountCollateral){
    


  }

  function redeemCollateralForDsc()external {}

  function burnDsc() external{}

  function Liquidation() external {}

  function getHealfactor() external {}


}