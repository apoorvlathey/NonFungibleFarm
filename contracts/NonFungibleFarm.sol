pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * User Flow:
 * NFT's are deposited into this contract, having some Price as `points` associated to them.
 * In order to claim an NFT, the user must have sufficient `points` to reach Price threshold.
 * To increase `points` balance, user must deposit lp tokens to this contract.
 * `points` balance increases dynamically with each passing second allowing user to Farm NFTs!
 * 
 */

contract NonFungibleFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;         // current staked LP
        uint256 lastUpdateAt;   // unix timestamp for last details update (when pointsDebt calculated)
        uint256 pointsDebt;     // total points collected before latest deposit
    }
    
    struct NFTInfo {
        address contractAddress;
        uint256 id;             // NFT id
        uint256 remaining;      // NFTs remaining to farm
        uint256 price;          // points required to claim NFT
    }
    
    uint256 public emissionRate;       // points generated per LP token per second staked
    IERC20 lpToken;                    // token being staked
    
    NFTInfo[] public nftInfo;
    mapping(address => UserInfo) public userInfo;
    
    constructor(uint256 _emissionRate, IERC20 _lpToken) public {
        emissionRate = _emissionRate;
        lpToken = _lpToken;
    }
    
    function addNFT(
        address contractAddress,    // Only ERC-1155 NFT Supported!
        uint256 id,
        uint256 total,              // amount of NFTs deposited to farm (need to approve before)
        uint256 price
    ) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            total,
            ""
        );
        nftInfo.push(NFTInfo({
            contractAddress: contractAddress,
            id: id,
            remaining: total,
            price: price
        }));
    }
    
    function deposit(uint256 _amount) external {
        lpToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        
        UserInfo storage user = userInfo[msg.sender];
        
        // already deposited before
        if(user.amount != 0) {
            user.pointsDebt = pointsBalance(msg.sender);
        }
        user.amount = user.amount.add(_amount);
        user.lastUpdateAt = now;
    }
    
    // claim nft if points threshold reached
    function claim(uint256 _nftIndex, uint256 _quantity) public {
        NFTInfo storage nft = nftInfo[_nftIndex];
        require(nft.remaining > 0, "All NFTs farmed");
        require(pointsBalance(msg.sender) >= nft.price.mul(_quantity), "Insufficient Points");
        UserInfo storage user = userInfo[msg.sender];
        
        // deduct points
        user.pointsDebt = pointsBalance(msg.sender).sub(nft.price.mul(_quantity));
        user.lastUpdateAt = now;
        
        // transfer nft
        IERC1155(nft.contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            nft.id,
            _quantity,
            ""
        );
        
        nft.remaining = nft.remaining.sub(_quantity);
    }
    
    function claimMultiple(uint256[] calldata _nftIndex, uint256[] calldata _quantity) external {
        require(_nftIndex.length == _quantity.length, "Incorrect array length");
        for(uint64 i=0; i< _nftIndex.length; i++) {
            claim(_nftIndex[i], _quantity[i]);
        }
    }
    
    // claim random nft's from available balance
    function claimRandom() public {
        for(uint64 i; i < nftCount(); i++) {
            NFTInfo storage nft = nftInfo[i];
            uint256 userBalance = pointsBalance(msg.sender);
            uint256 maxQty = userBalance.div(nft.price);        // max quantity of nfts user can claim
            if(nft.remaining > 0 && maxQty > 0) {
                if(maxQty <= nft.remaining) {
                    claim(i, maxQty);
                } else {
                    claim(i, nft.remaining);
                }
            }
        }
    }
    
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Insufficient staked");
        
        // update userInfo
        user.pointsDebt = pointsBalance(msg.sender);
        user.amount = user.amount.sub(_amount);
        user.lastUpdateAt = now;
        
        lpToken.safeTransfer(
            msg.sender,
            _amount
        );
    }
    
    // claim random NFTs and withdraw all LP tokens
    function exit() external {
        claimRandom();
        withdraw(userInfo[msg.sender].amount);
    }
    
    function pointsBalance(address userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        return user.pointsDebt.add(_unDebitedPoints(user));
    }
    
    function _unDebitedPoints(UserInfo memory user) internal view returns (uint256) {
        return now.sub(user.lastUpdateAt).mul(emissionRate).mul(user.amount);
    }
    
    function nftCount() public view returns (uint256) {
        return nftInfo.length;
    }
    
    // required function to allow receiving ERC-1155
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}