// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Dsc} from "./Dsc.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20}"@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
-1 Token == $1 peg
-Exogenous collateral
-Algorimitically stable

based on MakerDAO(DAI)

*/
contract DscEngine is ReentrancyGuard,IERC20{

   //errors
   error DscEngine_NeedsMorethanZero();
    error  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DscEngine__TokenNotAllowed(token);
    error DscEngine__TransferFailed();

     // Events
  event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);



 /// @dev Mapping of token address to price feed address

    mapping(address collateralToken => address priceFeed) private s_priceFeeds;

     /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;



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
    
    s_collateralDeposited[msg.sender][tokenCollateralAddress]+=amountCollateral; //updating state
    emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
     bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
     if(!success ){
      revert DscEngine__TransferFailed();
     }

  }



  function redeemCollateralForDsc()external {}

  function burnDsc() external{}

  function Liquidation() external {}

  function getHealfactor() external {}


}