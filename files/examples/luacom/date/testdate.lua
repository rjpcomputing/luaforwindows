require("luacom")

teste = {}

function print_date(date)
  if type(date)=="table" then
    for key, val in pairs(date) do
      print(key .. "=" .. val)
    end
  else
    print(date)
  end
end

teste.Test = function(self, in_param, in_out_param, out_param)
  print_date(in_param)
  print_date(in_out_param)
  return in_out_param, in_param, in_param
end

obj = luacom.ImplInterfaceFromTypelib(teste, "test.tlb", "IDataConversionTest")
assert(obj)

teste.TestDATE = teste.Test

date = "29/2/1996 10:00:00"
date2 = "1/1/2001 01:00:00"
date_res1, date_res2, date_res3 = obj:TestDATE(date, date2)
assert(date_res1:find '01')
assert(date_res2:find '96')
assert(date_res3 == date_res2)
-- note: Regional Settings in Windows Control Panel
-- may convert dates to a different format.

luacom.DateFormat = "table"

date = { Day=29, Month=2, Year=1996, Hour=10, Minute=0, Second=0 }
date2 = { Day=1, Month=1, Year=2001, Hour=01, Minute=0, Second=0 }
date_res1, date_res2, date_res3 = obj:TestDATE(date, date2)
print_date(date_res1)
print_date(date_res2)
print_date(date_res3)

luacom.DateFormat = "string"

date_res1, date_res2, date_res3 = obj:TestDATE(date, date2)
print_date(date_res1)
print_date(date_res2)
print_date(date_res3)
