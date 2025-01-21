test addToRegistry() {
  let registryInDatum =
    RegistryDatum {
      tokenPolicy: #"0000",
      nextPolicy: "",
      transferManagerHash: #"aaaa",
      userStateManagerHash: #"bbbb",
      globalStatePolicy: #"2222",
    }

  let registryOutDatum =
    RegistryDatum {
      tokenPolicy: #"0000",
      nextPolicy: #"1111",
      transferManagerHash: #"aaaa",
      userStateManagerHash: #"bbbb",
      globalStatePolicy: #"2222",
    }

  let newRegistryDatum =
    RegistryDatum {
      tokenPolicy: #"1111",
      nextPolicy: "",
      transferManagerHash: #"cccc",
      userStateManagerHash: #"dddd",
      globalStatePolicy: #"3333",
    }

  let tx =
    Transaction {
      ..placeholder,
      inputs: [userIn, registryIn],
      outputs: [registeryOut, newRegistery],
      mint: registryValue,
    }
}

test transferTokens() {
  let pInValue = assets.from_asset(#"1111", "", 100)
  let pOutValue = assets.from_asset(#"1111", "", 60)
  let pSentValue = assets.from_asset(#"1111", "", 40)

  let userIn =
    t.input(
      t.oref(#"0000", 1),
      t.output(t.scriptAddress(script, userPkh), pInValue, NoDatum),
    )

  let userOut = t.output(t.scriptAddress(script, userPkh), pOutValue, NoDatum)

  let sentOut = t.output(t.scriptAddress(script, userPkh), pSentValue, NoDatum)

  let tx =
    Transaction {
      ..placeholder,
      inputs: [userIn],
      outputs: [userOut, sentOut],
      reference_inputs: [registry, transferManager, userManager, globalState],
      extra_signatories: [user],
    }
}
