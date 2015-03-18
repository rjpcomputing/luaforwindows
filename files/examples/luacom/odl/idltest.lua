require "luacom"

lib = luacomE.NewLibrary {
  name = "SmallFurryCreatures",
  uuid = "22582D65-4EE0-11d1-8791-0060B07BFA18",
  version = "1.0"
}

lib:AddImport("stdole32.tlb")

int = lib:AddInterface{
  name = "ISFC",
  uuid = "22582D66-4EE0-11d1-8791-0060B07BFA18",
}

int:AddMethod{
  type = "boolean",
  name = "RequestMacro",
  parameters = {
    { attributes = { "out" }, type = "VARIANT*", name = "p_Variant1" },
    { attributes = { "out" }, type = "VARIANT*", name = "p_Variant2" }
  }
}

int:AddMethod{
  type = "boolean",
  name = "ExecuteMacro",
  parameters = {
    { attributes = { "in" }, type = "VARIANT*", name = "p_Variant1" },
    { attributes = { "in", "out" }, type = "VARIANT*", name = "p_Variant2" }
  }
}

int:AddMethod{
  name = "LoadCommand",
  parameters = {
    { attributes = { "in" }, type = "long", name = "Cmd" },
    { attributes = { "out" }, type = "BSTR*", name = "Data" }
  }
}

coclass = lib:AddCoclass{
  name = "OLE",
  uuid = "22582D67-4EE0-11d1-8791-0060B07BFA18"
}

coclass:AddInterface{
  "default",
  name = "ISFC"
}

lib:WriteTLB("test")
