use cardano/assets
use cardano/transaction.{NoDatum, Transaction, placeholder}
use init/pro_tokens.{Account, Recipient, Supply, Transfer}
use tools as t

test supplyMint() {
  let boot = t.oref(#"0000", 1)

  let script = #"aaaa"
  let supply = 1000000
  let action = Supply(supply)
  let supplyValue =
    assets.merge(
      t.makeAsset(script, script, 1),
      t.makeAsset(script, "", supply),
    )

  let bootIn =
    t.input(
      boot,
      t.output(t.walletAddress(#"1111"), assets.from_lovelace(100), NoDatum),
    )

  let supplyOut = t.output(t.scriptAddress(script), supplyValue, NoDatum)

  let tx =
    Transaction {
      ..placeholder,
      inputs: [bootIn],
      outputs: [supplyOut],
      mint: supplyValue,
    }

  pro_tokens.account.mint(boot, action, script, tx)?
}

test accountMint() {
  let boot = t.oref(#"0000", 1)

  let script = #"aaaa"
  let user = #"face"
  let action = Account(user)
  let accountValue = t.makeAsset(script, user, 1)

  let userIn =
    t.input(
      t.oref(#"1111", 1),
      t.output(t.walletAddress(user), assets.from_lovelace(100), NoDatum),
    )

  let supplyOut = t.output(t.scriptAddress(script), accountValue, NoDatum)

  let tx =
    Transaction {
      ..placeholder,
      inputs: [userIn],
      outputs: [supplyOut],
      mint: accountValue,
    }

  pro_tokens.account.mint(boot, action, script, tx)?
}

test sendTokens() {
  let boot = t.oref(#"0000", 1)
  let oref = t.oref(#"1111", 1)
  let recIn = t.oref(#"1111", 2)

  let script = #"aaaa"
  let user = #"face"
  let recipient = #"cafe"
  let action = Transfer(user, 40)
  let recAction = Recipient

  let userIn =
    t.input(
      t.oref(#"1111", 1),
      t.output(
        t.scriptAddress(script),
        assets.merge(t.makeAsset(script, user, 1), t.makeAsset(script, "", 100)),
        NoDatum,
      ),
    )

  let recipientIn =
    t.input(
      recIn,
      t.output(
        t.scriptAddress(script),
        assets.merge(
          t.makeAsset(script, recipient, 1),
          t.makeAsset(script, "", 10),
        ),
        NoDatum,
      ),
    )

  let userOut =
    t.output(
      t.scriptAddress(script),
      assets.merge(t.makeAsset(script, user, 1), t.makeAsset(script, "", 60)),
      NoDatum,
    )

  let recipientOut =
    t.output(
      t.scriptAddress(script),
      assets.merge(
        t.makeAsset(script, recipient, 1),
        t.makeAsset(script, "", 50),
      ),
      NoDatum,
    )

  let tx =
    Transaction {
      ..placeholder,
      inputs: [userIn, recipientIn],
      outputs: [userOut, recipientOut],
      extra_signatories: [user],
    }

  and {
    pro_tokens.account.spend(boot, None, action, oref, tx)?,
    pro_tokens.account.spend(boot, None, recAction, recIn, tx)?,
  }
}

test closeAccount() {
  True
}

test burnSupply() {
  True
}
