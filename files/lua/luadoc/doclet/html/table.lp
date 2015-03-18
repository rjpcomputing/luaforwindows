<dt><a name="<%=tab.name%>"></a><strong><%=tab.name%></strong></dt>
<dd><%=tab.description%><br /><br />

<%if type(tab.field) == "table" and #tab.field > 0 then%>
<h3>Fields:</h3>
<ul>
	<%for p = 1, #tab.field do%>
	<li>
	  <code><em><%=tab.field[p]%></em></code>: <%=tab.field[tab.field[p]] or ""%>
	</li>
	<%end%>
</ul>
<%end%>

</dd>
