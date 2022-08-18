<img src="https://svgur.com/i/jYf.svg" width="200"/>

## We empower ✊ people to fundraise for charities and individuals
### Trusted, secure and decentralised

### This [master contract](./socialclaim.sol) can be found live on the Polygon Mumbai Testnet :
[0x0a07E53cbF44B50e92F81594c5AD74E0b2D2d452](https://mumbai.polygonscan.com/address/0x0a07E53cbF44B50e92F81594c5AD74E0b2D2d452)

### Disclamer

[comment]: <> (This contract requires a transfer of $LINK to operate &#40;0.1 for the `requestVerification&#40;&#41;` method and 0.1 per each call of the `verify&#40;&#41;` method&#41;)

[comment]: <> (⚠️ Do not transfer $LINK directly to the contract, use the [ERC677 transferAndCall&#40;&#41; method]&#40;https://github.com/ethereum/EIPs/issues/677&#41;)

### Recommended usage
The recommended way of interaction with the contract is to use the following dapp :
[socialclaim.nescrypto.com](https://socialclaim.nescrypto.com)

### For contract owner
- 1: `setWalletSelector()` to a HTML selector valid that can only be edited by the owner of the social media page you selected

### Manual usage for wallet creation

- 1:  `transferAndCall()` to transfer $LINK tokens to the contract balance

- 2: `requestWalletCreation()` to create the wallet

- 3: subscribe to the `WalletCreationUpdate()` and `WalletCreated()` events to get the wallet information

### Manual usage for withdrawal
- 1:  `transferAndCall()` to transfer $LINK tokens to the contract balance

- 2:  `requestWithdrawal()` to initialize the withdrawal process and get the challenge

- 3:  `withdraw()` to process the withdrawal

- 4: subscribe to the `WithdrawalUpdate()` and `WithdrawalResult()` events to get the withdrawal information


### Notes if you wish to deploy this contract 
- at deploy the contract creates a [VRF subscription](https://vrf.chain.link), its recommended to manually transfer at least 1 $LINK at deploy, to avoid issues with getting "pending" stuck RNG requests
