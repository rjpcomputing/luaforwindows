--
-- Project:  LuaIDL
-- Version:  0.8.9b
-- Author:   Ricardo Cosme <rcosme@tecgraf.puc-rio.br>
-- Filename: sin.lua
--

-- OMG IDL Grammar ( Corba v3.0 )
-- LL(1)
--(1)  <specification>          :=    <import_l> <definition_l>
--(2)  <import_l>               :=    <import> <import_l>
--(3)                           |     empty
--(4)  <import>                 :=    TK_IMPORT <imported_scope> ";"
--(5)  <imported_scope>         :=    <scoped_name>
--(6)                           |     TK_STRING_LITERAL
--(7)  <scoped_name>            :=    TK_ID <scoped_name>
--(8)                           |     ":" ":" TK_ID <scoped_name_l>
--(9)  <scoped_name_l>          :=    ":" ":" TK_ID <scoped_name_l>
--(10)                          |     empty
--(11)  <definition_l>          :=    <definition> <definition_l_r>
--(12)  <definition_l_r>        :=    <definition> <definition_l_r>
--(13)                          |     empty
--(14)  <definition>            :=    <type_dcl> ";"
--(15)                          |     <const_dcl> ";"
--(16)                          |     <except_dcl> ";"
--(17)                          |     <inter_value_event> ";"
--(18)                          |     <module> ";"
--(19)                          |     <type_id_dcl> ";"
--(20)                          |     <type_prefix_dcl> ";"
--(21)                          |     <component> ";"
--(22)                          |     <home_dcl> ";"
--(23)  <type_dcl>              :=    "typedef" <type_declarator>
--(24)                          |     <enum_type>
--(25)                          |     TK_NATIVE TK_ID
--(26)                          |     <union_or_struct>
--(27)  <type_declarator>       :=    <type_spec> <declarator_l>
--(28)  <type_spec>             :=    <simple_type_spec>
--(29)                          |     <constr_type_spec>
--(30)  <simple_type_spec>      :=    <base_type_spec>
--(31)                          |     <template_type_spec>
--(32)                          |     <scoped_name>
--(33)  <constr_type_spec>      :=    <struct_type>
--(34)                          |     <union_type>
--(35)                          |     <enum_type>
--(36)  <base_type_spec>        :=    <float_type_or_int_type>
--(37)                          |     TK_CHAR
--                              |     TK_WCHAR **
--(38)                          |     TK_BOOLEAN
--(39)                          |     TK_OCTET
--(40)                          |     TK_ANY
--(41)                          |     TK_OBJECT
--(42)                          |     TK_VALUEBASE
--(43)  <float_type_or_int_type>:=    <floating_pt_type>
--(44)                          |     <integer_type>
--(45)                          |     TK_LONG <long_or_double>
--(46)  <floating_pt_type>      :=    TK_FLOAT
--(47)                          |     TK_DOUBLE
--(48)  <integer_type>          :=    TK_SHORT
--(49)                          |     <unsigned_int>
--(50)  <unsigned_int>          :=    TK_UNSIGNED <unsigned_int_tail>
--(51)  <unsigned_int_tail>     :=    TK_LONG <long_e>
--(52)                          |     TK_SHORT
--(53)  <long_e>                :=    TK_LONG
--(54)                          |     empty
--(55)  <long_or_double>        :=    TK_LONG
--(56)                          |     TK_DOUBLE
--(57)                          |     empty
--(58)  <template_type_spec>    :=    <sequence_type>
--(59)                          |     <string_type>
--                              |     <wide_string_type> **
--(60)                          |     <fixed_pt_type>
--(61)  <sequence_type>         :=    TK_SEQUENCE "<" <simple_type_spec> <sequence_type_tail>
--(69)  <sequence_type_tail>    :=    "," <positive_int_const> ">"
--(70)                          |     ">"
--(71)  <string_type>           :=    TK_STRING <string_type_tail>
--(72)  <string_type_tail>      :=    "<" <positive_int_const> ">"
--(73)                          |     empty
--    <wide_string_type>        :=    TK_WSTRING <string_type_tail> **
--(74)  <fixed_pt_type>         :=    TK_FIXED "<" <positive_int_const> "," <positive_int_const> ">"
--(75)  <positive_int_const>    :=    <xor_expr> <or_expr_l>
--(91)  <or_expr_l>             :=    "|" <xor_expr> <or_expr_l>
--(92)                          |     empty
--(93)  <xor_expr>              :=    <and_expr> <xor_expr_l>
--(94)  <xor_expr_l>            :=    "^" <and_expr> <xor_expr_l>
--(95)                          |     empty
--(96)  <and_expr>              :=    <shift_expr> <and_expr_l>
--(97)  <and_expr_l>            :=    "&" <shift_expr> <and_expr_l>
--(98)                          |     empty
--(99)  <shift_expr>            :=    <add_expr> <shift_expr_l>
--(100) <shift_expr_l>          :=    ">>" <add_expr> <shift_expr_l>
--(101)                         |     "<<" <add_expr> <shift_expr_l>
--(102)                         |     empty
--(103) <add_expr>              :=    <mult_expr> <add_expr_l>
--(104) <add_expr_l>            :=    "+" <mult_expr> <add_expr_l>
--(105)                         |     "-" <mult_expr> <add_expr_l>
--(106)                         |     empty
--(107) <mult_expr>             :=    <unary_expr> <mult_expr_l>
--(108) <mult_expr_l>           :=    "*" <unary_expr> <mult_expr_l>
--(109)                         |     "/" <unary_expr> <mult_expr_l>
--(110)                         |     "%" <unary_expr> <mult_expr_l>
--(111)                         |     empty
--(112) <unary_expr>            :=    <unary_operator> <primary_expr>
--(113)                         |     <primary_expr>
--(114) <unary_operator>        :=    "-"
--(115)                         |     "+"
--(116)                         |     "~"
--(117) <primary_expr>          :=    <scoped_name>
--(118)                         |     <literal>
--(119)                         |     "(" <positive_int_const3> ")"
--(120) <literal>               :=    TK_INTEGER_LITERAL
--(121)                         |     TK_STRING_LITERAL
--                              |     TK_WSTRING_LITERAL **
--(122)                         |     TK_CHAR_LITERAL
--                              |     TK_WCHAR_LITERAL **
--(123)                         |     TK_FIXED_LITERAL
--(124)                         |     TK_FLOAT_LITERAL
--(125)                         |     <boolean_literal>
--(126) <boolean_literal>       :=    TK_TRUE
--(127)                         |     TK_FALSE
--(136) <struct_type>           :=    TK_STRUCT TK_ID "{" <member_l> "}"
--(137) <member_l>              :=    <member> <member_r>
--(138) <member_r>              :=    <member> <member_r>
--(139)                         |     empty
--(140) <member>                :=    <type_spec> <declarator_l> ";"
--(141) <typedef_dcl_l>         :=    <typedef_dcl> <typedef_l_r>
--(142) <typedef_l_r>           :=    "," <typedef_dcl> <typedef_l_r>
--(143)                         |     empty
--(144) <typedef_dcl>           :=    TK_ID <fixed_array_size_l>
--(145) <fixed_array_size_l>    :=    <fixed_array_size> <fixed_array_size_l>
--(146)                         |     empty
--(147) <fixed_array_size>      :=    "[" <positive_int_const4> "]"
--(148) <union_type>            :=    TK_UNION TK_ID TK_SWITCH "(" <switch_type_spec> ")"
--                                    "{" <case_l> "}"
--(149) <switch_type_spec>      :=    <integer_type>
--(150)                         |     TK_LONG <long_e>
--(151)                         |     TK_CHAR
--(152)                         |     TK_BOOLEAN
--(153)                         |     TK_ENUM
--(154)                         |     <scoped_name>
--(155) <case_l>                :=    <case> <case_l_r>
--(156) <case_l_r>              :=    <case> <case_l_r>
--(157)                         |     empty
--(158) <case>                  :=    <case_label_l> <element_spec> ";"
--(159) <case_label_l>          :=    <case_label> <case_label_l_r>
--(160) <case_label_l_r>        :=    <case_label> <case_label_l_r>
--(161)                         |     empty
--(162) <case_label>            :=    TK_CASE <positive_int_const5> ":"
--(163)                         |     TK_DEFAULT ":"
--(164) <element_spec>          :=    <type_spec> <declarator>
--(165) <enum_type>             :=    TK_ENUM <enumerator>
--                                    "{" <enumerator> <enumerator_l> "}"
--(166) <enumerator_l>          :=    "," <enumerator> <enumerator_l>
--(167)                         |     empty
--(168) <union_or_struct>       :=    TK_STRUCT TK_ID <struct_tail>
--(169)                         |     TK_UNION TK_ID TK_SWITCH <union_tail>
--(170) <struct_tail>           :=    "{" <member_l> "}"
--(171)                         |     empty
--(172) <union_tail>            :=    TK_SWITCH "(" <switch_type_spec> ")"
--                                    "{" <case_l> "}"
--(173)                         |     empty
--(174) <const_dcl>             :=    TK_CONST <const_type> TK_ID "=" <positive_int_const>
--(175) <const_type>            :=    <float_type_or_int_type>
--(176)                         |     TK_CHAR
--                              |     TK_WCHAR **
--(177)                         |     TK_BOOLEAN
--(178)                         |     TK_STRING
--                              |     TK_WSTRING **
--(179)                         |     <scoped_name>
--(180)                         |     TK_OCTET
--(181)                         |     TK_FIXED
--(186) <except_dcl>            :=    TK_EXCEPTION TK_ID "{" <member_l_empty> "}"
--(187) <member_l_empty>        :=    <member> <member_l_empty>
--(188)                         |     empty
--(189) <inter_value_event>     :=    TK_ABSTRACT <abstract_tail>
--(190)                         |     TK_LOCAL TK_INTERFACE TK_ID <interface_tail>
--(191)                         |     TK_CUSTOM <value_or_event>
--(192)                         |     TK_INTERFACE TK_ID <interface_tail>
--(193)                         |     TK_VALUETYPE TK_ID <value_tail>
--(194)                         |     TK_EVENTTYPE TK_ID <eventtype_tail>
--(195) <abstract_tail>         :=    TK_INTERFACE TK_ID <interface_tail>
--(196)                         |     TK_VALUETYPE TK_ID <valueinhe_export_empty>
--(197)                         |     TK_EVENTTYPE TK_ID <valueinhe_export_empty>
--(198) <interface_tail>        :=    ":" <scoped_name> <bases> "{" <export_l> "}"
--(199)                         |     "{" <export_l> "}"
--(200)                         |     empty
--(205) <bases>                 :=    "," <scoped_name> <bases>
--(206)                         |     empty
--(207) <export_l>              :=    <export> <export_l>
--(208)                         |     empty
--(209) <export>                :=    <type_dcl> ";"
--(210)                         |     <const_dcl> ";"
--(211)                         |     <except_dcl> ";"
--(212)                         |     <attr_dcl> ";"
--(213)                         |     <op_dcl> ";"
--(214)                         |     <type_id_dcl> ";"
--(215)                         |     <type_prefix_dcl> ";"
--(216) <attr_dcl>              :=    <readonly_attr_spec>
--(217)                         |     <attr_spec>
--(218) <readonly_attr_spec>    :=    TK_READONLY TK_ATTRIBUTE <param_type_spec> <readonly_attr_dec>
--(219) <param_type_spec>       :=    <base_type_spec>
--(220)                         |     <string_type>
--                              |     <wide_string_type> **
--(221)                         |     <scoped_name>
--(226) <readonly_attr_dec>     :=    TK_ID <readonly_attr_dec_tail>
--(227) <readonly_attr_dec_tail>:=    <raises_expr>
--(228)                         |     <simple_dec_l>
--                              |     empty
--(229) <raises_expr>           :=    TK_RAISES "(" <scoped_name> <inter_name_seq> ")"
--(230) <simple_dec_l)          :=    "," TK_ID <simple_dec_l>
--(231)                         |     empty
--(232) <attr_spec>             :=    TK_ATTRIBUTE <param_type_spec> <attr_declarator>
--(233) <attr_declarator>       :=    TK_ID <attr_declarator_tail>
--(234) <attr_declarator_tail>  :=    <attr_raises_expr>
--(235)                         |     <simple_dec_l>
--                              |     empty
--(236) <attr_raises_expr>      :=    TK_GETRAISES <exception_l> <attr_raises_expr_tail>
--(237)                         |     TK_SETRAISES <exception_l>
--(238) <attr_raises_expr_tail> :=    TK_SETRAISES <exception_l>
--(239)                         |     empty
--(240) <exception_l>           :=    "(" <scoped_name> <inter_name_seq> ")"
--(241) <inter_name_seq>        :=    "," <scoped_name> <inter_name_seq>
--(242)                         |     empty
--(243) <op_dcl>                :=    TK_ONEWAY <op_type_spec> TK_ID <parameter_dcls> <raises_expr_e>
--                                    <context_expr_e>
--(244)                         |     <op_type_spec> TK_ID <parameter_dcls> <raises_expr_e>
--                                    <context_expr_e>
--(245) <op_type_spec>          :=    <param_type_spec>
--(246)                         |     TK_VOID
--(247) <parameter_dcls>        :=    "(" <parameter_dcls_tail>
--(248) <parameter_dcls_tail>   :=    <param_dcl> <param_dcl_l>
--(249)                         |     ")"
--(250) <param_dcl>             :=    <param_attribute> <param_type_spec> TK_ID
--(251) <param_attribute>       :=    TK_IN
--(252)                         |     TK_OUT
--(253)                         |     TK_INOUT
--(254) <param_dcl_l>           :=    "," <param_dcl> <param_dcl_l>
--(255)                         |     empty
--(256) <context_expr>          :=    TK_CONTEXT "(" <context> <string_literal_l> ")"
--(257) <string_literal_l>      :=    "," <context> <string_literal_l>
--(258)                         |     empty
--(259) <type_id_dcl>           :=    TK_TYPEID <scoped_name> TK_STRING_LITERAL
--(260) <type_prefix_dcl>       :=    TK_TYPEPREFIX <scoped_name> TK_STRING_LITERAL
--(265) <valueinhe_export_empty>:=    <value_inhe_spec> "{" <export_l> "}
--(266)                         |     "{" <export_l> "}"
--(267)                         |     empty
--(268) <value_inhe_spec>       :=    ":" <truncatable_e> <value_name> <value_name_list>
--                                    <supports_e>
--(269)                         |     <supports_e>
--(270)                         |     empty
--(271) <truncatable_e>         :=    TK_TRUNCATABLE
--(272)                         |     empty
--(273) <value_name>            :=    TK_ID <value_name_l>
--(274)                         |     ":" ":" TK_ID <value_name_l>
--(275) <value_name_l>          :=    ":" ":" TK_ID <value_name_l>
--(276)                         |     empty
--(277) <value_name_list>       :=    "," <value_name> <value_name_list>
--(278)                         |     empty
--(279) <supports_e>            :=    TK_SUPPORTS <inter_name> <inter_name_seq2>
--(280)                         |     empty
--(281) <value_or_event>        :=    TK_VALUETYPE TK_ID <valueinhe_export>
--(282)                         |     TK_EVENTTYPE TK_ID <valueinhe_export>
--(283) <valueinhe_export>      :=    <value_inhe_spec> "{" <value_element_l> "}"
--(284)                         |     "{" <value_element_l> "}"
--(285) <value_element_l>       :=    <value_element> <value_element_l>
--(286)                         |     empty
--(287) <value_element>         :=    <export>
--(288)                         |     <state_member>
--(289)                         |     <init_dcl>
--(290) <state_member>          :=    TK_PUBLIC <type_spec> <declarator_l> ";"
--(291)                         |     TK_PRIVATE <type_spec> <declarator_l> ";"
--(292) <init_dcl>              :=    TK_FACTORY TK_ID "(" <init_param_dcl_l_e> ")"
--                                    <raises_expr_e> ";"
--(293) <init_param_dcl_l_e>    :=    <init_param_dcl> <init_param_dcl_l_e_r>
--(294)                         |     empty
--(295) <init_param_dcl_l_e_r>  :=    "," <init_param_dcl> <init_param_dcl_l_e_r>
--(296)                         |     empty
--(297) <init_param_dcl>        :=    TK_IN <param_type_spec> TK_ID
--(298) <value_tail>            :=    <value_inhe_spec> "{" <value_element_l> "}"
--(299)                         |     "{" <value_element_l> "}"
--(300)                         |     <type_spec>
--(301)                         |     empty
--(302) <eventtype_tail>        :=    <value_inhe_spec> "{" <value_element_l> "}"
--(303)                         |     "{" <value_element_l> "}"
--(304)                         |     empty
--(305) <module>                :=    TK_MODULE TK_ID "{" <definition_l> "}"
--(306) <component>             :=    TK_COMPONENT TK_ID <component_tail>
--(307) <component_tail>        :=    <component_inh_spec> <supp_inter_spec>
--                                    "{" <component_body> "}"
--(308)                         |     <supp_inter_spec> "{" <component_body> "}"
--(309)                         |     "{" <component_body> "}"
--(310)                         |     empty
--(311) <component_inh_spec>    :=    ":" <component_name>
--(312) <component_name>        :=    TK_ID <component_name_l>
--(313)                         |     ":" ":" TK_ID <component_name_l>
--(314) <component_name_l>      :=    ":" ":" TK_ID <component_name_l>
--(315)                         |     empty
--(316) <supp_inter_spec>       :=    TK_SUPPORTS <supp_name> <supp_name_list>
--(316e)                        |     empty
--(317) <supp_name>             :=    TK_ID <supp_name_l>
--(318)                         |     ":" ":" TK_ID <supp_name_l>
--(319) <supp_name_l>           :=    ":" ":" TK_ID <supp_name_l>
--(320)                         |     empty
--(321) <supp_name_list>        :=    "," <supp_name> <supp_name_list>
--(322)                         |     empty
--(323) <component_body>        :=    <component_export> <component_body>
--(324)                         |     empty
--(325) <component_export>      :=    <provides_dcl> ";"
--(326)                         |     <uses_dcl> ";"
--(327)                         |     <emits_dcl> ";"
--(328)                         |     <publishes_dcl> ";"
--(329)                         |     <consumes_dcl> ";"
--(330)                         |     <attr_dcl> ";"
--(331) <provides_dcl>          :=    TK_PROVIDES <interface_type> TK_ID
--(332) <interface_type>        :=    <scoped_name>
--(333)                         |     TK_OBJECT
--(338) <uses_dcl>              :=    TK_USES <multiple_e> <interface_type> TK_ID
--(339) <multiple_e>            :=    TK_MULTIPLE
--(340)                         |     empty
--(341) <emits_dcl>             :=    TK_EMITS <scoped_name> TK_ID
--(342) <publishes_dcl>         :=    TK_PUBLISHES <scoped_name> TK_ID
--(343) <consumes_dcl>          :=    TK_CONSUMES <scoped_name> TK_ID

--(344) <home_dcl>              :=    TK_HOME TK_ID <home_dcl_tail>
--(345) <home_dcl_tail>         :=    <home_inh_spec> <supp_inter_spec>
--                                    TK_MANAGES <home_name> <primary_key_spec_e>
--                                    "{" <home_export_l> "}"raises_expr>
--(346)                         |     <supp_inter_spec> TK_MANAGES <home_name> <primary_key_spec_e>
--                                    "{" <home_export_l> "}"
--(347)                         |     TK_MANAGES <home_name> <primary_key_spec_e>
--                                    "{" <home_export_l> "}"
--(348) <home_inh_spec>         :=    ":" <scoped_name>
--(353) <primary_key_spec_e>    :=    TK_PRIMARYKEY <scoped_name>
--(354)                         |     empty
--(359) <home_export_l>         :=    <home_export> <home_export_l>
--(360)                         |     empty
--(361) <home_export>           :=    <export>
--(362)                         |     <factory_dcl> ";"
--(363)                         |     <finder_dcl> ";"
--(364) <factory_dcl>           :=    TK_FACTORY TK_ID "(" <init_param_dcls> ")"
--                                    <raises_expr_e>
--(365) <finder_dcl>            :=    TK_FINDER TK_ID "(" <init_param_dcls> ")"
--                                    <raises_expr_e>
--(366) <init_param_dcls>       :=    <init_param_dcl> <init_param_dcl_list>
--(367)                         |     empty
--(368) <init_param_dcl_list>   :=    "," <init_param_dcl> <init_param_dcl_list>
--(369)                         |     empty
--(370) <raises_expr_e>         :=    <raises_expr>
--(371)                         |     empty
--(376) <enumerator>            :=    TK_ID
--(377) <context_expr_e>        :=    <context_expr>
--(378)                         |     empty
--(379) <context>               :=    TK_STRING_LITERAL

local type     = type
local pairs    = pairs
local tonumber = tonumber
local require  = require
local error    = error
local ipairs   = ipairs

local math     = require "math"
local string   = require "string"
local table    = require "table"

module 'luaidl.sin'

local lex = require 'luaidl.lex'

local tab_firsts = { }
local tab_follow = { }

local specification, definition_l, definition_l_r, definition, type_dcl, const_dcl, except_dcl,
      const_type, inter_value_event, module, type_id_dcl, type_prefix_dcl, component, home_dcl,
      const_type, positive_int_const, float_type_or_int_type, scoped_name, type_declarator,
      enum_type, union_or_struct, type_dcl_name_l, simple_type_spec, constr_type_spec,

      type_spec, base_type_spec, floating_type_or_int_type,
      floating_pt_type, integer_type, unsigned_int, unsigned_int_tail,
      long_e, declarator_l, declarator_l_r, declarator, fixed_array_size_l, fixed_array_size,
      xor_expr, and_expr, shift_expr, add_expr, mult_expr, unary_expr,
      unary_operator, primary_expr, literal, boolean_literal, mult_expr_l, add_expr_l,
      shift_expr_l, and_expr_l, xor_expr_l, or_expr_l, template_type_spec, sequence_type,
      sequence_type_tail, string_type, string_type_tail, fixed_pt_type,
      struct_type, member_l, member, member_r, union_type, switch_type_spec, case_l, case,
      case_label_l, case_label, case_label_l_r, case_l_r, element_spec, component_tail


local function set_firsts( firsts )
  local tab = { }
  for _, token in ipairs(firsts) do
    local tokenDcl = lex.tab_tokens[token]
    if tokenDcl then
      tab[tokenDcl] = true
    else
      tab[token] = true
    end
  end
  return tab
end

tab_firsts.rule_1   = set_firsts { 'TK_IMPORT' }
tab_firsts.rule_11  = set_firsts { 'TK_TYPEDEF','TK_ENUM','TK_NATIVE','TK_UNION','TK_STRUCT',
                        'TK_CONST','TK_EXCEPTION','TK_ABSTRACT','TK_LOCAL',
                        'TK_INTERFACE','TK_CUSTOM','TK_VALUETYPE',
                        'TK_EVENTTYPE','TK_MODULE','TK_TYPEID',
                        'TK_TYPEPREFIX','TK_COMPONENT','TK_HOME'
                      }
tab_firsts.rule_12  = tab_firsts.rule_11
tab_firsts.rule_14  = set_firsts { 'TK_TYPEDEF', 'TK_ENUM', 'TK_NATIVE', 'TK_UNION', 'TK_STRUCT' }
tab_firsts.rule_15  = set_firsts { 'TK_CONST' }
tab_firsts.rule_16  = set_firsts { 'TK_EXCEPTION' }
tab_firsts.rule_17  = set_firsts { 'TK_ABSTRACT', 'TK_LOCAL', 'TK_INTERFACE', 'TK_CUSTOM',
                        'TK_VALUETYPE', 'TK_EVENTTYPE'
                       }
tab_firsts.rule_18  = set_firsts { 'TK_MODULE' }
tab_firsts.rule_19  = set_firsts { 'TK_TYPEID' }
tab_firsts.rule_20  = set_firsts { 'TK_TYPEPREFIX' }
tab_firsts.rule_21  = set_firsts { 'TK_COMPONENT' }
tab_firsts.rule_22  = set_firsts { 'TK_HOME' }
tab_firsts.rule_23  = set_firsts { 'TK_TYPEDEF' }
tab_firsts.rule_24  = set_firsts { 'TK_ENUM' }
tab_firsts.rule_25  = set_firsts { 'TK_NATIVE' }
tab_firsts.rule_26  = set_firsts { 'TK_STRUCT', 'TK_UNION' }
tab_firsts.rule_27  = set_firsts { 'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY', 'TK_OBJECT',
                        'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT',
                        'TK_UNSIGNED', 'TK_SEQUENCE' , 'TK_STRING', 'TK_FIXED' ,
                        'TK_ID', ":", 'TK_STRUCT', 'TK_UNION', 'TK_ENUM',-- 'TK_TYPECODE',
                      }
tab_firsts.rule_28  = set_firsts { 'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY', 'TK_OBJECT',
                        'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT',
                        'TK_UNSIGNED', 'TK_SEQUENCE' , 'TK_STRING', 'TK_FIXED' ,
                        'TK_ID', ":",-- 'TK_TYPECODE',
                       }
tab_firsts.rule_29  = set_firsts { 'TK_STRUCT', 'TK_UNION', 'TK_ENUM' }
tab_firsts.rule_30  = set_firsts { 'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY', 'TK_OBJECT',
                        'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT',
                        'TK_UNSIGNED',-- 'TK_TYPECODE',
                       }
tab_firsts.rule_31  = set_firsts { 'TK_SEQUENCE', 'TK_STRING', 'TK_FIXED' }
tab_firsts.rule_32  = set_firsts { 'TK_ID', ':' }

tab_firsts.rule_33  = set_firsts { 'TK_STRUCT' }
tab_firsts.rule_34  = set_firsts { 'TK_UNION' }
tab_firsts.rule_35  = set_firsts { 'TK_ENUM' }
tab_firsts.rule_36  = set_firsts { 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED', 'TK_LONG' }
tab_firsts.rule_37  = set_firsts { 'TK_CHAR' }
tab_firsts.rule_38  = set_firsts { 'TK_BOOLEAN' }
tab_firsts.rule_39  = set_firsts { 'TK_OCTET' }
tab_firsts.rule_40  = set_firsts { 'TK_ANY' }
tab_firsts.rule_41  = set_firsts { 'TK_OBJECT' }
tab_firsts.rule_42  = set_firsts { 'TK_VALUEBASE' }

tab_firsts.rule_43  = set_firsts { 'TK_FLOAT', 'TK_DOUBLE' }
tab_firsts.rule_44  = set_firsts { 'TK_SHORT', 'TK_UNSIGNED' }
tab_firsts.rule_45  = set_firsts { 'TK_LONG' }
tab_firsts.rule_46  = set_firsts { 'TK_FLOAT' }
tab_firsts.rule_47  = set_firsts { 'TK_DOUBLE' }
tab_firsts.rule_48  = set_firsts { 'TK_SHORT' }
tab_firsts.rule_49  = set_firsts { 'TK_UNSIGNED' }
tab_firsts.rule_50  = tab_firsts.rule_49
tab_firsts.rule_51  = tab_firsts.rule_45
tab_firsts.rule_52  = set_firsts { 'TK_SHORT' }
tab_firsts.rule_53  = set_firsts { 'TK_LONG' }
tab_firsts.rule_55  = set_firsts { 'TK_LONG' }
tab_firsts.rule_56  = set_firsts { 'TK_DOUBLE' }

tab_firsts.rule_58  = set_firsts { 'TK_SEQUENCE' }
tab_firsts.rule_59  = set_firsts { 'TK_STRING' }
tab_firsts.rule_60  = set_firsts { 'TK_FIXED' }

tab_firsts.rule_62  = tab_firsts.rule_30
tab_firsts.rule_63  = tab_firsts.rule_31
tab_firsts.rule_64  = tab_firsts.rule_32

tab_firsts.rule_69  = set_firsts { ',' }
tab_firsts.rule_70  = set_firsts { '>' }
tab_firsts.rule_72  = set_firsts { '<' }
tab_firsts.rule_75  = set_firsts { '-', '+', '~', '(', 'TK_ID', ':', 'TK_INTEGER_LITERAL',
                                   'TK_STRING_LITERAL', 'TK_CHAR_LITERAL', 'TK_FIXED_LITERAL',
                                   'TK_FLOAT_LITERAL', 'TK_TRUE', 'TK_FALSE'
                      }
tab_firsts.rule_93   = tab_firsts.rule_75
tab_firsts.rule_91   = set_firsts { '|' }
tab_firsts.rule_94   = set_firsts { '^' }
tab_firsts.rule_96   = tab_firsts.rule_75
tab_firsts.rule_97   = set_firsts { '&' }
tab_firsts.rule_99   = tab_firsts.rule_75
tab_firsts.rule_100  = set_firsts { '>>' }
tab_firsts.rule_101  = set_firsts { '<<' }
tab_firsts.rule_103  = tab_firsts.rule_75
tab_firsts.rule_104  = set_firsts { '+' }
tab_firsts.rule_105  = set_firsts { '-' }
tab_firsts.rule_107  = tab_firsts.rule_75
tab_firsts.rule_108  = set_firsts { '*' }
tab_firsts.rule_109  = set_firsts { '/' }
tab_firsts.rule_110  = set_firsts { '%' }
tab_firsts.rule_112  = set_firsts { '-', '+', '~' }
tab_firsts.rule_113  = set_firsts { '(', 'TK_ID', ':', 'TK_INTEGER_LITERAL',
                                    'TK_STRING_LITERAL', 'TK_CHAR_LITERAL', 'TK_FIXED_LITERAL',
                                    'TK_FLOAT_LITERAL', 'TK_TRUE', 'TK_FALSE'
                       }
tab_firsts.rule_114  = set_firsts { '-' }
tab_firsts.rule_115  = set_firsts { '+' }
tab_firsts.rule_116  = set_firsts { '~' }
tab_firsts.rule_117  = set_firsts { 'TK_ID', ':' }
tab_firsts.rule_118  = set_firsts { 'TK_INTEGER_LITERAL', 'TK_STRING_LITERAL', 'TK_CHAR_LITERAL',
                                    'TK_FIXED_LITERAL', 'TK_FLOAT_LITERAL', 'TK_TRUE', 'TK_FALSE'
                       }
tab_firsts.rule_119  = set_firsts { '(' }
tab_firsts.rule_120  = set_firsts { 'TK_INTEGER_LITERAL' }
tab_firsts.rule_121  = set_firsts { 'TK_STRING_LITERAL' }
tab_firsts.rule_122  = set_firsts { 'TK_CHAR_LITERAL' }
tab_firsts.rule_123  = set_firsts { 'TK_FIXED_LITERAL' }
tab_firsts.rule_124  = set_firsts { 'TK_FLOAT_LITERAL' }
tab_firsts.rule_125  = set_firsts { 'TK_TRUE', 'TK_FALSE' }
tab_firsts.rule_126  = set_firsts { 'TK_TRUE' }
tab_firsts.rule_127  = set_firsts { 'TK_FALSE' }

tab_firsts.rule_137  = tab_firsts.rule_27
tab_firsts.rule_138  = tab_firsts.rule_137

tab_firsts.rule_140  = tab_firsts.rule_138
tab_firsts.rule_141  = set_firsts { 'TK_ID' }
tab_firsts.rule_142  = set_firsts { "," }

tab_firsts.rule_144  = tab_firsts.rule_141
tab_firsts.rule_145  = set_firsts { "[" }

tab_firsts.rule_147  = tab_firsts.rule_145
tab_firsts.rule_148  = set_firsts { 'TK_UNION' }
tab_firsts.rule_149  = tab_firsts.rule_44
tab_firsts.rule_150  = set_firsts { 'TK_LONG' }
tab_firsts.rule_151  = set_firsts { 'TK_CHAR' }
tab_firsts.rule_152  = set_firsts { 'TK_BOOLEAN' }
tab_firsts.rule_153  = set_firsts { 'TK_ENUM' }
tab_firsts.rule_154  = set_firsts { 'TK_ID', ':' }
tab_firsts.rule_155  = set_firsts { 'TK_CASE', 'TK_DEFAULT' }
tab_firsts.rule_156  = set_firsts { 'TK_CASE', 'TK_DEFAULT' }

tab_firsts.rule_158  = set_firsts { 'TK_CASE', 'TK_DEFAULT' }
tab_firsts.rule_159  = set_firsts { 'TK_CASE', 'TK_DEFAULT' }
tab_firsts.rule_160  = set_firsts { 'TK_CASE', 'TK_DEFAULT' }

tab_firsts.rule_162  = set_firsts { 'TK_CASE' }
tab_firsts.rule_163  = set_firsts { 'TK_DEFAULT' }
tab_firsts.rule_164  = tab_firsts.rule_27

tab_firsts.rule_166  = set_firsts { "," }

tab_firsts.rule_168  = set_firsts { 'TK_STRUCT' }
tab_firsts.rule_169  = set_firsts { 'TK_UNION' }
tab_firsts.rule_170  = set_firsts { '{' }

tab_firsts.rule_172  = set_firsts { 'TK_SWITCH' }

tab_firsts.rule_174  = set_firsts { 'TK_CONST' }
tab_firsts.rule_175  = tab_firsts.rule_36
tab_firsts.rule_176  = set_firsts { 'TK_CHAR' }
tab_firsts.rule_177  = set_firsts { 'TK_BOOLEAN' }
tab_firsts.rule_178  = set_firsts { 'TK_STRING' }
tab_firsts.rule_179  = set_firsts { 'TK_ID', ':' }
tab_firsts.rule_180  = set_firsts { 'TK_OCTET' }
tab_firsts.rule_181  = set_firsts { 'TK_FIXED' }
tab_firsts.rule_186  = set_firsts { 'TK_EXCEPTION' }
tab_firsts.rule_187  = tab_firsts.rule_137

tab_firsts.rule_189  = set_firsts { 'TK_ABSTRACT' }
tab_firsts.rule_190  = set_firsts { 'TK_LOCAL' }
tab_firsts.rule_191  = set_firsts { 'TK_CUSTOM' }
tab_firsts.rule_192  = set_firsts { 'TK_INTERFACE' }
tab_firsts.rule_193  = set_firsts { 'TK_VALUETYPE' }
tab_firsts.rule_194  = set_firsts { 'TK_EVENTTYPE' }
tab_firsts.rule_195  = set_firsts { 'TK_INTERFACE' }
tab_firsts.rule_196  = set_firsts { 'TK_VALUETYPE' }
tab_firsts.rule_198  = set_firsts { ':' }
tab_firsts.rule_199  = set_firsts { '{' }

tab_firsts.rule_207  = set_firsts { 'TK_ONEWAY', 'TK_VOID', 'TK_STRING', 'TK_ID', ':',
                        'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY',
                        'TK_OBJECT', 'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT',
                        'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED','TK_TYPEDEF',
                        'TK_ENUM', 'TK_NATIVE', 'TK_UNION', 'TK_STRUCT',
                        'TK_EXCEPTION', 'TK_READONLY', 'TK_ATTRIBUTE',-- 'TK_TYPECODE',
                       }

tab_firsts.rule_209  = tab_firsts.rule_14
tab_firsts.rule_211  = set_firsts { 'TK_EXCEPTION' }
tab_firsts.rule_212  = set_firsts { 'TK_READONLY', 'TK_ATTRIBUTE' }
tab_firsts.rule_213  = set_firsts { 'TK_ONEWAY', 'TK_VOID', 'TK_STRING', 'TK_ID', ':',
                        'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY',
                        'TK_OBJECT', 'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT',
                        'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED',-- 'TK_TYPECODE',
                       }

tab_firsts.rule_216  = set_firsts { 'TK_READONLY' }
tab_firsts.rule_217  = set_firsts { 'TK_ATTRIBUTE' }

tab_firsts.rule_219  = tab_firsts.rule_30
tab_firsts.rule_220  = set_firsts { 'TK_STRING' }
tab_firsts.rule_221  = tab_firsts.rule_32


tab_firsts.rule_227  = set_firsts { 'TK_RAISES' }
tab_firsts.rule_228  = set_firsts { ',' }

tab_firsts.rule_230  = set_firsts { 'TK_ID' }
tab_firsts.rule_234  = set_firsts { 'TK_GETRAISES', 'TK_SETRAISES' }
tab_firsts.rule_235  = set_firsts { ',' }
tab_firsts.rule_236  = set_firsts { 'TK_GETRAISES' }
tab_firsts.rule_237  = set_firsts { 'TK_SETRAISES' }
tab_firsts.rule_238  = tab_firsts.rule_237

tab_firsts.rule_243  = set_firsts { 'TK_ONEWAY' }
tab_firsts.rule_244  = set_firsts { 'TK_VOID', 'TK_STRING', 'TK_ID', ':',
                        'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY',
                        'TK_OBJECT', 'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT',
                        'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED',-- 'TK_TYPECODE',
                       }
tab_firsts.rule_245  = set_firsts { 'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY', 'TK_OBJECT',
                        'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT',
                        'TK_UNSIGNED', 'TK_STRING', 'TK_ID', ":",-- 'TK_TYPECODE',
                       }
tab_firsts.rule_246  = set_firsts { 'TK_VOID' }

tab_firsts.rule_248  = set_firsts { 'TK_IN', 'TK_OUT', 'TK_INOUT' }
tab_firsts.rule_249  = set_firsts { ')' }

tab_firsts.rule_251  = set_firsts { 'TK_IN' }
tab_firsts.rule_252  = set_firsts { 'TK_OUT' }
tab_firsts.rule_253  = set_firsts { 'TK_INOUT' }
tab_firsts.rule_254  = set_firsts { ',' }

tab_firsts.rule_257  = set_firsts { ',' }

tab_firsts.rule_268  = set_firsts { ':' }
tab_firsts.rule_269  = set_firsts { 'TK_SUPPORTS' }
tab_firsts.rule_271  = set_firsts { 'TK_TRUNCATABLE' }
tab_firsts.rule_277  = set_firsts { ',' }
tab_firsts.rule_281  = set_firsts { 'TK_VALUETYPE' }
tab_firsts.rule_285  = set_firsts { 'TK_ONEWAY', 'TK_VOID', 'TK_STRING', 'TK_ID', ':',
                        'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY',
                        'TK_OBJECT', 'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT',
                        'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED','TK_TYPEDEF',
                        'TK_ENUM', 'TK_NATIVE', 'TK_UNION', 'TK_STRUCT',
                        'TK_EXCEPTION', 'TK_READONLY', 'TK_ATTRIBUTE',-- 'TK_TYPECODE',
                        'TK_PUBLIC', 'TK_PRIVATE',
                        'TK_FACTORY' }
tab_firsts.rule_287  = tab_firsts.rule_207
tab_firsts.rule_288  = set_firsts { 'TK_PUBLIC', 'TK_PRIVATE' }
tab_firsts.rule_289  = set_firsts { 'TK_FACTORY' }
tab_firsts.rule_290  = set_firsts { 'TK_PUBLIC' }
tab_firsts.rule_291  = set_firsts { 'TK_PRIVATE' }
tab_firsts.rule_292  = tab_firsts.rule_289
tab_firsts.rule_297  = set_firsts { 'TK_IN' }
tab_firsts.rule_298  = set_firsts { ':', 'TK_SUPPORTS' }
tab_firsts.rule_299  = set_firsts { '{' }
tab_firsts.rule_300  = tab_firsts.rule_27
tab_firsts.rule_302  = tab_firsts.rule_298
tab_firsts.rule_303  = set_firsts { '{' }
tab_firsts.rule_305  = set_firsts { 'TK_MODULE' }
tab_firsts.rule_306  = set_firsts { 'TK_COMPONENT' }
tab_firsts.rule_307  = set_firsts { ':' }
tab_firsts.rule_308  = set_firsts { 'TK_SUPPORTS' }
tab_firsts.rule_309  = set_firsts { '{' }
tab_firsts.rule_316  = set_firsts { 'TK_SUPPORTS' }
tab_firsts.rule_321  = set_firsts { ',' }
tab_firsts.rule_323  = set_firsts { 'TK_PROVIDES', 'TK_USES', 'TK_EMITS', 'TK_PUBLISHES',
                                    'TK_CONSUMES', 'TK_READONLY', 'TK_ATTRIBUTE' }
tab_firsts.rule_325  = set_firsts { 'TK_PROVIDES' }
tab_firsts.rule_326  = set_firsts { 'TK_USES' }
tab_firsts.rule_327  = set_firsts { 'TK_EMITS' }
tab_firsts.rule_328  = set_firsts { 'TK_PUBLISHES' }
tab_firsts.rule_329  = set_firsts { 'TK_CONSUMES' }
tab_firsts.rule_330  = set_firsts { 'TK_READONLY', 'TK_ATTRIBUTE' }
tab_firsts.rule_332  = set_firsts { 'TK_ID', ':' }
tab_firsts.rule_333  = set_firsts { 'TK_OBJECT' }
tab_firsts.rule_339  = set_firsts { 'TK_MULTIPLE' }
tab_firsts.rule_345  = set_firsts { ':' }
tab_firsts.rule_346  = set_firsts { 'TK_SUPPORTS' }
tab_firsts.rule_347  = set_firsts { 'TK_MANAGES' }
tab_firsts.rule_353  = set_firsts { 'TK_PRIMARYKEY' }
tab_firsts.rule_359  = set_firsts { 'TK_ONEWAY', 'TK_VOID', 'TK_STRING', 'TK_ID', ':',
                        'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY',
                        'TK_OBJECT', 'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT',
                        'TK_DOUBLE', 'TK_SHORT', 'TK_UNSIGNED','TK_TYPEDEF',
                        'TK_ENUM', 'TK_NATIVE', 'TK_UNION', 'TK_STRUCT',
                        'TK_EXCEPTION', 'TK_READONLY', 'TK_ATTRIBUTE',-- 'TK_TYPECODE',
                        'TK_FACTORY', 'TK_FINDER'
                       }
tab_firsts.rule_361  = tab_firsts.rule_207
tab_firsts.rule_362  = set_firsts { 'TK_FACTORY' }
tab_firsts.rule_363  = set_firsts { 'TK_FINDER' }
tab_firsts.rule_364  = tab_firsts.rule_362
tab_firsts.rule_365  = tab_firsts.rule_363
tab_firsts.rule_366  = tab_firsts.rule_297
tab_firsts.rule_368  = set_firsts { ',' }
tab_firsts.rule_370  = set_firsts { 'TK_RAISES' }

tab_firsts.rule_377  = set_firsts { 'TK_CONTEXT' }

tab_firsts.rule_400  = set_firsts { 'TK_ID' }
tab_firsts.rule_401  = set_firsts { ':' }

tab_follow.rule_32   = set_firsts { 'TK_ID' }
tab_follow.rule_54   = set_firsts { 'TK_ID', '>' }
tab_follow.rule_61   = set_firsts { '>', ',' }
tab_follow.rule_64   = set_firsts { ',', '>' }
tab_follow.rule_69   = set_firsts { '>' }
tab_follow.rule_72   = set_firsts { '>' }
tab_follow.rule_73   = set_firsts { 'TK_ID' }
tab_follow.rule_95   = set_firsts { '|', ']', ')' }
tab_follow.rule_98   = set_firsts { '^', ']', ')' }
tab_follow.rule_102  = set_firsts { '&', ']', ')' }
tab_follow.rule_106  = set_firsts { '>>', '<<', '&', '^', '|', ']', ')' }
tab_follow.rule_111  = set_firsts { '+', '-', '>>', '<<', '&', '^', '|', ']', ')' }
tab_follow.rule_119  = set_firsts { ')' }
tab_follow.rule_139  = set_firsts { '}' }
tab_follow.rule_143  = set_firsts { ';' }
tab_follow.rule_146  = set_firsts { ',', ';' }
tab_follow.rule_147  = set_firsts { '*', '/', '%', '+', '-', '>>', '<<', '&', '^', '|', ']', ')' }
tab_follow.rule_148  = set_firsts { ')' }
tab_follow.rule_154  = set_firsts { ',', ')' }
tab_follow.rule_157  = set_firsts { '}' }
tab_follow.rule_161  = set_firsts { 'TK_CHAR', 'TK_BOOLEAN', 'TK_OCTET', 'TK_ANY', 'TK_OBJECT',
                        'TK_VALUEBASE', 'TK_LONG', 'TK_FLOAT', 'TK_DOUBLE', 'TK_SHORT',
                        'TK_UNSIGNED', 'TK_SEQUENCE' , 'TK_STRING', 'TK_FIXED' ,
                        'TK_ID', ":", 'TK_STRUCT', 'TK_UNION', 'TK_ENUM',-- 'TK_TYPECODE',
                       }
tab_follow.rule_162  = set_firsts { ":" }
tab_follow.rule_167  = set_firsts { "}" }
tab_follow.rule_204  = set_firsts { ',', '{' }
tab_follow.rule_221  = set_firsts { 'TK_ID' }
tab_follow.rule_229  = set_firsts { ',', ')' }
tab_follow.rule_268  = set_firsts { ',', 'TK_SUPPORTS', '{' }
tab_follow.rule_272  = set_firsts { ':', 'TK_ID' }
tab_follow.rule_278  = set_firsts { 'TK_SUPPORTS', '{' }
tab_follow.rule_286  = set_firsts { '}' }
tab_follow.rule_301  = set_firsts { ';' }
tab_follow.rule_304  = set_firsts { ';' }
tab_follow.rule_307  = set_firsts { 'TK_SUPPORTS', '{' }
tab_follow.rule_308  = set_firsts { ',', '{' }
tab_follow.rule_316  = set_firsts { ',', '{' }
tab_follow.rule_316e = set_firsts { '{' }
tab_follow.rule_321  = tab_follow.rule_316
tab_follow.rule_332  = set_firsts { 'TK_ID' }
tab_follow.rule_340  = set_firsts { 'TK_MULTIPLE', 'TK_ID', ':', 'TK_OBJECT' }
tab_follow.rule_341  = set_firsts { 'TK_ID' }
tab_follow.rule_342  = tab_follow.rule_341
tab_follow.rule_343  = tab_follow.rule_342
tab_follow.rule_345  = set_firsts { ',', ':', 'TK_MANAGES' }
tab_follow.rule_347  = set_firsts { 'TK_PRIMARYKEY', '{' }
tab_follow.rule_348  = set_firsts { 'TK_SUPPORTS' }
tab_follow.rule_353  = set_firsts { '{' }
tab_follow.rule_359  = set_firsts { '}' }
tab_follow.rule_367  = set_firsts { ',', ')' }
tab_follow.rule_369  = set_firsts { ')' }
tab_follow.rule_600  = set_firsts { 'TK_STRING_LITERAL' }
tab_follow_rule_error_msg = { [32]  = 'identifier',
                              [64]  = "',' or '>'",
                              [154] = "',' or ')'",
                              [161] = "'char', 'boolean', 'octet', 'any', 'Object',"..
                                      "'ValueBase', 'long', 'float', 'double', 'short'"..
                                      "'unsigned', 'sequence', 'string', 'fixed', identifier,"..
                                      "'struct', 'union', 'enum'",
                              [204] = "',', '{'",
                              [221] = "identifier",
                              [229] = "',', ')'",
                              [268] = "',', 'supports' or '{'",
                              [307] = "'{'",
                              [308] = "',' or '{'",
                              [345] = "':', ',' or 'manages'",
                              [316] = "',', '{'",
                              [332] = "identifier",
                              [600] = 'string literal',
                            }

local token = lex.token

local tab_curr_scope
local tab_namespaces
-- It is a stack of roots.
local ROOTS
local currentScope
local CORBAVisible

-- this a list of type declarations
local TAB_TYPEID = {
               [ 'CONST' ]     = 'const',
               [ 'NATIVE' ]    = 'native',
               [ 'CHAR' ]      = 'char',
               [ 'BOOLEAN' ]   = 'boolean',
               [ 'OCTET' ]     = 'octet',
               [ 'ANY' ]       = 'any',
               [ 'OBJECT' ]    = 'Object',
               [ 'VALUEBASE' ] = 'valuebase',
               [ 'STRUCT' ]    = 'struct',
               [ 'FLOAT' ]     = 'float',
               [ 'SHORT' ]     = 'short',
               [ 'FLOAT' ]     = 'float',
               [ 'DOUBLE' ]    = 'double',
               [ 'USHORT' ]    = 'ushort',
               [ 'ULLONG' ]    = 'ulonglong',
               [ 'ULONG' ]     = 'ulong',
               [ 'LLONG' ]     = 'longlong',
               [ 'LDOUBLE' ]   = 'longdouble',
               [ 'LONG' ]      = 'long',
               [ 'STRING']     = 'string',
               [ 'FIXED' ]     = 'fixed',
               [ 'EXCEPTION' ] = 'except',
               [ 'INTERFACE' ] = 'interface',
               [ 'VOID' ]      = 'void',
               [ 'OPERATION' ] = 'operation',
               [ 'TYPEDEF' ]   = 'typedef',
               [ 'ENUM' ]      = 'enum',
               [ 'SEQUENCE' ]  = 'sequence',
               [ 'ATTRIBUTE' ] = 'attribute',
               [ 'MODULE' ]    = 'module',
               [ 'UNION' ]     = 'union',
               [ 'TYPECODE' ]  = 'TypeCode',
               [ 'COMPONENT' ] = 'component',
               [ 'HOME' ]      = 'home',
               [ 'FACTORY' ]   = 'factory',
               [ 'FINDER' ]    = 'finder',
               [ 'VALUETYPE' ] = 'valuetype',
               [ 'EVENTTYPE' ] = 'eventtype',
             }

local TAB_BASICTYPE = {
               [ 'NATIVE' ]    = { _type = TAB_TYPEID[ 'NATIVE' ] },
               [ 'CHAR' ]      = { _type = TAB_TYPEID[ 'CHAR' ] },
               [ 'BOOLEAN' ]   = { _type = TAB_TYPEID[ 'BOOLEAN' ] },
               [ 'OCTET' ]     = { _type = TAB_TYPEID[ 'OCTET' ] },
               [ 'ANY' ]       = { _type = TAB_TYPEID[ 'ANY' ] },
               [ 'OBJECT' ]    = { _type = TAB_TYPEID[ 'OBJECT' ],
                                   repID = 'IDL:omg.org/CORBA/Object:1.0' },
               [ 'VALUEBASE' ] = { _type = TAB_TYPEID[ 'VALUEBASE' ] },
               [ 'FLOAT' ]     = { _type = TAB_TYPEID[ 'FLOAT' ] },
               [ 'SHORT' ]     = { _type = TAB_TYPEID[ 'SHORT' ] },
               [ 'FLOAT' ]     = { _type = TAB_TYPEID[ 'FLOAT' ] } ,
               [ 'DOUBLE' ]    = { _type = TAB_TYPEID[ 'DOUBLE' ] },
               [ 'USHORT' ]    = { _type = TAB_TYPEID[ 'USHORT' ] },
               [ 'ULLONG' ]    = { _type = TAB_TYPEID[ 'ULLONG' ] },
               [ 'ULONG' ]     = { _type = TAB_TYPEID[ 'ULONG' ] },
               [ 'LLONG' ]     = { _type = TAB_TYPEID[ 'LLONG' ] },
               [ 'LDOUBLE' ]   = { _type = TAB_TYPEID[ 'LDOUBLE' ] },
               [ 'LONG' ]      = { _type = TAB_TYPEID[ 'LONG' ] },
               [ 'FIXED' ]     = { _type = TAB_TYPEID[ 'FIXED' ] },
               [ 'VOID' ]      = { _type = TAB_TYPEID[ 'VOID' ] },
               [ 'STRING' ]    = { _type = TAB_TYPEID[ 'STRING' ] },
}

local TAB_IMPLICITTYPE = {
               [ 'TYPECODE' ]  = { _type = TAB_TYPEID[ 'TYPECODE' ],
                                   repID = 'IDL:omg.org/CORBA/TypeCode:1.0' },
}

local tab_legal_type = {
    [ TAB_TYPEID.TYPEDEF ] = true,
    [ TAB_TYPEID.STRUCT ] = true,
    [ TAB_TYPEID.ENUM ] = true,
    [ TAB_TYPEID.INTERFACE ] = true,
    [ TAB_TYPEID.NATIVE ] = true,
    [ TAB_TYPEID.UNION ] = true,
    [ TAB_TYPEID.CHAR ] = true,
    [ TAB_TYPEID.BOOLEAN ] = true,
    [ TAB_TYPEID.OCTET ] = true,
    [ TAB_TYPEID.ANY ] = true,
    [ TAB_TYPEID.OBJECT ] = true,
    [ TAB_TYPEID.VALUEBASE ] = true,
    [ TAB_TYPEID.FLOAT ] = true,
    [ TAB_TYPEID.DOUBLE ] = true,
    [ TAB_TYPEID.SHORT ] = true,
    [ TAB_TYPEID.USHORT ] = true,
    [ TAB_TYPEID.ULLONG ] = true,
    [ TAB_TYPEID.ULONG ] = true,
    [ TAB_TYPEID.LLONG ] = true,
    [ TAB_TYPEID.LDOUBLE ] = true,
    [ TAB_TYPEID.LONG ] = true,
    [ TAB_TYPEID.FIXED ] = true,
    [ TAB_TYPEID.VOID ] = true,
    [ TAB_TYPEID.TYPECODE ] = true,
    [ TAB_TYPEID.SEQUENCE ] = true,
    [ TAB_TYPEID.STRING ] = true,
}

local tab_accept_definition = {
    [ TAB_TYPEID.STRUCT] = true,
    [ TAB_TYPEID.EXCEPTION ] = true,
    [ TAB_TYPEID.INTERFACE ] = true,
    [ TAB_TYPEID.MODULE ] = true,
--??
    [ TAB_TYPEID.COMPONENT ] = true,
    [ TAB_TYPEID.HOME ] = true,
    [ TAB_TYPEID.VALUETYPE ] = true,
    [ TAB_TYPEID.EVENTTYPE ] = true,
}

local tab_define_scope = {
  [ TAB_TYPEID.INTERFACE ] = true,
  [ TAB_TYPEID.EXCEPTION ] = true,
  [ TAB_TYPEID.OPERATION ] = true,
  [ TAB_TYPEID.STRUCT ] = true,
  [ TAB_TYPEID.UNION ] = true,
  [ TAB_TYPEID.MODULE ] = true,
  [ TAB_TYPEID.COMPONENT ] = true,
}

local tab_is_contained = {
    [ TAB_TYPEID.ATTRIBUTE ] = true,
    [ TAB_TYPEID.TYPEDEF ] = true,
    [ TAB_TYPEID.INTERFACE ] = true,
    [ TAB_TYPEID.OPERATION ] = true,
    [ TAB_TYPEID.CONST ] = true,

    [ TAB_TYPEID.STRUCT ] = true,
    [ TAB_TYPEID.EXCEPTION ] = true,
    [ TAB_TYPEID.MODULE ] = true,
    [ TAB_TYPEID.ENUM ] = true,
    [ TAB_TYPEID.UNION ] = true,
    [ TAB_TYPEID.COMPONENT ] = true,
    [ TAB_TYPEID.HOME ] = true,
    [ TAB_TYPEID.VALUETYPE ] = true,
    [ TAB_TYPEID.EVENTTYPE ] = true,
    [ TAB_TYPEID.TYPECODE ] = true,
}

local TAB_VALUEEXPECTED = {
  [lex.tab_tokens.TK_ID]              = "<identifier>",
  [lex.tab_tokens.TK_ABSTRACT]        = "abstract",
  [lex.tab_tokens.TK_ANY]             = TAB_TYPEID.ANY,
  [lex.tab_tokens.TK_ATTRIBUTE]       = TAB_TYPEID.ATTRIBUTE,
  [lex.tab_tokens.TK_BOOLEAN]         = TAB_TYPEID.BOOLEAN,
  [lex.tab_tokens.TK_CASE]            = "case",
  [lex.tab_tokens.TK_CHAR]            = TAB_TYPEID.CHAR,
  [lex.tab_tokens.TK_COMPONENT]       = TAB_TYPEID.COMPONENT,
  [lex.tab_tokens.TK_CONST]           = TAB_TYPEID.CONST,
  [lex.tab_tokens.TK_CONSUMES]        = "consumes",
  [lex.tab_tokens.TK_CONTEXT]         = "context",
  [lex.tab_tokens.TK_CUSTOM]          = "custom",
  [lex.tab_tokens.TK_DEFAULT]         = "default",
  [lex.tab_tokens.TK_DOUBLE]          = TAB_TYPEID.DOUBLEF,
  [lex.tab_tokens.TK_EXCEPTION]       = TAB_TYPEID.EXCEPTION,
  [lex.tab_tokens.TK_EMITS]           = "emits",
  [lex.tab_tokens.TK_ENUM]            = TAB_TYPEID.ENUM,
  [lex.tab_tokens.TK_EVENTTYPE]       = TAB_TYPEID.EVENTTYPE,
  [lex.tab_tokens.TK_FACTORY]         = TAB_TYPEID.FACTORY,
  [lex.tab_tokens.TK_FALSE]           = "FALSE",
  [lex.tab_tokens.TK_FINDER]          = TAB_TYPEID.FINDER,
  [lex.tab_tokens.TK_FIXED]           = TAB_TYPEID.FIXED,
  [lex.tab_tokens.TK_FLOAT]           = TAB_TYPEID.FLOAT,
  [lex.tab_tokens.TK_GETRAISES]       = "getraises",
  [lex.tab_tokens.TK_HOME]            = TAB_TYPEID.HOME,
  [lex.tab_tokens.TK_IMPORT]          = "import",
  [lex.tab_tokens.TK_IN]              = "in",
  [lex.tab_tokens.TK_INOUT]           = "inout",
  [lex.tab_tokens.TK_INTERFACE]       = TAB_TYPEID.INTERFACE,
  [lex.tab_tokens.TK_LOCAL]           = "local",
  [lex.tab_tokens.TK_LONG]            = TAB_TYPEID.LONG,
  [lex.tab_tokens.TK_MODULE]          = TAB_TYPEID.MODULE,
  [lex.tab_tokens.TK_MULTIPLE]        = "multiple",
  [lex.tab_tokens.TK_NATIVE]          = TAB_TYPEID.NATIVE,
  [lex.tab_tokens.TK_OBJECT]          = TAB_TYPEID.OBJECT,
  [lex.tab_tokens.TK_OCTET]           = TAB_TYPEID.OCTET,
  [lex.tab_tokens.TK_ONEWAY]          = "oneway",
  [lex.tab_tokens.TK_OUT]             = "out",
  [lex.tab_tokens.TK_PRIMARYKEY]      = "primarykey",
  [lex.tab_tokens.TK_PRIVATE]         = "private",
  [lex.tab_tokens.TK_PROVIDES]        = "provides",
  [lex.tab_tokens.TK_PUBLIC]          = "public",
  [lex.tab_tokens.TK_PUBLISHES]       = "publishes",
  [lex.tab_tokens.TK_RAISES]          = "raises",
  [lex.tab_tokens.TK_READONLY]        = "readonly",
  [lex.tab_tokens.TK_SETRAISES]       = "setraises",
  [lex.tab_tokens.TK_SEQUENCE]        = "sequence",
  [lex.tab_tokens.TK_SHORT]           = TAB_TYPEID.SHORT,
  [lex.tab_tokens.TK_STRING]          = TAB_TYPEID.STRING,
  [lex.tab_tokens.TK_STRUCT]          = TAB_TYPEID.STRUCT,
  [lex.tab_tokens.TK_SUPPORTS]        = "supports",
  [lex.tab_tokens.TK_SWITCH]          = "switch",
  [lex.tab_tokens.TK_TRUE]            = "TRUE",
  [lex.tab_tokens.TK_TRUNCATABLE]     = "truncatable",
  [lex.tab_tokens.TK_TYPEDEF]         = TAB_TYPEID.TYPEDEF,
  [lex.tab_tokens.TK_TYPEID]          = "typeid",
  [lex.tab_tokens.TK_TYPEPREFIX]      = "typeprefix",
  [lex.tab_tokens.TK_UNSIGNED]        = "unsigned",
  [lex.tab_tokens.TK_UNION]           = TAB_TYPEID.UNION,
  [lex.tab_tokens.TK_USES]            = "uses",
  [lex.tab_tokens.TK_VALUEBASE]       = TAB_TYPEID.VALUEBASE,
  [lex.tab_tokens.TK_VALUETYPE]       = TAB_TYPEID.VALUETYPE,
  [lex.tab_tokens.TK_VOID]            = TAB_TYPEID.VOID,
  [lex.tab_tokens.TK_WCHAR]           = "wchar",
  [lex.tab_tokens.TK_WSTRING]         = "wstring",
  [lex.tab_tokens.TK_INTEGER_LITERAL] = "<integer literal>",
  [lex.tab_tokens.TK_FLOAT_LITERAL]   = "<float literal>",
  [lex.tab_tokens.TK_CHAR_LITERAL]    = "<char literal>",
  [lex.tab_tokens.TK_WCHAR_LITERAL]   = "<wchar literal>",
  [lex.tab_tokens.TK_STRING_LITERAL]  = "<string literal>",
  [lex.tab_tokens.TK_WSTRING_LITERAL] = "<wstring literal>",
  [lex.tab_tokens.TK_FIXED_LITERAL]   = "<fixed literal>",
  [lex.tab_tokens.TK_PRAGMA_PREFIX]   = "<pragma prefix>",
  [lex.tab_tokens.TK_PRAGMA_ID]       = "<pragma id>",
  [lex.tab_tokens.TK_MANAGES]         = "manages",
}

local ERRMSG_DECLARED       = "'%s' has already been declared"
local ERRMSG_PARAMDECLARED  = "parameter '%s' has already been declared"
local ERRMSG_RAISESDECLARED = "raise '%s' has already been declared"
local ERRMSG_OPDECLARED     = "operation '%s' has already been declared"
local ERRMSG_REDEFINITION   = "redefinition of '%s'"
local ERRMSG_NOTTYPE        = "%s is not a legal type"
local ERRMSG_UNDECLARED     = "%s is an undeclared type"
local ERRMSG_FORWARD        = "There is a forward reference to %s, but it is not defined"

local function sinError( val_expected )
  error(string.format("%s(line %i): %s expected, encountered '%s'." ,
        lex.srcfilename, lex.line, val_expected, lex.tokenvalue), 2)
end

local function semanticError( error_msg )
  local scope_name = tab_curr_scope.absolute_name
  if (scope_name == '') then
    scope_name = 'GLOBAL'
  end
  error(string.format("%s(line %i):Scope:'%s': %s.", lex.srcfilename,
        lex.line, scope_name, error_msg), 2)
end

local function isForward()
  for k, _ in pairs(tab_forward) do
    semanticError(string.format(ERRMSG_FORWARD, k))
  end
end

local function gotoFatherScope()
  if (ROOTS[#ROOTS].scope == tab_curr_scope.absolute_name) then
    table.remove(ROOTS)
  end
  currentRoot = ROOTS[#ROOTS].root
  if (tab_curr_scope._type == TAB_TYPEID.MODULE) then
    currentRoot = string.gsub(currentRoot, "::[^:]+$", "")
    ROOTS[#ROOTS].root = currentRoot
  elseif (tab_curr_scope._type == TAB_TYPEID.INTERFACE) or
         (tab_curr_scope._type == TAB_TYPEID.STRUCT) or
         (tab_curr_scope._type == TAB_TYPEID.UNION) or
         (tab_curr_scope._type == TAB_TYPEID.EXCEPTION)
  then
    currentScope = string.gsub(currentScope, "::[^:]+$", "")
  end
  tab_curr_scope = tab_namespaces[tab_curr_scope.absolute_name].father_scope
end

local function getAbsolutename( scope, name )
  return scope.absolute_name..'::'..name
end

local function dclName( name, target, value, error_msg )
  local absolutename = getAbsolutename(tab_curr_scope, name)
  if tab_namespaces[absolutename] then
    if not error_msg then
      error_msg = ERRMSG_DECLARED
    end
    semanticError(string.format(error_msg, name))
  else
    if value then
      value.name = name
      table.insert(target, value)
    else
      tab_namespaces[absolutename] = {tab_namespace = name}
      table.insert(target, name)
    end
  end
end

local reconhecer

local function getToken()
  token = lex.lexer(stridl)

  for _, linemark in ipairs(lex.tab_linemarks) do
    if linemark['1'] then
      table.insert(ROOTS, {root = '', scope = tab_curr_scope.absolute_name})
    elseif linemark['2'] then
      table.remove(ROOTS)
    end
  end
  lex.tab_linemarks = { }

-- The ID Pragma
-- #pragma ID <name> "<id>"
  if (token == lex.tab_tokens.TK_PRAGMA_ID) then
    token = lex.lexer(stridl)
    local definition = scoped_name(600)
    local repid = lex.tokenvalue
    reconhecer(lex.tab_tokens.TK_STRING_LITERAL)
    local absolutename = definition.absolute_name
    if tab_namespaces[absolutename].pragmaID then
      if (definition.repID ~= repid) then
        semanticError("repository ID ever defined")
      end
    else
      tab_namespaces[absolutename].pragmaID = true
      definition.repID = repid
    end
-- The Prefix Pragma
-- #pragma prefix "<string>"
  elseif (token == lex.tab_tokens.TK_PRAGMA_PREFIX) then
    token = lex.lexer(stridl)
    local prefix = lex.tokenvalue
    if (ROOTS[#ROOTS].scope == tab_curr_scope.absolute_name) then
      table.remove(ROOTS)
    end
    table.insert(ROOTS, {root = prefix, scope = tab_curr_scope.absolute_name})
    reconhecer(lex.tab_tokens.TK_STRING_LITERAL)
  end
  return token
end

function reconhecer( tokenExpected )
  if (tokenExpected == token) then
    token = getToken()
  else
    local valueExpected = TAB_VALUEEXPECTED[tokenExpected]
    if not valueExpected then
      valueExpected = "'"..tokenExpected.."'"
    end
    sinError(valueExpected)
  end
end

local function updateGlobalName( type, name )
  local localName = ''
  local currentRoot = ROOTS[#ROOTS].root
-- Whenever a module is encountered, the string "::" and the <name> are appended
-- to the name of the current root.
  if (type == TAB_TYPEID.MODULE) then
    currentRoot = currentRoot..'::'..name
-- Whenever a interface, struct, union or exception is encountered,
-- the string "::" and the <name> are appended to the name of the current scope.
  elseif (type == TAB_TYPEID.INTERFACE) or
         (type == TAB_TYPEID.STRUCT) or
         (type == TAB_TYPEID.UNION) or
         (type == TAB_TYPEID.EXCEPTION)
  then
    currentScope = currentScope..'::'..name
  else
    localName = '::'..name
  end
  ROOTS[#ROOTS].root = currentRoot
  return currentRoot, currentScope, localName
end

local function define( name, type, value )
  local absolutename = getAbsolutename(tab_curr_scope, name)
  local tab_definitions

  if (tab_namespaces[absolutename]) then
    if (
        tab_namespaces[absolutename].tab_namespace._type == TAB_TYPEID.MODULE
        and
        type == TAB_TYPEID.MODULE
       )
    then
      value = tab_namespaces[absolutename].tab_namespace
      tab_curr_scope = value
      updateGlobalName(type, name)
      return false, value
    else
      semanticError(string.format(ERRMSG_REDEFINITION, name))
    end
  end

  if tab_forward[absolutename] then
    value = tab_forward[absolutename]
    tab_forward[absolutename] = nil
  end

  if (not tab_definitions and tab_accept_definition[type]) then
    tab_definitions = {}
  end

  local root, scope, localName = updateGlobalName(type, name)
  repID = root..scope..localName
  repID = string.gsub(string.gsub(repID, "^::", ""), "::", "/")

  if (not value) then
    value = {}
  end

  value.name = name
  value._type = type
  value.absolute_name = absolutename
  value.repID = "IDL:"..repID..":"..lex.PRAGMA_VERSION
  value.definitions = tab_definitions

-- tab_curr_scope ~= tab_output ????
  if (tab_is_contained[type] and tab_curr_scope ~= tab_output) then
    table.insert(tab_curr_scope.definitions, value)
  else
    table.insert(tab_curr_scope, value)
  end

  if (tab_define_scope[type]) then
    tab_namespaces[absolutename] = {
                                     father_scope = tab_curr_scope,
                                     tab_namespace = value,
                                   }
    tab_curr_scope = value
  else
    tab_namespaces[absolutename] = {tab_namespace = value}
  end
  return true, value
end

local function getTabDefinition( name )
  if (type(tab_namespaces[name]) == 'table') then
    return tab_namespaces[name].tab_namespace
  end
  local forward = tab_forward[name]
  if forward then
    return forward
  end
  return nil
end

local function getDefinition( name, scope )
  local tab_scope = tab_curr_scope
  if scope then
    tabDef = getTabDefinition(scope..'::'..name)
    if (tabDef) then
      return tabDef
    end
  else
    while true do
      local absolutename = getAbsolutename(tab_scope, name)
      local tabDef = getTabDefinition(absolutename)
      if tabDef then
        return tabDef
      end
      if (tab_scope._type == TAB_TYPEID.INTERFACE) then
        for _, v in ipairs(tab_scope) do
          local tab_scope = tab_namespaces[v.absolute_name].tab_namespace
          absolutename = getAbsolutename(tab_scope, name)
          local tabDef = getTabDefinition(absolutename)
          if tabDef then
            return tabDef
          end
        end
      end
      if tab_scope ~= tab_output then
        tab_scope = tab_namespaces[tab_scope.absolute_name].father_scope
      else
        if (tab_curr_scope._type == TAB_TYPEID.UNION) then
          if (tab_curr_scope.switch) then
            if (tab_curr_scope.switch._type == TAB_TYPEID.ENUM) then
              return tab_namespaces[getAbsolutename(tab_curr_scope.switch, namespace)].tab_namespace
            end
          end
        end
        break
      end
    end
  end
  semanticError(string.format(ERRMSG_UNDECLARED, name))
end

local function dclForward( name, type )
  local absolute_name = getAbsolutename(tab_curr_scope, name)
  local definition = tab_namespaces[absolute_name] or tab_forward[absolute_name]
  if not definition then
    definition = {name = name, _type = type, absolute_name = absolute_name}
    tab_forward[absolute_name] = definition
  end
  return definition
end

local tab_ERRORMSG = {
    [01] = "definition ('typedef', 'enum', 'native', 'union', 'struct', "..
           "'const', 'exception', 'abstract', 'local', "..
           "'interface', 'custom', 'valuetype', 'eventtype', "..
           "'module', 'typeid', 'typeprefix', 'component' or 'home')",
    [02] = "type declaration ( 'typedef', 'struct', 'union', 'enum' or 'native' )",
    [03] = "type specification ( 'char', 'boolean', 'octet', 'any', 'Object', "..
           "'ValueBase', 'long', 'float', 'double', 'short', 'unsigned', 'sequence', "..
           "'string', 'fixed', identifier, 'struct', 'union', 'enum' )",
    [04] = "simple type specification ( base type, template type or a scoped name )",
    [05] = "base type specification ( 'char', 'boolean', 'octet', 'any', 'Object', "..
           "'ValueBase', 'long', 'float', 'double', 'short', 'unsigned' )",
    [06] = "'float', 'double', 'short', 'unsigned' or 'long'",
    [07] = "'float' or 'double'",
    [08] = "'short' or 'unsigned'",
    [09] = "'long' or 'short'",
  --follows!?
    [10] = "'long'",
    [11] = "',' or ';'",
    [12] = "'[', ',' or ';'",
    [13] = "'-', '+', '~', '(', identifier, ':', <integer literal>,"..
           "<string literal>, <char literal>, <fixed literal>,"..
           "<float literal>, 'TRUE' or 'FALSE'",
    [14] = "'-', '+', '~'",
    [15] = "'(', identifier, ':', <integer literal>,"..
           "<string literal>, <char literal>, <fixed literal>,"..
           "<float literal>, 'TK_TRUE', 'TK_FALSE'",
    [16] = "<integer literal>, <string literal>, <char literal>,"..
           "<fixed literal>, <float literal>",
    [17] = "'TK_TRUE', 'TK_FALSE'",
    [18] = "'*', '/', '%', '+', '-', ']', ')', '>>', '<<', '&', '^', '|'",
    [19] = "'+', '-', '>>', '<<'",
    [20] = "'>>', '<<', '&'",
    [21] = "'&', '^'",
    [22] = "'^', '|'",
    [23] = "'|'",
    [24] = "you must entry with a positive integer",
    [25] = "you must entry with a integer",
    [26] = "'<' or identifier",
    [27] = "constructed type specification ( 'struct', 'union' or 'enum' )",
    [28] = "type specification or '}'",
    [29] = "'short', 'unsigned', 'char', 'boolean', 'enum', identifier, '::'",
    [30] = "'case', 'default'",
    [31] = "'case', 'default' or type specification",
    [32] = "'case', 'default' or '}'",
  }

--------------------------------------------------------------------------
-- GRAMMAR RULES
--------------------------------------------------------------------------

function specification()
--  import_l()
  if (tab_callbacks.start) then
    tab_callbacks.start()
  end
  definition_l()
-- Is there any forward reference without definition?
  isForward()
  if (tab_callbacks.finish) then
    tab_callbacks.finish()
  end
end

function definition_l()
  if (tab_firsts.rule_11[token]) then
    definition()
    definition_l_r()
  else
    sinError(tab_ERRORMSG[01])
  end
end

function definition_l_r()
  if (tab_firsts.rule_12[token]) then
    definition()
    definition_l_r()
  elseif (not token) then
    --empty
  else
    sinError(tab_ERRORMSG[01])
  end
end

function definition()
  if (tab_firsts.rule_14[token]) then
    type_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_15[token]) then
    const_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_16[token]) then
    except_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_17[token]) then
    inter_value_event()
    reconhecer(";")
  elseif (tab_firsts.rule_18[token]) then
    module()
    reconhecer(";")
  elseif (tab_firsts.rule_19[token]) then
    type_id_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_20[token]) then
    type_prefix_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_21[token]) then
    component()
    reconhecer(";")
  elseif (tab_firsts.rule_22[token]) then
    home_dcl()
    reconhecer(";")
  end
end

function const_dcl()
  if (tab_firsts.rule_174[token]) then
    reconhecer(lex.tab_tokens.TK_CONST)
    local type = const_type()
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    reconhecer('=')
    local value = positive_int_const(143)
    local const = {type = type, value = value}
    define(name, TAB_TYPEID.CONST, const)
    if (tab_callbacks.const) then
      tab_callbacks.const(const)
    end
  end
end

function const_type()
  if (tab_firsts.rule_175[token]) then
    return float_type_or_int_type()
  elseif (tab_firsts.rule_176[token]) then
    reconhecer(lex.tab_tokens.TK_CHAR)
    return TAB_BASICTYPE.CHAR
  elseif (tab_firsts.rule_177[token]) then
    reconhecer(lex.tab_tokens.TK_BOOLEAN)
    return TAB_BASICTYPE.BOOLEAN
  elseif (tab_firsts.rule_178[token]) then
    reconhecer(lex.tab_tokens.TK_STRING)
    return TAB_BASICTYPE.STRING
  elseif (tab_firsts.rule_179[token]) then
    return scoped_name(32)
  elseif (tab_firsts.rule_180[token]) then
    reconhecer(lex.tab_tokens.TK_OCTET)
    return TAB_BASICTYPE.OCTET
  elseif (tab_firsts.rule_181[token]) then
    reconhecer(lex.tab_tokens.TK_FIXED)
    return TAB_BASICTYPE.FIXED
  end
end

function type_dcl()
  if (tab_firsts.rule_23[token]) then
    reconhecer(lex.tab_tokens.TK_TYPEDEF)
    type_declarator()
  elseif (tab_firsts.rule_24[token]) then
    enum_type()
  elseif (tab_firsts.rule_25[token]) then
    reconhecer(lex.tab_tokens.TK_NATIVE)
    reconhecer(lex.tab_tokens.TK_ID)
    define(lex.tokenvalue_previous, TAB_TYPEID.NATIVE, {})
  elseif (tab_firsts.rule_26[token]) then
    union_or_struct()
  else
    sinError(tab_ERRORMSG[02])
  end
end

function type_declarator()
  local type = type_spec()
  if (not tab_legal_type[type._type]) then
    semanticError(string.format(ERRMSG_NOTTYPE, type._type))
  end
  type_dcl_name_l(type)
end

function type_spec(numrule)
  if (tab_firsts.rule_28[token]) then
    return simple_type_spec(numrule)
  elseif (tab_firsts.rule_29[token]) then
    return constr_type_spec()
  else
    sinError(tab_ERRORMSG[03])
  end
end

function simple_type_spec(numrule)
  if (tab_firsts.rule_30[token]) then
    return base_type_spec()
  elseif (tab_firsts.rule_31[token]) then
    return template_type_spec()
  elseif (tab_firsts.rule_32[token]) then
    tab = scoped_name( numrule or 32 )
    return tab
  else
    sinError(tab_ERRORMSG[04])
  end
end

function base_type_spec()
  if (tab_firsts.rule_36[token]) then
    return float_type_or_int_type()
  elseif (tab_firsts.rule_37[token]) then
    reconhecer(lex.tab_tokens.TK_CHAR)
    return TAB_BASICTYPE.CHAR
  elseif (tab_firsts.rule_38[token]) then
    reconhecer(lex.tab_tokens.TK_BOOLEAN)
    return TAB_BASICTYPE.BOOLEAN
  elseif (tab_firsts.rule_39[token]) then
    reconhecer(lex.tab_tokens.TK_OCTET)
    return TAB_BASICTYPE.OCTET
  elseif (tab_firsts.rule_40[token]) then
    reconhecer(lex.tab_tokens.TK_ANY)
    return TAB_BASICTYPE.ANY
  elseif (tab_firsts.rule_41[token]) then
    reconhecer(lex.tab_tokens.TK_OBJECT)
    return TAB_BASICTYPE.OBJECT
  elseif (tab_firsts.rule_42[token]) then
    reconhecer(lex.tab_tokens.TK_VALUEBASE)
    return TAB_BASICTYPE.VALUEBASE
--  else
--    sinError( tab_ERRORMSG[ 05 ] )
  end
end

function float_type_or_int_type()
  if (tab_firsts.rule_43[token]) then
    return floating_pt_type()
  elseif (tab_firsts.rule_44[token]) then
    return integer_type(54)
  elseif (tab_firsts.rule_45[token]) then
    reconhecer(lex.tab_tokens.TK_LONG)
    return long_or_double()
  else
    sinError(tab_ERRORMSG[06])
  end
end

function floating_pt_type()
  if (tab_firsts.rule_46[token]) then
    reconhecer(lex.tab_tokens.TK_FLOAT)
    return TAB_BASICTYPE.FLOAT
  elseif (tab_firsts.rule_47[token]) then
    reconhecer(lex.tab_tokens.TK_DOUBLE)
    return TAB_BASICTYPE.DOUBLE
--  else
--    sinError( tab_ERRORMSG[ 07 ] )
  end
end

function integer_type(numrule)
  if (tab_firsts.rule_48[token]) then
    reconhecer(lex.tab_tokens.TK_SHORT)
    return TAB_BASICTYPE.SHORT
  elseif (tab_firsts.rule_49[token]) then
    return unsigned_int(numrule)
--  else
--    sinError( tab_ERRORMSG[ 08 ] )
  end
end

function unsigned_int(numrule)
  reconhecer(lex.tab_tokens.TK_UNSIGNED)
  return unsigned_int_tail(numrule)
end

function unsigned_int_tail(numrule)
  if (tab_firsts.rule_51[token]) then
    reconhecer(lex.tab_tokens.TK_LONG)
    return ulong_e(numrule)
  elseif (tab_firsts.rule_52[token]) then
    reconhecer(lex.tab_tokens.TK_SHORT)
    return TAB_BASICTYPE.USHORT
  else
    sinError( tab_ERRORMSG[09] )
  end
end

function long_e(numrule)
  if (tab_firsts.rule_53[token]) then
    reconhecer(lex.tab_tokens.TK_LONG)
    return TAB_BASICTYPE.LLONG
  elseif (tab_follow['rule_'..numrule][token]) then
    return TAB_BASICTYPE.LONG
    --empty
  else
    sinError(tab_ERRORMSG[10])
  end
end

function ulong_e(numrule)
  if (tab_firsts.rule_53[token]) then
    reconhecer(lex.tab_tokens.TK_LONG)
    return TAB_BASICTYPE.ULLONG
  elseif (tab_follow['rule_'..numrule][token]) then
    return TAB_BASICTYPE.ULONG
    --empty
  else
    sinError(tab_ERRORMSG[10])
  end
end

function type_dcl_name_l(type)
  type_dcl_name(type)
  type_dcl_name_l_r(type)
end

function type_dcl_name_l_r(type)
  if (tab_firsts.rule_142[token]) then
    reconhecer(",")
    type_dcl_name(type)
    type_dcl_name_l_r(type)
  elseif (tab_follow.rule_143 [token]) then
    --empty
  else
    sinError(tab_ERRORMSG[11])
  end
end

function type_dcl_name(type)
  reconhecer(lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  local typedef = {type = fixed_array_size_l(type)}
  define(name, TAB_TYPEID.TYPEDEF, typedef)
  if (tab_callbacks.typedef) then
    tab_callbacks.typedef(typedef)
  end
end

-- without revision
function fixed_array_size_l( tab_type_spec )
  if (tab_firsts.rule_145[token]) then
    local array =  {
             length = fixed_array_size( tab_type_spec ),
             elementtype = fixed_array_size_l( tab_type_spec ),
             _type = 'array'
           }
    if tab_callbacks.array then
      tab_callbacks.array( array )
    end
    return array
  elseif (tab_follow.rule_146[token]) then
    --empty
    return tab_type_spec
  else
    sinError(tab_ERRORMSG[12])
  end
end

function fixed_array_size( tab_type_spec )
  reconhecer( "[" )
  local const = positive_int_const( 147 )
  reconhecer( "]" )
  return const
end

-- without revision
--without revision
--without bitwise logical operations
function positive_int_const( numrule )
  if tab_firsts.rule_75[ token ] then
    local const1 = xor_expr( numrule )
    or_expr_l( numrule )
    if string.find(const1, '[%d]') then
     const1 = tonumber(const1)
     if const1 < 0 then
        semanticError( tab_ERRORMSG[ 24 ] )
      end
    end
    return const1
  else
    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
function xor_expr( numrule )
  if tab_firsts.rule_93[ token ] then
    local exp1 = and_expr( numrule )
    xor_expr_l( numrule )
    return exp1
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
function and_expr( numrule )
  if tab_firsts.rule_96[ token ] then
    local const1 = shift_expr( numrule )
    return and_expr_l( const1, numrule )
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
function shift_expr( numrule )
  if tab_firsts.rule_99[ token ] then
    local const1 = add_expr( numrule )
    return shift_expr_l( const1, numrule )
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
function add_expr( numrule )
  if tab_firsts.rule_103[ token ] then
    local const1 = mult_expr( numrule )
    return add_expr_l( const1, numrule )
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
function mult_expr( numrule )
  if tab_firsts.rule_107[ token ] then
    local const = unary_expr()
--[[    if not is_num( const ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
]]
    const = mult_expr_l( const, numrule )
    return const
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

--ok2
--semantic of '~' operator ???!!
function unary_expr()
  if tab_firsts.rule_112[ token ] then
    local op = unary_operator()
    local exp = primary_expr()
    if tonumber( exp ) then
      if op == '-' then
        exp = tonumber( '-'..exp )
      elseif op == '+' then
        exp = tonumber( '+'..exp )
      end
    end
    return exp
  elseif tab_firsts.rule_113[ token ] then
    return primary_expr()
--  else
--    sinError( tab_ERRORMSG[ 13 ] )
  end
end

function unary_operator()
  if tab_firsts.rule_114[ token ] then
    reconhecer( "-" )
    return '-'
  elseif tab_firsts.rule_115[ token ] then
    reconhecer( "+" )
    return '+'
  elseif tab_firsts.rule_116[ token ] then
    reconhecer( "~" )
    return '~'
--  else
--    sinError( tab_ERRORMSG[ 14 ] )
  end
end


function primary_expr()
  if tab_firsts.rule_117[ token ] then
    local value = case_label_aux()
    if type(value) == 'table' then
       sinError("The <scoped_name> in the <const_type> production must be a previously \
                  defined name of an <integer_type>, <char_type>, <wide_char_type>, \
                  <boolean_type>, <floating_pt_type>, \
                  <string_type>, <wide_string_type>, <octet_type>, or <enum_type> constant.")
    end
    return value
  elseif tab_firsts.rule_118[ token ] then
    local value = literal()
    if tab_curr_scope._type == TAB_TYPEID.UNION then
      reconhecer( ":" )
    end
    return value
  elseif tab_firsts.rule_119[ token ] then
    reconhecer( "(" )
    local const = positive_int_const( 119 )
    reconhecer( ")" )
    return const
  else
    sinError( tab_ERRORMSG[ 15 ] )
  end
end

function literal()
  if tab_firsts.rule_120[ token ] then
    reconhecer( lex.tab_tokens.TK_INTEGER_LITERAL )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_121[ token ] then
    reconhecer( lex.tab_tokens.TK_STRING_LITERAL )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_122[ token ] then
    reconhecer( lex.tab_tokens.TK_CHAR_LITERAL )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_123[ token ] then
    reconhecer( lex.tab_tokens.TK_FIXED_LITERAL )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_124[ token ] then
    reconhecer( lex.tab_tokens.TK_FLOAT_LITERAL )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_125[ token ] then
    return boolean_literal()
--  else
--    sinError( tab_ERRORMSG[ 16 ] )
  end
end

--ok2
function boolean_literal()
  if tab_firsts.rule_126[ token ] then
    reconhecer( lex.tab_tokens.TK_TRUE )
    return lex.tokenvalue_previous
  elseif tab_firsts.rule_127[ token ] then
    reconhecer( lex.tab_tokens.TK_FALSE )
    return lex.tokenvalue_previous
--  else
--    sinError( tab_ERRORMSG[ 17 ] )
  end
end

--ok2
function mult_expr_l( const1, numrule )
  if tab_firsts.rule_108[ token ] then
    reconhecer( "*" )
    local const2 = unary_expr()
    if not tonumber( const2 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
    local const = const1 * const2
    return mult_expr_l( const, numrule )
  elseif tab_firsts.rule_109[ token ] then
    reconhecer( "/" )
    local const2 = unary_expr()
    if not tonumber( const2 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
    local const = const1 / const2
    return mult_expr_l( const, numrule )
  elseif tab_firsts.rule_110[ token ] then
    reconhecer( "%" )
    local const2 = unary_expr()
    if not tonumber( const2 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
    local const = math.mod( const1, const2 )
    return mult_expr_l( const, numrule )
  elseif ( tab_follow.rule_111[ token ] or tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':'
)) then
    --empty
    return const1
  else
    sinError( tab_ERRORMSG[ 18 ] )
  end
end

function add_expr_l( const1, numrule )
  if tab_firsts.rule_104[ token ] then
    reconhecer( "+" )
    if not tonumber( const1 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
    local const2 = mult_expr( numrule )
    local const = const1 + const2
    return add_expr_l( const, numrule )
  elseif tab_firsts.rule_105[ token ] then
    reconhecer( "-" )
    if not tonumber( const1 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end
    local const2 = mult_expr( numrule )
    local const = const1 - const2
    return add_expr_l( const, numrule )
  elseif ( tab_follow.rule_106[ token ] or tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':' )
) then
    --empty
    return const1
  else
    sinError( tab_ERRORMSG[ 19 ] )
  end
end

--
function shift_expr_l( const1, numrule )
  if tab_firsts.rule_100[ token ] then
    reconhecer( ">>" )
    add_expr( numrule )
    shift_expr_l( numrule )
  elseif tab_firsts.rule_101[ token ] then
    reconhecer( "<<" )
    add_expr( numrule )
    shift_expr_l( numrule )
  elseif ( tab_follow.rule_102[ token ] or tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':'
)) then
    --empty
    return const1
  else
    sinError( tab_ERRORMSG[ 20 ] )
  end
end

--
function and_expr_l( const1, numrule )
  if tab_firsts.rule_97[ token ] then
    reconhecer( "&" )
--[[    if not is_num( const1 ) then
      semanticError( tab_ERRORMSG[ 25 ] )
    end]]
    local const2 = shift_expr( numrule )
--    local const = const1 and const2
    return and_expr_l( const, numrule )
  elseif ( tab_follow.rule_98[ token ] or tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':' )
) then
    --empty
    return const1
  else
    sinError( tab_ERRORMSG[ 21 ] )
  end
end

--
function xor_expr_l( numrule )
  if tab_firsts.rule_94[ token ] then
    reconhecer( "^" )
    and_expr( numrule )
    xor_expr_l( numrule )
  elseif ( tab_follow.rule_95[ token ] or tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':' )
) then
    --empty
  else
    sinError( tab_ERRORMSG[ 22 ] )
  end
end

--
function or_expr_l( numrule )
  if tab_firsts.rule_91[ token ] then
    reconhecer( "|" )
    xor_expr( numrule )
    or_expr_l( numrule )
  elseif ( tab_follow[ 'rule_'..numrule ][ token ] or ( lex.tokenvalue_previous == ':' ) ) then
    --empty
  else
    sinError( tab_ERRORMSG[ 23 ] )
  end
end

function template_type_spec()
  if tab_firsts.rule_58[ token ] then
    return sequence_type()
  elseif tab_firsts.rule_59[ token ] then
    return string_type()
  elseif tab_firsts.rule_60[ token ] then
    return fixed_pt_type()
  end
end

function sequence_type()
  reconhecer( lex.tab_tokens.TK_SEQUENCE, "'sequence'" )
  reconhecer( "<" )
  local tab_type_spec = simple_type_spec( 61 )
  tab_type_spec = sequence_type_tail( tab_type_spec )
  if tab_callbacks.sequence then
    tab_callbacks.sequence( tab_type_spec )
  end
  return tab_type_spec
end

function sequence_type_tail( tab_type_spec )
  if tab_firsts.rule_69[ token ] then
    reconhecer( "," )
    local const = positive_int_const( 69 )
    reconhecer( ">" )
    return { _type = TAB_TYPEID.SEQUENCE, elementtype = tab_type_spec, maxlength = const  }
  elseif tab_firsts.rule_70[ token ] then
    reconhecer( ">" )
  --maxlength??
    return { _type = TAB_TYPEID.SEQUENCE, elementtype = tab_type_spec, maxlength = 0  }
  else
    sinError( "',' or '>'" )
  end
end

--ok2
function string_type()
  reconhecer( lex.tab_tokens.TK_STRING )
--maxlength??
  return TAB_BASICTYPE.STRING
end

--ok2
function string_type_tail()
  if tab_firsts.rule_72[ token ] then
    reconhecer( "<" )
    local const = positive_int_const( 72 )
    reconhecer( ">" )
    return const
  elseif tab_follow.rule_73[ token ] then
    return nil
    --empty
  else
    sinError( tab_ERRORMSG[ 26 ] )
  end
end

--const1 and const2 ??!?
function fixed_pt_type()
  reconhecer( lex.tab_tokens.TK_FIXED )
  reconhecer( "<" )
  local const1 = positive_int_const( 74 )
  reconhecer( "," )
  local const2 = positive_int_const( 74 )
  reconhecer( ">" )
  return TAB_BASICTYPE.FIXED
end

function constr_type_spec()
  if tab_firsts.rule_33[ token ] then
    return struct_type()
  elseif tab_firsts.rule_34[ token ] then
    return union_type()
  elseif tab_firsts.rule_35[ token ] then
    return enum_type()
  else
    sinError( tab_ERRORMSG[ 27 ] )
  end
end

function struct_type()
  reconhecer(lex.tab_tokens.TK_STRUCT)
  reconhecer(lex.tab_tokens.TK_ID)
  define(lex.tokenvalue_previous, TAB_TYPEID.STRUCT)
  reconhecer("{")
  member_l()
  local struct = tab_curr_scope
  gotoFatherScope()
  reconhecer("}")
  if tab_callbacks.struct then
    tab_callbacks.struct(struct)
  end
  return struct
end

function union_type()
  if tab_firsts.rule_148[ token ] then
    reconhecer(lex.tab_tokens.TK_UNION)
    reconhecer(lex.tab_tokens.TK_ID)
    local union_name = lex.tokenvalue_previous
    reconhecer(lex.tab_tokens.TK_SWITCH)
    define(union_name, TAB_TYPEID.UNION )
    reconhecer("(")
    tab_curr_scope.switch = switch_type_spec()
    reconhecer(")")
    reconhecer("{")
    tab_curr_scope.default = -1
    case_l()
    reconhecer("}")
    local union = tab_curr_scope
    gotoFatherScope()
    if tab_callbacks.union then
      tab_callbacks.union( union )
    end
    return tab_union
  else
    sinError( tab_ERRORMSG[ 29 ] )
  end
end

function switch_type_spec()
  if tab_firsts.rule_149[ token ] then
    return integer_type( 148 )
  elseif tab_firsts.rule_150[ token ] then
    reconhecer( lex.tab_tokens.TK_LONG)
    return long_e( 148 )
  elseif tab_firsts.rule_151[ token ] then
    reconhecer( lex.tab_tokens.TK_CHAR)
    return TAB_BASICTYPE.CHAR
  elseif tab_firsts.rule_152[ token ] then
    reconhecer( lex.tab_tokens.TK_BOOLEAN)
    return TAB_BASICTYPE.BOOLEAN
  elseif tab_firsts.rule_153[ token ] then
    reconhecer( lex.tab_tokens.TK_ENUM)
    return TAB_BASICTYPE.ENUM
  elseif tab_firsts.rule_154[ token ] then
    return scoped_name( 154 )
  else
    sinError( tab_ERRORMSG[ 30 ] )
  end
end

function case_l()
  if tab_firsts.rule_155[ token ] then
    case()
    case_l_r()
  else
    sinError( tab_ERRORMSG[ 31 ] )
  end
end

function case_l_r()
  if tab_firsts.rule_156[ token ] then
    case()
    case_l_r()
  elseif tab_follow.rule_157[ token ] then
    --empty
  else
    sinError( tab_ERRORMSG[ 33 ] )
  end
end

function case()
  if tab_firsts.rule_158[ token ] then
    local cases = case_label_l()
    local tab_type_spec, name = element_spec(cases)
    for i, case in pairs(cases) do
      if i == 1 then
        dclName(name, tab_curr_scope, {type = tab_type_spec, label = case})
      else
        table.insert(tab_curr_scope, {name = name, type = tab_type_spec, label = case})
      end
      if case == 'none' then
        tab_curr_scope.default = table.getn(tab_curr_scope)
      end
    end
    reconhecer(";")
  else
    sinError( tab_ERRORMSG[ 31 ] )
  end
end

function case_label_l()
  local cases = {}
  if tab_firsts.rule_159[ token ] then
    case_label(cases)
    case_label_l_r(cases)
  else
    sinError( tab_ERRORMSG[ 31 ] )
  end
  return cases
end

function case_label_l_r(cases)
  if tab_firsts.rule_160[ token ] then
    case_label(cases)
    case_label_l_r(cases)
  elseif tab_follow.rule_161[ token ] then
    --empty
  else
    sinError( tab_ERRORMSG[ 32 ] )
  end
end

function case_label(cases)
  if (tab_firsts.rule_162[token]) then
    reconhecer(lex.tab_tokens.TK_CASE)
    local value = positive_int_const(162)
    table.insert(cases, value)
  elseif (tab_firsts.rule_163[token]) then
    reconhecer(lex.tab_tokens.TK_DEFAULT)
    reconhecer(":")
    if (tab_curr_scope.default ~= -1) then
      semanticError("A default case can appear at most once.")
    else
      table.insert(cases, 'none')
      tab_curr_scope.default = 1
    end
  else
    sinError( tab_ERRORMSG[ 31 ] )
  end
end

function case_label_aux()
  if (token == lex.tab_tokens.TK_ID) then
    reconhecer(lex.tab_tokens.TK_ID)
    tab_scope = getDefinition(lex.tokenvalue_previous)
    reconhecer(":")
    return case_label_tail(tab_scope)
  elseif (token == ':') then
    reconhecer(":")
    reconhecer(":")
    reconhecer(lex.tab_tokens.TK_ID, "identifier")
    tab_scope = getDefinition(lex.tokenvalue_previous)
    reconhecer(":")
    return case_label_tail(tab_scope)
  end
end

function case_label_tail(tab_scope)
  if (token == ':') then
    reconhecer(":")
    return case_label_tail_aux(tab_scope)
  elseif (tab_firsts.rule_28[token] or tab_firsts.rule_29[token]) then
    --empty
    return tab_scope
  end
end

function case_label_tail_aux(tab_scope)
  if (token == ':') then
    reconhecer(":")
  elseif (token == lex.tab_tokens.TK_ID) then
    reconhecer(lex.tab_tokens.TK_ID)
    local namespace = lex.tokenvalue_previous
    tab_scope = getDefinition(namespace, tab_scope.absolute_name)
    tab_scope = case_label_tail_aux(tab_scope)
  end
  return tab_scope
end

function element_spec(cases)
  if (tab_firsts.rule_164[token]) then
    local tab_type_spec = type_spec(221)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    return tab_type_spec, name
  else
    sinError( tab_ERRORMSG[ 03 ] )
  end
end

function enum_type()
  reconhecer(lex.tab_tokens.TK_ENUM)
  reconhecer(lex.tab_tokens.TK_ID)
  local _, tab_enum = define(lex.tokenvalue_previous, TAB_TYPEID.ENUM)
  reconhecer("{")
  enumerator(tab_enum)
  enumerator_l(tab_enum)
  reconhecer("}")
  if tab_callbacks.enum then
    tab_callbacks.enum(tab_enum)
  end
  return tab_enum
end

function enumerator(tab_enum)
  reconhecer(lex.tab_tokens.TK_ID)
  dclName(lex.tokenvalue_previous, tab_enum)
end

function enumerator_l(tab_enum)
  if (tab_firsts.rule_166[token]) then
    reconhecer(",")
    enumerator(tab_enum)
    enumerator_l(tab_enum)
  elseif (tab_follow.rule_167[token]) then
    -- empty
  else
    sinError("',' or '}'")
  end
end

function module()
  if (tab_firsts.rule_305[token]) then
    reconhecer(lex.tab_tokens.TK_MODULE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    if (name == 'CORBA') then
      CORBAVisible = true
    end
    local status, _module = define(name, TAB_TYPEID.MODULE)
    reconhecer("{")
    definition_l_module()
    local module = tab_curr_scope
    gotoFatherScope()
    reconhecer("}")
    if tab_callbacks.module then
      tab_callbacks.module(module)
    end
  end
end

function long_or_double()
  if tab_firsts.rule_55[ token ] then
    reconhecer(lex.tab_tokens.TK_LONG)
    return TAB_BASICTYPE.LLONG
  elseif tab_firsts.rule_56[ token ] then
    reconhecer(lex.tab_tokens.TK_DOUBLE)
    return TAB_BASICTYPE.LDOUBLE
  else
    return TAB_BASICTYPE.LONG
  end
end

function scoped_name_l( tab_scope, full_namespace, num_follow_rule )
  if (token == ":") then
    reconhecer(":")
    reconhecer(":")
    reconhecer(lex.tab_tokens.TK_ID)
    local namespace = lex.tokenvalue_previous
    full_namespace = tab_scope.absolute_name..'::'..namespace
    tab_scope = getDefinition(namespace, tab_scope.absolute_name)
    tab_scope = scoped_name_l(tab_scope, full_namespace, num_follow_rule)
  elseif (tab_follow['rule_'..num_follow_rule][token]) then
    -- empty
  else
    sinError("':' or "..tab_follow_rule_error_msg[num_follow_rule])
  end
  return tab_scope
end

function scoped_name( num_follow_rule )
  local name = ''
  local tab_scope = { }
  if (token == lex.tab_tokens.TK_ID) then
    reconhecer(lex.tab_tokens.TK_ID)
    name = lex.tokenvalue_previous
    tab_scope = getDefinition(name)
    tab_scope = scoped_name_l(tab_scope, name, num_follow_rule)
  elseif (token == ":") then
    reconhecer(":")
    reconhecer(":")
    reconhecer(lex.tab_tokens.TK_ID)
    name = lex.tokenvalue_previous
    tab_scope = getDefinition(name)
    tab_scope = scoped_name_l(tab_scope, name, num_follow_rule)
  end
  return tab_scope
end

function union_or_struct()
  if (tab_firsts.rule_168[token]) then
    reconhecer(lex.tab_tokens.TK_STRUCT)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    return struct_tail(name)
  elseif (tab_firsts.rule_169[token]) then
    reconhecer(lex.tab_tokens.TK_UNION)
    reconhecer(lex.tab_tokens.TK_ID)
    define(lex.tokenvalue_previous, TAB_TYPEID.UNION)
    union_tail()
    local union = tab_curr_scope
    gotoFatherScope()
    if tab_callbacks.union then
      tab_callbacks.union(union)
    end
    return union
  else
    sinError("'struct' or 'union'")
  end
end

function struct_tail(name)
  if (tab_firsts.rule_170[token]) then
    define(name, TAB_TYPEID.STRUCT)
    reconhecer("{")
    member_l()
    reconhecer("}")
    local struct = tab_curr_scope
    gotoFatherScope()
    if tab_callbacks.struct then
      tab_callbacks.struct(struct)
    end
    return struct
  elseif (token == ";") then
    return dclForward(name, TAB_TYPEID.STRUCT)
  else
    sinError(" '{' or ';' ")
  end
end

function member_l()
  if (tab_firsts.rule_137[token]) then
    member()
    member_r()
  else
    sinError(tab_ERRORMSG[03])
  end
end

function member()
  if (tab_firsts.rule_140[token]) then
    declarator_l(type_spec())
    reconhecer(";")
  else
    sinError(tab_ERRORMSG[03])
  end
end

function member_r()
  if tab_firsts.rule_138[ token ] then
    member()
    member_r()
  elseif tab_follow.rule_139[ token ] then
    -- empty
  else
    sinError( tab_ERRORMSG[ 28 ] )
  end
end

function declarator_l(type)
  local declarators = {}
  declarator(type)
  declarator_l_r(type)
end

function declarator_l_r(type)
  if (tab_firsts.rule_142[token]) then
    reconhecer(",")
    declarator(type)
    declarator_l_r(type)
  elseif (tab_follow.rule_143[token]) then
    --empty
  else
    sinError(tab_ERRORMSG[11])
  end
end

--array - missing
function declarator(type)
  reconhecer(lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  dclName(name, tab_curr_scope, {type = fixed_array_size_l(type)})
end

function union_tail()
  if ( tab_firsts.rule_172[ token ] ) then
    reconhecer( lex.tab_tokens.TK_SWITCH)
    reconhecer("(")
    tab_curr_scope.switch  = switch_type_spec()
    reconhecer(")")
    reconhecer("{")
    tab_curr_scope.default = -1
    case_l()
    reconhecer("}")
  else
    sinError("'switch'")
  end
end

function except_dcl()
  reconhecer(lex.tab_tokens.TK_EXCEPTION)
  reconhecer(lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  define(name, TAB_TYPEID.EXCEPTION)
  reconhecer("{")
  member_l_empty()
  local except = tab_curr_scope
  gotoFatherScope()
  reconhecer("}")
  if tab_callbacks.except then
    tab_callbacks.except(except)
  end
end

function member_l_empty()
  if (tab_firsts.rule_187[token]) then
    member()
    member_l_empty()
  elseif (token == "}") then
    -- empty
  else
    sinError("member list { ... } or '}'")
  end
end

function definition_l_r_module()
  if ( tab_firsts.rule_12[ token ] ) then
    definition()
    definition_l_r_module()
  elseif ( token == '}' ) then
    -- empty
  else
    sinError( "definition" )
  end
end

function definition_l_module()
  if ( tab_firsts.rule_11[ token ] ) then
    definition()
    definition_l_r_module()
  else
    sinError( "definition" )
  end
end

--------------------------------------------------------------------------
-- INTERFACE DECLARATION
--------------------------------------------------------------------------

function inter_value_event()
  if (tab_firsts.rule_192[token]) then
    reconhecer(lex.tab_tokens.TK_INTERFACE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local interface = interface_tail(name)
    if tab_callbacks.interface then
      tab_callbacks.interface( interface )
    end
  elseif (tab_firsts.rule_189[token]) then
    reconhecer(lex.tab_tokens.TK_ABSTRACT)
    abstract_tail()
  elseif ( tab_firsts.rule_190[ token ] ) then
    reconhecer(lex.tab_tokens.TK_LOCAL)
    reconhecer(lex.tab_tokens.TK_INTERFACE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local interface = interface_tail(name, 'local')
    if tab_callbacks.interface and interface then
      tab_callbacks.interface( interface )
    end
  elseif ( tab_firsts.rule_193[ token ] ) then
    reconhecer(lex.tab_tokens.TK_VALUETYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define( name, TAB_TYPEID.VALUETYPE )
    local tab_valuetypescope = value_tail( name )
    if tab_callbacks.valuetype then
      tab_callbacks.valuetype( tab_valuetypescope )
    end
  elseif ( tab_firsts.rule_191[ token ] ) then
    reconhecer(lex.tab_tokens.TK_CUSTOM)
    value_or_event()
  elseif tab_firsts.rule_194[ token ] then
    reconhecer(lex.tab_tokens.TK_EVENTTYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define( name, TAB_TYPEID.EVENTTYPE )
    local tab_eventtypescope = eventtype_tail(name)
    if tab_callbacks.eventtype then
      tab_callbacks.eventtype( tab_eventtypescope )
    end
  else
    sinError( "'interface', 'abstract', 'local' or 'valuetype'" )
  end
end

function abstract_tail()
  if (tab_firsts.rule_195[token]) then
    reconhecer(lex.tab_tokens.TK_INTERFACE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local interface = interface_tail(name, 'abstract')
    if tab_callbacks.interface then
      tab_callbacks.interface( interface )
    end
  elseif (tab_firsts.rule_196[token]) then
    reconhecer(lex.tab_tokens.TK_VALUETYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define(name, TAB_TYPEID.VALUETYPE)
    tab_curr_scope.abstract = true
    local tab_valuetypescope = value_tail( name )
    if tab_callbacks.valuetype then
      tab_callbacks.valuetype( tab_valuetypescope )
    end
  elseif tab_firsts.rule_197[ token ] then
    reconhecer(lex.tab_tokens.TK_EVENTTYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define( name, TAB_TYPEID.EVENTTYPE )
    tab_curr_scope.abstract = true
    local tab_eventtypescope = eventtype_tail( name )
    if tab_callbacks.eventtype then
      tab_callbacks.eventtype( tab_eventtypescope )
    end
  else
    sinError( "'interface', 'valuetype' or 'event'" )
  end
end

function interface_tail(name, header)
  if (tab_firsts.rule_198[token]) then
    reconhecer(":")
    local base = scoped_name(204)
    define(name, TAB_TYPEID.INTERFACE)
    table.insert(tab_curr_scope, base)
    bases()
    reconhecer("{")
    export_l()
    reconhecer("}")
    local interface = tab_curr_scope
    verifyHeader(header)
    gotoFatherScope()
    return interface
  elseif (tab_firsts.rule_199[token]) then
    reconhecer("{")
    define(name, TAB_TYPEID.INTERFACE)
    export_l()
    reconhecer("}")
    local interface = tab_curr_scope
    verifyHeader(header)
    gotoFatherScope()
    return interface
  elseif (token == ';') then
    return dclForward(name, TAB_TYPEID.INTERFACE)
  else
    sinError("'{', ':' or ';'")
  end
end

function bases()
  if (tab_firsts.rule_254[token]) then
    reconhecer(",")
    local base = scoped_name(204)
    table.insert(tab_curr_scope, base)
    bases()
  elseif (token == '{') then
    -- empty
  else
    sinError( "',' or '{'" )
  end
end

function verifyHeader(header)
  if (header == 'local') then
    tab_curr_scope['header'] = true
  elseif (header == 'abstract') then
    tab_curr_scope['abstract'] = true
  end
end

function export_l()
  if (tab_firsts.rule_207[token]) then
    export()
    export_l()
  elseif (token == "}") then
    --empty
  else
    sinError("empty interface, a declaration or '}'")
  end
end

function export()
  if (tab_firsts.rule_209[token]) then
    type_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_211[token]) then
    except_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_212[token]) then
    attr_dcl()
    reconhecer(";")
  elseif (tab_firsts.rule_213[token]) then
    op_dcl()
    reconhecer(";")
  else
    sinError("constant, type, exception, attribute or operation declaration")
  end
end

--------------------------------------------------------------------------
-- OPERATION DECLARATION
--------------------------------------------------------------------------

function op_dcl()
  if (tab_firsts.rule_243[token]) then
    reconhecer(lex.tab_tokens.TK_ONEWAY)
    local result = op_type_spec()
    if (result._type ~= 'void') then
      semanticError( "An operation with the oneway attribute must specify a 'void' return type." )
    end
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define(name, TAB_TYPEID.OPERATION)
    tab_curr_scope.name = name
    tab_curr_scope.oneway = true
    parameter_dcls()
    raises_expr_e(tab_curr_scope)
    context_expr_e()
    local operation = tab_curr_scope
    gotoFatherScope()
    if (tab_callbacks.operation) then
      tab_callbacks.operation(operation)
    end
  elseif tab_firsts.rule_244[token] then
    local result = op_type_spec()
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define(name, TAB_TYPEID.OPERATION)
    tab_curr_scope.name = name
    tab_curr_scope.result = result
    parameter_dcls()
    raises_expr_e(tab_curr_scope)
    context_expr_e()
    local operation = tab_curr_scope
    gotoFatherScope()
    if tab_callbacks.operation then
      tab_callbacks.operation(operation)
    end
  else
    sinError("'oneway' or type specification")
  end
end

function op_type_spec()
  if (tab_firsts.rule_245[token]) then
    return param_type_spec()
  elseif (tab_firsts.rule_246[token]) then
    reconhecer(lex.tab_tokens.TK_VOID)
    return TAB_BASICTYPE.VOID
  else
    sinError("type return")
  end
end

function parameter_dcls()
  reconhecer("(")
  parameter_dcls_tail()
end

function parameter_dcls_tail()
  if (tab_firsts.rule_248[token]) then
    tab_curr_scope.parameters = {}
    param_dcl()
    param_dcl_l()
    reconhecer(")")
  elseif (tab_firsts.rule_249[token]) then
    reconhecer(")")
  else
    sinError("'in', 'out', 'inout' or ')'")
  end
end

function param_dcl()
  local attribute = param_attribute()
  local type = param_type_spec()
  reconhecer(lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  dclName(name, tab_curr_scope.parameters, {mode = attribute, type = type})
end

function param_dcl_l()
  if (tab_firsts.rule_254[token]) then
    reconhecer(",")
    param_dcl()
    param_dcl_l()
  elseif token == lex.tab_tokens.TK_RAISES or
       token == lex.tab_tokens.TK_CONTEXT or
       token == ')' then
    -- empty
  else
    sinError("',', ')', 'raises' or 'context'")
  end
end

function param_attribute()
  if (tab_firsts.rule_251[token]) then
    reconhecer(lex.tab_tokens.TK_IN)
    return 'PARAM_IN'
  elseif (tab_firsts.rule_252[token]) then
    reconhecer(lex.tab_tokens.TK_OUT)
    return 'PARAM_OUT'
  elseif (tab_firsts.rule_253[token]) then
    reconhecer(lex.tab_tokens.TK_INOUT)
    return 'PARAM_INOUT'
  end
end

function param_type_spec()
  if (tab_firsts.rule_219[token]) then
    return base_type_spec()
  elseif (tab_firsts.rule_220[token]) then
    return string_type()
  elseif (tab_firsts.rule_221[token]) then
    return scoped_name( 221 )
  else
    sinError('type specification')
  end
end

function raises_expr( tab )
  reconhecer(lex.tab_tokens.TK_RAISES)
  reconhecer("(")
  tab.exceptions = {}
  raises(tab.exceptions)
  inter_name_seq(tab.exceptions)
  reconhecer(")")
end

function raises(raises)
  local exception = scoped_name( 229 )
  if exception._type ~= TAB_TYPEID.EXCEPTION then
    semanticError( string.format( "The type of '%s' is %s, but it should be exception.",
          exception.absolute_name, exception._type ) )
  end
  table.insert(raises, exception)
end

function inter_name_seq(_raises)
  if (tab_firsts.rule_254[token]) then
    reconhecer(",")
    raises(_raises)
    inter_name_seq(_raises)
  elseif (token == ')') then
    -- empty
  else
    sinError("')'")
  end
end

function raises_expr_e(tab)
  if (tab_firsts.rule_370[token]) then
    raises_expr(tab)
  elseif (token == ';' or token == lex.tab_tokens.TK_CONTEXT) then
    -- empty
  else
    sinError("'raises', 'context', ';'")
  end
end

function context_expr_e()
  if (tab_firsts.rule_377[token]) then
    context_expr()
  elseif (token == ';') then
    -- empty
  else
    sinError("'context' or ';'")
  end
end

function context_expr()
  reconhecer(lex.tab_tokens.TK_CONTEXT)
  reconhecer("(")
  tab_curr_scope.contexts = {}
  context()
  string_literal_l()
  reconhecer(")")
end

function context()
  reconhecer(lex.tab_tokens.TK_STRING_LITERAL)
  dclName(lex.tokenvalue_previous, tab_curr_scope.contexts, {})
end

function string_literal_l()
  if (tab_firsts.rule_257[token]) then
    reconhecer(",")
    context()
    string_literal_l()
  elseif (token == ')') then
    -- empty
  else
    sinError("',' or ')'")
  end
end

--------------------------------------------------------------------------
-- ATTRIBUTE
--------------------------------------------------------------------------

function attr_dcl()
  if (tab_firsts.rule_216[token]) then
    readonly_attr_spec()
  elseif (tab_firsts.rule_217[token] ) then
    attr_spec()
  else
    sinError( "'readonly' or 'attribute'" )
  end
end

function readonly_attr_spec()
  reconhecer(lex.tab_tokens.TK_READONLY)
  reconhecer(lex.tab_tokens.TK_ATTRIBUTE)
  local type = param_type_spec()
  readonly_attr_spec_dec(type)
end

function attr_spec()
  reconhecer( lex.tab_tokens.TK_ATTRIBUTE)
  local type = param_type_spec()
  attr_declarator(type)
end

function readonly_attr_spec_dec(type)
  local attribute = {type = type, readonly = true}
  local name = simple_dcl()
  define(name, TAB_TYPEID.ATTRIBUTE, attribute)
  readonly_attr_spec_dec_tail(attribute)
  if tab_callbacks.attribute then
    tab_callbacks.attribute(attribute)
  end
end

function attr_declarator(type)
  local attribute = {type = type}
  local name = simple_dcl()
  define(name, TAB_TYPEID.ATTRIBUTE, attribute)
  attr_declarator_tail(attribute)
  if tab_callbacks.attribute then
    tab_callbacks.attribute(attribute)
  end
end

function readonly_attr_spec_dec_tail(attribute)
  if (tab_firsts.rule_227[token]) then
    raises_expr(attribute)
  elseif (tab_firsts.rule_228[token]) then
    simple_dcl_l(type, true)
  elseif (token == ';') then
    -- empty
  else
    sinError( "'raises', ',' or ';'" )
  end
end

function attr_declarator_tail(attribute)
  if (tab_firsts.rule_234[token]) then
    attr_raises_expr(attribute)
  elseif (tab_firsts.rule_235[token]) then
    simple_dcl_l(attribute.type)
  elseif (token == ';') then
    -- empty
  else
    sinError( "'getraises', 'setraises', ',' or ';'" )
  end
end

function simple_dcl()
  reconhecer( lex.tab_tokens.TK_ID)
  return lex.tokenvalue_previous
end

function simple_dcl_l(type, readonly)
  if ( tab_firsts.rule_142[ token ] ) then
    reconhecer(",")
    local attribute = {type = type, readonly = readonly}
    local name = simple_dcl()
    define(name, TAB_TYPEID.ATTRIBUTE, attribute)
    simple_dcl_l(type)
  elseif (token == ';') then
    -- empty
  end
end

function attr_raises_expr(attribute)
  if (tab_firsts.rule_236[token]) then
    reconhecer(lex.tab_tokens.TK_GETRAISES)
    attribute.raises = {}
    exception_l(attribute, 'getraises')
    attr_raises_expr_tail(attribute)
  elseif (tab_firsts.rule_237[token]) then
    reconhecer(lex.tab_tokens.TK_SETRAISES)
    attribute.raises = {}
    exception_l(attribute, 'setraises')
  end
end

function attr_raises_expr_tail(attribute)
  if (tab_firsts.rule_238[token]) then
    reconhecer(lex.tab_tokens.TK_SETRAISES)
    exception_l(attribute, 'setraises')
  elseif (token == ';') then
    --empty
  else
    sinError("'setraises' or ';'")
  end
end

function exception(attribute, raises_type)
  local exception = {type = raises_type, exception = scoped_name(229)}
  table.insert(attribute.raises, exception)
end

function exception_l(attribute, raises_type)
  reconhecer("(")
  exception(attribute, raises_type)
  exception_l_seq(attribute, raises_type)
  reconhecer( ")")
end

function exception_l_seq(attribute, raises_type)
  if (tab_firsts.rule_142[token]) then
    reconhecer(",")
    exception(attribute, raises_type)
    exception_l_seq(attribute, raises_type)
  elseif (token == ';') then
    -- empty
  end
end

--------------------------------------------------------------------------
-- COMPONENT DECLARATION
--------------------------------------------------------------------------

function component()
  reconhecer( lex.tab_tokens.TK_COMPONENT)
  reconhecer( lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  define( name, TAB_TYPEID.COMPONENT )
  tab_curr_scope.declarations = { }
  component_tail( name )
  gotoFatherScope()
end

function component_tail( name )
  if ( tab_firsts.rule_307[ token ] ) then
    reconhecer(":", "':'")
    local component = scoped_name( 307 )
    if component._type ~= TAB_TYPEID.COMPONENT then
      semanticError( "The previously-defined type is not a COMPONENT" )
    end
    tab_curr_scope.component_base = component
    supp_inter_spec(308)
    reconhecer("{")
    component_body()
    reconhecer("}")
  elseif ( tab_firsts.rule_308[ token ] ) then
    supp_inter_spec(308)
    reconhecer("{")
    component_body()
    reconhecer("}")
  elseif ( tab_firsts.rule_309[ token ] ) then
    reconhecer("{")
    component_body()
    reconhecer("}")
  elseif ( token == ';' ) then
    dclForward( name, TAB_TYPEID.COMPONENT )
    --empty
  else
    sinError( "':', 'supports' or '{'" )
  end
end

function supp_inter_spec(num_follow_rule)
  if tab_firsts.rule_316[ token ] then
    reconhecer( lex.tab_tokens.TK_SUPPORTS)
    tab_curr_scope.supports = { }
    local interface = scoped_name( num_follow_rule )
    if interface._type ~= TAB_TYPEID.INTERFACE then
      semanticError( "The 'SUPPORTS' construction must be reference to an interface" )
    end
    table.insert( tab_curr_scope.supports, interface )
    supp_name_list(num_follow_rule)
  elseif ( tab_follow[ 'rule_'..num_follow_rule ][ token ] ) then
    -- empty
  else
    sinError( "':', ',', or "..tab_follow_rule_error_msg[ num_follow_rule ] )
  end
end

function supp_name_list(num_follow_rule)
  if ( tab_firsts.rule_321[ token ] ) then
    reconhecer(',')
    local interface = scoped_name( num_follow_rule )
    if interface._type ~= TAB_TYPEID.INTERFACE then
      semanticError( "The 'SUPPORTS' construction must be reference to an interface" )
    end
    table.insert( tab_curr_scope.supports, interface )
    supp_name_list(num_follow_rule)
  elseif ( tab_follow[ 'rule_'..num_follow_rule ][ token ] ) then
    --empty
  else
    sinError( "',' or '{'" )
  end
end

function component_body()
  if ( tab_firsts.rule_323[ token ] ) then
    component_export()
    component_body()
  elseif ( token == '}' ) then
    --empty
  else
    sinError( "'provides', 'uses', 'emits', 'publishes', 'consumes', 'readonly' 'attribute' or '}'" )
  end
end

function component_export()
  if ( tab_firsts.rule_325[ token ] ) then
    provides_dcl()
    reconhecer(';')
  elseif ( tab_firsts.rule_326[ token ] ) then
    uses_dcl()
    reconhecer(';')
  elseif ( tab_firsts.rule_327[ token ] ) then
    emits_dcl()
    reconhecer(';')
  elseif ( tab_firsts.rule_328[ token ] ) then
    publishes_dcl()
    reconhecer(';')
  elseif ( tab_firsts.rule_329[ token ] ) then
    consumes_dcl()
    reconhecer(';')
  elseif ( tab_firsts.rule_330[ token ] ) then
    attr_dcl()
    reconhecer(';')
  end
end

function provides_dcl()
  reconhecer( lex.tab_tokens.TK_PROVIDES, 'provides' )
  local tab_provides = { _type = 'provides' }
  tab_provides.interface_type = interface_type()
  reconhecer( lex.tab_tokens.TK_ID, '<identifier>' )
  local name = lex.tokenvalue_previous
--  new_name( name, name, tab_curr_scope.declarations, tab_provides, ERRMSG_DECLARED, name )
end

function interface_type()
  if ( tab_firsts.rule_332[ token ] ) then
    local scope = scoped_name( 332 )
    if scope._type ~= TAB_TYPEID.INTERFACE then
      semanticError( "The interface type of this provides declaration shall be either the keyword \
                Object or a scoped name that denotes a previously-declared interface type" )
    end
    return scope
  elseif ( tab_firsts.rule_333[ token ] ) then
    reconhecer( lex.tab_tokens.TK_OBJECT)
    return TAB_BASICTYPE.OBJECT
  else
    sinError( "<identifier> or 'Object'" )
  end
end

function uses_dcl()
  reconhecer( lex.tab_tokens.TK_USES)
  local tab_uses = { _type = 'uses' }
  tab_uses.multiple = multiple_e()
  tab_uses.interface_type = interface_type()
  reconhecer( lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
--  new_name( name, name, tab_curr_scope.declarations, tab_uses, ERRMSG_DECLARED, name )
end

function multiple_e()
  if ( tab_firsts.rule_339[ token ] ) then
    reconhecer( lex.tab_tokens.TK_MULTIPLE)
    return true
  elseif ( tab_follow.rule_340[ token ] ) then
    return nil
    --empty
  else
    sinError( "'multiple', <identifier>, ':' or 'Object'" )
  end
end

--falta event!!
function emits_dcl()
  reconhecer( lex.tab_tokens.TK_EMITS)
  local name = lex.tokenvalue_previous
  local tab_uses = { _type = 'emits' }
--  new_name( name, name, tab_curr_scope.declarations, tab_emits, ERRMSG_DECLARED, name )
  tab_uses.event_type = scoped_name( 341 )
  reconhecer( lex.tab_tokens.TK_ID)
  tab_uses.evtsrc = lex.tokenvalue_previous
end

--falta event!!
function publishes_dcl()
  reconhecer( lex.tab_tokens.TK_PUBLISHES)
  local name = lex.tokenvalue_previous
  local tab_publishes = { _type = 'publishes' }
--  new_name( name, name, tab_curr_scope.declarations, tab_publishes, ERRMSG_DECLARED, name )
  tab_uses.event_type = scoped_name( 342 )
  reconhecer( lex.tab_tokens.TK_ID)
  tab_uses.evtsrc = lex.tokenvalue_previous
end

--falta event!!
function consumes_dcl()
  reconhecer( lex.tab_tokens.TK_CONSUMES)
  local name = lex.tokenvalue_previous
  local tab_publishes = { _type = 'consumes' }
--  new_name( name, name, tab_curr_scope.declarations, tab_consumes, ERRMSG_DECLARED, name )
  tab_uses.event_type = scoped_name( 343 )
  reconhecer( lex.tab_tokens.TK_ID)
  tab_uses.evtsink = lex.tokenvalue_previous
end

--------------------------------------------------------------------------
-- HOME DECLARATION
--------------------------------------------------------------------------

--19
function home_dcl()
  reconhecer(lex.tab_tokens.TK_HOME)
  reconhecer(lex.tab_tokens.TK_ID)
  local name = lex.tokenvalue_previous
  define( name, TAB_TYPEID.HOME )
  home_dcl_tail(name)
  gotoFatherScope()
end

--19
--falta primary key
function home_dcl_tail(name)
  if ( tab_firsts.rule_345[ token ] )then
    home_inh_spec()
    supp_inter_spec(345)
    reconhecer(lex.tab_tokens.TK_MANAGES)
    local component = scoped_name(347)
    tab_curr_scope.manages = component
    primary_key_spec_e()
    reconhecer("{")
    home_export_l()
    reconhecer("}")
  elseif ( tab_firsts.rule_346[ token ] ) then
    supp_inter_spec(345)
    reconhecer(lex.tab_tokens.TK_MANAGES)
    local component = scoped_name(347)
    tab_curr_scope.manages = component
    primary_key_spec_e()
    reconhecer("{")
    home_export_l()
    reconhecer("}")
  elseif ( tab_firsts.rule_347[ token ] ) then
    reconhecer(lex.tab_tokens.TK_MANAGES)
    tab_curr_scope.component = scoped_name(347)
    primary_key_spec_e()
    reconhecer("{")
    home_export_l()
    reconhecer("}")
  else
    sin.error("'supports', 'manages', ':'")
  end
end

--19
function home_inh_spec()
  if ( tab_firsts.rule_348[ token ] ) then
    reconhecer(":")
    local home = scoped_name( 348 )
    if home._type ~= TAB_TYPEID.HOME then
      semanticError( "The previously-defined type is not a HOME" )
    end
    tab_curr_scope.home_base = home
  end
end

--(353) <primary_key_spec_e>    :=    TK_PRIMARYKEY <scoped_name>
--(354)                         |     empty
function primary_key_spec_e()
  if tab_firsts.rule_353[ token ] then
    reconhecer(lex.tab_tokens.TK_PRIMARYKEY, 'primarykey')
    scoped_name(353)
  elseif tab_follow.rule_353[ token ] then
    --empty
  end
end

--19
function home_export_l()
  if tab_firsts.rule_359[ token ] then
    home_export()
    home_export_l()
  elseif tab_follow.rule_359[ token ] then
    --empty
  end
end

--19
function home_export()
  if tab_firsts.rule_361[ token ] then
    export()
  elseif tab_firsts.rule_362[ token ] then
    factory_dcl()
    reconhecer(";")
  elseif tab_firsts.rule_363[ token ] then
    finder_dcl()
    reconhecer(";")
  else
    sinError("error")
  end
end

--19
function factory_dcl()
  if tab_firsts.rule_364[ token ] then
    reconhecer(lex.tab_tokens.TK_FACTORY)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local tab_factory = { _type = TAB_TYPEID.FACTORY, name = name }
--    new_name( name, name,
--           tab_curr_scope.members, tab_factory, ERRMSG_OPDECLARED, name )
    reconhecer("(")
    init_param_dcls(tab_factory)
    reconhecer(")")
    raises_expr_e(tab_factory)
  end
end

--19
function init_param_dcls(tab_factory)
  if tab_firsts.rule_366[ token ] then
    tab_factory.parameters = { }
    init_param_dcl(tab_factory)
    init_param_dcl_list(tab_factory)
  elseif tab_follow.rule_367[ token ] then
    --empty
  end
end

--19
function init_param_dcl(tab_factory)
  if tab_firsts.rule_297[ token ] then
    reconhecer(lex.tab_tokens.TK_IN)
    local tab_type_spec = param_type_spec()
    reconhecer(lex.tab_tokens.TK_ID)
    local param_name = lex.tokenvalue_previous
--    new_name( tab_factory.name..'._parameters.'..param_name,
--           param_name, tab_factory.parameters,
--           { mode = 'PARAM_IN', type = tab_type_spec, name = param_name },
--           ERRMSG_PARAMDECLARED
--  )
  else
    sinError("'in'")
  end
end

--19
function init_param_dcl_list(tab_factory)
  if tab_firsts.rule_368[ token ] then
    reconhecer(",")
    init_param_dcl(tab_factory)
    init_param_dcl_list(tab_factory)
  elseif tab_follow.rule_369[ token ] then
    --empty
  end
end

--19
function finder_dcl()
  if tab_firsts.rule_365[ token ] then
    reconhecer(lex.tab_tokens.TK_FINDER)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local tab_finder = { _type = TAB_TYPEID.FINDER, name = name }
--    new_name( name, name,
--           tab_curr_scope.members, tab_finder, ERRMSG_OPDECLARED, name )
    reconhecer("(")
    init_param_dcls(tab_finder)
    reconhecer(")")
    raises_expr_e(tab_finder)
  else
    sinError("'finder'")
  end
end

function value_or_event()
  if ( tab_firsts.rule_281[ token ] ) then
    reconhecer(lex.tab_tokens.TK_VALUETYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define( name, TAB_TYPEID.VALUETYPE )
    tab_curr_scope.custom = true
    local tab_valuetypescope = value_tail( name )
    if tab_callbacks.valuetype then
      tab_callbacks.valuetype( tab_valuetypescope )
    end
  elseif ( tab_firsts.rule_282[ token ] ) then
    reconhecer(lex.tab_tokens.TK_EVENTTYPE)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    define( name, TAB_TYPEID.EVENTTYPE )
    tab_curr_scope.custom = true
    local tab_eventtypescope = eventtype_tail( name )
    if tab_callbacks.eventtype then
      tab_callbacks.eventtype( tab_eventtypescope )
    end
  else
    sinError( "'valuetype' or 'eventtype'" )
  end
end
--------------------------------------------------------------------------
-- VALUE DECLARATION
--------------------------------------------------------------------------

function value_tail( name )
  if ( tab_firsts.rule_299[ token ] ) then
    return value_tail_aux( name )
  elseif ( tab_firsts.rule_298[ token ] ) then
    value_inhe_spec()
    return value_tail_aux( name )
  elseif tab_firsts.rule_300[ token ] then
    tab_curr_scope.type = type_spec()
    local tab_valuetypescope = tab_curr_scope
    gotoFatherScope()
    return tab_valuetypescope
  elseif tab_follow.rule_301[ token ] then
    return dclForward( name, TAB_TYPEID.VALUETYPE )
  end
end

function value_tail_aux( name )
    reconhecer("{")
    value_element_l()
    reconhecer("}")
    local tab_valuetypescope = tab_curr_scope
    gotoFatherScope()
    return tab_valuetypescope
end

function value_inhe_spec()
  if tab_firsts.rule_268[ token ] then
    reconhecer(":")
    local truncatable = truncatable_e()
    local value = scoped_name(268)
    if value._type ~= TAB_TYPEID.VALUETYPE and value._type ~= TAB_TYPEID.INTERFACE then
      semanticError( "The previously-defined type is not a VALUETYPE or INTERFACE" )
    end
    tab_curr_scope.value_base = { }
    tab_curr_scope.value_base.truncatable = truncatable
    table.insert( tab_curr_scope.value_base, value )
    value_name_list()
    supp_inter_spec(308)
  elseif tab_firsts.rule_269[ token ] then
    supp_inter_spec(308)
  else
    sinError( "':', 'supports'" )
  end
end

function value_name_list()
  if tab_firsts.rule_277[ token ] then
    reconhecer(",")
    local value = scoped_name(268)
    table.insert( tab_curr_scope.value_base, value )
    value_name_list()
  elseif tab_follow.rule_278[ token ] then
    --empty
  end
end

function truncatable_e()
  if tab_firsts.rule_271[ token ] then
    reconhecer(lex.tab_tokens.TK_TRUNCATABLE)
    return true
  elseif tab_follow.rule_272[ token ] then
    --empty
  end
end

function value_element_l()
  if ( tab_firsts.rule_285[ token ] ) then
    value_element()
    value_element_l()
  elseif ( tab_follow.rule_286[ token ] ) then
    --empty
  end
end

function value_element()
  if ( tab_firsts.rule_287[ token ] ) then
    export()
  elseif ( tab_firsts.rule_288[ token ] ) then
    state_member()
  elseif ( tab_firsts.rule_289[ token ] ) then
    init_dcl()
  end
end

function state_member()
  if ( tab_firsts.rule_290[ token ] ) then
    reconhecer(lex.tab_tokens.TK_PUBLIC)
    state_member_tail()
  elseif ( tab_firsts.rule_291[ token ] ) then
    reconhecer(lex.tab_tokens.TK_PRIVATE)
    state_member_tail()
  end
end

function state_member_tail()
  local tab_dcls = { }
  declarator_l( type_spec(), tab_dcls )
  reconhecer(";")
end

function init_dcl()
  if ( tab_firsts.rule_292[ token ] ) then
    reconhecer(lex.tab_tokens.TK_FACTORY)
    reconhecer(lex.tab_tokens.TK_ID)
    local name = lex.tokenvalue_previous
    local tab_factory = { _type = TAB_TYPEID.FACTORY, name = name }
--    new_name( name, name,
--           tab_curr_scope.members, tab_factory, ERRMSG_OPDECLARED, name )
    reconhecer("(")
    init_param_dcls(tab_factory)
    reconhecer(")")
    raises_expr_e(tab_factory)
    reconhecer(";")
  end
end

--------------------------------------------------------------------------
-- EVENT DECLARATION
--------------------------------------------------------------------------

function eventtype_tail(name)
  if tab_firsts.rule_302[ token ] then
    value_inhe_spec()
    reconhecer("{")
    value_element_l()
    reconhecer("}")
    local tab_eventtypescope = tab_curr_scope
    gotoFatherScope()
    return tab_eventtypescope
  elseif tab_firsts.rule_303[ token ] then
    reconhecer("{")
    value_element_l()
    reconhecer("}")
    local tab_eventtypescope = tab_curr_scope
    gotoFatherScope()
    return tab_eventtypescope
  elseif tab_follow.rule_304[ token ] then
    return dclForward( name, TAB_TYPEID.EVENTTYPE )
  end
end

--[[function type_prefix_dcl()
  if tab_firsts.rule_260[ token ] then
    reconhecer(lex.tab_tokens.TK_TYPEPREFIX)
    scoped_name()
    reconhecer(lex.tab_tokens.TK_STRING_LITERAL)
  else
    sinError( "'typeprefix'" )
  end
end
]]

--------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------

function parse( _stridl, options )
  if not options then
    options = {}
  end

  if options.callbacks then
    tab_callbacks = options.callbacks
    for type, tab in pairs( TAB_BASICTYPE ) do
      local callback = tab_callbacks[ type ]
      if callback then
        if type == 'TYPECODE' then
        else
          TAB_BASICTYPE[ type ] = callback
        end
      end
    end

    for type, tab in pairs(TAB_IMPLICITTYPE) do
      local callback = tab_callbacks[type]
      if callback then
        TAB_IMPLICITTYPE[type] = callback
      end
    end
  end

  if not tab_callbacks then
    tab_callbacks = {}
  end

  tab_output                = { absolute_name = '' }
  tab_curr_scope            = tab_output
  tab_namespaces            = {
                                [''] =   {
                                  tab_namespace = tab_output,
                                }
                              }
  tab_forward               = { }
  stridl                    = _stridl
  CORBAVisible              = nil
  currentScope              = ''
  ROOTS                     = { }
  table.insert(ROOTS, {root = '', scope = ''})
  lex.init()
  token = getToken()
--Implicit definitions
--  CORBA::TypeCode
  if not options.notypecode then
    define('CORBA', TAB_TYPEID.MODULE)
    define('TypeCode', TAB_TYPEID.TYPECODE, TAB_IMPLICITTYPE.TYPECODE)
    gotoFatherScope()
  end
-- starts parsing with the first grammar rule
  specification()
-- Removing CORBA::TypeCode implicit definition
  if (not options.notypecode) and (not CORBAVisible) then
    table.remove(tab_output, 1)
  end
  return tab_output
end
