// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC677Receiver {
    /**
     * @dev Method invoked when tokens transferred via transferAndCall method
     * @param sender Original token sender
     * @param value Tokens amount
     * @param data Additional data passed to contract
     */
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes calldata data
    ) external virtual;
}

contract SocialClaim is VRFConsumerBaseV2, ChainlinkClient, ERC677Receiver, Ownable {
    address linkTokenContract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    uint256 constant NULL = 0;

    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 public VRFSubscriptionId;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint256 fee = 0.1 * 10 ** 18;

    // Withdrawal Oracle
    address private withdrawalOracle = 0xFA776B1C972578c034B88e880F2F65729b43e9B0;
    bytes32 private withdrawalJobId = "154067c0791e4b738cbc7edde49139be";
    uint256 withdrawalOracleFee = 0.1 * 10 ** 18;

    // walletManagement Oracle
    address private walletManagementOracle = 0x8B0376CF8CAcA511bB4F84b844f001B80263dfCE;
    bytes32 private walletManagementJobId = "c5a0f8caea544d75b03fb8ada31a1c65";
    uint256 walletManagementOracleFee = 0.1 * 10 ** 18;

    // SOCIALCLAIM SPECIFIC

    string public validSelector;
    struct Request
    {
        string URL;
        bytes32 walletID;
        string selector;
        uint256 challenge;
        address recipient;
    }

    struct Transfer
    {
        bytes32 walletID;
        address recipient;
    }

    struct Balance
    {
        uint256 amount;
    }

    struct Wallet
    {
        string URL;
    }

    mapping (address => Balance) balances;
    mapping (bytes32 => Wallet) wallets;

    mapping (uint256 => address) VRFRequestIds;

    mapping (address => Request) creationRequests;
    mapping (bytes32 => address) creationRequestIds;

    mapping (address => Request) withdrawalRequests;
    mapping (bytes32 => address) withdrawalRequestIds;

    mapping (address => Transfer) transfers;
    mapping (bytes32 => address) transferRequestIds;

    // EVENTS

    event PaymentSet(address requester, uint256 balance);
    event WithdrawalUpdate(address requester, uint256 challenge);
    event WithdrawalResult(address requester, uint256 status);
    event WalletCreationUpdate(address requester);
    event WalletCreated(address requester, bytes32 walletAddress);

    using Chainlink for Chainlink.Request;
    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkTokenContract);
        setChainlinkToken(linkTokenContract);
        createNewSubscription();
    }

    function setValidSelector(string calldata selector) public onlyOwner {
        validSelector = selector;
    }

    function requestWithdrawal(bytes32 walletID) public {
        Wallet memory w = wallets[walletID];
        if (bytes(w.URL).length == NULL)
            revert("Wallet doesn't exist");
        Balance storage balance = balances[msg.sender];
        Request storage rq = withdrawalRequests[msg.sender];
        if (balance.amount < fee)
            revert("Please send 0.1 LINK for wallet creation to this contract address");
        balance.amount -= fee;
        rq.URL = w.URL;
        rq.walletID = walletID;
        rq.challenge = NULL;

        emit WithdrawalUpdate(msg.sender, rq.challenge);
        LINKTOKEN.transferAndCall(address(COORDINATOR), fee, abi.encode(VRFSubscriptionId));
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            VRFSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        VRFRequestIds[requestId] = msg.sender;
    }

    function requestWalletCreation(string calldata URL) public {
        Request storage rq = creationRequests[msg.sender];
        Balance storage balance = balances[msg.sender];
        if (balance.amount < walletManagementOracleFee)
            revert("Please send 0. LINK (request) and 0.1 LINK (per 'verify' call) to this contract address");
        balance.amount -= walletManagementOracleFee;
        rq.URL = URL;
        emit WalletCreationUpdate(msg.sender);
        Chainlink.Request memory oracleRequest = buildChainlinkRequest(walletManagementJobId, address(this), this.fulfill.selector);
        oracleRequest.add("url", URL);
        bytes32 oracleRequestId = sendChainlinkRequestTo(walletManagementOracle, oracleRequest, walletManagementOracleFee);
        creationRequestIds[oracleRequestId] = msg.sender;
    }

    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes calldata data
    ) external override linkTokenOnly {
        Balance storage balance = balances[sender];
        balance.amount += value;
        emit PaymentSet(sender, balance.amount);
    }

    modifier linkTokenOnly() {
        require(msg.sender == address(LINKTOKEN), "Tokens can only be sent via LINK");
        _;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address initiator = VRFRequestIds[requestId];
        withdrawalRequests[initiator].challenge = randomWords[0];
        emit WithdrawalUpdate(initiator, withdrawalRequests[initiator].challenge);
    }

    function createNewSubscription() private {
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        VRFSubscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(VRFSubscriptionId, consumers[0]);
    }

    function withdraw(address recipient) public
    {
        Request storage rq = withdrawalRequests[msg.sender];
        Balance storage balance = balances[msg.sender];
        if (recipient != address(recipient))
            revert("Invalid ERC20 Address provided");
        if (bytes(validSelector).length == NULL)
            revert("Valid selector not set");
        if (balance.amount < withdrawalOracleFee)
            revert("Please send 0.1 LINK (withdrawal request) and 0.1 LINK (per 'withdraw' call) to this contract address");
        balance.amount -= withdrawalOracleFee;
        rq.recipient = recipient;

        Chainlink.Request memory withdrawalOracleRequest = buildChainlinkRequest(withdrawalJobId, address(this), this.fulfill.selector);
        withdrawalOracleRequest.add("url", rq.URL);
        withdrawalOracleRequest.add("selector", validSelector);
        withdrawalOracleRequest.add("challenge", Strings.toString(rq.challenge));
        withdrawalOracleRequest.add("walletID", bytes32ToString(rq.walletID));
        withdrawalOracleRequest.add("recipient", toAsciiString(rq.recipient));
        bytes32 oracleRequestId = sendChainlinkRequestTo(withdrawalOracle, withdrawalOracleRequest, withdrawalOracleFee);
        withdrawalRequestIds[oracleRequestId] = msg.sender;
    }

    function fulfill(bytes32 _requestId, bytes32 _value) public recordChainlinkFulfillment(_requestId)
    {
        address creatorInitiator = creationRequestIds[_requestId];
        address withdrawerInitiator = withdrawalRequestIds[_requestId];

        if (creatorInitiator != address(0)) {
            Wallet memory wt = Wallet({URL: creationRequests[creatorInitiator].URL});
            wallets[_value] = wt;
            delete creationRequests[creatorInitiator];
            delete creationRequestIds[_requestId];
            emit WalletCreated(creatorInitiator, _value);
        } else if (withdrawerInitiator != address(0)) {
            emit WithdrawalResult(withdrawerInitiator, uint(_value));
            delete withdrawalRequests[withdrawerInitiator];
            delete withdrawalRequestIds[_requestId];
        }
    }

    // UTILS

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
