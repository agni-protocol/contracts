import { bytecode } from '../../../core/artifacts/contracts/AgniPool.sol/AgniPool.json'
import { utils } from 'ethers'

export const POOL_BYTECODE_HASH = utils.keccak256(bytecode)

export function computePoolAddress(deployerAddress: string, [tokenA, tokenB]: [string, string], fee: number): string {
  console.log("POOL_BYTECODE_HASH", POOL_BYTECODE_HASH);
  const [token0, token1] = tokenA.toLowerCase() < tokenB.toLowerCase() ? [tokenA, tokenB] : [tokenB, tokenA]
  const constructorArgumentsEncoded = utils.defaultAbiCoder.encode(
    ['address', 'address', 'uint24'],
    [token0, token1, fee]
  )

  const create2Inputs = [
    "0xff",
    deployerAddress,
    // salt
    utils.keccak256(constructorArgumentsEncoded),
    // init code hash
    POOL_BYTECODE_HASH,
    // "0x6381d1fec6fd43bf99593bd7b0430ecc17a9539602121d21935e75216355d19c",
  ];
  const sanitizedInputs = `0x${create2Inputs.map((i) => i.slice(2)).join('')}`
  return utils.getAddress(`0x${utils.keccak256(sanitizedInputs).slice(-40)}`)
}
