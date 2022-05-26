<img src="https://svgur.com/i/jYf.svg" width="200"/>

## We empower ✊ people to fundraise for charities and individuals
####Trusted, secure and decentralised

### This [master contract](./socialclain.sol) can be found live on the Polygon Mumbai Testnet :
[0x100Fd5DC88898Fd061078579CACCD431FDEE72fA](https://mumbai.polygonscan.com/address/0x100Fd5DC88898Fd061078579CACCD431FDEE72fA)

### Disclamer
TODO
[comment]: <> (This contract requires a transfer of $LINK to operate &#40;0.1 for the `requestVerification&#40;&#41;` method and 0.1 per each call of the `verify&#40;&#41;` method&#41;)

[comment]: <> (⚠️ Do not transfer $LINK directly to the contract, use the [ERC677 transferAndCall&#40;&#41; method]&#40;https://github.com/ethereum/EIPs/issues/677&#41;)

### Recommended usage
The recommended way of interaction with the contract is to use the following dapp :
[socialclaim.nescrypto.com](https://socialclaim.nescrypto.com)

### Manual usage for URL verification
TODO

[comment]: <> (- 1:  `transferAndCall&#40;&#41;` to transfer $LINK tokens to the contract balance)

[comment]: <> (- 2: `requestVerification&#40;&#41;` to create the request)

[comment]: <> (- 3: subscribe for the `ValidationUpdate&#40;&#41;` event to get the randomly-generated challenge)

[comment]: <> (- 4:  `verify&#40;&#41;` to finalize the process)

[comment]: <> (- 5: subscribe to the `VerificationResult&#40;&#41;` event to get the verification result)

### Manual usage for getting a verification report
TODO

[comment]: <> (- 1: `getVerificationsForAddress&#40;address&#41;` with a valid BSC Testnet address)

[comment]: <> (- 2: subscribe to the `VerificationForAddress&#40;&#41;` event to get each verification)

### Notes if you wish to deploy this contract 
- at deploy the contract creates a [VRF subscription](https://vrf.chain.link), its recommended to manually transfer at least 1 $LINK at deploy, to avoid issues with getting "pending" stuck RNG requests
