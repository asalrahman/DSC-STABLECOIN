// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Dsc} from "./Dsc.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
- 1 Token == $1 peg
- Exogenous collateral
- Algorimitically stable

based on MakerDAO(DAI)

*/
contract DscEngine is ReentrancyGuard{

   //errors
   error DscEngine_NeedsMorethanZero();
    error  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DscEngine__TokenNotAllowed(address token);
    error DscEngine__TransferFailed();
    error DscEngine__BreaksHealthFactor(uint256 healthfactor);
    error DscEngine__MintingFailed();

     // Events
  event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
  event CollateralRedemed(address indexed user, address indexed token, uint256 indexed amount);

//state Variables 
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // need to be 200% over-collateralized
     uint256 private constant MINIMUM_HEATH_FACTOR =1;

 /// @dev Mapping of token address to price feed address

    mapping(address collateralToken => address priceFeed) private s_priceFeeds;

     /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
     //user to amount minted
     mapping(address user => uint256 amount) private s_DscMinted;
     address[] private s_collateralTokens;

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
    _;
   }



     Dsc private immutable i_dsc;


    constructor(address[] memory tokenAddresses,address[]memory priceFeedaddresses,address dscAddress) {
        
        if(tokenAddresses.length != priceFeedaddresses.length){
            revert  DscEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
            }

            for(uint256 i=0;i<tokenAddresses.length;i++){
              s_priceFeeds[tokenAddresses[i]]=priceFeedaddresses[i];
              s_collateralTokens.push(tokenAddresses[i]);
            }

         i_dsc =Dsc(dscAddress);
    }
  


//tokenCollateralAddress is the address of the collateral token you are depositing 
//amountCollateral the  amount you are depositing 
//amountDscToMint to get the dsc token
//deposite and mint dsc in one section
  function depositeCollateralAndMintDsc(
    address tokenCollateralAddress,
  uint256 amountCollateral,
  uint256 amountDscToMint) external {
   
   deposite(tokenCollateralAddress,amountCollateral);
   mintDsc(amountDscToMint);

  }



  function  deposite(address tokenCollateralAddress,uint256 amountCollateral ) public
   moreThanZero(amountCollateral) isAllowed(tokenCollateralAddress) nonReentrant{
    
    s_collateralDeposited[msg.sender][tokenCollateralAddress]+=amountCollateral; //updating state
    emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
     bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
     if(!success ){
      revert DscEngine__TransferFailed();
     }

  }

  function mintDsc(uint256 amountDscToMint)public moreThanZero(amountDscToMint) nonReentrant{
    
    s_DscMinted[msg.sender]+=amountDscToMint;
     _revertIfHealthFactorIsBroken(msg.sender);
     bool minted = i_dsc.mint(msg.sender,amountDscToMint);
     if(!minted){revert 
      DscEngine__MintingFailed();
     }

  }




  function redeemCollateralForDsc(address tokenCollateralAddress,
  uint256 amountCollateral,
  uint256 amountDscToBurn
             )external {
     
     burnDsc(amountDscToBurn);
     redemmCollateral(tokenCollateralAddress,amountCollateral);


  }

  function  redemmCollateral(address tokenCollateralAddress
  ,uint256 amountCollateral
   ) moreThanZero(amountCollateral) nonReentrant public  {
    s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral; //pull from state
     emit CollateralRedemed(msg.sender, tokenCollateralAddress,amountCollateral);
     bool success = IERC20(tokenCollateralAddress).transfer(msg.sender,amountCollateral);
     if(!success){
      revert DscEngine__TransferFailed();
     }


  }

  function burnDsc(uint256 amount) moreThanZero(amount) public{
    s_DscMinted[msg.sender]-=amount;
    bool success = i_dsc.transferFrom(msg.sender,address(this),amount);
    if (!success){
      revert DscEngine__TransferFailed();

    }
    i_dsc.burn(amount);
  }

  function Liquidation() external {}

  function getHealfactor() external {}


  
// view funtions 

  function _getAccountInfo(address user) private view returns(uint256 totalDscMinted,
  uint256 totalCollateralValueInUsd){
      
      totalDscMinted= s_DscMinted[user];
      totalCollateralValueInUsd=getAccountCollateralValue(user);//TODO: check this logic
      
  }

  function _healthfactor(address user) private view returns (uint256) {
    //total dsc minted 
    // total collateral Value
    (uint256 totalDscMinted,uint256 totalCollateralValueInUsd) = _getAccountInfo(user);
    uint256 collateralAdjustedForThreshold  =(totalCollateralValueInUsd * LIQUIDATION_THRESHOLD)/100;
    return (collateralAdjustedForThreshold * PRECISION)/totalDscMinted;
    
    //(1000 $eth *50)/100 = 500
    // then 500/100 = >1

  }

  function _revertIfHealthFactorIsBroken(address user)   internal view {
    // check healthfactor 
    // revert not enough health factor
    uint256 healthfactor =  _healthfactor(user);
    if(healthfactor<MINIMUM_HEATH_FACTOR) {
      revert DscEngine__BreaksHealthFactor(healthfactor);
    }
  }

 // External & Public View & Pure Functions

function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

 function getUsdValue(address token, uint256 usdAmountInWei) public view returns (uint256) {
          AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // $100e18 USD Debt
        // 1 ETH = 2000 USD
        // The returned value from Chainlink will be 2000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        return ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }


}