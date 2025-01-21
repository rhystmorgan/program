use aiken/collection/list
use cardano/transaction.{Transaction}

//                                //
// Smart Wallet PKH -> StakeCred? //
//                                //

validator smartWallet(pkh: ByteArray) {
  spend(_d: Data, _r: Data, _oref: Data, tx: Transaction) {
    list.has(tx.extra_signatories, pkh)
  }

  else(_) {
    fail
  }
}
