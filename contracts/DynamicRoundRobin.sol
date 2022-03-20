// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./APIConsumer.sol";

/**
 * @title ダイナミック傘連判状
 * @author tomoking
 * @notice ERC721
 */
contract DynamicRoundRobin is ERC721URIStorage, Ownable,APIConsumer {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _robinCounter;

    //@notice 列挙型グレード
    enum Rarity {STANDARD, EPIC, LEGEND}

    //@notice ロビンごとの継承者数
    mapping(uint256 => uint256) RobinsToSuccessors;
    //@notice ロビンごとの継承者名マッピング
    mapping(uint256 => mapping (uint256 => string)) Successors; 
    //@notice ロビンごとのグレード
    mapping(uint256 => Rarity) public tokenIdToRarity;
    
    string private _initialUri;
    Rarity public rarity;

    //@title コンストラクタ
    constructor(string memory initialUri_)ERC721("RoundRobin","Robin"){
      _initialUri = initialUri_;
    }

    /*
    * @title createPlainRobin
    * @notice ロビンのMintとinitialURIの設定
    * @dev RobinIdはCounterを使用
    */
    function createPlainRobin() public {
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      _safeMint(msg.sender, _RobinId);

      RobinsToSuccessors[_RobinId] = 0;
      _setTokenURI(_RobinId, _initialUri);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      _robinCounter.increment();
    }

    /*
    * @title createRobin
    * @notice ロビンのMintと継承
    * @dev RobinIdはCounterを使用
    */
    function createRobin() public {
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      _safeMint(msg.sender, _RobinId);

      RobinsToSuccessors[_RobinId] = 1;
      uint256 successorId = RobinsToSuccessors[_RobinId];
      RobinsToSuccessors[_RobinId] = RobinsToSuccessors[_RobinId].add(1);
      _change(successorId, _RobinId);
      _setTokenURI(_RobinId, _initialUri);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      _robinCounter.increment();
    }

    /*
    * @title Inherit
    * @notice ロビンの継承
    * @param to 継承先のアドレス
    * @param robinId 継承するロビンのId
    * @dev ConsumerApiからprofileを取得して格納
    */
    function Inherit(
      address to,
      uint256 robinId
    ) public {
      uint256 successorId = RobinsToSuccessors[robinId];
      RobinsToSuccessors[robinId] = RobinsToSuccessors[robinId].add(1);

      _change(successorId, robinId);
      transferFrom(_msgSender(), to, robinId);
    }

    /*
    * @title _change
    * @notice profileの更新
    * @param successorId 継承者数
    * @param robinId ロビンID
    * @dev url => _setTokenURI
    *      successor => Successors
    */
    function _change(uint256 successorId, uint256 robinId) private {
      string memory robinUri = getUri();
      string memory successor = getSuccessor();
      grading(successorId);
      _setTokenURI(robinId, robinUri);
      Successors[robinId][successorId] = successor;
      tokenIdToRarity[robinId] = rarity;
    }

    /*
    * @title grading
    * @notice グレードの判定
    * @dev Successor = 0~2=>STANDARD, 3~9=>EPIC, 10~=>LEGEND
    */
    function grading(uint256 successorId) private {
      if(successorId <= 2){
        rarity = Rarity.STANDARD;
      }
      else if(successorId <= 9){
        rarity = Rarity.EPIC;
      }
      else {
        rarity = Rarity.LEGEND;
      }
    }

    function getSuccessors(uint256 robinId) public view returns(uint256){
      return RobinsToSuccessors[robinId].sub(1);
    }

    function getGrade(uint256 robinId) public view returns(Rarity){
      return tokenIdToRarity[robinId];
    }

    function getSuccessorName(uint256 robinId, uint256 successorId) public view returns(string memory){
      return Successors[robinId][successorId];
    }
}