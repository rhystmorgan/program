contractIn
smart in

refInputs
registry
user
receiver ( each )
global state


---

## Linked List Datum - Token Registry

```
type RegistryNode {
  tokenPolicy: ByteArray, // minting policy of this programmable token 
  nextTokenPolicy: ByteArray, // linked list
  transferManagerHash: ByteArray, // spending logic
  userStateManagerHash: ByteArray, // userState (verify readonly states without transfers)
  policyGlobalStateCurrencySym: ByteArray, // nft of a global state for the programmable token
}
```

## User SmartWallet

`NoDatum`

---