// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




error Dsc__AmountMustBeMoreThanZero();
error  Dsc__NotZeroAccount();
error Dsc__BurnAmountExceedsBalance();




contract Dsc is ERC20Burnable,Ownable {
    constructor() ERC20("Decentalized stablecoin","DSC"){}


  function burn(uint256 _amount) public override onlyOwner {
    uint256 balnce = balanceOf(msg.sender);
    if (_amount <=0 ){
        revert Dsc__AmountMustBeMoreThanZero();
        }

        if(balnce < _amount){
            revert Dsc__BurnAmountExceedsBalance();
            }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if(_to == address(0)){
            revert  Dsc__NotZeroAccount();}

        if(_amount <= 0  ){
            revert Dsc__AmountMustBeMoreThanZero();}

              _mint(_to, _amount);
        return true;
    }
}