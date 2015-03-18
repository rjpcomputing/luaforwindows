-------------------------------------------------------------------------=---
-- Name:        dialog.wx.lua
-- Purpose:     Dialog wxLua sample, a temperature converter
--              Based on the C++ version by Marco Ghislanzoni
-- Author:      J Winwood, John Labenski
-- Created:     March 2002
-- Copyright:   (c) 2001 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- IDs of the controls in the dialog
ID_CELSIUS_BUTTON      = 1  -- NOTE: We use the fact that the textctrl ids
ID_CELSIUS_TEXTCTRL    = 2  --       are +1 fom the button ids.
ID_KELVIN_BUTTON       = 3
ID_KELVIN_TEXTCTRL     = 4
ID_FAHRENHEIT_BUTTON   = 5
ID_FAHRENHEIT_TEXTCTRL = 6
ID_RANKINE_BUTTON      = 7
ID_RANKINE_TEXTCTRL    = 8
ID_ABOUT_BUTTON        = 9
ID_CLOSE_BUTTON        = 10

ID__MAX                = 11 -- max of our window ids

-- Create the dialog, there's no reason why we couldn't use a wxFrame and
-- a frame would probably be a better choice.
dialog = wx.wxDialog(wx.NULL, wx.wxID_ANY, "wxLua Temperature Converter",
                     wx.wxDefaultPosition, wx.wxDefaultSize)

-- Create a wxPanel to contain all the buttons. It's a good idea to always
-- create a single child window for top level windows (frames, dialogs) since
-- by default the top level window will want to expand the child to fill the
-- whole client area. The wxPanel also gives us keyboard navigation with TAB key.
panel = wx.wxPanel(dialog, wx.wxID_ANY)

-- Layout all the buttons using wxSizers
local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

local staticBox      = wx.wxStaticBox(panel, wx.wxID_ANY, "Enter temperature")
local staticBoxSizer = wx.wxStaticBoxSizer(staticBox, wx.wxVERTICAL)
local flexGridSizer  = wx.wxFlexGridSizer( 3, 3, 0, 0 )
flexGridSizer:AddGrowableCol(1, 0)

-- Make a function to reduce the amount of duplicate code.
function AddConverterControl(name_string, button_text, textCtrlID, buttonID)
    local staticText = wx.wxStaticText( panel, wx.wxID_ANY, name_string)
    local textCtrl   = wx.wxTextCtrl( panel, textCtrlID, "000000.00000", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_PROCESS_ENTER )
    local button     = wx.wxButton( panel, buttonID, button_text)
    flexGridSizer:Add( staticText, 0, wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5 )
    flexGridSizer:Add( textCtrl,   0, wx.wxGROW+wx.wxALIGN_CENTER+wx.wxALL, 5 )
    flexGridSizer:Add( button,     0, wx.wxGROW+wx.wxALIGN_CENTER+wx.wxALL, 5 )

    return textCtrl
end

celsiusTextCtrl    = AddConverterControl("Celsius",    "From &Celsius",    ID_CELSIUS_TEXTCTRL,    ID_CELSIUS_BUTTON)
kelvinTextCtrl     = AddConverterControl("Kelvin",     "From &Kelvin",     ID_KELVIN_TEXTCTRL,     ID_KELVIN_BUTTON)
fahrenheitTextCtrl = AddConverterControl("Fahrenheit", "From &Fahrenheit", ID_FAHRENHEIT_TEXTCTRL, ID_FAHRENHEIT_BUTTON)
rankineTextCtrl    = AddConverterControl("Rankine",    "From &Rankine",    ID_RANKINE_TEXTCTRL,    ID_RANKINE_BUTTON)

--[[
NOTE: We've wrapped the creation of the controls into a function, but we could
      have created them all separately this way.

local celsiusStaticText = wx.wxStaticText( panel, wx.wxID_ANY, "Celsius")
local celsiusTextCtrl   = wx.wxTextCtrl( panel, ID_CELSIUS_TEXTCTRL, "", wx.wxDefaultPosition, wx.wxSize(80,-1), 0 )
local celsiusButton     = wx.wxButton( panel, ID_CELSIUS_BUTTON, "C -> K && F")
flexGridSizer:AddWindow( celsiusStaticText, 0, wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5 )
flexGridSizer:AddWindow( celsiusTextCtrl,   0, wx.wxGROW+wx.wxALIGN_CENTER+wx.wxALL, 5 )
flexGridSizer:AddWindow( celsiusButton,     0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
]]

staticBoxSizer:Add( flexGridSizer,  0, wx.wxGROW+wx.wxALIGN_CENTER+wx.wxALL, 5 )
mainSizer:Add(      staticBoxSizer, 1, wx.wxGROW+wx.wxALIGN_CENTER+wx.wxALL, 5 )

local buttonSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
local aboutButton = wx.wxButton( panel, ID_ABOUT_BUTTON, "&About")
local closeButton = wx.wxButton( panel, ID_CLOSE_BUTTON, "E&xit")
buttonSizer:Add( aboutButton, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
buttonSizer:Add( closeButton, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
mainSizer:Add(    buttonSizer, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )

panel:SetSizer( mainSizer )
mainSizer:SetSizeHints( dialog )

-- ---------------------------------------------------------------------------
-- Calculate the temp conversions, input only one temp, set others to nil
--    Shows how to handle nil inputs and return multiple ones
function ConvertTemp( Tc, Tk, Tf, Tr )
    if Tc or Tk then
        Tc = Tc or (Tk - 273.15)
        Tf = (Tc * 9/5) + 32
    else -- Tf or Tr
        Tf = Tf or (Tr - 459.67)
        Tc = (Tf - 32) * 5/9
    end

    Tk = Tc + 273.15
    Tr = Tf + 459.67

    return Tc, Tk, Tf, Tr
end

-- ---------------------------------------------------------------------------
-- Connect a handler for pressing enter in the textctrls
dialog:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_ENTER,
    function(event)
        -- Send "fake" button press to do calculation.
        -- Button ids have been set to be -1 from textctrl ids.
        dialog:ProcessEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, event:GetId()-1))
    end)

-- ---------------------------------------------------------------------------
-- Connect a central event handler that responds to all button clicks.
-- NOTE: Since we Connect() the about and close buttons after this they will be
--       called first and unless we call event:Skip() in their handlers the
--       events will never reach this function. Therefore we don't need to
--       check that the ids are only from temp conversion buttons.

dialog:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function(event)
        -- NOTE: A wxID_CANCEL event is sent when the close button on the
        -- dialog is pressed.
        if event:GetId() >= ID__MAX then
            event:Skip()
            return
        end

        -- We know that the textctrl window ids are +1 from the button ids
        local T = tonumber(dialog:FindWindow(event:GetId()+1):DynamicCast("wxTextCtrl"):GetValue())

        if T == nil then
            wx.wxMessageBox("The input temperature is invalid, enter a number.",
                            "Error!",
                            wx.wxOK + wx.wxICON_EXCLAMATION + wx.wxCENTRE,
                            dialog)
        else
            -- Create a "case" type statement
            local TempCase = {
                [ID_CELSIUS_BUTTON]    = function() return ConvertTemp(T, nil, nil, nil) end,
                [ID_KELVIN_BUTTON]     = function() return ConvertTemp(nil, T) end, -- don't need trailing nils
                [ID_FAHRENHEIT_BUTTON] = function() return ConvertTemp(nil, nil, T) end,
                [ID_RANKINE_BUTTON]    = function() return ConvertTemp(nil, nil, nil, T) end
            }

            -- call the "case" statement
            local Tc, Tk, Tf, Tr = TempCase[event:GetId()]()

            celsiusTextCtrl:SetValue(   string.format("%.3f", Tc))
            kelvinTextCtrl:SetValue(    string.format("%.3f", Tk))
            fahrenheitTextCtrl:SetValue(string.format("%.3f", Tf))
            rankineTextCtrl:SetValue(   string.format("%.3f", Tr))
        end
    end)

--[[
-- NOTE: You can also attach single event handlers to each of the buttons and
--       handle them separately.

dialog:Connect(ID_CELSIUS_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function(event)
        local T = tonumber(celsiusTextCtrl:GetValue())
        if T == nil then
            wx.wxMessageBox("The Celsius temperature is invalid, enter a number.",
                            "Error!",
                            wx.wxOK + wx.wxICON_EXCLAMATION + wx.wxCENTRE,
                            dialog)
        else
            kelvinTextCtrl:SetValue(T + 273.15)
            fahrenheitTextCtrl:SetValue((T * 9 / 5) + 32)
            rankineTextCtrl:SetValue((T * 9 / 5) + 32 + 459.67)
        end
    end)
]]

-- ---------------------------------------------------------------------------
-- Attach an event handler to the Close button
dialog:Connect(ID_CLOSE_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function(event) dialog:Destroy() end)

dialog:Connect(wx.wxEVT_CLOSE_WINDOW,
    function (event)
        dialog:Destroy()
        event:Skip()
    end)

-- ---------------------------------------------------------------------------
-- Attach an event handler to the About button
dialog:Connect(ID_ABOUT_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function(event)
        wx.wxMessageBox("Based on the C++ version by Marco Ghislanzoni.\n"..
                        wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                        "About wxLua Temperature Converter",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        dialog)
    end)

-- ---------------------------------------------------------------------------
-- Send a "fake" event to simulate a button press to update the textctrls
dialog:ProcessEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, ID_CELSIUS_BUTTON))

-- ---------------------------------------------------------------------------
-- Centre the dialog on the screen
dialog:Centre()
-- Show the dialog
dialog:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
