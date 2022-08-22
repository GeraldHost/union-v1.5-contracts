//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Controller} from "../Controller.sol";
import {AMarket3} from "../interfaces/aave/AMarket3.sol";
import {LendingPool3} from "../interfaces/aave/LendingPool3.sol";
import {IMoneyMarketAdapter} from "../interfaces/IMoneyMarketAdapter.sol";

/**
 * @author Union
 * @title AaveAdapter
 * @dev The implementation of Aave.Finance MoneyMarket that integrates with AssetManager.
 */
contract AaveV3Adapter is Controller, IMoneyMarketAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* -------------------------------------------------------------------
      Storage 
    ------------------------------------------------------------------- */

    /**
     * @dev the AssetManager contract address
     */
    address public assetManager;

    /**
     * @dev Aave Market contract
     */
    AMarket3 public market;

    /**
     * @dev Aave Lending pool contract
     */
    LendingPool3 public lendingPool;

    /**
     * @dev Mapping of token to aToken
     */
    mapping(address => address) public tokenToAToken;

    /**
     * @dev Mapping of token to floor amount
     */
    mapping(address => uint256) public override floorMap;

    /**
     * @dev Mapping of token to ceiling amount
     */
    mapping(address => uint256) public override ceilingMap;

    /* -------------------------------------------------------------------
      Events 
    ------------------------------------------------------------------- */

    event LogSetAssetManager(address sender, address assetManager);

    event LogSetFloor(address sender, address tokenAddress, uint256 floor);

    event LogSetCeiling(address sender, address tokenAddress, uint256 ceiling);

    /* -------------------------------------------------------------------
      Constructor/Initializer 
    ------------------------------------------------------------------- */

    function __AaveAdapter_init(
        address _assetManager,
        LendingPool3 _lendingPool,
        AMarket3 _market
    ) public initializer {
        Controller.__Controller_init(msg.sender);
        assetManager = _assetManager;
        lendingPool = _lendingPool;
        market = _market;
    }

    /* -------------------------------------------------------------------
      Modifiers 
    ------------------------------------------------------------------- */

    modifier checkTokenSupported(address tokenAddress) {
        require(_supportsToken(tokenAddress), "AaveAdapter: Token not supported");
        _;
    }

    modifier onlyAssetManager() {
        require(msg.sender == assetManager, "AaveAdapter: only asset manager can call");
        _;
    }

    /* -------------------------------------------------------------------
      Setter Functions 
    ------------------------------------------------------------------- */

    /**
     * @dev Set the asset manager contract address
     * @dev Only callable by the admin
     * @param _assetManager AssetManager contract address
     */
    function setAssetManager(address _assetManager) external onlyAdmin {
        assetManager = _assetManager;
        emit LogSetAssetManager(msg.sender, _assetManager);
    }

    /**
     * @dev Set floor amount
     * @dev Only callable by the admin
     * @param tokenAddress Address of the token to set the floor for
     * @param floor Floor amount
     */
    function setFloor(address tokenAddress, uint256 floor) external onlyAdmin checkTokenSupported(tokenAddress) {
        floorMap[tokenAddress] = floor;
        emit LogSetFloor(msg.sender, tokenAddress, floor);
    }

    /**
     * @dev Set ceiling amount
     * @dev Only callable by the admin
     * @param tokenAddress Address of the token to set the ceiling for
     * @param ceiling ceiling amount
     */
    function setCeiling(address tokenAddress, uint256 ceiling) external onlyAdmin checkTokenSupported(tokenAddress) {
        ceilingMap[tokenAddress] = ceiling;
        emit LogSetCeiling(msg.sender, tokenAddress, ceiling);
    }

    /* -------------------------------------------------------------------
      View Functions  
    ------------------------------------------------------------------- */

    /**
     * @dev Get the underlying market rate
     * @param tokenAddress The underlying token address
     */
    function getRate(address tokenAddress) external view override returns (uint256) {
        LendingPool3.ReserveData memory reserveData = lendingPool.getReserveData(tokenAddress);
        return uint256(reserveData.currentLiquidityRate);
    }

    /**
     * @dev Get total supply of this Contracts
     * @param tokenAddress The token to check supply for
     */
    function getSupply(address tokenAddress) external view override returns (uint256) {
        return _getSupply(tokenAddress);
    }

    /**
     * @dev Get total supply of this Contracts including any balance that has been
     * deposited into the underlying market
     * @param tokenAddress The token to check supply for
     */
    function getSupplyView(address tokenAddress) external view override returns (uint256) {
        return _getSupply(tokenAddress);
    }

    /**
     * @dev Check if this token is supported
     * @param tokenAddress The token to check
     */
    function supportsToken(address tokenAddress) external view override returns (bool) {
        return _supportsToken(tokenAddress);
    }

    /* -------------------------------------------------------------------
      Core Functions  
    ------------------------------------------------------------------- */

    /**
     * @dev Add aToken to the token mapping for a supported token
     * @param tokenAddress Token address
     */
    function mapTokenToAToken(address tokenAddress) external onlyAdmin {
        LendingPool3.ReserveData memory reserveData = lendingPool.getReserveData(tokenAddress);
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        token.safeApprove(address(lendingPool), 0);
        token.safeApprove(address(lendingPool), type(uint256).max);
        tokenToAToken[tokenAddress] = reserveData.aTokenAddress;
    }

    /**
     * @dev Deposit tokens into the underlying Aave V3 lending pool
     * @param tokenAddress Token address
     */
    function deposit(address tokenAddress) external override checkTokenSupported(tokenAddress) {
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        lendingPool.deposit(tokenAddress, amount, address(this), 0);
    }

    /**
     * @dev Withdraw tokens from this adapter
     * @dev Only callable by the AssetManager
     * @param tokenAddress Token to withdraw
     * @param recipient Recieved by
     * @param tokenAmount Amount of tokens to withdraw
     */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 tokenAmount
    ) external override onlyAssetManager checkTokenSupported(tokenAddress) {
        lendingPool.withdraw(tokenAddress, tokenAmount, recipient);
    }

    /**
     * @dev Withdraw all tokens from this adapter
     * @dev Only callable by the AssetManager
     * @param tokenAddress Token to withdraw
     * @param recipient Recieved by
     */
    function withdrawAll(address tokenAddress, address recipient)
        external
        override
        onlyAssetManager
        checkTokenSupported(tokenAddress)
    {
        lendingPool.withdraw(tokenAddress, type(uint256).max, recipient);
    }

    /**
     * @dev Claim rewards from the Aave rewards controller
     * @param tokenAddress Token address
     * @param recipient The recipient
     */
    function claimRewards(address tokenAddress, address recipient) external override onlyAdmin {
        address aTokenAddress = tokenToAToken[tokenAddress];
        address[] memory assets = new address[](1);
        assets[0] = aTokenAddress;
        market.claimAllRewards(assets, recipient);
    }

    /* -------------------------------------------------------------------
      Internal Functions 
    ------------------------------------------------------------------- */

    function _getSupply(address tokenAddress) internal view returns (uint256) {
        address aTokenAddress = tokenToAToken[tokenAddress];
        IERC20Upgradeable aToken = IERC20Upgradeable(aTokenAddress);
        uint256 balance = aToken.balanceOf(address(this));
        if (balance <= 10) {
            return 0;
        }
        return balance;
    }

    function _supportsToken(address tokenAddress) internal view returns (bool) {
        return tokenToAToken[tokenAddress] != address(0);
    }
}
