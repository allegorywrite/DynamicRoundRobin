// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title ダイナミック傘連判状
 * @author tomoking
 * @notice ERC721
 */
contract DynamicRoundRobin is ERC721URIStorage, ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
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

    //ユーザーデータ
    bytes32 public data;
    string private _initialUri;
    string private robinUri;
    string private successor = "tomoking";

    //Chainlinknode情報
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 private currentRobinId;

    //@title コンストラクタ
    constructor(string memory initialUri_)ERC721("RoundRobin","Robin"){
      _initialUri = initialUri_;
      setPublicChainlinkToken();
      // Oracle address here
      oracle = 0xD8269ebfE7fCdfCF6FaB16Bb4A782dC8Ab59b53C;
      // Job Id here
      jobId = "09f1fff2c5374f5bb98052a4ac833571";
      fee = 0.1 * 10 ** 18; 
    }

    /*
    * @title createPlainRobin
    * @notice ロビンのMintとinitialURIの設定
    * @dev RobinIdはCounterを使用
    */
    function createPlainRobin() public {
      //準備
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      RobinsToSuccessors[_RobinId] = 0;

      _safeMint(msg.sender, _RobinId);
      _setTokenURI(_RobinId, _initialUri);

      _robinCounter.increment();
    }

    /*
    * @title createRobin
    * @notice ロビンのMintと継承
    * @dev RobinIdはCounterを使用
    */
    function createRobin() public {
      //準備
      uint256 _RobinId = _robinCounter.current();
      Rarity initialEigenVal = Rarity(0);
      tokenIdToRarity[_RobinId] = initialEigenVal;
      RobinsToSuccessors[_RobinId] = 1;
      uint256 successorId = RobinsToSuccessors[_RobinId];

      _safeMint(msg.sender, _RobinId);
      _setTokenURI(_RobinId, _initialUri);
      _change(successorId, _RobinId);

      RobinsToSuccessors[_RobinId] = RobinsToSuccessors[_RobinId].add(1);
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
      currentRobinId = robinId;
      requestData();
      _grading(robinId, successorId);
    }

    /*
    * @title _grading
    * @notice グレードの判定
    * @dev Successor = 0~2=>STANDARD, 3~9=>EPIC, 10~=>LEGEND
    */
    function _grading(uint256 robinId, uint256 successorId) private {
      if(successorId <= 2){
        tokenIdToRarity[robinId] = Rarity.STANDARD;
      }
      else if(successorId <= 9){
        tokenIdToRarity[robinId] = Rarity.EPIC;
      }
      else {
        tokenIdToRarity[robinId] = Rarity.LEGEND;
      }
    }

    /*
    * @title requestData
    * @notice apiにデータ取得をリクエスト
    * @return requestId 
    * @dev requestの経路 DynamicRountRobin => ChainlinkClient => Oracle
    * => Job(Chainlinknode) => api
    */
    function requestData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "API_URL");
        request.add("path", "JSON_PATH");

        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /*
    * @title fulfill
    * @notice apiからデータを受け取ってコントラクトに格納する関数
    * @param _requestId 
    * @param _data bytes32のデータ群
    * @dev ChainlinkClientがこの関数を呼び出すことをbuildChainlinkRequest()で設定
    */
    function fulfill(bytes32 _requestId, bytes32 _data) public recordChainlinkFulfillment(_requestId)
    {
        data = _data;
        //データの分岐
        //ToDo
        robinUri = toString(data);
        // successor = bytes32ToString(successor_byte32);
        _setTokenURI(currentRobinId, robinUri);
    }

    /*
    * @title toString
    * @notice bytes32 => string
    * @param _bytes32 oracleから渡されるbytes32のデータ
    * @return string
    * @dev 引数はマージンが右側のByteコードのみ
    */
    function toString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
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