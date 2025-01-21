//                     //
// Token Registry List //
//                     //

pub type RegistryNode {
  // minting policy of this programmable token 
  tokenPolicy: ByteArray,
  // linked list
  nextTokenPolicy: ByteArray,
  // spending logic
  transferManagerHash: ByteArray,
  // userState (verify readonly states without transfers)
  userStateManagerHash: ByteArray,
  // nft of a global state for the programmable token
  globalStatePolicy: ByteArray,
}

pub type RegistryAction {
  // I dont think we need this
  RUpdate
  RInsert
  RRemove
  RPrevious
}

pub type RegistryMintAction {
  RMint {
    policy: ByteArray,
    transfer: ByteArray,
    user: ByteArray,
    global: ByteArray,
  }
  RBurn
}
// validator
