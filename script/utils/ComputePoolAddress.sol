// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract ComputePoolAddress {
    // get bytecode of deployed pool, or any other contract
    function getContractByteCode(
        address _addr
    ) public view returns (bytes memory) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        bytes memory bytecode = new bytes(length);
        assembly {
            extcodecopy(_addr, add(bytecode, 0x20), 0, length)
        }
        return bytecode;
    }

    // compute hash of bytecode
    function computePoolInitCodeHash(
        address _contractAddress
    ) public view returns (bytes32) {
        // Get the bytecode of the pool contract
        bytes memory poolBytecode = getContractByteCode(_contractAddress);

        // Compute the keccak256 hash of the bytecode
        bytes32 hash = keccak256(poolBytecode);

        return hash;
    }

    // compute [replicate] deployed pool address deterministically
    function computeAddress(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        address contract_
    ) public view returns (address pool) {
        require(token0 < token1, "token1 > token0");
        bytes32 POOL_INIT_CODE_HASH = computePoolInitCodeHash(contract_);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(token0, token1, fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
