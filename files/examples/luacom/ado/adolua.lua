-- dblua.lua

do 
local dblua_data = {}

require("luacom")


function DBOpen(connection_string)
  dblua_data.connection = luacom.CreateObject("ADODB.Connection")

  assert(dblua_data.connection)


  dblua_data.connection.ConnectionString = connection_string
  dblua_data.connection:Open()
end

function DBClose()
  dblua_data.connection:Close()
  dblua_data.connection = nil
  dblua_data.recordset = nil
end

function DBExec(statement)

  if statement == "%BEGIN" then
    dblua_data.connection:BeginTrans()
    return
  elseif statement == "%COMMIT" then
    dblua_data.connection:CommitTrans()
    return
  elseif statement == "%ROLLBACK" then
    dblua_data.connection:RollbackTrans()
    return
  end

  if dblua_data.recordset == nil then
    dblua_data.recordset = luacom.CreateObject("ADODB.RecordSet")
  elseif dblua_data.recordset.State ~= 0 then
    dblua_data.recordset:Close()
  end

  dblua_data.recordset:Open(statement, dblua_data.connection)

end


function DBRow()

  if dblua_data.recordset == nil then
    return nil
  elseif dblua_data.recordset.ActiveConnection == nil then
    return nil
  end

  if dblua_data.recordset.EOF == true then
    return nil
  end

  local row = {}
  local fields = dblua_data.recordset.Fields
  local i = 0

  while i < fields.Count do
  
    local field = fields:Item(i)
    row[i] = field.Value
    row[field.Name] = field.Value

    i = i + 1
  end

  dblua_data.recordset:MoveNext()

  return row
  
end

end
