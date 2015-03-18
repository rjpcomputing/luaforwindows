-----------------------------------------------------------------------------
-- Name:        unittest.wx.lua
-- Purpose:     Unit testing for wxLua, test a number of things to ensure
--              that wxLua is operating correctly.
-- Author:      John Labenski
-- Modified by:
-- Created:     04/20/2006
-- RCS-ID:
-- Copyright:   (c) 2006, John Labenski
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

tests_run = 0
failed_tests = 0
warnings = 0

function PrintOk(test, str)
    local result = ""
    tests_run = tests_run + 1

    if test then
        result = "OK   "
    else
        result = "FAIL "
        failed_tests = failed_tests + 1
    end

    print(result, str)
end

-- ---------------------------------------------------------------------------
-- Print args passed to this program when run
-- ---------------------------------------------------------------------------

if not arg then
    print("No args passed to the program")
else
    local start_n = 1
    while arg[start_n-1] do start_n = start_n - 1 end

    print(string.format("Program arg count %d", #arg))
    for n = start_n, #arg do
        if arg[n] then
            print(string.format("Program arg #%2d of %2d '%s'", n, #arg, arg[n]))
        end
    end
end

-- ---------------------------------------------------------------------------
print("\nSimple bindings tests of numbers, strings, objects.\n")
-- ---------------------------------------------------------------------------

a = wx.wxID_ANY
PrintOk(a == wx.wxID_ANY and a == -1, "Test %define wxID_ANY == -1")

a = wx.wxACCEL_NORMAL
PrintOk(a == wx.wxACCEL_NORMAL and a == 0, "Test %enum wxACCEL_NORMAL == 0")

a = wx.wxFILE_KIND_UNKNOWN
PrintOk(a == wx.wxFILE_KIND_UNKNOWN and a == 0, "Test %enum wxFileKind::wxFILE_KIND_UNKNOWN == 0")

a = wx.wxFile.read
PrintOk(a == wx.wxFile.read and a == 0, "Test %enum wxFile::OpenMode::read == 0")

PrintOk(wx.wxFTP.ASCII ~= nil, "Test class %enum wxFTP::ASCII is bound as wx.wxFTP.ASCII.")

a = wx.wxEVT_NULL
PrintOk(a == wx.wxEVT_NULL and a ~= nil, "Test %define_event wxEVT_NULL")

a = wx.wxIMAGE_OPTION_CUR_HOTSPOT_X
PrintOk(a == wx.wxIMAGE_OPTION_CUR_HOTSPOT_X and a == "HotSpotX", "Test %define_string wxIMAGE_OPTION_CUR_HOTSPOT_X")

a = wx.wxNullColour
PrintOk(a:Ok() == false, "Test %define_object wxNullColour is not Ok()")

a = wx.wxThePenList
PrintOk(a:FindOrCreatePen(wx.wxColour(1,2,3), 1, wx.wxSOLID):Ok(), "Test %define_pointer wxThePenList:FindOrCreatePen(wx.wxColour, 1, wx.wxSOLID) is Ok()")
PrintOk(a:FindOrCreatePen(wx.wxRED, 1, wx.wxSOLID):Ok(), "Test %define_pointer wxThePenList:FindOrCreatePen(wx.wxRED, 1, wx.wxSOLID) is Ok()")

-- ---------------------------------------------------------------------------
print("\nTest loading multiple bindings.\n")
-- ---------------------------------------------------------------------------

if wxstc then
    PrintOk(wxstc.wxSTC_WRAP_WORD == 1, "Test wxstc bindings wxstc.wxSTC_WRAP_WORD == 1")
    PrintOk(type(wxstc.wxStyledTextCtrl.new) == "function", "Test wxstc bindings type(wxstc.wxStyledTextCtrl.new) == \"function\"")
else
    print("\nWARNING - unable to test wxstc bindings? Should they be here?\n\n")
    warnings = warnings + 1
end

PrintOk(wxlua.WXLUA_TNIL == 2, "Test wxlua bindings wxlua.WXLUA_TNIL == 2")

-- ---------------------------------------------------------------------------
print("\nTest some automatic overload binding functions.\n")
-- ---------------------------------------------------------------------------

a = wx.wxString("Hello")
PrintOk(a:GetData() == "Hello", "Test automatic overload of wxString(\"lua string\")")
b = wx.wxString(a)
PrintOk(b:GetData() == "Hello", "Test automatic overload of wxString(wxString)")
b = wx.wxFileName("Hello")
PrintOk(b:GetFullPath() == "Hello", "Test automatic overload of wxFileName(\"lua string\")")
b = wx.wxFileName(a)
PrintOk(b:GetFullPath() == "Hello", "Test automatic overload of wxFileName(wxString)")

a = wx.wxArrayString({"a", "b", "c"})
PrintOk((a:Item(0) == "a") and (a:GetCount() == 3), "Test automatic overload of wxArrayString(lua table)")
b = wx.wxArrayString(a)
PrintOk((b:Item(1) == "b") and (b:GetCount() == 3), "Test automatic overload of wxArrayString(wxArrayString)")
b = a:ToLuaTable()
PrintOk((b[2] == "b") and (#b == 3), "Test wxArrayString::ToLuaTable()")

a = wx.wxSortedArrayString(wx.wxArrayString({"c", "b", "a"}))
PrintOk((a:Item(0) == "a") and (a:GetCount() == 3), "Test automatic overload of wxSortedArrayString(wxArrayString(lua table))")
a = wx.wxSortedArrayString({"c", "b", "a"})
PrintOk((a:Item(0) == "a") and (a:GetCount() == 3), "Test automatic overload of wxSortedArrayString(lua table)")
b = wx.wxSortedArrayString(a)
PrintOk((b:Item(1) == "b") and (b:GetCount() == 3), "Test automatic overload of wxSortedArrayString(wxSortedArrayString)")
b = a:ToLuaTable()
PrintOk((b[2] == "b") and (#b == 3), "Test wxSortedArrayString::ToLuaTable()")
collectgarbage("collect") -- test if wxLuaSmartwxSortedArrayString works

a = wx.wxArrayInt({1, 2, 3})
PrintOk((a:Item(0) == 1) and (a:GetCount() == 3), "Test automatic overload of wxArrayInt(lua table)")
b = wx.wxArrayInt(a)
PrintOk((b:Item(1) == 2) and (b:GetCount() == 3), "Test automatic overload of wxArrayInt(wxArrayInt)")
b = a:ToLuaTable()
PrintOk((b[2] == 2) and (#b == 3), "Test wxArrayInt::ToLuaTable()")

-- ---------------------------------------------------------------------------
print("\nTest some %member binding class functions.\n")
-- ---------------------------------------------------------------------------

pt = wx.wxPoint(1, 2)
PrintOk(pt:GetX() == 1, "%rename %member using wxPoint:GetX(), member variable functions")
PrintOk(pt.x == 1, "%rename %member using wxPoint.x, member variable properties work.")
PrintOk(pt.X == 1, "%rename %member using wxPoint.X, automatic properties work.")

pt2 = wx.wxPoint(pt)
PrintOk(pt.x == pt2:GetX(), "%rename %member using wxPoint(pt) and pt.x == pt2:GetX()")
pt2 = nil; pt2 = wx.wxPoint(pt)
PrintOk(pt:GetX() == pt2.x, "%rename %member using wxPoint(pt) and pt:GetX() == pt2.x")

-- Get functions already work, test Set functions
pt.x = 10
PrintOk(pt:GetX() == 10, "%rename %member using wxPoint.x = 10; wxPoint:GetX()")
PrintOk(pt.GetX(pt) == 10, "%rename %member using wxPoint.x = 10; wxPoint.GetX(self)")
pt:SetX(20)
PrintOk(pt.x == 20, "%rename %member using wxPoint:SetX(20); wxPoint.x")
pt.SetX(pt, 30)
PrintOk(pt.x == 30, "%rename %member using wxPoint.SetX(self, 30); wxPoint.x")
pt.X = 40
PrintOk(pt.X == 40, "%rename %member using wxPoint.X = 40; wxPoint.x")

-- ---------------------------------------------------------------------------
print("\nTest some %operator binding class functions.\n")
-- ---------------------------------------------------------------------------

a = wx.wxPoint(1, 2)
b = wx.wxPoint(1, 2)
c = wx.wxPoint(2, 4)
PrintOk(a:op_eq(b), "%operator wxPoint& operator==(const wxPoint& p) const")
PrintOk(a:op_eq(a), "%operator wxPoint& operator==(const wxPoint& p) const")
PrintOk(not a:op_ne(b), "%operator wxPoint& operator!=(const wxPoint& p) const")
PrintOk(a:op_ne(c), "%operator wxPoint& operator!=(const wxPoint& p) const")

d = a:op_add(b)
PrintOk(d:op_eq(c), "%operator wxPoint operator+(const wxPoint& p) const")
d:op_set(a); d:op_iadd(a)
PrintOk(d:op_eq(c), "%operator wxPoint& operator+=(const wxPoint& p)")
d:op_set(a); d = d:op_neg()
PrintOk(d:op_eq(wx.wxPoint(-1, -2)), "%operator wxPoint& operator-()")

d = a:op_add(wx.wxSize(1,2))
PrintOk(d:op_eq(c), "%operator wxPoint operator+(const wxSize& p) const")
d:op_set(a); d:op_iadd(wx.wxSize(1,2))
PrintOk(d:op_eq(c), "%operator wxPoint& operator+=(const wxSize& p)")

-- ---------------------------------------------------------------------------
print("\nTest some binding class functions.\n")
-- ---------------------------------------------------------------------------

-- Call functions with user data
size = wx.wxSize(-1,2)
size2 = wx.wxSize(10, 20)
size:SetDefaults(wx.wxSize(10, 20)); size:SetDefaults(size2) -- test both ways
PrintOk(size:GetWidth() == size2:GetWidth(), "Function call with user data, wxSize:SetDefaults(wxSize)")

-- Call %override functions
w, h = wx.wxDisplaySize()
PrintOk(w ~= nil and h ~= nil, "%override function wxDisplaySize returned ("..tostring(w)..", "..tostring(h)..")")

-- Call %overload and %rename functions
pen = wx.wxPen(wx.wxBLACK, 1, wx.wxSOLID)
pen:SetColour(wx.wxColour(12, 13, 14))
PrintOk(pen:GetColour():Red() == 12, "overload function wxPen:SetColour(wxColour)")
pen:SetColour("red")
PrintOk(pen:GetColour():Red() == 255, "overload function wxPen:SetColour(\"red\")")
pen:SetColour(1, 2, 3)
PrintOk(pen:GetColour():Red() == 1, "overload function wxPen:SetColour(1, 2, 3)")

-- Test static functions and calling them
fname = 'a321.123X!x!' -- should not exist
f = wx.wxFileName(fname)
PrintOk(f.GetCwd() == wx.wxFileName.GetCwd(), "Calling static wxString wxFileName::GetCwd(), as static member and static global.")
PrintOk(f.GetCwd() == wx.wxGetCwd(), "Calling static wxString wxFileName::GetCwd() == wx.wxGetCwd().")

-- Test overloaded static and non static functions
PrintOk(f:FileExists() == wx.wxFileName.FileExists(fname), "Calling static wxFileName::FileExists(str) == member wxFileName::FileExists.")

-- Test new() constructor function and copying it
f = wx.wxImage.new
PrintOk(f(5,6):Ok(), "Calling wx.wxImage.new(5,6) function as constructor.")

f = wx.wxImage(5,6)
g = f.GetWidth
PrintOk(type(g) == "function", "Type f = wx.wxImage(5,6); f.GetWidth is a function.")

PrintOk(g(f) == 5, "Calling f = wx.wxImage(5,6); g = f.GetWidth; g(f) == 5; function is callable outside of userdata.")

-- Test calling a baseclass function a few levels deep
a = wx.wxStdDialogButtonSizer(); -- base is wxBoxSizer whose base is wxSizer
a:SetMinSize(1, 2) -- this should also work
PrintOk(a:GetMinSize():GetWidth() == 1, "Calling wx.wxStdDialogButtonSizer[base func wxBoxSizer->wxSizer]::GetMinSize().")
PrintOk(a:GetOrientation() == wx.wxHORIZONTAL, "Calling wx.wxStdDialogButtonSizer[base func wxBoxSizer]::GetOrientation().")
PrintOk(a:GetCancelButton() == nil, "Calling wx.wxStdDialogButtonSizer::GetCancelButton().") -- not a great test
b = wx.wxButton(); b:SetName("Hello"); a:SetCancelButton(b)
PrintOk(a:GetCancelButton():GetName() == "Hello", "Calling wx.wxStdDialogButtonSizer::GetCancelButton() after setting it with a button.")

-- ---------------------------------------------------------------------------
print("\nTest wxObject::DynamicCast.\n")
-- ---------------------------------------------------------------------------

a = wx.wxCommandEvent()
b = a:DynamicCast("wxObject")

print(a, b)

PrintOk((a ~= b) and string.find(tostring(a), "wxCommandEvent", 1, 1) and string.find(tostring(b), "wxObject", 1, 1),
    "wxObject::DynamicCast a wxCommandEvent to a wxObject")
PrintOk((a ~= b) and (string.match(tostring(a), "%([abcdefx%d]*") == string.match(tostring(b), "%([abcdefx%d]*")),
    "wxObject::DynamicCast a wxCommandEvent to a wxObject the object pointer stays the same")

b = b:DynamicCast("wxCommandEvent")
PrintOk((a == b) and string.find(tostring(a), "wxCommandEvent", 1, 1) and string.find(tostring(b), "wxCommandEvent", 1, 1),
    "wxObject::DynamicCast the wxObject back to a wxCommandEvent to get original userdata back")
PrintOk((a == b) and (string.match(tostring(a), "%([abcdefx%d]*") == string.match(tostring(b), "%([abcdefx%d]*")),
    "wxObject::DynamicCast the wxObject back to a wxCommandEvent the object pointer stays the same")

b = b:DynamicCast("wxCommandEvent") -- should do nothing
PrintOk((a == b) and string.find(tostring(a), "wxCommandEvent", 1, 1) and string.find(tostring(b), "wxCommandEvent", 1, 1),
    "wxObject::DynamicCast a wxCommandEvent to a wxCommandEvent to get same userdata back")
PrintOk((a == b) and (string.match(tostring(a), "%([abcdefx%d]*") == string.match(tostring(b), "%([abcdefx%d]*")),
    "wxObject::DynamicCast a wxCommandEvent to a wxCommandEvent the object pointer stays the same")

b = b:DynamicCast("wxEvent")
b:delete()
PrintOk((a ~= b) and not (string.find(tostring(a), "wx", 1, 1) or string.find(tostring(b), "wx", 1, 1)),
    "wxObject::DynamicCast a wxCommandEvent to a wxEvent then delete the wxEvent, both should be deleted")

-- NOTE! It is probably a mistake in wxWidgets that there are two functions with
-- the same name, but it's good dynamic casting test for wxLua.
-- wxBookCtrlBaseEvent::GetSelection() returns its int m_nSel
-- wxCommandEvent::GetSelection() return its int m_commandInt
a = wx.wxBookCtrlBaseEvent(wx.wxEVT_NULL, 5, 10, 11)
b = a:DynamicCast("wxCommandEvent")
PrintOk((a ~= b) and (a:GetSelection() == 10) and (b:GetSelection() == 0),
    "wxObject::DynamicCast a wxBookCtrlBaseEvent to a wxCommandEvent and compare the two GetSelection() functions which use different member vars")

-- ---------------------------------------------------------------------------
print("\nTest adding a methods to a class object userdata.\n")
-- ---------------------------------------------------------------------------

a = wx.wxRect(1,2,3,4);
function a.Print(self) return string.format("%d,%d,%d,%d", self:GetX(), self:GetY(), self:GetWidth(), self:GetHeight()) end
PrintOk(a:Print() == "1,2,3,4", "Add a new lua function to an already created wx.wxRect")

a.value = 5
PrintOk(a.value == 5, "Add a number value to an already created wx.wxRect")

a = wx.wxRect(1,2,3,4);
function a.GetX(self) return "x" end
PrintOk(a:GetX()  == "x", "Replace wxRect:GetX with a lua function")
PrintOk(a:_GetX() == 1,   "Replace wxRect:GetX with a lua function, call wxRect:_GetX for original function")
PrintOk(a:GetX()  == "x", "Replace wxRect:GetX with a lua function (test recursion)")
PrintOk(a:_GetX() == 1,   "Replace wxRect:GetX with a lua function, call wxRect:_GetX for original function (test recursion)")

-- ---------------------------------------------------------------------------
print("\nTest virtual class functions and calling base class functions.\n")
-- ---------------------------------------------------------------------------

a = wx.wxLuaPrintout()
PrintOk(a:TestVirtualFunctionBinding("Hello") == "Hello-Base",  "Test wxLuaPrintout::TestVirtualFunctionBinding without overriding it.")
PrintOk(a:_TestVirtualFunctionBinding("Hello") == "Hello-Base", "Test wxLuaPrintout::_TestVirtualFunctionBinding without overriding it.")

a.TestVirtualFunctionBinding = function(self, val) return val.."-Lua" end
PrintOk(a:TestVirtualFunctionBinding("Hello") == "Hello-Lua",   "Test wxLuaPrintout::TestVirtualFunctionBinding overriding it, but not calling base.")
PrintOk(a:_TestVirtualFunctionBinding("Hello") == "Hello-Base", "Test wxLuaPrintout::_TestVirtualFunctionBinding overriding it, but directly calling the base.")

a.TestVirtualFunctionBinding = function(self, val)
    return self:_TestVirtualFunctionBinding(val).."-Lua"
end
PrintOk(a:TestVirtualFunctionBinding("Hello") == "Hello-Base-Lua", "Test wxLuaPrintout::TestVirtualFunctionBinding overriding it and calling base.")

-- ---------------------------------------------------------------------------
print("\nTest the wxLuaObject.\n")
-- ---------------------------------------------------------------------------

a = "Hello"; o = wxlua.wxLuaObject(a); b = o:GetObject()
PrintOk((b == "Hello") and (a == b), "Test wxLuaObject::GetObject(string).")
o = wxlua.wxLuaObject("hello"); b = o:GetObject()
PrintOk((b == "hello") and (a ~= b), "Test wxLuaObject::GetObject(string).")

o = wxlua.wxLuaObject(10); b = o:GetObject()
PrintOk(b == 10, "Test wxLuaObject::GetObject(number).")

o = wxlua.wxLuaObject(true); b = o:GetObject()
PrintOk(b == true, "Test wxLuaObject::GetObject(boolean).")

a = {"hello"}; o = wxlua.wxLuaObject(a); b = o:GetObject()
PrintOk((a == b) and (b[1] == "hello"), "Test wxLuaObject::GetObject(table).")

a = wx.wxPoint(1,2); o = wxlua.wxLuaObject(a); b = o:GetObject()
PrintOk(a == b, "Test wxLuaObject::GetObject(userdata).")
a = wx.wxPoint(1,2); o = wxlua.wxLuaObject(a); a = nil; b = o:GetObject()
PrintOk(b:GetX() == 1, "Test wxLuaObject::GetObject(userdata).")

a = function(txt) return txt.."!" end
o = wxlua.wxLuaObject(a); b = o:GetObject()
PrintOk((a == b) and (b("Hello") == "Hello!"), "Test wxLuaObject::GetObject(function).")

-- ---------------------------------------------------------------------------
print("\nTest the bit library.\n")
-- ---------------------------------------------------------------------------

PrintOk(bit.bnot(bit.bnot(0)) == 0,         "Test bit library bit.bnot.")
PrintOk(bit.bnot(bit.bnot(0xF)) == 0xF,     "Test bit library bit.bnot.")
PrintOk(bit.band(0x1, 0x3, 0x5) == 1,       "Test bit library bit.band.")
PrintOk(bit.bor(0x1, 0x3, 0x5)  == 7,       "Test bit library bit.bor.")
PrintOk(bit.bxor(0x1, 0x1, 0x3, 0x5) == 6,  "Test bit library bit.bxor.")
PrintOk(bit.lshift(0x1, 1) == 2,            "Test bit library bit.lshift.")
PrintOk(bit.rshift(0x2, 1) == 1,            "Test bit library bit.rshift.")
PrintOk(bit.arshift(-2, 1) == -1,           "Test bit library bit.arshift. Note, this preserves sign")

-- ---------------------------------------------------------------------------
print("\n\nResults.\n")
-- ---------------------------------------------------------------------------

print("Tests run         : "..tostring(tests_run))
print("Tests that failed : "..tostring(failed_tests))
print("Warnings          : "..tostring(warnings).."\n")

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
--wx.wxGetApp():MainLoop()
