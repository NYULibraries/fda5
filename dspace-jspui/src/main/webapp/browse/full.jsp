<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Display the results of browsing a full hit list
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="org.dspace.browse.BrowseInfo" %>
<%@ page import="org.dspace.sort.SortOption" %>
<%@ page import="org.dspace.content.Collection" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.browse.BrowseIndex" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.content.DCDate" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>

<%
    request.setAttribute("LanguageSwitch", "hide");

    String urlFragment = "browse";
    String layoutNavbar = "default";
    boolean withdrawn = false;
    boolean privateitems = false;
	if (request.getAttribute("browseWithdrawn") != null)
	{
	    layoutNavbar = "admin";
        urlFragment = "dspace-admin/withdrawn";
        withdrawn = true;
    }
	else if (request.getAttribute("browsePrivate") != null)
	{
	    layoutNavbar = "admin";
        urlFragment = "dspace-admin/privateitems";
        privateitems = true;
    }

	// First, get the browse info object
	BrowseInfo bi = (BrowseInfo) request.getAttribute("browse.info");
	BrowseIndex bix = bi.getBrowseIndex();
	SortOption so = bi.getSortOption();

	// values used by the header
	String scope = "";
	String type = "";
	String value = "";
	
	Community community = null;
	Collection collection = null;
	if (bi.inCommunity())
	{
		community = (Community) bi.getBrowseContainer();
	}
	if (bi.inCollection())
	{
		collection = (Collection) bi.getBrowseContainer();
	}
	
	if (community != null)
	{
		scope = "\"" + community.getMetadata("name") + "\"";
	}
	if (collection != null)
	{
		scope = "\"" + collection.getMetadata("name") + "\"";
	}
	
	type = bix.getName();
	
	// next and previous links are of the form:
	// [handle/<prefix>/<suffix>/]browse?type=<type>&sort_by=<sort_by>&order=<order>[&value=<value>][&rpp=<rpp>][&[focus=<focus>|vfocus=<vfocus>]
	
	// prepare the next and previous links
	String linkBase = request.getContextPath() + "/";
	if (collection != null)
	{
		linkBase = linkBase + "handle/" + collection.getHandle() + "/";
	}
	if (community != null)
	{
		linkBase = linkBase + "handle/" + community.getHandle() + "/";
	}
	
	String direction = (bi.isAscending() ? "ASC" : "DESC");
	
	String argument = null;
	if (bi.hasAuthority())
    {
        value = bi.getAuthority();
        argument = "authority";
    }
	else if (bi.hasValue())
	{
		value = bi.getValue();
	    argument = "value";
	}

	String valueString = "";
	if (value!=null)
	{
		valueString = "&amp;" + argument + "=" + URLEncoder.encode(value, "UTF-8");
	}
	
    String sharedLink = linkBase + urlFragment + "?";

    if (bix.getName() != null)
        sharedLink += "type=" + URLEncoder.encode(bix.getName(), "UTF-8");

    sharedLink += "&amp;sort_by=" + URLEncoder.encode(Integer.toString(so.getNumber()), "UTF-8") +
				  "&amp;order=" + URLEncoder.encode(direction, "UTF-8") +
				  "&amp;rpp=" + URLEncoder.encode(Integer.toString(bi.getResultsPerPage()), "UTF-8") +
				  "&amp;etal=" + URLEncoder.encode(Integer.toString(bi.getEtAl()), "UTF-8") +
				  valueString;
	
	String next = sharedLink;
	String prev = sharedLink;
	
	if (bi.hasNextPage())
    {
        next = next + "&amp;offset=" + bi.getNextOffset();
    }
	
	if (bi.hasPrevPage())
    {
        prev = prev + "&amp;offset=" + bi.getPrevOffset();
    }
	
	// prepare a url for use by form actions
	String formaction = request.getContextPath() + "/";
	if (collection != null)
	{
		formaction = formaction + "handle/" + collection.getHandle() + "/";
	}
	if (community != null)
	{
		formaction = formaction + "handle/" + community.getHandle() + "/";
	}
	formaction = formaction + urlFragment;
	
	// prepare the known information about sorting, ordering and results per page
	String sortedBy = so.getName();
	String ascSelected = (bi.isAscending() ? "selected=\"selected\"" : "");
	String descSelected = (bi.isAscending() ? "" : "selected=\"selected\"");
	String theNum = Integer.toString(so.getNumber());
	String titleAscSelected = 	((direction.equalsIgnoreCase("ASC") && theNum.equals("1")) ? "selected=\"selected\"" : "");
  String titleDescSelected = 	((direction.equalsIgnoreCase("DESC") && theNum.equals("1"))  ? "selected=\"selected\"" : "");
 	String dateIAscSelected = 	((direction.equalsIgnoreCase("ASC") && theNum.equals("2")) ? "selected=\"selected\"" : "");
  String dateIDescSelected = 	((direction.equalsIgnoreCase("DESC") && theNum.equals("2")) ? "selected=\"selected\"" : "");
  String dateSAscSelected = 	((direction.equalsIgnoreCase("ASC") && theNum.equals("3")) ? "selected=\"selected\"" : "");
  String dateSDescSelected = 	((direction.equalsIgnoreCase("DESC") && theNum.equals("3")) ? "selected=\"selected\"" : "");


	int rpp = bi.getResultsPerPage();
	
	// the message key for the type
	String typeKey;

	if (bix.isMetadataIndex())
		typeKey = "browse.type.metadata." + bix.getName();
	else if (bi.getSortOption() != null)
		typeKey = "browse.type.item." + bi.getSortOption().getName();
	else
		typeKey = "browse.type.item." + bix.getSortOption().getName();

    // Admin user or not
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());
%>

<%-- OK, so here we start to develop the various components we will use in the UI --%>

<%@page import="java.util.Set"%>
<dspace:layout locbar="Link" titlekey="browse.page-title" navbar="<%=layoutNavbar %>">

	<%-- Build the header (careful use of spacing) --%>
	<h2>
		<fmt:message key="browse.full.header"><fmt:param value="<%= scope %>"/></fmt:message> <fmt:message key="<%= typeKey %>"/> <%= value %>
	</h2>

	<%-- Include the main navigation for all the browse pages --%>
	<%-- This first part is where we render the standard bits required by both possibly navigations --%>
	
	<%-- End of Navigation Headers --%>

	<%-- Include a component for modifying sort by, order, results per page, and et-al limit --%>
	<div id="browse_controls" class="discovery-pagination-controls">
	<form method="get" action="<%= formaction %>">
		<input type="hidden" name="type" value="<%= bix.getName() %>"/>
<%
		if (bi.hasAuthority())
		{
		%><input type="hidden" name="authority" value="<%=bi.getAuthority() %>"/><%
		}
		else if (bi.hasValue())
		{
			%><input type="hidden" name="value" value="<%= bi.getValue() %>"/><%
		}
%>
<%-- The following code can be used to force the browse around the current focus.  Without
      it the browse will revert to page 1 of the results each time a change is made --%>
<%--
		if (!bi.hasItemFocus() && bi.hasFocus())
		{
			%><input type="hidden" name="vfocus" value="<%= bi.getFocus() %>"/><%
		}
--%>

<%--
		if (bi.hasItemFocus())
		{
			%><input type="hidden" name="focus" value="<%= bi.getFocusItem() %>"/><%
		}
--%>
<%
	Set<SortOption> sortOptions = SortOption.getSortOptions();
	if (sortOptions.size() > 1) // && bi.getBrowseLevel() > 0
	{



		%>
	

		<select name="sort_by" id="sort_by" class="form-control">
 				<option value="1" data-order="ASC"  <%= titleAscSelected %>>Title A-Z</option>
 				<option value="1" data-order="DESC" <%= titleDescSelected %>>Title Z-A</option>
 				<option value="2" data-order="DESC" <%= dateIDescSelected %>>Issue date newest</option>
 				<option value="2" data-order="ASC" 	<%= dateIAscSelected %>>Issue date oldest</option>
 				<option value="3" data-order="DESC" <%= dateSDescSelected %>>Submit date newest</option>
 				<option value="3" data-order="ASC" 	<%= dateSAscSelected %>>Submit date oldest</option>
		</select>

		<input type="hidden" value="<%= direction %>" name="order" />
<%
	}
%>
	
	<select name="rpp" id="rpp_select" class="form-control">
<%
	for (int i = 5; i <= 100 ; i += 5)
	{
		String selected = (i == rpp ? "selected=\"selected\"" : "");
%>	
			<option value="<%= i %>" <%= selected %>><%= i %></option>
<%
	}
%>
	</select>


	<input type="submit" style="display:none" class="btn btn-default" name="submit_browse" value="<fmt:message key="jsp.general.update"/>"/>

<%
    if (admin_button && !withdrawn && !privateitems)
    {
        %><input type="submit" class="btn btn-default" name="submit_export_metadata" value="<fmt:message key="jsp.general.metadataexport.button"/>" /><%
    }
%>

	</form>
	</div>
<div class="panelx panel-primaryx browsing-by">
	<%-- give us the top report on what we are looking at --%>
	<div class="panel-headingx ">
		<fmt:message key="browse.full.range">
			<fmt:param value="<%= Integer.toString(bi.getStart()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getFinish()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getTotal()) %>"/>
		</fmt:message>

	<%--  do the top previous and next page links --%>
<% 
	if (bi.hasPrevPage())
	{
%>
	<a class="pull-left" href="<%= prev %>"><fmt:message key="browse.full.prev"/></a>&nbsp;
<%
	}
%>

<%
	if (bi.hasNextPage())
	{
%>
	&nbsp;<a class="pull-right" href="<%= next %>"><fmt:message key="browse.full.next"/></a>
<%
	}
%>
	</div>
	
    <%-- output the results using the browselist tag --%>
    <%
    	if (bix.isMetadataIndex())
    	{
    %>
	<dspace:browselist browseInfo="<%= bi %>" emphcolumn="<%= bix.getMetadata() %>" />
    <%
        }
        else if (withdrawn || privateitems)
        {
    %>
    <dspace:browselist browseInfo="<%= bi %>" emphcolumn="<%= bix.getSortOption().getMetadata() %>" linkToEdit="true" disableCrossLinks="true" />
	<%
    	}
    	else
    	{
	%>
	<dspace:browselist browseInfo="<%= bi %>" emphcolumn="<%= bix.getSortOption().getMetadata() %>" />
	<%
    	}
	%>
	<%-- give us the bottom report on what we are looking at --%>
	<div class="panel-footer text-center">
		<fmt:message key="browse.full.range">
			<fmt:param value="<%= Integer.toString(bi.getStart()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getFinish()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getTotal()) %>"/>
		</fmt:message>

	<%--  do the bottom previous and next page links --%>
<% 
	if (bi.hasPrevPage())
	{
%>
	<a class="pull-left" href="<%= prev %>"><fmt:message key="browse.full.prev"/></a>&nbsp;
<%
	}
%>

<%
	if (bi.hasNextPage())
	{
%>
	&nbsp;<a class="pull-right" href="<%= next %>"><fmt:message key="browse.full.next"/></a>
<%
	}
%>
	</div>
</div>
	<%-- dump the results for debug (uncomment to enable) --%>
	<%-- 
	<!-- <%= bi.toString() %> -->
	--%>
<script type="text/javascript">
	var jQ = jQuery.noConflict();
	jQ(document).ready(function() {
			jQ("#sort_by").change(function(){
				var direction = jQ(this).find("option:selected").attr('data-order');
				var hiddenfield = jQ(this).closest('form').find('input[name=order]');
				hiddenfield.val(direction);
				jQ(this).closest('form').trigger('submit');
			});
    	jQ("#rpp_select").change(function(){
       	jQ(this).closest('form').trigger('submit');
			});
	});
</script>		

</dspace:layout>
