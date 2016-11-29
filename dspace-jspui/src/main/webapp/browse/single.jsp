<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - 
  --%>

<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="org.dspace.browse.BrowseInfo" %>
<%@ page import="org.dspace.browse.BrowseIndex" %>
<%@ page import="org.dspace.content.Collection" %>
<%@ page import="org.dspace.content.Community" %>
<%@ page import="org.dspace.content.DCDate" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.dspace.core.Utils" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>

<%
    request.setAttribute("LanguageSwitch", "hide");

	//First, get the browse info object
	BrowseInfo bi = (BrowseInfo) request.getAttribute("browse.info");

	BrowseIndex bix = bi.getBrowseIndex();

	//values used by the header
	String scope = "";
	String type = "";

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
	
	//FIXME: so this can probably be placed into the Messages.properties file at some point
	// String header = "Browsing " + scope + " by " + type;
	
	// get the values together for reporting on the browse values
	// String range = "Showing results " + bi.getStart() + " to " + bi.getFinish() + " of " + bi.getTotal();
	
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
	String sharedLink = linkBase + "browse?type=" + URLEncoder.encode(bix.getName(), "UTF-8") +
						"&amp;order=" + URLEncoder.encode(direction, "UTF-8") +
						"&amp;rpp=" + URLEncoder.encode(Integer.toString(bi.getResultsPerPage()), "UTF-8");
	
	// prepare the next and previous links
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

	// added by Kate to return to the collection page. There is something wrong with contextpath so has
	// to normilize
	String collectionHome = UIUtil.normalizePath(formaction);


	if (collection != null)
	{
		formaction = formaction + "handle/" + collection.getHandle() + "/";
		collectionHome = collectionHome + "handle/" + collection.getHandle();
	}
	if (community != null)
	{
		formaction = formaction + "handle/" + community.getHandle() + "/";
	}
	formaction = formaction + "browse";
	
	String ascSelected = (bi.isAscending() ? "selected=\"selected\"" : "");
	String descSelected = (bi.isAscending() ? "" : "selected=\"selected\"");
	int rpp = bi.getResultsPerPage();
	
//	 the message key for the type
	String typeKey = "browse.type.metadata." + bix.getName();


%>

<dspace:layout locbar="Link" titlekey="browse.page-title"  parenttitle="<%= scope %>" parentlink="<%= collectionHome %>" >

	<%-- Build the header (careful use of spacing) --%>
	<header class="browseheader">
	<h2>
		<fmt:message key="browse.single.header"><fmt:param value="<%= scope %>"/></fmt:message> <fmt:message key="<%= typeKey %>"/>
	</h2>
	</header>
<%
	if (!bix.isTagCloudEnabled())
	{
%>




	<%-- give us the top report on what we are looking at --%>
	<div class="taxonomy-browse ">
	<div class=" browselist-heading">
	<div class="start-to-finish-info flexset">
		<fmt:message key="browse.single.range">
			<fmt:param value="<%= Integer.toString(bi.getStart()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getFinish()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getTotal()) %>"/>
		</fmt:message>
		</div>

	<%-- Include a component for modifying sort by, order and results per page --%>
		<div class="flexset discovery-pagination-controls f1">
			<form method="get" action="<%= formaction %>">
			<input type="hidden" name="type" value="<%= bix.getName() %>"/>
		
<%-- The following code can be used to force the browse around the current focus.  Without
      it the browse will revert to page 1 of the results each time a change is made --%>
<%--
		if (!bi.hasItemFocus() && bi.hasFocus())
		{
			%><input type="hidden" name="vfocus" value="<%= bi.getFocus() %>"/><%
		}
--%>
	<%--	<label for="order"><fmt:message key="browse.single.order"/></label>--%>
		<select name="order" id="order_sort" class="form-control">
		<%--		<fmt:message key="browse.order.asc" />--%>
			<option value="ASC" <%= ascSelected %>>Sorting A-Z</option>
			<option value="DESC" <%= descSelected %>>Sorting Z-A</option>
		</select>
		
		<%--	<label for="rpp"><fmt:message key="browse.single.rpp"/></label>--%>
		<select name="rpp" class="form-control" id="rpp_select">
<%
	for (int i = 10; i <= 100 ; i += 10)
	{
		String selected = (i == rpp ? "selected=\"selected\"" : "");
%>	
			<option value="<%= i %>" <%= selected %>><%= i %> per page</option>
<%
	}
%>
		</select>
		<input type="submit" style="display:none" class="btn btn-default" name="submit_browse" value="<fmt:message key="jsp.general.update"/>"/>
	</form>
	</div>
	</div>
	<%--  do the bottom previous and next page links --%>
<% 
	if (bi.hasPrevPage())
	{
%>
	<a class="pull-left" href="<%= prev %>"><fmt:message key="browse.single.prev"/></a>&nbsp;
<%
	}
%>

<%
	if (bi.hasNextPage())
	{
%>
	&nbsp;<a class="pull-right" href="<%= next %>"><fmt:message key="browse.single.next"/></a>
<%
	}
%>
<ul class="list-group facets">
<%
    String[][] results = bi.getStringResults();

    for (int i = 0; i < results.length; i++)
    {
%>
      <li >
            <% if(bi.getBrowseIndex().getDataType().equals("semester"))
              { %>
              <a href="<%= sharedLink %><% if (results[i][1] != null) { %>&amp;authority=<%= URLEncoder.encode(results[i][1], "UTF-8") %>" class="authority <%= bix.getName() %>"><%= UIUtil.returnSemester(Utils.addEntities(results[i][0])) %></a> <% } else { %>&amp;value=<%= URLEncoder.encode(results[i][0], "UTF-8") %>"><%= UIUtil.returnSemester(Utils.addEntities(results[i][0])) %>	<%= StringUtils.isNotBlank(results[i][2])?" <span class=\"badge\">"+results[i][2]+" </span>":""%></a> <% } %>
              <% }
              else
               { %>
               <a href="<%= sharedLink %><% if (results[i][1] != null) { %>&amp;authority=<%= URLEncoder.encode(results[i][1], "UTF-8") %>" class="authority <%= bix.getName() %>"><%= Utils.addEntities(results[i][0]) %></a> <% } else { %>&amp;value=<%= URLEncoder.encode(results[i][0], "UTF-8") %>"><%= Utils.addEntities(results[i][0]) %>	<%= StringUtils.isNotBlank(results[i][2])?" <span class=\"badge\">"+results[i][2]+"</span>":""%></a> <% } %>
               <%}%>
      </li>
<%
    }
%>
        </ul></div>
	<%-- give us the bottom report on what we are looking at --%>
	<div class="text-center">
		<fmt:message key="browse.single.range">
			<fmt:param value="<%= Integer.toString(bi.getStart()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getFinish()) %>"/>
			<fmt:param value="<%= Integer.toString(bi.getTotal()) %>"/>
		</fmt:message>

	<%--  do the bottom previous and next page links --%>
<% 
	if (bi.hasPrevPage())
	{
%>
	<a class="pull-left" href="<%= prev %>"><fmt:message key="browse.single.prev"/></a>&nbsp;
<%
	}
%>

<%
	if (bi.hasNextPage())
	{
%>
	&nbsp;<a class="pull-right" href="<%= next %>"><fmt:message key="browse.single.next"/></a>
<%
	}
%>
	</div>


	<%-- dump the results for debug (uncomment to enable) --%>
	<%-- 
	<!-- <%= bi.toString() %> -->
    --%>
<%
	}
	else {
	
%>
<div class="row" style="overflow:hidden">
	<%@ include file="static-tagcloud-browse.jsp" %>
</div>
<%
	}
%>

<script type="text/javascript">
	var jQ = jQuery.noConflict();
	jQ(document).ready(function() {
			jQ("#order_sort").change(function(){
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
