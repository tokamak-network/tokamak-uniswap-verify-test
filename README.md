# verify-uniswap-contracts
 verify uniswap contracts on etherscan

# verify-permit2(foundry version)
```bash
#Thanos-sepolia.
cd permit2 \
forge verify-contract --verifier blockscout \ 
  --verifier-url https://explorer.thanos-sepolia.tokamak.network/api \
  --compiler-version "v0.8.17+commit.8df45f5f" \
  --chain-id 111551119090 \
  0x000000000022D473030F116dDEE9F6B43aC78BA3 Permit2  
#Thanos-sepolia-nightly.
cd permit2 \
forge verify-contract --verifier blockscout \ 
  --verifier-url https://explorer.thanos-sepolia-nightly.tokamak.network/api \
  --compiler-version "v0.8.17+commit.8df45f5f" \
  --chain-id 111551118282 \
  0x000000000022D473030F116dDEE9F6B43aC78BA3 Permit2



